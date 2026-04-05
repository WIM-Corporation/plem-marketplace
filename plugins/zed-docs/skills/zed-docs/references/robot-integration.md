---
description: "ZED robot integration — manipulator TF setup, URDF 2-Layer pattern, multi-camera, streaming bridge, diagnostics"
---

# ZED Robot Integration

## 1. TF 결정 (CRITICAL — 먼저 읽을 것)

TF 설정 오류 시 ZED driver ↔ robot_state_publisher 간 충돌 → "chaotic behaviors" (좌표계 깜빡임, 위치 불일치).

### 결정 흐름도

```
고정형 manipulator? → publish_tf: false, publish_map_tf: false
모바일 로봇?       → publish_tf: true (camera #1 only)
다중 카메라?       → camera #1만 publish_tf: true, 나머지 false
```

### 고정형 Manipulator (plem)

`base_link`가 PARENT, `camera_link`가 CHILD.
Manipulator TF 트리(robot_state_publisher / MoveIt)가 권위를 가짐.
ZED `camera_link`는 마운트 포인트 링크의 child로 부착.

ZED driver에서 **반드시** 비활성화할 파라미터:
```yaml
pos_tracking:
  pos_tracking_enabled: false   # 로봇 FK가 위치를 제공하므로 VIO 불필요
  publish_tf: false
  publish_map_tf: false
depth:
  depth_stabilization: 0        # 이것 없으면 카메라 멈춤 (아래 설명 참조)
```

비활성화 안 하면 ZED가 독립적인 `odom → camera_link` TF를 발행하여
`base_link → camera_link` 경로와 충돌한다.

### `depth_stabilization`과 `pos_tracking_enabled` 필수 조합

`depth_stabilization`의 기본값은 1이다. 이 값이 0이 아니면 SDK 내부에서
positional tracking을 활성화하여 `base_link` TF를 기다린다.
그런데 `publish_tf: false`로 ZED의 TF 발행을 꺼 놓았으므로,
SDK가 TF를 기다리며 **카메라가 멈춘다** (데이터 발행 중단, 에러 로그 없음).

이 조합은 **로봇 통합 시 거의 반드시 겪는 문제**이지만, 증상이
"아무 에러 없이 카메라가 그냥 안 됨"이라 원인을 찾기 어렵다.

```bash
# launch 시 param_overrides로 한 줄에 설정하는 예
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    param_overrides:="pos_tracking.pos_tracking_enabled:=false;pos_tracking.publish_tf:=false;pos_tracking.publish_map_tf:=false;depth.depth_stabilization:=0"
```

### ZED RSP와 Robot RSP 이중 발행

`camera_name`이 URDF의 카메라 프레임 prefix와 일치하면,
ZED 드라이버의 내장 `robot_state_publisher`와 로봇 쪽 `robot_state_publisher`가
**같은 프레임을 동시에 발행**할 수 있다.

해결:
- `publish_urdf: false` — ZED 드라이버의 RSP를 비활성화
- 또는 `camera_name`을 URDF와 다르게 설정 (비권장 — 프레임명 불일치 유발)

### 모바일 로봇 (참고 — plem 해당 없음)

`use_zed_localization: true` → `camera_link`가 PARENT, `base_link`가 CHILD.
TF: `map → odom → camera_link → base_link`
Origin은 **반전**: `xyz="-0.12 0.0 -0.25"` (parent-child 역전 때문)

## 2. URDF — plem 2-Layer 패턴

| Layer | 패키지 | 역할 |
|------|--------|------|
| 1 | `neuromeka_description` | 로봇 본체 URDF |
| 2 | `stereolabs_description` | ZED 카메라 URDF (이 패키지) |
| 3 | `neuromeka_integrations` | 통합 xacro / SRDF |

ZED URDF는 Integration Layer 통합 xacro를 통해 포함.
Hand-Eye 캘리브레이션: `neuromeka_integrations/urdf/sensors/config/zedxm_mount.yaml`

ZED wrapper 공식 xacro 매크로:
```xml
<xacro:include filename="$(find zed_wrapper)/urdf/zed_macro.urdf.xacro" />
<xacro:zed_camera name="$(arg camera_name)" model="$(arg camera_model)" />
```
→ `<camera_name>_camera_link` reference link 생성.

