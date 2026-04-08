---
description: "plem YOLO 3D Object Detection 통합 — 커스텀 ONNX 모델 설정, 농작물 class config (is_grounded, is_static), imgsz 3곳 일치, TensorRT 캐시 무효화, param_overrides 함정, common_stereo.yaml 수정 금지, 근거리 OD 3D bbox 거리 의존성과 depth median 미티게이션"
source: "zed-docs/references/yolo-integration.md + yolo-config.md"
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
    param_overrides:="object_detection.od_enabled:=true;object_detection.detection_model:=CUSTOM_YOLOLIKE_BOX_OBJECTS;object_detection.enable_tracking:=true;object_detection.max_range:=20.0"
```

> **대안**: OD 클래스 정의 전용 launch arg `custom_object_detection_config_path`도 사용 가능:
> ```bash
> ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
>     custom_object_detection_config_path:=/path/to/custom_object_detection.yaml \
>     param_overrides:="object_detection.od_enabled:=true;object_detection.detection_model:=CUSTOM_YOLOLIKE_BOX_OBJECTS"
> ```

#### Step 3: 결과 확인

```bash
# 탐지 결과 토픽 구독
ros2 topic echo /zed/zed_node/obj_det/objects
```

**RViz에서 3D 바운딩 박스 시각화:**

`ObjectsStamped`는 RViz2 기본 display type이 아니다.
`obj_det/objects` 토픽에 데이터가 발행되어도 RViz에 아무것도 표시되지 않는다면,
`rviz_plugin_zed_od` 플러그인이 빌드되어 있지 않기 때문이다.

이 플러그인은 `zed-ros2-wrapper`가 **아닌** 별도 저장소 `zed-ros2-examples`에 포함되어 있다.

```bash
# 방법 1: deps.repos에 추가 (워크스페이스에서 관리)
# deps.repos 파일에 추가:
#   zed-ros2-examples:
#     type: git
#     url: https://github.com/stereolabs/zed-ros2-examples.git
#     version: master
vcs import src < deps.repos
colcon build --packages-select rviz_plugin_zed_od zed_display_rviz2

# 방법 2: 직접 clone
cd ~/zed_ws/src
git clone --depth 1 https://github.com/stereolabs/zed-ros2-examples.git
cd ~/zed_ws && colcon build --packages-select rviz_plugin_zed_od zed_display_rviz2
```

빌드 후 RViz 실행:

```bash
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
| ZED X Mini | 0.1 ~ 8m (2.2mm) / 0.15 ~ 12m (4mm) | GMSL2, 짧은 baseline |
| ZED X HDR Max | 0.2 ~ 20m | GMSL2, 최대 범위 |

> ZED X Mini는 베이스라인이 짧아 다른 모델보다 가까운 거리까지 disparity를 잡을 수 있다 — 단, "잡을 수 있다"와 "안정적이다"는 다르다 (아래 참조). Body Tracking 유효 거리는 약 6m.

### "최소 거리"는 "안정 거리"가 아니다

위 표의 하한(`depth_minimum_distance`)은 disparity 매칭이 *가능한* 한계이지, Object Detection 3D 출력(`position`, `dimensions_3d`, `bounding_box_3d.corners`)이 *안정한* 한계가 아니다. 객체가 최소 거리에 근접할수록 disparity가 stereo search window 끝단에 몰려 매칭 노이즈가 커지고, 그 노이즈가 depth map → OD 3D 출력으로 그대로 전파된다 — 프레임마다 `corners`가 cm 단위로 점프하는 형태로 관찰된다.

베이스라인이 짧은 모델일수록(ZED X Mini가 대표적) 이 현상이 더 가까운 거리부터 시작된다. 안정 작동 거리는 최소 거리 자체가 아니라 그보다 충분히 떨어진 영역으로 잡아야 한다. 이는 SDK 알고리즘 한계가 아니라 stereo 광학의 본질적 특성이라 `NEURAL_PLUS`나 `depth_stabilization`으로 해결되지 않는다.

> pendant·RViz에서 박스가 튀는 현상을 보면 먼저 카메라-객체 거리를 의심한다. 거리를 늘려서 멈추면 위 원인이 맞다.

### 근거리에서 안정한 3D 위치가 필요하면

`bounding_box_3d.corners`를 그대로 사용하지 말고, **2D bbox 또는 마스크 영역의 depth median**을 집계해 pinhole 역투영으로 3D 위치를 산출한다. 단일 픽셀 노이즈가 median으로 흡수되므로 corners보다 거리 의존성이 훨씬 약하다 — 동일 파이프라인으로 근거리(픽킹 직전)와 원거리(접근 단계)를 모두 처리할 수 있다.

