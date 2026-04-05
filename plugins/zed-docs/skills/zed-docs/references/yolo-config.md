---
description: "ZED + YOLO configuration reference — ONNX config structure, detection_model values, class_XXX block definition, output topics"
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