### Mount YAML — rpy가 의미하는 것

mount YAML의 `x, y, z, roll, pitch, yaw`는 **URDF `<joint>` `<origin>`의 xyz/rpy**다.
즉, `parent_link`(예: `link6`) → `camera_link`(나사 구멍) 사이 fixed joint의 변환을 정의한다.

```yaml
# zedxm_mount.yaml 예시
camera_mount:
  x: 0.0626      # parent_link 원점에서 카메라까지의 x 오프셋 (m)
  y: 0.0019      # y 오프셋
  z: 0.2182      # z 오프셋
  roll: 0.0061   # parent_link → camera_link 회전 (rad)
  pitch: 0.0030
  yaw: 0.00
```

핵심 포인트:
- **reference point는 `camera_link` = 카메라 나사 구멍** (body center가 아님)
- rpy는 라디안 단위, URDF 표준 `<origin rpy="R P Y"/>` 순서 (X-Y-Z extrinsic = Z-Y-X intrinsic)
- ZED 공식 매크로가 `camera_link` 아래에 `left_camera_frame`, `left_camera_frame_optical` 등을 자동 생성

### Optical Frame vs Body Frame 축 차이

ZED SDK는 **body frame** (X-right, Y-up, Z-backward)을 사용하고,
ROS optical frame은 **카메라 광학 표준** (X-right, Y-down, Z-forward)을 사용한다.

```
Body frame (camera_link):     Optical frame (_optical):
      Y (up)                        Z (forward/depth)
      |                             |
      |                             |
      +--- X (right)                +--- X (right)
     /                             /
    Z (backward)                  Y (down)
```

ZED 공식 xacro 매크로가 `camera_link` → `left_camera_frame_optical` 사이에
90도 회전을 자동 삽입하므로, mount YAML에서는 **body frame 기준으로만** rpy를 설정한다.
Point cloud 토픽의 `frame_id`는 optical frame이므로 RViz에서는 Z-forward로 표시된다.

### Hand-Eye 캘리브레이션 결과를 Mount YAML에 넣는 방법

Hand-Eye 캘리브레이션 도구는 보통 4x4 변환 행렬 또는 quaternion으로 결과를 제공한다.
이를 mount YAML에 넣으려면 RPY로 변환해야 한다.

```python
# quaternion → RPY 변환 예시
import numpy as np
from scipy.spatial.transform import Rotation

# 캘리브레이션 결과 (예시)
quat = [qx, qy, qz, qw]  # scipy 순서: x, y, z, w
t = [tx, ty, tz]           # 미터 단위

r = Rotation.from_quat(quat)
rpy = r.as_euler('xyz', degrees=False)  # URDF extrinsic XYZ 순서

print(f"x: {t[0]:.4f}")
print(f"y: {t[1]:.4f}")
print(f"z: {t[2]:.4f}")
print(f"roll: {rpy[0]:.4f}")
print(f"pitch: {rpy[1]:.4f}")
print(f"yaw: {rpy[2]:.4f}")
```

> **참고**: 캘리브레이션 결과의 z가 body center 기준이면, camera_link(나사 구멍) 기준으로
> 보정해야 한다. ZED X Mini의 경우 body center → 나사 구멍 오프셋은 약 -0.016m (높이의 절반).

> **yaw=0인 이유**: 로봇 end-effector에 카메라를 마운트할 때, 보통 카메라 정면이
> 로봇 tool frame의 Z축과 정렬된다. yaw 오프셋이 발생하면 물리적 마운트 각도를 확인한다.

## 3. Multi-Camera

```bash
ros2 launch zed_multi_camera zed_multi_camera.launch.py \
    cam_names:='[zed_front,zed_rear]' \
    cam_models:='[zedx,zedxm]' \
    cam_serials:='[<serial1>,<serial2>]'
```