```python
# 개념 코드 — OD 결과 + depth map 조합
depths = depth_map[mask]                           # OD 2D mask 영역만
z = np.median(depths[np.isfinite(depths) & (depths > 0)])
u, v = bbox_2d_center
x = (u - cx) * z / fx                              # pinhole 역투영 (left rectified)
y = (v - cy) * z / fy
```

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

### `param_overrides` 문자열 값에 따옴표 금지

`param_overrides`에서 문자열 값을 전달할 때 따옴표로 감싸면 안 된다.
따옴표가 값의 일부로 파싱되어 파라미터 매칭에 실패한다.

```bash
# 잘못됨 — 따옴표가 값에 포함되어 크래시
param_overrides:="object_detection.detection_model:='CUSTOM_YOLOLIKE_BOX_OBJECTS'"

# 올바름 — 따옴표 없이 직접 지정
param_overrides:="object_detection.detection_model:=CUSTOM_YOLOLIKE_BOX_OBJECTS"
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

### ONNX 배포 전 독립 검증 (강력 권장)

ZED SDK는 ONNX 텐서 포맷이 SDK 기대치와 다를 때 **에러 없이 "탐지 0건"으로 실패**하는 경우가 있다 (스택트레이스나 명확한 진단 메시지 없이). TensorRT 변환·RViz 확인까지 모두 거친 후 발견되는 함정. ONNX Runtime으로 모델을 독립 검증하여 이를 사전에 잡는다.

> **중요**: 이 검증은 "모델 구조 자체가 정상"임을 확정한다. ZED SDK는 TensorRT를 사용하므로 통과해도 SDK에서 실패할 가능성은 여전히 있다 (op 호환성, 캐시 오염 등). 다만 통과 후 SDK가 실패한다면 원인이 SDK 측 설정 영역으로 좁혀져 디버깅이 훨씬 쉬워진다.

**언제 실행하는가** — 모델 재학습 후, Ultralytics 버전 업그레이드 후, 클래스 추가/제거 후, `imgsz` 변경 후, 새 ONNX 파일을 처음 받아 deploy하기 전.

#### 진단 가능한 실패 모드

| 원인 | 증상 | 진단 난이도 |
|------|------|------------|
| 학습 imgsz / export imgsz / YAML `custom_onnx_input_size` 불일치 | **탐지 0건** (에러 없이) | 매우 어려움 |
| 출력 텐서 shape이 `[1, nc+4, N]`이 아님 (`simplify=False`, `dynamic=True` 등) | 탐지 0건 또는 SDK 로드 실패 | 어려움 |
| Ultralytics 버전 변경으로 텐서 포맷 미세 변동 | 탐지 0건 또는 노이즈성 검출 | 매우 어려움 |
| 학습 데이터 병합 시 class_id 리맵핑 오류 | **탐지 정상, 클래스 라벨이 뒤바뀜** | 중간 (RViz로 눈 확인) |
| YOLOv7 `--end2end` 플래그 사용 | 출력 포맷 자체 다름 → 로드 실패 | 쉬움 |

#### 의존성

```bash
pip install onnx onnxruntime  # GPU 버전 불필요 — 검증용이라 CPU로 충분
```

#### 1단계: 텐서 구조 검증

```python
import onnx

model = onnx.load("best.onnx")

# 입력 shape: [1, 3, imgsz, imgsz] 이어야 함
for inp in model.graph.input:
    shape = [d.dim_value for d in inp.type.tensor_type.shape.dim]
    print(f"Input: {inp.name}, shape: {shape}")
    # 기대: [1, 3, 640, 640] (학습 imgsz)

# 출력 shape: [1, nc+4, N] 이어야 함 (YOLOv8/v11 계열)
for out in model.graph.output:
    shape = [d.dim_value for d in out.type.tensor_type.shape.dim]
    print(f"Output: {out.name}, shape: {shape}")
    # 기대 (예: 3 클래스, imgsz=640): [1, 7, 8400]
    # 일반 공식: [1, nc + 4, num_anchors]
    # num_anchors(imgsz=640) = 80*80 + 40*40 + 20*20 = 8400
```

**검증 포인트:**

- 입력 두 번째 차원 = `3` (RGB 채널)
- 입력 마지막 두 차원 = 학습 `imgsz` = 내보내기 `imgsz` = YAML `custom_onnx_input_size` (삼위일체)
- 출력 두 번째 차원 = `nc + 4` (`nc`=클래스 수, `4`=cx/cy/w/h)
- 위 셋 중 하나라도 다르면 SDK가 포맷을 인식하지 못한다 → 학습/export 단계로 돌아갈 것

#### 2단계: ONNX Runtime 추론 테스트

> **letterbox 사용 필수**: Ultralytics는 학습/추론 시 단순 resize가 아닌 aspect ratio를 보존하는 letterbox 전처리를 사용한다. 단순 `cv2.resize`로 대체하면 검증 결과가 학습 시점과 어긋날 수 있다.

```python
import onnxruntime as ort
import cv2
import numpy as np

