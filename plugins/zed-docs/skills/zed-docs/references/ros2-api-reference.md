---
description: "ZED ROS 2 API reference — complete topic/service/parameter/message specification for zed-ros2-wrapper"
---

# ZED ROS 2 API 레퍼런스

## 목차

- [1. 토픽](#1-토픽)
- [2. 서비스](#2-서비스)
- [3. 파라미터](#3-파라미터)
- [4. zed_msgs 인터페이스 명세](#4-zed_msgs-인터페이스-명세)
- [5. 지원 카메라 모델](#5-지원-카메라-모델)

> zed-ros2-wrapper가 제공하는 토픽, 서비스, 파라미터, 메시지 명세, 카메라 모델 전체 목록.
> 소스: [zed-ros2-wrapper](https://github.com/stereolabs/zed-ros2-wrapper) C++ 소스코드 및 `config/*.yaml`
>
> 설치: plem-init 스킬 `zed-driver-setup.md` 참조 | 카메라 사용법: `zed-usage-guide.md` 참조 | YOLO 통합: `zed-yolo-integration.md` 참조

이 문서는 zed-ros2-wrapper 노드가 실행 중인 환경을 전제합니다. 설치는 `zed-driver-setup.md` 참고.

---

## 1. 토픽

> 소스: `zed_camera_component.cpp`, `zed_camera_component_video_depth.cpp`
> 토픽 접두사: `/<camera_name>/<node_name>/` (기본: `/zed/zed_node/`)

### 이미지

| 토픽 | 메시지 타입 | 기본 발행 | 조건 |
|------|------------|-----------|------|
| `rgb/color/rect/image` | `sensor_msgs/Image` | O | `video.publish_rgb: true` |
| `rgb/color/raw/image` | `sensor_msgs/Image` | - | `video.publish_raw: true` |
| `rgb/gray/rect/image` | `sensor_msgs/Image` | - | `video.publish_gray: true` |
| `rgb/gray/raw/image` | `sensor_msgs/Image` | - | `video.publish_gray + publish_raw` |
| `rgb/camera_info` | `sensor_msgs/CameraInfo` | O | rgb 이미지와 함께 |
| `left/color/rect/image` | `sensor_msgs/Image` | - | `video.publish_left_right: true` |
| `left/color/raw/image` | `sensor_msgs/Image` | - | `publish_left_right + publish_raw` |
| `left/gray/rect/image` | `sensor_msgs/Image` | - | `publish_left_right + publish_gray` |
| `left/camera_info` | `sensor_msgs/CameraInfo` | - | left 이미지와 함께 |
| `right/color/rect/image` | `sensor_msgs/Image` | - | `publish_left_right: true` |
| `right/color/raw/image` | `sensor_msgs/Image` | - | `publish_left_right + publish_raw` |
| `right/gray/rect/image` | `sensor_msgs/Image` | - | `publish_left_right + publish_gray` |
| `right/camera_info` | `sensor_msgs/CameraInfo` | - | right 이미지와 함께 |
| `stereo/color/rect/image` | `sensor_msgs/Image` | - | `video.publish_stereo: true` |
| `stereo/color/raw/image` | `sensor_msgs/Image` | - | `publish_stereo + publish_raw` |

### Depth / Disparity / Point Cloud

| 토픽 | 메시지 타입 | 기본 발행 | 조건 |
|------|------------|-----------|------|
| `depth/depth_registered` | `sensor_msgs/Image` | O | `depth.publish_depth_map: true` |
| `depth/depth_info` | `zed_msgs/DepthInfoStamped` | - | `depth.publish_depth_info: true` (기본 false) |
| `confidence/confidence_map` | `sensor_msgs/Image` | - | `depth.publish_depth_confidence: true` (기본 false) |
| `disparity/disparity_image` | `stereo_msgs/DisparityImage` | - | `depth.publish_disparity: true` (기본 false) |
| `point_cloud/cloud_registered` | `sensor_msgs/PointCloud2` | O | `depth.publish_point_cloud: true` |

### 위치 추적

| 토픽 | 메시지 타입 | 기본 발행 | 조건 |
|------|------------|-----------|------|
| `odom` | `nav_msgs/Odometry` | O | `pos_tracking.pos_tracking_enabled: true` |
| `pose` | `geometry_msgs/PoseStamped` | O | `publish_odom_pose: true` (기본 true) |
| `pose/status` | `zed_msgs/PosTrackStatus` | O | pos_tracking 활성화 시 |
| `pose_with_covariance` | `geometry_msgs/PoseWithCovarianceStamped` | - | `publish_pose_cov: true` (기본 false) |
| `path_map` | `nav_msgs/Path` | - | `publish_cam_path: true` (기본 false) |
| `path_odom` | `nav_msgs/Path` | - | `publish_cam_path: true` (기본 false) |
| `pose/landmarks` | `sensor_msgs/PointCloud2` | - | `publish_3d_landmarks: true` (기본 false) |

### IMU / 센서

| 토픽 | 메시지 타입 | 기본 발행 | 조건 |
|------|------------|-----------|------|
| `imu/data` | `sensor_msgs/Imu` | O | `sensors.publish_imu: true` |
| `imu/data_raw` | `sensor_msgs/Imu` | - | `sensors.publish_imu_raw: true` (기본 false) |
| `imu/mag` | `sensor_msgs/MagneticField` | - | `sensors.publish_mag: true` (기본 **false**) |
| `atm_press` | `sensor_msgs/FluidPressure` | - | `sensors.publish_baro: true` (기본 **false**) |
| `temperature/imu` | `sensor_msgs/Temperature` | - | `sensors.publish_temp: true` (기본 **false**) |
| `temperature/left` | `sensor_msgs/Temperature` | - | `sensors.publish_temp: true` |
| `temperature/right` | `sensor_msgs/Temperature` | - | `sensors.publish_temp: true` |
| `left_cam_imu_transform` | `geometry_msgs/TransformStamped` | - | `sensors.publish_cam_imu_transf: true` (기본 false) |

### AI 모듈

| 토픽 | 메시지 타입 | 기본 발행 | 조건 |
|------|------------|-----------|------|
| `obj_det/objects` | `zed_msgs/ObjectsStamped` | - | `object_detection.od_enabled: true` |
| `body_trk/skeletons` | `zed_msgs/ObjectsStamped` | - | `body_tracking.bt_enabled: true` |

### 매핑 / 평면 감지

| 토픽 | 메시지 타입 | 기본 발행 | 조건 |
|------|------------|-----------|------|
| `mapping/fused_cloud` | `sensor_msgs/PointCloud2` | - | `mapping.mapping_enabled: true` |
| `plane` | `zed_msgs/PlaneStamped` | - | `mapping.publish_det_plane: true` (기본 false) |
| `plane_marker` | `visualization_msgs/Marker` | - | plane과 함께 (RViz 시각화) |

### GNSS Fusion

| 토픽 | 메시지 타입 | 기본 발행 | 조건 |
|------|------------|-----------|------|
| `pose/filtered` | `nav_msgs/Odometry` | - | `gnss_fusion.gnss_fusion_enabled: true` |
| `pose/filtered/status` | `zed_msgs/GnssFusionStatus` | - | gnss_fusion 활성화 시 |
| `geo_pose` | `geographic_msgs/GeoPoseStamped` | - | gnss_fusion 활성화 시 |
| `geo_pose/status` | `zed_msgs/GnssFusionStatus` | - | gnss_fusion 활성화 시 |
| `pose/fused_fix` | `sensor_msgs/NavSatFix` | - | gnss_fusion 활성화 시 |
| `pose/origin_fix` | `sensor_msgs/NavSatFix` | - | gnss_fusion 활성화 시 |

### 진단 / 상태

| 토픽 | 메시지 타입 | 기본 발행 | 조건 |
|------|------------|-----------|------|
| `svo_status` | `zed_msgs/SvoStatus` | - | SVO 모드에서만 |
| `status/health` | `zed_msgs/HealthStatusStamped` | O | `general.publish_status: true` |
| `status/heartbeat` | `zed_msgs/Heartbeat` | O | `general.publish_status: true` |
| `roi_mask/image` | `sensor_msgs/Image` | - | `region_of_interest.publish_roi_mask: true` (기본 false) |

---

## 2. 서비스

> 소스: `zed_camera_component.hpp` (16개), `zed_camera_one_component.hpp` (5개)
> 서비스 접두사: `/<camera_name>/<node_name>/`

### ZedCamera (스테레오 카메라)

| 서비스 | 타입 | 설명 |
|--------|------|------|
| `enable_depth` | `std_srvs/SetBool` | Depth 처리 on/off (미검증 -- 공식 문서에 미기재) |
| `reset_odometry` | `std_srvs/Trigger` | Odometry 리셋 |
| `reset_pos_tracking` | `std_srvs/Trigger` | 위치 추적 전체 리셋 |
| `set_pose` | `zed_msgs/SetPose` | 특정 자세로 리셋 (pos xyz + orient rpy) |
| `save_area_memory` | `zed_msgs/SaveAreaMemory` | 공간 메모리 `.area` 파일 저장 |
| `enable_obj_det` | `std_srvs/SetBool` | Object Detection on/off |
| `enable_body_trk` | `std_srvs/SetBool` | Body Tracking on/off |
| `enable_mapping` | `std_srvs/SetBool` | Spatial Mapping on/off |
| `enable_streaming` | `std_srvs/SetBool` | 네트워크 스트리밍 on/off |
| `start_svo_rec` | `zed_msgs/StartSvoRec` | SVO 녹화 시작 |
| `stop_svo_rec` | `std_srvs/Trigger` | SVO 녹화 중지 |
| `toggle_svo_pause` | `std_srvs/Trigger` | SVO 재생 일시정지 토글 |
| `set_svo_frame` | `zed_msgs/SetSvoFrame` | SVO 특정 프레임으로 이동 |
| `set_roi` | `zed_msgs/SetROI` | ROI 설정 (정규화 polygon JSON) |
| `reset_roi` | `std_srvs/Trigger` | ROI 초기화 |
| `toLL` | `robot_localization/ToLL` | 로컬 좌표 → 위경도 (GNSS 활성화 시) |
| `fromLL` | `robot_localization/FromLL` | 위경도 → 로컬 좌표 (GNSS 활성화 시) |

### ZedCameraOne (단안 카메라)

| 서비스 | 타입 | 설명 |
|--------|------|------|
| `enable_streaming` | `std_srvs/SetBool` | 네트워크 스트리밍 on/off |
| `start_svo_rec` | `zed_msgs/StartSvoRec` | SVO 녹화 시작 |
| `stop_svo_rec` | `std_srvs/Trigger` | SVO 녹화 중지 |
| `toggle_svo_pause` | `std_srvs/Trigger` | SVO 재생 일시정지 토글 |
| `set_svo_frame` | `zed_msgs/SetSvoFrame` | SVO 특정 프레임으로 이동 |

### 서비스 호출 예시

```bash
# Depth 비활성화
ros2 service call /zed/zed_node/enable_depth std_srvs/srv/SetBool "{data: false}"

# ROI 설정 (이미지 중앙 50%)
ros2 service call /zed/zed_node/set_roi zed_msgs/srv/SetROI \
    "{roi: '[[0.25,0.25],[0.75,0.25],[0.75,0.75],[0.25,0.75]]'}"

# SVO 녹화 시작
ros2 service call /zed/zed_node/start_svo_rec zed_msgs/srv/StartSvoRec \
    "{bitrate: 0, compression_mode: 1, target_framerate: 0, svo_filename: '/tmp/record.svo2'}"

# 위치 추적 리셋
ros2 service call /zed/zed_node/set_pose zed_msgs/srv/SetPose \
    "{pos: [0.0, 0.0, 0.0], orient: [0.0, 0.0, 0.0]}"
```

---

## 3. 파라미터

> 소스: `zed_wrapper/config/common_stereo.yaml`, 개별 카메라 YAML
> **[D]** = 런타임 동적 변경 가능

### 3.1 General

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `general.grab_resolution` | string | 카메라별 | 캡처 해상도 (HD2K/HD1200/HD1080/SVGA 등) |
| `general.grab_frame_rate` | int | 30 | 캡처 FPS |
| `general.pub_resolution` | string | `CUSTOM` | 발행 해상도 (NATIVE/CUSTOM) |
| `general.pub_downscale_factor` | float | `2.0` | CUSTOM 시 다운스케일 배수 |
| `general.pub_frame_rate` **[D]** | float | `0.0` | 발행 FPS (0=제한 없음) |
| `general.gpu_id` | int | `-1` | GPU 디바이스 (-1=자동) |
| `general.camera_timeout_sec` | int | `5` | 카메라 연결 타임아웃 (초) |
| `general.camera_max_reconnect` | int | `5` | 최대 재연결 시도 |
| `general.camera_flip` | bool | `false` | 이미지 좌우반전 |
| `general.self_calib` | bool | `true` | 자동 캘리브레이션 |
| `general.publish_status` | bool | `true` | 상태 토픽 발행 |
| `general.enable_image_validity_check` | int | `1` | 프레임 유효성 검사 |
| `general.grab_compute_capping_fps` | float | `0.0` | 처리 상한 FPS (0=무제한) |
| `general.async_image_retrieval` | bool | `false` | 비동기 이미지 수신 |

### 3.2 Video

**구형 카메라 (ZED, ZED M, ZED 2, ZED 2i)**:

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `video.brightness` **[D]** | int | `4` | 밝기 (0-8) |
| `video.contrast` **[D]** | int | `4` | 대비 (0-8) |
| `video.hue` **[D]** | int | `0` | 색상 (0-11) |
| `video.saturation` **[D]** | int | `4` | 채도 (0-8) |
| `video.sharpness` **[D]** | int | `4` | 선명도 (0-8) |
| `video.gamma` **[D]** | int | `8` | 감마 (1-9) |
| `video.auto_exposure_gain` **[D]** | bool | `true` | 자동 노출/게인 |
| `video.exposure` **[D]** | int | `80` | 수동 노출 (0-100) |
| `video.gain` **[D]** | int | `80` | 수동 게인 (0-100) |
| `video.auto_whitebalance` **[D]** | bool | `true` | 자동 화이트밸런스 |
| `video.whitebalance_temperature` **[D]** | int | `42` | 색온도 (x100, 28-65) |

**신형 카메라 (ZED X, ZED X Mini, ZED X HDR, ZED X One)**:

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `video.auto_exposure` **[D]** | bool | `true` | 자동 노출 |
| `video.exposure_time` **[D]** | int | 모델별 | 노출 시간 (us) |
| `video.auto_exposure_time_range_min` **[D]** | int | `28` | 자동 노출 최소 (us) |
| `video.auto_exposure_time_range_max` **[D]** | int | 모델별 | 자동 노출 최대 (us) |
| `video.exposure_compensation` **[D]** | int | `50` | 노출 보정 (0-100) |
| `video.auto_analog_gain` **[D]** | bool | `true` | 자동 센서 게인 |
| `video.analog_gain` **[D]** | int | 모델별 | 센서 게인 (mDB) |
| `video.auto_analog_gain_range_min` **[D]** | int | `1000` | 게인 최소 (mDB) |
| `video.auto_analog_gain_range_max` **[D]** | int | `16000` | 게인 최대 (mDB) |
| `video.auto_digital_gain` **[D]** | bool | `false` | 자동 디지털 게인 |
| `video.digital_gain` **[D]** | int | 모델별 | 디지털 게인 (1-256) |
| `video.denoising` **[D]** | int | `50` | 노이즈 제거 (0-100) |

**공통 발행 제어**:

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `video.publish_rgb` | bool | `true` | RGB 이미지 발행 |
| `video.publish_left_right` | bool | `false` | 좌/우 이미지 발행 |
| `video.publish_raw` | bool | `false` | 원본(미보정) 이미지 발행 |
| `video.publish_gray` | bool | `false` | 그레이스케일 발행 |
| `video.publish_stereo` | bool | `false` | 스테레오(좌우 병합) 발행 |
| `video.enable_24bit_output` | bool | `false` | 24비트 BGR (기본 32비트 BGRA) |

### 3.3 Depth

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `depth.depth_mode` | string | `NEURAL_LIGHT` | 깊이 모드 (NONE/NEURAL_LIGHT/NEURAL/NEURAL_PLUS) |
| `depth.depth_stabilization` | int | `-1` | 깊이 안정화 (-1=SDK 기본, 0-100). **주의**: `> 0` 설정 시 positional tracking이 강제 활성화됨. plem URDF TF와 충돌할 수 있으므로 `0`으로 설정 권장 |
| `depth.min_depth` | float | 카메라별 | 최소 깊이 (m) |
| `depth.max_depth` | float | 카메라별 | 최대 깊이 (m) |
| `depth.openni_depth_mode` | bool | `false` | false=32bit float(m), true=16bit uint(mm) |
| `depth.depth_confidence` **[D]** | int | `95` | 깊이 신뢰도 임계값 (0-100) |
| `depth.depth_texture_conf` **[D]** | int | `100` | 텍스처 신뢰도 (0-100) |
| `depth.remove_saturated_areas` **[D]** | bool | `true` | 포화 영역 제거 |
| `depth.point_cloud_freq` **[D]** | float | `10.0` | Point Cloud 발행 Hz |
| `depth.point_cloud_res` | string | `COMPACT` | Point Cloud 해상도 (COMPACT/REDUCED) |
| `depth.publish_depth_map` | bool | `true` | 깊이 맵 발행 |
| `depth.publish_depth_info` | bool | `false` | 깊이 정보 발행 |
| `depth.publish_point_cloud` | bool | `true` | Point Cloud 발행 |
| `depth.publish_depth_confidence` | bool | `false` | 신뢰도 맵 발행 |
| `depth.publish_disparity` | bool | `false` | Disparity 맵 발행 |

### 3.4 Positional Tracking

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `pos_tracking.pos_tracking_enabled` | bool | `true` | 위치 추적 on/off |
| `pos_tracking.pos_tracking_mode` | string | `AUTO` | 추적 모드 (AUTO/GEN_1/GEN_3) |
| `pos_tracking.imu_fusion` | bool | `true` | IMU 융합 |
| `pos_tracking.publish_tf` | bool | `true` | odom→camera TF 발행 |
| `pos_tracking.publish_map_tf` | bool | `true` | map→odom TF 발행 |
| `pos_tracking.map_frame` | string | `map` | map 프레임 이름 |
| `pos_tracking.odometry_frame` | string | `odom` | odometry 프레임 이름 |
| `pos_tracking.area_memory` | bool | `true` | Loop closure 활성화 |
| `pos_tracking.area_file_path` | string | `''` | Area memory 파일 경로 |
| `pos_tracking.set_as_static` | bool | `false` | 정적 카메라 모드 |
| `pos_tracking.set_gravity_as_origin` | bool | `true` | 중력 방향 기준 정렬 |
| `pos_tracking.floor_alignment` | bool | `false` | 바닥 높이 자동 계산 |
| `pos_tracking.initial_base_pose` | array | `[0,0,0,0,0,0]` | 초기 위치 [X,Y,Z,R,P,Y] |
| `pos_tracking.path_pub_rate` **[D]** | float | `2.0` | 경로 발행 Hz |
| `pos_tracking.path_max_count` | int | `-1` | 최대 경로 포인트 (-1=무제한) |
| `pos_tracking.two_d_mode` | bool | `false` | 2D 네비게이션 (z=0) |
| `pos_tracking.fixed_z_value` | float | `0.0` | 2D 모드 Z 고정값 (m) |
| `pos_tracking.depth_min_range` | float | `0.0` | VIO 최소 깊이 제외 (m) |
| `pos_tracking.transform_time_offset` | float | `0.0` | TF 타임스탬프 오프셋 (s) |
| `pos_tracking.publish_odom_pose` | bool | `true` | 오도메트리/자세 발행 |
| `pos_tracking.publish_pose_cov` | bool | `false` | 공분산 포함 자세 발행 |
| `pos_tracking.publish_cam_path` | bool | `false` | 카메라 경로 발행 |
| `pos_tracking.publish_3d_landmarks` | bool | `false` | 3D 랜드마크 발행 |

### 3.5 Sensors

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `sensors.sensors_pub_rate` **[D]** | float | `100.0` | 센서 발행 Hz |
| `sensors.sensors_image_sync` | bool | `false` | 센서-이미지 동기화 |
| `sensors.publish_imu` | bool | `true` | IMU 발행 |
| `sensors.publish_imu_raw` | bool | `false` | 원본 IMU 발행 |
| `sensors.publish_imu_tf` | bool | `true` | IMU TF 발행 |
| `sensors.publish_cam_imu_transf` | bool | `false` | 카메라-IMU 변환 발행 |
| `sensors.publish_mag` | bool | **`false`** | 자력계 발행 |
| `sensors.publish_baro` | bool | **`false`** | 기압계 발행 |
| `sensors.publish_temp` | bool | **`false`** | 온도 발행 |

### 3.6 Object Detection

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `object_detection.od_enabled` | bool | `false` | Object Detection on/off |
| `object_detection.detection_model` | string | `MULTI_CLASS_BOX_FAST` | 검출 모델 |
| `object_detection.enable_tracking` | bool | `true` | 다중 프레임 추적 |
| `object_detection.max_range` | float | `40.0` | 최대 검출 거리 (m) |
| `object_detection.filtering_mode` | string | `NMS3D` | 필터링 (NONE/NMS3D/NMS3D_PER_CLASS) |
| `object_detection.prediction_timeout` | float | `2.0` | 폐색 시 궤적 예측 (s) |
| `object_detection.allow_reduced_precision_inference` | bool | `false` | 저정밀 추론 허용 |

**클래스별 설정** (동적 변경 가능):

| 클래스 | `enabled` 기본값 | `confidence_threshold` 기본값 |
|--------|----------------|------------------------------|
| `class.people` | `true` | `65.0` |
| `class.vehicle` | `true` | `60.0` |
| `class.bag` | `true` | `40.0` |
| `class.animal` | `true` | `40.0` |
| `class.electronics` | `true` | `45.0` |
| `class.fruit_vegetable` | `true` | `50.0` |
| `class.sport` | `true` | `30.0` |

### 3.7 Body Tracking

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `body_tracking.bt_enabled` | bool | `false` | Body Tracking on/off |
| `body_tracking.model` | string | `HUMAN_BODY_MEDIUM` | 모델 (FAST/MEDIUM/ACCURATE) |
| `body_tracking.body_format` | string | `BODY_38` | 골격 형식 (BODY_18/34/38) |
| `body_tracking.max_range` | float | `15.0` | 최대 감지 거리 (m) |
| `body_tracking.body_kp_selection` | string | `FULL` | 키포인트 선택 (FULL/UPPER_BODY) |
| `body_tracking.enable_body_fitting` | bool | `false` | Body fitting |
| `body_tracking.enable_tracking` | bool | `true` | 추적 활성화 |
| `body_tracking.prediction_timeout_s` | float | `0.5` | 예측 타임아웃 (s) |
| `body_tracking.confidence_threshold` **[D]** | float | `50.0` | 신뢰도 임계값 (0-99) |
| `body_tracking.minimum_keypoints_threshold` **[D]** | int | `5` | 최소 키포인트 수 |

### 3.8 Mapping

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `mapping.mapping_enabled` | bool | `false` | Spatial Mapping on/off |
| `mapping.resolution` | float | `0.05` | 맵 해상도 (m, 0.01-0.2) |
| `mapping.max_mapping_range` | float | `5.0` | 최대 매핑 거리 (m, -1=자동) |
| `mapping.fused_pointcloud_freq` | float | `1.0` | Fused cloud 발행 Hz |
| `mapping.publish_det_plane` | bool | `false` | 평면 감지 발행 |

### 3.9 GNSS Fusion

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `gnss_fusion.gnss_fusion_enabled` | bool | `false` | GNSS 융합 on/off |
| `gnss_fusion.gnss_fix_topic` | string | `/fix` | NavSatFix 토픽 |
| `gnss_fusion.gnss_zero_altitude` | bool | `false` | 고도 무시 |
| `gnss_fusion.h_covariance_mul` | float | `1.0` | 수평 공분산 배수 |
| `gnss_fusion.v_covariance_mul` | float | `1.0` | 수직 공분산 배수 |
| `gnss_fusion.publish_utm_tf` | bool | `true` | utm→map TF 발행 |
| `gnss_fusion.enable_reinitialization` | bool | `false` | GNSS/VIO 불일치 시 재초기화 |
| `gnss_fusion.enable_rolling_calibration` | bool | `true` | 동적 캘리브레이션 |
| `gnss_fusion.gnss_vio_reinit_threshold` | float | `5.0` | 재초기화 임계값 |

### 3.10 Streaming Server

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `stream_server.stream_enabled` | bool | `false` | 스트리밍 on/off |
| `stream_server.codec` | string | `H265` | 코덱 (H264/H265) |
| `stream_server.port` | int | `30000` | 포트 (짝수만) |
| `stream_server.bitrate` | int | `12500` | 비트레이트 (Kbps) |
| `stream_server.gop_size` | int | `-1` | GOP 크기 |
| `stream_server.adaptative_bitrate` | bool | `false` | 적응형 비트레이트 |
| `stream_server.target_framerate` | int | `0` | 스트리밍 FPS (0=카메라 FPS) |

### 3.11 Region of Interest (ROI)

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `region_of_interest.automatic_roi` | bool | `false` | 자동 ROI (로봇 부위 자동 제거) |
| `region_of_interest.depth_far_threshold_meters` | float | `2.5` | ROI 깊이 임계값 (m) |
| `region_of_interest.image_height_ratio_cutoff` | float | `0.5` | ROI 높이 비율 |
| `region_of_interest.apply_to_depth` | bool | `true` | 깊이에 ROI 적용 |
| `region_of_interest.apply_to_positional_tracking` | bool | `true` | 위치 추적에 적용 |
| `region_of_interest.apply_to_object_detection` | bool | `true` | Object Detection에 적용 |
| `region_of_interest.apply_to_body_tracking` | bool | `true` | Body Tracking에 적용 |
| `region_of_interest.apply_to_spatial_mapping` | bool | `true` | Mapping에 적용 |
| `region_of_interest.publish_roi_mask` | bool | `false` | ROI 마스크 이미지 발행 |

### 3.12 SVO

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `svo.svo_loop` | bool | `false` | 루프 재생 |
| `svo.svo_realtime` | bool | `false` | 실시간 재생 모드 |
| `svo.use_svo_timestamps` | bool | `true` | SVO 타임스탬프 사용 |
| `svo.publish_svo_clock` | bool | `false` | SVO 클록 → `/clock` 발행 |
| `svo.play_from_frame` | int | `0` | 시작 프레임 |
| `svo.replay_rate` | float | `1.0` | 재생 속도 배수 (0.1-5.0) |

### 3.13 Advanced

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `advanced.thread_sched_policy` | string | `SCHED_BATCH` | 스레드 정책 (FIFO/RR=sudo 필요) |
| `advanced.thread_grab_priority` | int | `50` | Grab 스레드 우선순위 (1-99) |
| `advanced.thread_sensor_priority` | int | `70` | Sensor 스레드 우선순위 |
| `advanced.thread_pointcloud_priority` | int | `60` | Point Cloud 스레드 우선순위 |

---

## 4. zed_msgs 인터페이스 명세

> 소스: `ros-humble-zed-msgs` apt 패키지

### Messages

#### DepthInfoStamped

```
std_msgs/Header header
float32 min_depth     # 최소 깊이 [m]
float32 max_depth     # 최대 깊이 [m]
```

#### HealthStatusStamped

```
std_msgs/Header header
uint32  serial_number
string  camera_name
bool    low_image_quality
bool    low_lighting
bool    low_depth_reliability
bool    low_motion_sensors_reliability
```

#### Heartbeat

```
uint64 beat_count
string node_ns
string node_name
string full_name
uint32 camera_sn
bool   svo_mode
bool   simul_mode
```

#### PosTrackStatus

```
uint8 OK = 0
uint8 UNAVAILABLE = 1
uint8 SEARCHING = 2
uint8 OFF = 3

uint8 odometry_status
uint8 spatial_memory_status
```

#### GnssFusionStatus

```
uint8 OK = 0
uint8 OFF = 1
uint8 CALIBRATION_IN_PROGRESS = 2
uint8 RECALIBRATION_IN_PROGRESS = 3

uint8 gnss_fusion_status
```

#### Object

```
string  label
int16   label_id
string  sublabel
float32 confidence         # 1-99
float32[3] position        # 3D 무게중심 [m]
float32[6] position_covariance
float32[3] velocity        # [m/s]
bool    tracking_available
int8    tracking_state     # 0=OFF, 1=OK, 2=SEARCHING, 3=TERMINATE
int8    action_state       # 0=IDLE, 2=MOVING
BoundingBox2Di bounding_box_2d
BoundingBox3D  bounding_box_3d
float32[3] dimensions_3d   # [w, h, l] [m]
bool    skeleton_available
int8    body_format        # 0=POSE_18, 1=POSE_34, 2=POSE_38
BoundingBox2Df head_bounding_box_2d
BoundingBox3D  head_bounding_box_3d
float32[3] head_position
Skeleton2D skeleton_2d
Skeleton3D skeleton_3d
```

#### ObjectsStamped

```
std_msgs/Header header
zed_msgs/Object[] objects
```

#### PlaneStamped

```
std_msgs/Header header
shape_msgs/Mesh mesh
shape_msgs/Plane coefficients   # ax + by + cz + d = 0
geometry_msgs/Point32 normal
geometry_msgs/Point32 center
geometry_msgs/Transform pose
float32[2] extents              # [width, height]
geometry_msgs/Polygon bounds
```

#### SvoStatus

```
string file_name
uint8  status        # 0=PLAYING, 1=PAUSED, 2=END
uint64 frame_ts      # [microseconds]
uint32 frame_id
uint32 total_frames
bool   loop_active
uint32 loop_count
bool   real_time_mode
```

#### 기본 기하 타입

```
BoundingBox2Df  → Keypoint2Df[4] corners
BoundingBox2Di  → Keypoint2Di[4] corners
BoundingBox3D   → Keypoint3D[8] corners
Keypoint2Df     → float32[2] kp
Keypoint2Di     → uint32[2] kp
Keypoint3D      → float32[3] kp
Skeleton2D      → Keypoint2Df[70] keypoints
Skeleton3D      → Keypoint3D[70] keypoints
```

### Services

| 서비스 | 요청 | 응답 |
|--------|------|------|
| `SetPose` | `float32[3] pos`, `float32[3] orient` (RPY, rad) | `bool success`, `string message` |
| `SetROI` | `string roi` (정규화 polygon JSON) | `bool success`, `string message` |
| `StartSvoRec` | `uint32 bitrate`, `uint8 compression_mode`, `uint32 target_framerate`, `bool input_transcode`, `string svo_filename` | `bool success`, `string message` |
| `SetSvoFrame` | `int32 frame_id` | `bool success`, `string message` |
| `SaveAreaMemory` | `string area_file_path` | `bool success`, `string message` |

---

## 5. 지원 카메라 모델

> 소스: `zed_camera.launch.py` choices 리스트

| 모델명 | `camera_model` | 연결 | grab_resolution | max_depth |
|--------|---------------|------|-----------------|-----------|
| ZED | `zed` | USB 3.0 | HD720 | 10.0m |
| ZED Mini | `zedm` | USB 3.0 | HD1080 | 10.0m |
| ZED 2 | `zed2` | USB 3.0 | HD720 | 15.0m |
| ZED 2i | `zed2i` | USB 3.0 | HD1080 | 15.0m |
| ZED X | `zedx` | GMSL2 | HD1200 | 15.0m |
| ZED X Mini | `zedxm` | GMSL2 | HD1200 | 10.0m |
| ZED X HDR | `zedxhdr` | GMSL2 | HD1536 | 15.0m |
| ZED X HDR Mini | `zedxhdrmini` | GMSL2 | HD1536 | 10.0m |
| ZED X HDR Max | `zedxhdrmax` | GMSL2 | HD1536 | 20.0m |
| ZED X One GS | `zedxonegs` | GMSL2 | HD1200 | AI depth |
| ZED X One 4K | `zedxone4k` | GMSL2 | QHDPLUS | AI depth |
| ZED X One HDR | `zedxonehdr` | GMSL2 | HD1536 | AI depth |
| Virtual | `virtual` | - | HD1200 | 10.0m |

> GMSL2 카메라는 ZED Link (Duo/Quad) 캡처보드 필요. Jetson에서만 지원.
> ZED X One은 단안 카메라 (AI 기반 depth). 위치 추적/매핑 미지원.