핵심 규칙:
- 모든 노드는 `zed_multi` namespace + 동일 컨테이너
- **camera #1만** `publish_tf: true`, 나머지 **반드시** `false`
- URDF: 첫 번째 카메라 joint는 parent/child 반전 (visual odometry reference)
- 시리얼 확인: `ZED_Explorer -a`

## 4. Streaming Bridge (GPU 인코딩 원격 시각화)

DDS 대신 단일 GPU 인코딩 스트림으로 원격 시각화. 서버/클라이언트 양쪽 NVIDIA GPU 필수.

**서버** (Jetson with ZED):
```yaml
stream_server:
  stream_enabled: true
  codec: 'H265'
  port: 30000           # 반드시 짝수
  bitrate: 12500        # Kbps
  adaptative_bitrate: true
```

런타임: `ros2 service call /zed/zed_node/enable_streaming std_srvs/srv/SetBool "{data: true}"`

**클라이언트** (원격 PC):
```bash
ros2 launch zed_wrapper zed_camera.launch.py \
    camera_model:=zedxm stream_address:=<jetson_ip> stream_port:=30000
```

장점: 각 클라이언트가 depth/OD 등 기능을 독립 설정. 네트워크는 압축 스트림만 통과.

## 5. Point Cloud 방향 트러블슈팅

### 증상

RViz에서 point cloud가 카메라 시야와 다른 방향에 표시된다.
예: 카메라가 아래를 보는데 point cloud가 위를 향하거나 옆으로 나온다.

### 원인

mount YAML의 rpy 값이 실제 카메라 장착 방향과 일치하지 않는다.
특히 Hand-Eye 캘리브레이션 없이 초기 셋업할 때 거의 반드시 겪는다.

### 진단 방법: static_transform_publisher로 런타임 실험

mount YAML을 수정하고 재빌드하는 대신, `static_transform_publisher`로
런타임에 rpy를 바꿔가며 올바른 방향을 찾는다.

```bash
# 1. 로봇 + ZED 노드 실행 (기존 mount joint가 있으면 그대로)

# 2. 90도 단위로 brute-force 테스트
#    parent_link(link6) → camera_link 사이의 회전을 직접 발행
ros2 run tf2_ros static_transform_publisher \
    --x 0.06 --y 0.0 --z 0.22 \
    --roll 0.0 --pitch 0.0 --yaw 0.0 \
    --frame-id link6 --child-frame-id indy_cam_camera_link

# 3. RViz에서 point cloud 방향 확인
# 4. 틀리면 roll/pitch/yaw를 pi/2 (1.5708) 단위로 변경하며 반복
#    예: --roll 1.5708 --pitch 0.0 --yaw 0.0
#    예: --roll 0.0 --pitch 1.5708 --yaw 0.0
#    예: --roll 3.1416 --pitch 0.0 --yaw 0.0
```

### 해결

올바른 rpy를 찾으면 mount YAML에 반영한다:

```yaml
camera_mount:
  x: 0.06
  y: 0.0
  z: 0.22
  roll: 0.0        # 확정된 값
  pitch: 1.5708    # 확정된 값
  yaw: 0.0
```

이후 정밀 조정이 필요하면 Hand-Eye 캘리브레이션을 수행한다 (위 2절 참조).

## 6. Diagnostics

`/diagnostics` 토픽: grab frequency, frame drop rate, publishing rates, temperature, module statuses.

```bash
ros2 topic echo /diagnostics
```

## 체크리스트

- [ ] `pos_tracking_enabled: false` (로봇 FK가 위치 제공)
- [ ] `publish_tf: false`, `publish_map_tf: false` (fixed-base manipulator)
- [ ] `depth_stabilization: 0` (없으면 카메라 멈춤)
- [ ] `publish_urdf: false` (robot RSP와 이중 발행 방지)
- [ ] Integration Layer xacro에 ZED 매크로 포함 + mount joint 정의
- [ ] `zedxm_mount.yaml`의 rpy 값이 실제 마운트 방향과 일치하는지 확인
- [ ] Point cloud 방향이 카메라 시야와 일치하는지 RViz에서 확인
- [ ] 다중 카메라 시 camera #1만 TF 발행
- [ ] Streaming bridge: server/client 양쪽 NVIDIA GPU 확인
