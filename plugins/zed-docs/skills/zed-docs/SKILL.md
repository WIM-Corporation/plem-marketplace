---
name: zed-docs
description: "ZED camera ROS 2 integration reference. Use when working with Stereolabs ZED cameras, depth sensing, point clouds, YOLO 3D detection, DDS tuning, TF alignment, or any zed_wrapper configuration."
argument-hint: "[topic]"
---

# ZED Camera ROS 2 — Reference Skill

`zed-ros2-wrapper` 사용 시 필수 규칙과 상세 레퍼런스를 제공한다.
인자로 토픽을 지정하면 해당 상세 문서를 바로 참조한다.

## Quick Routing

사용자 질문에 따라 적절한 reference 문서를 읽어 답변한다:

| 사용자가 묻는 것 | 읽어야 할 문서 | 핵심 키워드 |
|----------------|--------------|------------|
| 토픽/서비스/파라미터 전체 목록 | `references/ros2-api-reference.md` | topic, service, parameter, 파라미터 |
| YOLO 3D detection 통합 | `references/yolo-integration.md` | yolo, object detection, onnx, 물체 감지 |
| YOLO config 작성법 | `references/yolo-config.md` | yolo config, class, detection_model |
| DDS/네트워크 튜닝 | `references/dds-network.md` | dds, cyclone, 커널 버퍼, 토픽 안옴 |
| 성능 최적화 | `references/optimization.md` | 느림, cpu, latency, frequency, ROI |
| TF/URDF/마운트/멀티카메라 | `references/robot-integration.md` | tf, urdf, mount, 마운트, multi-camera |
| RViz 확인/SVO/OD 데모 | `references/usage-guide.md` | rviz, svo, recording, 데모 |
| 녹화/재생/벤치마크 | `references/recording.md` | rosbag, svo, 녹화, 재생 |

인자가 없으면 아래 핵심 규칙을 기반으로 답변하고, 상세가 필요하면 해당 reference를 읽는다.

---

## 핵심 규칙

### 카메라 모델

| 모델 | `camera_model` | 연결 |
|------|----------------|------|
| ZED / ZED Mini | `zed` / `zedm` | USB 3.0 |
| ZED 2 / 2i | `zed2` / `zed2i` | USB 3.0 |
| ZED X / X Mini | `zedx` / `zedxm` | GMSL2 |
| ZED X HDR / Mini / Max | `zedxhdr` / `zedxhdrmini` / `zedxhdrmax` | GMSL2 |
| ZED X One GS / 4K / HDR | `zedxonegs` / `zedxone4k` / `zedxonehdr` | GMSL2 (단안) |

GMSL2 카메라는 ZED Link + Jetson 필수. ZED X One은 단안이라 위치 추적/매핑 미지원.

### QoS — Silent Failure 원인 1위

드라이버 기본 QoS: **RELIABLE + VOLATILE**. 구독자 QoS 불일치 시 데이터가 오지 않고 에러도 없다.

```python
# 올바른 구독 예
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy

qos = QoSProfile(
    reliability=ReliabilityPolicy.BEST_EFFORT,
    history=HistoryPolicy.KEEP_LAST,
    depth=1
)
self.create_subscription(Image, topic, cb, qos)
```

> **참고**: BEST_EFFORT 구독자는 RELIABLE 발행자에 연결 가능하지만, 데이터 손실이 발생할 수 있다. 신뢰성이 중요하면 `RELIABLE`로 매칭한다. 대부분의 이미지/포인트클라우드 구독에서는 `BEST_EFFORT`가 적합하다 (프레임 드롭 허용).

TRANSIENT_LOCAL 사용 시 연결 자체가 안 된다. 반드시 VOLATILE 사용.

### 토픽명 (v5.1+ 네이밍)

접두사: `/<camera_name>/<node_name>/` (기본: `/zed/zed_node/`)

