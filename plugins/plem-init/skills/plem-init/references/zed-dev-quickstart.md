# ZED Camera Development Quickstart

설치 완료 후 첫 개발 작업까지의 워크플로. plem-init Step 3.5 이후에 참조.

## 사전 확인

```bash
# 1. ZED SDK 설치 확인
ls /usr/local/zed/lib/libsl_zed.so

# 2. ZED wrapper 설치 확인
source ~/zed_ws/install/setup.bash
ros2 pkg prefix zed_wrapper

# 3. 카메라 하드웨어 확인 (GMSL2 카메라)
ZED_Explorer -a    # State: "AVAILABLE" 확인
```

## Step 1: DDS 네트워크 튜닝 (필수)

대용량 이미지/포인트 클라우드 토픽 수신을 위해 **반드시** DDS를 설정한다.
설정 없이 진행하면 토픽이 silently drop된다.

`./packaging/zed-setup/zed-setup install` 이 CycloneDDS 설치, 커널 버퍼 설정(`/etc/sysctl.d/60-zed-dds-buffers.conf`), `RMW_IMPLEMENTATION` 환경변수를 자동 처리한다 (deps 단계).

수동으로 설정하려면 `/zed-sdk dds` 참조.

## Step 2: 카메라 실행 + 토픽 확인

```bash
# ZED X Mini 실행 (headless 환경이면 disable_nitros 추가)
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    param_overrides:="debug.disable_nitros:=true"

# 다른 터미널에서 토픽 확인
ros2 topic list | grep zed
ros2 topic hz /zed/zed_node/rgb/color/rect/image
```

정상이면 RGB 이미지가 ~30Hz로 publish됨.

> **plem 로봇 통합 시 네임스페이스가 달라진다.**
> 로봇에 마운트하면 `camera_name`을 URDF와 일치시켜야 한다: `camera_name:=cam` (plem 기본값).
> 이 경우 토픽 경로는 `/{robot_id}/cam/...` (예: `/indy/cam/...`)가 된다.
> 멀티카메라 시 `hand_cam`, `front_cam` 등으로 override.
>
> **필수 파라미터** (고정형 manipulator):
> `pos_tracking.pos_tracking_enabled:=false`, `pos_tracking.publish_tf:=false`,
> `pos_tracking.publish_map_tf:=false`, `depth.depth_stabilization:=0`.
> `depth_stabilization`을 0으로 설정하지 않으면 카메라가 에러 없이 멈춘다.
> 상세: `/zed-sdk tf` 참조.

## Step 3: 첫 이미지 Subscribe (Python)

```python
#!/usr/bin/env python3
"""ZED 이미지 subscriber 최소 예제."""
import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy
from sensor_msgs.msg import Image


class ZedImageSub(Node):
    def __init__(self):
        super().__init__('zed_image_sub')
        # QoS: ZED 드라이버는 RELIABLE + VOLATILE로 발행. 매칭 권장.
        qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            history=HistoryPolicy.KEEP_LAST,
            depth=1,
        )
        self.sub = self.create_subscription(
            Image,
            '/zed/zed_node/rgb/color/rect/image',
            self.cb,
            qos,
        )

    def cb(self, msg: Image):
        self.get_logger().info(
            f'Image: {msg.width}x{msg.height}, encoding={msg.encoding}'
        )


def main():
    rclpy.init()
    rclpy.spin(ZedImageSub())


if __name__ == '__main__':
    main()
```

> **주의**: QoS 불일치 시 데이터가 오지 않고 에러도 없음 (silent failure).
> 반드시 `ReliabilityPolicy.RELIABLE` + `HistoryPolicy.KEEP_LAST` 사용.
> 프레임 드롭이 허용되는 뷰어 용도에서만 `BEST_EFFORT` 사용 가능.

## Step 4: VisionInspection Action Server 스캐폴딩

plem은 `plem_msgs/action/VisionInspection` 인터페이스만 정의한다.
비전 처리 로직(액션 서버)은 개발자가 구현한다.

```bash
# 인터페이스 확인
ros2 interface show plem_msgs/action/VisionInspection
```

최소 스캐폴딩:

```python
#!/usr/bin/env python3
"""VisionInspection action server 스캐폴딩."""
import rclpy
from rclpy.node import Node
from rclpy.action import ActionServer
from plem_msgs.action import VisionInspection


class VisionInspectionServer(Node):
    def __init__(self):
        super().__init__('vision_inspection_server')
        self._action_server = ActionServer(
            self,
            VisionInspection,
            'vision_inspect',  # /{robot_id}/plem/vision_inspect
            self.execute_callback,
        )
        self.get_logger().info('VisionInspection server ready')

    async def execute_callback(self, goal_handle):
        self.get_logger().info(f'Inspection request: {goal_handle.request}')

        # TODO: 여기에 비전 처리 로직 구현
        # 1. ZED 이미지 토픽 subscribe
        # 2. 이미지 처리 (YOLO, OpenCV 등)
        # 3. 결과를 VisionInspection.Result에 담아 반환

        goal_handle.succeed()
        result = VisionInspection.Result()
        return result


def main():
    rclpy.init()
    rclpy.spin(VisionInspectionServer())


if __name__ == '__main__':
    main()
```

## Step 5: YOLO 연동 (선택)

ZED SDK가 YOLO ONNX를 네이티브 로드하여 2D → 3D 변환 + 추적 + 속도를 자동 처리한다.

```bash
# 빌트인 모델로 빠른 테스트
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    param_overrides:="object_detection.od_enabled:=true;debug.disable_nitros:=true"

# 결과 확인
ros2 topic echo /zed/zed_node/obj_det/objects
```

커스텀 YOLO 모델 사용: `/zed-sdk yolo` 참조.

## 다음 단계

| 목적 | 참조 |
|------|------|
| 토픽/서비스/파라미터 전체 목록 | `/zed-sdk api` |
| 성능 최적화 (frequency, ROI) | `/zed-sdk optimization` |
| 네트워크 튜닝 상세 | `/zed-sdk dds` |
| URDF TF 통합 | `/zed-sdk tf` |
| 데이터 녹화/재생, RViz | `/zed-sdk recording` |
