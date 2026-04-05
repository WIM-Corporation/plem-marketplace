---
description: "ZED camera usage reference — RViz verification, SVO recording/playback, Object Detection demo, param_overrides usage"
---

# ZED Camera Usage Guide

## Verify Camera Topics

After launching the ZED node, confirm topics are publishing:

```bash
# List all ZED topics
ros2 topic list | grep zed

# Check image publish rate
ros2 topic hz /zed/zed_node/rgb/color/rect/image

# Check depth info
ros2 topic echo /zed/zed_node/depth/depth_info --once
```

Key topics:

| Topic | Type | Description |
|-------|------|-------------|
| `rgb/color/rect/image` | `sensor_msgs/Image` | Rectified color image |
| `depth/depth_registered` | `sensor_msgs/Image` | Registered depth map |
| `point_cloud/cloud_registered` | `sensor_msgs/PointCloud2` | 3D point cloud |
| `imu/data` | `sensor_msgs/Imu` | IMU measurements |
| `odom` | `nav_msgs/Odometry` | Visual-inertial odometry |

All topics are under `/{camera_name}/{node_name}/` namespace (default: `/zed/zed_node/`).

## RViz2 Visualization

> **주의**: zed-ros2-wrapper README에 안내된 `zed_wrapper/config/rviz2/<model>.rviz` 경로는 존재하지 않는 문서 오류다.

```bash
# plem-init 번들 설정 파일 사용 (프로젝트에 포함됨)
rviz2 -d scripts/zed/config/zedxm_display.rviz

# 또는 설정 없이 실행 후 GUI에서 디스플레이 추가
rviz2
```

Object Detection 3D 바운딩 박스 시각화가 필요하면 `rviz-plugin-zed-od` 플러그인을 빌드:
```bash
cd ~/zed_ws/src
git clone --depth 1 https://github.com/stereolabs/zed-ros2-examples.git
cd ~/zed_ws && colcon build --packages-select rviz_plugin_zed_od zed_display_rviz2
source install/setup.bash

# RViz만 시작 (ZED 노드는 이미 실행 중)
ros2 launch zed_display_rviz2 display_zed_cam.launch.py \
    camera_model:=zedxm start_zed_node:=False

# 또는 ZED + RViz 한번에 (새로 시작할 때)
ros2 launch zed_display_rviz2 display_zed_cam.launch.py camera_model:=zedxm
```

**주의**: `zed_display_rviz2` launch는 `param_overrides`를 전달하지 않으므로 OD를 활성화하려면 launch 후 서비스 호출 필요:
```bash
ros2 service call /zed/zed_node/enable_obj_det std_srvs/srv/SetBool "{data: true}"
```

## SVO Recording / Playback

SVO is ZED's raw sensor data format. Useful for offline testing without a physical camera.

```bash
# Start recording
ros2 service call /zed/zed_node/start_svo_rec zed_msgs/srv/StartSvoRec \
    "{bitrate: 0, compression_mode: 1, target_framerate: 0, svo_filename: '/tmp/record.svo2'}"

# Stop recording
ros2 service call /zed/zed_node/stop_svo_rec std_srvs/srv/Trigger

# Playback (no camera needed)
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    svo_path:=/tmp/record.svo2
```

SVO playback publishes the same topics as a live camera — downstream nodes work without changes.

## Object Detection Demo

> **주의**: `object_detection.od_enabled:=true`는 launch argument가 아니다. ROS 2 launch는 미선언 argument를 경고 없이 무시한다.

```bash
# Launch with Object Detection enabled (param_overrides 사용)
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    param_overrides:="object_detection.od_enabled:=true"

# Runtime toggle (launch 후 서비스로 on/off)
ros2 service call /zed/zed_node/enable_obj_det std_srvs/srv/SetBool "{data: true}"

# Body Tracking
ros2 service call /zed/zed_node/enable_body_trk std_srvs/srv/SetBool "{data: true}"
```

Detection results publish to `/zed/zed_node/obj_det/objects` (`zed_msgs/msg/ObjectsStamped`).

## `param_overrides` 사용법

`param_overrides`는 CLI에서 YAML을 수정하지 않고 zed-ros2-wrapper 파라미터를 오버라이드하는 launch argument이다. YAML, 다른 launch argument보다 최고 우선순위를 가진다.

```bash
# 세미콜론으로 복수 파라미터 전달
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    param_overrides:="object_detection.od_enabled:=true;debug.disable_nitros:=true"
```

- 자동 타입 변환: `true`→bool, 숫자→int/float, 나머지→string
- `zed_camera.launch.py` 내부의 `_parse_param_overrides()`에서 처리

## Headless (SSH) 환경 주의

> **SIGSEGV 크래시 위험**: SSH 등 headless 환경(`DISPLAY` 미설정)에서는 NITROS가 EGL 초기화에 실패하여 카메라 열기 단계에서 SIGSEGV가 발생한다.

```bash
# headless 환경에서는 disable_nitros 필수
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    param_overrides:="debug.disable_nitros:=true"

# 또는 DISPLAY 환경변수가 설정된 환경에서 실행 (로컬/Xvfb)
```

## Launch Arguments Quick Reference

| Argument | Default | Description |
|----------|---------|-------------|
| `camera_model` | *required* | Camera model (e.g. `zedxm`, `zed2i`) |
| `camera_name` | `"zed"` | Topic namespace prefix |
| `serial_number` | `0` | Specific camera (for multi-camera) |
| `svo_path` | `""` | SVO file path (empty = live camera) |
| `publish_tf` | `true` | Publish TF transforms |
| `publish_map_tf` | `true` | Publish map→odom TF |
| `ros_params_override_path` | `""` | Custom parameter YAML path |
| `param_overrides` | `""` | CLI 파라미터 오버라이드 (`;` 구분, 최고 우선순위) |
| `enable_ipc` | `true` | NITROS IPC 활성화 |
| `object_detection_config_path` | `""` | OD 파라미터 YAML path |
| `custom_object_detection_config_path` | `""` | 커스텀 YOLO 파라미터 YAML path |