CLASS_NAMES = {0: "apple", 1: "persimmon", 2: "box"}  # 프로젝트별로 수정
CONF_THRESHOLD = 0.25
IMGSZ = 640


def letterbox(img, new_shape=640, color=(114, 114, 114)):
    """Ultralytics letterbox: aspect ratio 보존 + 패딩."""
    h, w = img.shape[:2]
    r = min(new_shape / h, new_shape / w)
    new_unpad = (int(round(w * r)), int(round(h * r)))
    dw = (new_shape - new_unpad[0]) / 2
    dh = (new_shape - new_unpad[1]) / 2
    img = cv2.resize(img, new_unpad, interpolation=cv2.INTER_LINEAR)
    top, bottom = int(round(dh - 0.1)), int(round(dh + 0.1))
    left, right = int(round(dw - 0.1)), int(round(dw + 0.1))
    return cv2.copyMakeBorder(img, top, bottom, left, right,
                              cv2.BORDER_CONSTANT, value=color)


# 더 안전한 대안: Ultralytics와 동일한 코드 경로
# from ultralytics.data.augment import LetterBox
# letterbox_op = LetterBox(new_shape=(IMGSZ, IMGSZ), auto=False)
# img_lb = letterbox_op(image=img_rgb)


# 세션 생성 (CPU provider로 충분)
session = ort.InferenceSession(
    "best.onnx",
    providers=["CPUExecutionProvider"],
)
input_name = session.get_inputs()[0].name

# 테스트 이미지 — 학습 데이터와 같은 도메인이어야 의미 있음
img_bgr = cv2.imread("test_apple_01.jpg")
img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
img_lb = letterbox(img_rgb, new_shape=IMGSZ)
blob = (img_lb.astype(np.float32) / 255.0).transpose(2, 0, 1)[np.newaxis, ...]
# blob shape: [1, 3, IMGSZ, IMGSZ]

# 추론
outputs = session.run(None, {input_name: blob})
print(f"Output shape: {outputs[0].shape}")

preds = outputs[0][0]  # [nc+4, N]

# YOLOv8/v11 디코딩: bbox=preds[0:4], class scores=preds[4:]
# 좌표는 IMGSZ 기준 픽셀 단위 (정규화 아님)
# 주의: NMS 전 raw output이라 같은 객체에 여러 detection이 나오는 게 정상
detections = []
for i in range(preds.shape[1]):
    class_scores = preds[4:, i]
    max_score = float(class_scores.max())
    if max_score > CONF_THRESHOLD:
        class_id = int(class_scores.argmax())
        cx, cy, w, h = preds[0:4, i]
        detections.append((class_id, max_score, cx, cy, w, h))

# 클래스별 최고 신뢰도 검출만 표시 (raw NMS 전이라 너무 많음)
print(f"\n총 raw 검출 (conf>{CONF_THRESHOLD}): {len(detections)}개")
top_per_class = {}
for d in detections:
    cid = d[0]
    if cid not in top_per_class or d[1] > top_per_class[cid][1]:
        top_per_class[cid] = d

print("클래스별 1순위 검출:")
for cid, (_, conf, cx, cy, w, h) in sorted(top_per_class.items()):
    name = CLASS_NAMES.get(cid, f"unknown_{cid}")
    print(f"  [{name}] conf={conf:.2f} "
          f"cx={cx:.0f} cy={cy:.0f} w={w:.0f} h={h:.0f} "
          f"(pixel, {IMGSZ}-base)")
