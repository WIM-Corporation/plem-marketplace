---
description: "ZED data recording — SVO format, rosbag mcap, Jetson HW encoding, performance benchmarks"
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