| 기능 | 토픽 | 흔한 실수 |
|------|------|----------|
| 이미지 | `rgb/color/rect/image` | ~~`rgb/image_rect_color`~~ |
| 깊이 | `depth/depth_registered` | |
| Point Cloud | `point_cloud/cloud_registered` | ~~`point_cloud/cloud`~~ |
| Disparity | `disparity/disparity_image` | ~~`disparity/disparity`~~ |
| 신뢰도 | `confidence/confidence_map` | ~~`depth/confidence_map`~~ |
| Object Detection | `obj_det/objects` | ~~`objects`~~ |
| Body Tracking | `body_trk/skeletons` | |
| Fused Cloud | `mapping/fused_cloud` | ~~`fused_cloud`~~ |

### 다중 카메라

`camera_name` + `serial_number`로 namespace 분리:

```bash
ros2 launch zed_wrapper zed_camera.launch.py \
    camera_model:=zedxm camera_name:=front serial_number:=12345678
# → /front/zed_node/...
```

시리얼 확인: `ZED_Explorer -a`

### TF 프레임 정합

plem URDF 사용 시 (벤더링 공식 매크로):
- 프레임명이 ZED 드라이버와 100% 일치
- 카메라 이름 규칙: `{prefix}{name}_cam` (예: `indy_cam`)
- 주요 프레임: `{cam_name}_camera_link`, `{cam_name}_left_camera_frame_optical`
- 드라이버 TF 비활성화 필수:

```yaml
pos_tracking:
  publish_tf: false
  publish_map_tf: false
```

드라이버와 `robot_state_publisher`가 동시에 TF를 발행하면 프레임 충돌이 발생한다. plem이 TF를 관리하므로 드라이버 쪽을 비활성화한다.

상세: `references/robot-integration.md`

### Headless (SSH) — NITROS SIGSEGV

`DISPLAY` 미설정 환경에서 NITROS EGL 초기화 실패 → SIGSEGV:

```
nvbufsurftransform: Could not get EGL display connection
exit code -11 (SIGSEGV)
```

해결: `param_overrides:="debug.disable_nitros:=true"`

### `param_overrides` — 파라미터 오버라이드

YAML 수정 없이 최고 우선순위로 파라미터를 오버라이드한다. 세미콜론 구분:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    param_overrides:="object_detection.od_enabled:=true;debug.disable_nitros:=true"
```

`od_enabled:=true`를 launch arg로 직접 전달하면 효과 없다. `zed_camera.launch.py`에 미선언된 arg이므로 ROS 2가 경고 없이 무시한다. 반드시 `param_overrides` 사용.

### Lazy Publishing

ZED는 구독자가 있을 때만 publish한다. 데이터 미수신 시 구독자 수를 확인한다:

```bash
ros2 topic info /zed/zed_node/rgb/color/rect/image
```

### 첫 실행 AI 모델 최적화

Object Detection / Body Tracking 첫 실행 시 TensorRT 최적화에 수 분이 소요된다.
캐시 위치: `/usr/local/zed/resources/` (이후 즉시 로드)

### `zed_msgs` 핵심 메시지

**Object** (`obj_det/objects`):
- `label`, `label_id`, `confidence`(1-99), `position[3]`(m), `velocity[3]`(m/s)
- `tracking_state`: 0=OFF, 1=OK, 2=SEARCHING, 3=TERMINATE
- `bounding_box_2d`(4 corners), `bounding_box_3d`(8 corners), `dimensions_3d[w,h,l]`(m)

**HealthStatusStamped** (`status/health`):
- `low_image_quality`, `low_lighting`, `low_depth_reliability`, `low_motion_sensors_reliability` (bool)

---

## 성능 이슈 Quick Fix

| 증상 | 해결 | 상세 |
|------|------|------|
| CPU 과부하 | `grab_compute_capping_fps`, `point_cloud_freq` 동적 조절 | `references/optimization.md` |
| 해상도 높음 | `pub_downscale_factor: 2.0` | `references/optimization.md` |
| 토픽 안 옴 | DDS 커널 버퍼 튜닝 | `references/dds-network.md` |
| 네트워크 대역폭 | compressed topics | `references/dds-network.md` |
