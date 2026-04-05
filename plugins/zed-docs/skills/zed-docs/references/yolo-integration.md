---
description: "ZED + YOLO integration guide — ONNX export, custom model config, ROS 2 launch, 3D detection output"
---

# ZED SDK + YOLO 통합 가이드

## 목차

- [1. 개요 -- YOLO + ZED SDK가 주는 것](#1-개요--yolo--zed-sdk가-주는-것)
- [2. 통합 방식](#2-통합-방식)
- [3. YOLO 모델 준비 (ONNX 내보내기)](#3-yolo-모델-준비-onnx-내보내기)
- [4. ROS 2에서 사용하기 (zed-ros2-wrapper)](#4-ros-2에서-사용하기-zed-ros2-wrapper)
- [5. 클래스별 세부 파라미터](#5-클래스별-세부-파라미터)
- [6. 출력 메시지 구조](#6-출력-메시지-구조)
- [7. 카메라별 유효 거리](#7-카메라별-유효-거리)
- [8. 실전 팁](#8-실전-팁)
- [참고 링크](#참고-링크)

> ZED 카메라의 스테레오 뎁스를 활용하여 YOLO의 2D 탐지를 3D 공간 인식으로 확장하는 방법.
> 소스: [Stereolabs 공식 YOLO 문서](https://www.stereolabs.com/docs/yolo/export), `zed-ros2-wrapper/config/custom_object_detection.yaml`
>
> 설치: plem-init 스킬 `zed-driver-setup.md` 참조 | 카메라 사용법: `zed-usage-guide.md` 참조 | API 레퍼런스: `zed-ros2-api-reference.md` 참조

이 문서는 zed-ros2-wrapper가 빌드·실행 가능한 환경을 전제합니다. 설치는 `zed-driver-setup.md` 참고.

---

## 1. 개요 — YOLO + ZED SDK가 주는 것

YOLO가 2D 바운딩 박스를 만들면, ZED SDK가 스테레오 뎁스 맵을 활용해 다음을 자동 계산한다:

| YOLO만 사용 | ZED SDK 통합 시 추가 |
|------------|---------------------|
| 2D 바운딩 박스 | **3D 바운딩 박스** (뎁스 기반) |
| 클래스 + 신뢰도 | **3D 위치** (카메라 기준 미터 단위) |
| - | **객체 추적** (고유 ID, 가림/FOV 이탈 시에도 유지) |
| - | **속도 추정** (m/s) |
| - | **2D 마스크** (객체 픽셀 영역) |

즉, 2D 탐지 → 3D 위치 + 추적 + 속도까지 SDK가 처리해준다.

---

## 2. 통합 방식

### 방식 1 (권장): `CUSTOM_YOLOLIKE_BOX_OBJECTS` 네이티브 모드

YOLO ONNX 모델을 ZED SDK에 직접 넘기는 방식. SDK 내부에서 TensorRT 최적화·추론·3D 변환을 모두 처리한다.

```
사용자 → ONNX 파일 제공 → ZED SDK (TensorRT 변환 + 추론 + 3D) → ROS 2 토픽
```

- ONNX → TensorRT 엔진 변환을 SDK가 자동 처리
- 첫 실행 시 GPU 최적화 (수 분 소요), 이후 캐싱
- 추론 코드 작성 불필요

### 방식 2 (고급): 외부 추론 + 바운딩 박스 주입

SDK가 지원하지 않는 모델 아키텍처를 사용할 때. 외부 코드로 추론 후 2D 박스를 SDK에 주입.

- 추론 코드를 직접 관리해야 함
- SDK는 3D 변환 + 추적만 담당

---

## 3. YOLO 모델 준비 (ONNX 내보내기)

> 참고: https://www.stereolabs.com/docs/yolo/export

### 지원 YOLO 버전

Ultralytics YOLO v5, v8, v9, v10, v11, v12 및 YOLOv6, YOLOv7 공식 지원.
SDK는 출력 텐서 크기로 모델 포맷을 추론하므로, 동일한 출력 구조의 미래 버전도 호환 가능.

> v9는 samples 페이지 지원 목록에 포함되나 export 가이드에는 미기재.

### ONNX 내보내기

```bash
pip install ultralytics

# YOLOv11 예시 (Stereolabs 공식 기본 imgsz=608, Ultralytics 기본=640)
yolo export model=yolo11n.pt format=onnx simplify=True dynamic=False imgsz=640

# YOLOv8 예시
yolo export model=yolov8n.pt format=onnx simplify=True dynamic=False imgsz=640

# 커스텀 학습 모델
yolo export model=path/to/best.pt format=onnx simplify=True dynamic=False imgsz=640
```

**핵심 옵션:**
- `simplify=True` — ONNX 그래프 최적화 (필수)
- `dynamic=False` — 고정 배치 크기 (필수)
- `imgsz` — 학습 시 사용한 입력 해상도와 일치시킬 것. **Stereolabs 공식 기본값은 608**, Ultralytics 기본값은 640. 어느 값이든 학습 `imgsz` = 내보내기 `imgsz` = YAML `custom_onnx_input_size` 세 값이 **반드시 동일**해야 한다.

---

## 4. ROS 2에서 사용하기 (zed-ros2-wrapper)

### 4.1 빌트인 모델 사용 (즉시 사용 가능)

SDK 내장 모델로 Object Detection을 바로 실행:

> **주의**: `object_detection.od_enabled:=true`를 launch argument로 직접 전달하면 **효과 없음**. ROS 2 launch는 미선언 argument를 경고 없이 무시한다. 반드시 `param_overrides`를 사용할 것.

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    param_overrides:="object_detection.od_enabled:=true"
```

내장 모델 목록:

| `detection_model` | 설명 |
|-------------------|------|
| `MULTI_CLASS_BOX_FAST` | 다중 클래스 (빠름) — **기본값** |
| `MULTI_CLASS_BOX_MEDIUM` | 다중 클래스 (중간) |
| `MULTI_CLASS_BOX_ACCURATE` | 다중 클래스 (정확) |
| `PERSON_HEAD_BOX_FAST` | 사람 머리만 (빠름) |
| `PERSON_HEAD_BOX_ACCURATE` | 사람 머리만 (정확) |
| `CUSTOM_YOLOLIKE_BOX_OBJECTS` | **커스텀 YOLO ONNX 모델** |

### 4.2 커스텀 YOLO 모델 사용

#### Step 1: 설정 YAML 작성

`custom_object_detection.yaml`을 복사하여 프로젝트 클래스에 맞게 수정:

```yaml
/**:
  ros__parameters:
    object_detection:
      # ONNX 모델 경로 및 입력 크기
      custom_onnx_file: '/path/to/best.onnx'
      custom_onnx_input_size: 640      # 학습 시 imgsz와 일치
      custom_class_count: 4            # 클래스 수
      allow_reduced_precision_inference: true  # FP16 추론 (Jetson 필수)

      # 클래스 정의 (class_000 ~ class_003)
      class_000:
        label: 'cucumber'
        model_class_id: 0              # ONNX 모델 내 클래스 ID
        enabled: true
        confidence_threshold: 50.0     # 0-99
        is_grounded: false             # 공중 물체이면 false
        is_static: false               # 정적 물체이면 true

      class_001:
        label: 'main_stem'
        model_class_id: 1
        enabled: true
        confidence_threshold: 50.0
        is_grounded: false
        is_static: true

      class_002:
        label: 'leaf_petiole'
        model_class_id: 2
        enabled: true
        confidence_threshold: 50.0
        is_grounded: false
        is_static: true

      class_003:
        label: 'leaf'
        model_class_id: 3
        enabled: true
        confidence_threshold: 40.0
        is_grounded: false
        is_static: false
```

#### Step 2: OD 활성화 (param_overrides 또는 별도 override YAML)

> **`common_stereo.yaml`을 직접 수정하지 않는다.** 패키지 재빌드 시 덮어써진다.
> 항상 `param_overrides` launch arg 또는 별도 override YAML을 사용한다.

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    ros_params_override_path:=/path/to/custom_object_detection.yaml \
    param_overrides:="object_detection.od_enabled:=true;object_detection.detection_model:='CUSTOM_YOLOLIKE_BOX_OBJECTS';object_detection.enable_tracking:=true;object_detection.max_range:=20.0"
```

> **대안**: OD 클래스 정의 전용 launch arg `custom_object_detection_config_path`도 사용 가능:
> ```bash
> ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
>     custom_object_detection_config_path:=/path/to/custom_object_detection.yaml \
>     param_overrides:="object_detection.od_enabled:=true;object_detection.detection_model:='CUSTOM_YOLOLIKE_BOX_OBJECTS'"
> ```

#### Step 3: 결과 확인

```bash
# 탐지 결과 토픽 구독
ros2 topic echo /zed/zed_node/obj_det/objects
```

**RViz에서 3D 바운딩 박스 시각화:**

`ObjectsStamped`는 RViz2 기본 display type이 아니다. 공식 `rviz-plugin-zed-od` 플러그인을 빌드하여 사용:

```bash
# 빌드 (zed-ros2-examples 저장소 필요)
cd ~/zed_ws/src
git clone --depth 1 https://github.com/stereolabs/zed-ros2-examples.git
cd ~/zed_ws && colcon build --packages-select rviz_plugin_zed_od zed_display_rviz2

# RViz만 시작 (ZED 노드는 이미 실행 중)
ros2 launch zed_display_rviz2 display_zed_cam.launch.py \
    camera_model:=zedxm start_zed_node:=False

# 또는 ZED + RViz 한번에
ros2 launch zed_display_rviz2 display_zed_cam.launch.py camera_model:=zedxm
```

**주의**: `zed_display_rviz2` launch는 `param_overrides`를 전달하지 않으므로, OD 활성화는 launch 후 서비스 호출 필요:
```bash
ros2 service call /zed/zed_node/enable_obj_det std_srvs/srv/SetBool "{data: true}"
```

### 4.3 런타임 제어

```bash
# Object Detection on/off
ros2 service call /zed/zed_node/enable_obj_det std_srvs/srv/SetBool "{data: true}"
ros2 service call /zed/zed_node/enable_obj_det std_srvs/srv/SetBool "{data: false}"
```

---

## 5. 클래스별 세부 파라미터

> 소스: `custom_object_detection.yaml`

각 `class_XXX` 블록에서 설정 가능한 전체 파라미터:

### 기본 설정

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `label` | string | - | 클래스 이름 |
| `model_class_id` | int | - | ONNX 모델 내 클래스 ID |
| `enabled` | bool | `true` | 감지 활성화 |
| `confidence_threshold` | float | `50.0` | 신뢰도 임계값 (0-99) |

### 추적 힌트

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `is_grounded` | bool | `true` | 지면 기반 객체 (자유도 제한으로 추적 개선) |
| `is_static` | bool | `false` | 정적 객체 (이동하지 않는 물체) |
| `tracking_timeout` | float | `-1.0` | 미감지 시 추적 유지 시간 (s, -1=무제한) |
| `tracking_max_dist` | float | `-1.0` | 정적 객체 추적 최대 거리 (m, -1=무제한) |

### 바운딩 박스 필터링

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `max_box_width_normalized` | float | `-1.0` | 최대 2D 너비 (이미지 비율, -1=무제한) |
| `min_box_width_normalized` | float | `-1.0` | 최소 2D 너비 |
| `max_box_height_normalized` | float | `-1.0` | 최대 2D 높이 |
| `min_box_height_normalized` | float | `-1.0` | 최소 2D 높이 |
| `max_box_width_meters` | float | `-1.0` | 최대 3D 너비 (m) |
| `min_box_width_meters` | float | `-1.0` | 최소 3D 너비 |
| `max_box_height_meters` | float | `-1.0` | 최대 3D 높이 |
| `min_box_height_meters` | float | `-1.0` | 최소 3D 높이 |

### 동역학 설정

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `object_acceleration_preset` | string | `DEFAULT` | 가속도 프리셋 (DEFAULT/LOW/MEDIUM/HIGH) |
| `max_allowed_acceleration` | float | `100000.0` | 최대 가속도 (m/s^2, 프리셋 오버라이드) |
| `velocity_smoothing_factor` | float | `0.5` | 속도 평활화 (0.0-1.0) |
| `min_velocity_threshold` | float | `0.2` | 정지 판정 속도 임계값 (m/s) |
| `prediction_timeout_s` | float | `0.5` | 폐색 시 위치 예측 유지 시간 (s) |
| `min_confirmation_time_s` | float | `0.05` | 추적 확정 최소 시간 (s) |

---

## 6. 출력 메시지 구조

Object Detection 결과는 `obj_det/objects` 토픽으로 발행된다.

메시지 타입: `zed_msgs/ObjectsStamped`

각 `Object`에 포함되는 정보:

```
label: "cucumber"           # 클래스명
label_id: 0                 # 클래스 ID
confidence: 85.3            # 신뢰도 (1-99)
position: [1.2, 0.3, -0.5]  # 3D 무게중심 [m] (카메라 기준)
velocity: [0.0, 0.0, 0.0]   # 속도 [m/s]
tracking_state: 1            # 0=OFF, 1=OK, 2=SEARCHING, 3=TERMINATE
action_state: 0              # 0=IDLE, 2=MOVING
bounding_box_2d              # 이미지 평면 2D 박스 (4 corners)
bounding_box_3d              # 월드 3D 박스 (8 corners)
dimensions_3d: [0.1, 0.3, 0.1]  # [w, h, l] [m]
```

---

## 7. 카메라별 유효 거리

| 카메라 | Object Detection 범위 | 비고 |
|--------|----------------------|------|
| ZED 2 / 2i | 0.3 ~ 15m | USB 3.0 |
| ZED X | 0.2 ~ 15m | GMSL2 |
| ZED X Mini | 0.1 ~ 8m (2.2mm) / 0.15 ~ 12m (4mm) | GMSL2, 근거리 최적화 |
| ZED X HDR Max | 0.2 ~ 20m | GMSL2, 최대 범위 |

> ZED X Mini는 베이스라인이 짧아 근거리에 최적화. Body Tracking 유효 거리는 약 6m.

---

## 8. 실전 팁

### 첫 실행 시 모델 최적화

커스텀 ONNX 모델을 처음 로드하면 SDK가 TensorRT 엔진으로 자동 변환한다.
GPU에 따라 수 분 소요. 이후에는 캐싱되어 즉시 로드.

```
# 콘솔 로그에서 확인:
# [ZED] Optimizing ONNX model for TensorRT...
# [ZED] Model optimization complete. Cached at /usr/local/zed/resources/
```

### `imgsz`와 `custom_onnx_input_size` 일치

ONNX 내보내기 시 `imgsz`와 YAML의 `custom_onnx_input_size`가 반드시 일치해야 한다.
불일치 시 추론 결과가 비정상.

### TensorRT 캐시 무효화

모델 재학습 후 같은 파일명으로 ONNX를 덮어쓰면 이전 TensorRT 엔진 캐시가 사용된다.
새 모델을 반영하려면 **파일명을 변경**하거나 캐시를 삭제한다:

```bash
sudo rm /usr/local/zed/resources/*custom*  # 캐시 삭제 후 재시작
```

### `is_grounded` 설정

지면 위의 물체(사람, 차량 등)는 `is_grounded: true`로 설정하면 추적 품질이 개선된다.
공중에 매달린 물체(잎자루, 과일 등)는 `false`.

### 성능 최적화

| 설정 | 효과 |
|------|------|
| `max_range` 줄이기 | 불필요한 원거리 계산 절감 |
| 불필요 클래스 `enabled: false` | 후처리 부하 감소 |
| `filtering_mode: NMS3D_PER_CLASS` | 클래스 간 겹침 허용 시 사용 |
| `allow_reduced_precision_inference: true` | FP16 추론 (Jetson 권장) |

---

## 참고 링크

- [ZED YOLO 모델 내보내기 가이드](https://www.stereolabs.com/docs/yolo/export)
- [ZED Object Detection 문서](https://www.stereolabs.com/docs/object-detection/)
- [zed-ros2-wrapper custom_object_detection.yaml](https://github.com/stereolabs/zed-ros2-wrapper/blob/master/zed_wrapper/config/custom_object_detection.yaml)
- [zed-ros2-examples](https://github.com/stereolabs/zed-ros2-examples)
