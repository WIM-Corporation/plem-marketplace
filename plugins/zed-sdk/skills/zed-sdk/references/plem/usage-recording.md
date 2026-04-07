---
description: "plem ZED 사용 가이드 — headless SIGSEGV 해결, RViz config 오류, param_overrides 사용법, SVO 녹화/재생, Jetson HW 인코딩 rosbag, 실측 벤치마크"
source: "zed-docs/references/usage-guide.md + recording.md"
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

All topics are under `/{camera_name}/{node_name}/` namespace (default: `/zed/zed_node/`). namespace 명시 시 `/{namespace}/{camera_name}/` (예: `/robot2/cam/`).

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

---

# ZED 데이터 Recording & Replay

오프라인 테스트, 데이터 수집, 물리 카메라 없이 디버깅할 때 사용.

## 1. SVO Recording (ZED 전용 포맷)

```bash
# 녹화 시작
ros2 service call /zed/zed_node/start_svo_rec zed_msgs/srv/StartSvoRec \
    "{bitrate: 0, compression_mode: 1, target_framerate: 0, svo_filename: '/tmp/record.svo2'}"

# 녹화 중지
ros2 service call /zed/zed_node/stop_svo_rec std_srvs/srv/Trigger
```

| Mode | Name | 용량 비율 |
|------|------|-----------|
| 0 | H265 HEVC (default) | ~1% |
| 1 | H264 | ~1% |
| 3 | H264 Lossless | ~25% |
| 4 | H265 Lossless | ~25% |
| 5 | Lossless PNG/ZSTD | ~42% |

다중 카메라: `/zed_multi/<camera_name>/start_svo_rec`

## 2. SVO Replay

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    svo_path:=/absolute/path/record.svo2
```

**주의**: `svo_path`는 반드시 **절대 경로**. 상대 경로 불가.

실제 카메라와 동일한 토픽을 publish — downstream 노드 변경 없이 사용 가능.

### 제어 서비스

- 일시정지/재개: `toggle_svo_pause`
- 프레임 이동: `set_svo_frame` (type: `zed_msgs/srv/SetSvoFrame`)

### 재생 파라미터

| 파라미터 | 기본값 | 설명 |
|---------|--------|------|
| `svo.svo_loop` | `false` | 반복 재생 |
| `svo.svo_realtime` | `false` | 실시간 재생 |
| `svo.replay_rate` | `1.0` | 재생 속도 (0.1–5.0) |
| `svo.use_svo_timestamps` | `true` | 원본 타임스탬프 사용 |

## 3. Rosbag/mcap Recording

```bash
sudo apt install ros-humble-rosbag2-storage-mcap

ros2 bag record -s mcap \
    /zed/zed_node/rgb/color/rect/image \
    /zed/zed_node/depth/depth_registered \
    /zed/zed_node/point_cloud/cloud_registered \
    /zed/zed_node/imu/data
```

팁:
- `--max-bag-size` / `--max-bag-duration`으로 파일 분할
- `pub_downscale_factor: 2.0`으로 해상도 축소 후 녹화
- `pub_frame_rate` 제한으로 용량 절감

## 4. Jetson HW 가속 인코딩

Jetson 전용 HW 인코더(`h264_nvmpi` / `hevc_nvmpi`)로 압축 rosbag 녹화.

사전 요구:
- `jetson-ffmpeg` + patched ffmpeg release/7.1
- `ros-humble-image-transport-plugins`
- `ros-humble-ffmpeg-image-transport`

Foxglove transport 파라미터 (이미지 토픽별):
```python
'.<cam_name>.left.color.rect.image.foxglove.encoding': 'h264_nvmpi',
'.<cam_name>.left.color.rect.image.foxglove.profile': 'main',
'.<cam_name>.left.color.rect.image.foxglove.preset': 'medium',
'.<cam_name>.left.color.rect.image.foxglove.gop': 10,
'.<cam_name>.left.color.rect.image.foxglove.bitrate': 4194304,
```

## 5. 성능 벤치마크

### SVO (카메라당, 1분)

| 플랫폼 | 해상도 | FPS | 용량 |
|--------|--------|-----|------|
| Orin AGX, 1 cam | HD1200 | 60 | 400MB |
| Orin AGX, 4 cams | HD1200 | 30 | 200MB |
| Orin NX, 1 cam | HD1200 | 60 | 400MB |
| Orin NX, 4 cams | HD1200 | 30 | 200MB |

### Rosbag mcap (h264_nvmpi, 1분)

| 플랫폼 | 카메라 | FPS | 용량 |
|--------|--------|-----|------|
| Orin AGX, 1 cam | HD1200 | 23 | 50MB |
| Orin AGX, 2 cams | HD1200 | 19 | 85MB |
| Orin AGX, 4 cams | HD1200 | 16 | 140MB |
| Orin NX, 1 cam | HD1200 | 15 | 62MB |
| Orin NX, 4 cams | HD1200 | 7.5 | 124.5MB |

## 6. SVO vs Rosbag 비교

| 기준 | SVO | Rosbag mcap |
|------|-----|-------------|
| 용량 | 매우 작음 (H265 ~1%) | 작음 (h264 ~10%) |
| FPS | 최대 (60fps) | 제한적 (15–23fps) |
| 재생 | ZED wrapper만 | 범용 `ros2 bag play` |
| 후처리 | ZED SDK 필요 | 표준 ROS 도구 |
| 다중 카메라 | 카메라당 별도 SVO | 하나의 bag |

성능 팁: `jetson_clocks.sh` 실행, MAXN 전원 모드, `pub_downscale_factor` 적용.