```

**검증 체크리스트** — 클래스당 최소 3장씩, **학습 데이터와 비슷한 도메인의 이미지로** 테스트:

| 체크 | 통과 기준 | 실패 시 의심 영역 |
|------|---------|----------------|
| Output shape이 `[1, nc+4, N]` 포맷인가? | 1단계 print와 일치 | export 옵션 (`simplify`, `dynamic`), Ultralytics 버전 |
| Raw 검출 건수가 0이 아닌가? | ≥1 | imgsz 불일치, export 옵션, 학습 자체 실패 |
| 각 테스트 이미지에서 **올바른 클래스**가 1순위로 나오는가? | 사람 눈 확인 | class_id 리맵핑 오류, 학습 데이터 라벨 오염 |
| YAML `class_XXX → model_class_id`가 ONNX 출력 인덱스와 일치하는가? | 사람이 직접 매칭 | 리맵핑 테이블 |
| 신뢰도가 합리적인 범위(0.3~0.95)인가? | conf 분포 확인 | 학습 부족, 도메인 갭 |

> **하나라도 실패하면 SDK 배포로 넘어가지 않는다.**
> 데이터 리맵핑·학습·ONNX export 단계로 돌아가서 원인을 잡는다.
>
> 모든 검증 통과 후에도 SDK에서 검출이 0건이라면, **원인은 SDK 측**으로 좁혀진다:
> - YAML `custom_onnx_input_size` 값
> - `param_overrides` 따옴표/escape 문제
> - TensorRT 캐시 오염 (`/usr/local/zed/resources/`)
> - TensorRT의 op 호환성 (드물지만 가능)

#### 자주 헷갈리는 점

- **좌표는 픽셀 단위**: YOLOv8/v11 ONNX 출력은 input imgsz 기준 픽셀 좌표(0~`imgsz`)이지 정규화 좌표(0~1)가 아니다.
- **NMS 미적용**: ONNX 모델 자체는 NMS 전 raw output이라 같은 객체에 대해 여러 개 detection이 나오는 게 정상. ZED SDK가 NMS를 처리한다.
- **letterbox 좌표 역변환**: 검출된 bbox를 원본 이미지에 그리려면 letterbox 패딩/스케일을 역으로 적용해야 한다. 검증 단계에서는 imgsz 좌표 자체로 충분.
- **ONNX Runtime CPU vs SDK TensorRT**: 둘은 다른 런타임이라 신뢰도 수치가 미세하게 다를 수 있지만, **검출 유무와 클래스 매핑은 동일해야 한다**.
- **테스트 이미지 도메인**: 인터넷에서 받은 이미지로 검증하면 도메인 갭으로 검출이 안 되는데 모델 문제로 오해할 수 있다. 학습 셋의 val 이미지나 실제 배포 환경 캡처를 사용할 것.

#### YOLO 버전별 적용 범위

- **YOLOv8 / v11 / v12** (Ultralytics 계열, output `[1, nc+4, N]`): 위 디코딩 그대로 동작
- **YOLOv5**: output 포맷이 다름 (`[1, N, nc+5]`, objectness 포함). 디코딩 수정 필요
- **YOLOv6**: 자체 export 스크립트, 포맷 다를 수 있음
- **YOLOv7**: `--end2end` 플래그 사용 시 NMS 포함된 다른 포맷, 검증 코드 수정 필요
- **YOLOv9 / v10**: Ultralytics 계열이면 v8/v11과 동일한 디코딩 가능 (확인 필요)

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

---

# ZED + YOLO 통합 — 코딩 규칙

ZED SDK는 YOLO ONNX 모델을 네이티브로 로드하여 2D 탐지 → 3D 위치 + 추적 + 속도를 자동 계산한다.

## detection_model 값

`common_stereo.yaml`의 `object_detection.detection_model`:
- `MULTI_CLASS_BOX_FAST` — 내장 다중 클래스 (기본값)
- `MULTI_CLASS_BOX_MEDIUM` / `MULTI_CLASS_BOX_ACCURATE`
- `PERSON_HEAD_BOX_FAST` / `PERSON_HEAD_BOX_ACCURATE`
- `CUSTOM_YOLOLIKE_BOX_OBJECTS` — **커스텀 YOLO ONNX 모델**

## 커스텀 ONNX 설정 구조

`custom_object_detection.yaml` 필수 파라미터:
```yaml
object_detection:
  custom_onnx_file: '/path/to/model.onnx'
  custom_onnx_input_size: 640        # ONNX export imgsz와 반드시 일치
  custom_class_count: 4              # 클래스 수
```

## 클래스 정의 (class_XXX 블록)

```yaml
class_000:
  label: 'my_class'
  model_class_id: 0                  # ONNX 내 클래스 ID
  enabled: true
  confidence_threshold: 50.0         # 0-99
  is_grounded: true                  # 지면 물체=true, 공중=false
  is_static: false                   # 정적 물체=true
```

- `XXX`는 `000` ~ `custom_class_count-1`
- `model_class_id`는 ONNX 모델의 클래스 ID와 일치시킬 것
- `is_grounded: false`로 설정하면 공중 물체의 추적 자유도가 증가

## ONNX 내보내기

```bash
yolo export model=best.pt format=onnx simplify=True dynamic=False imgsz=640
```

`simplify=True`와 `dynamic=False`는 필수.

## 출력 토픽

`obj_det/objects` (`zed_msgs/ObjectsStamped`) — 각 Object에 포함:
- `position[3]`: 3D 무게중심 (m)
- `velocity[3]`: 속도 (m/s)
- `bounding_box_3d`: 8 corners
- `tracking_state`: 0=OFF, 1=OK, 2=SEARCHING, 3=TERMINATE
