---
description: >
  YOLO integration with ZED SDK -- overview, code samples, and ONNX model export
  for YOLOv5 through YOLOv12 with TensorRT optimization.
source_urls:
  - https://www.stereolabs.com/docs/yolo/
  - https://www.stereolabs.com/docs/yolo/samples/
  - https://www.stereolabs.com/docs/yolo/export/
fetched: 2026-04-07
---

# YOLO with ZED SDK

## Table of Contents

- [YOLO Overview](#yolo-overview)
- [YOLO Samples](#yolo-samples)
- [Exporting a YOLO ONNX Model](#exporting-a-yolo-onnx-model)

---

## YOLO Overview

This integration enables YOLO object detection models to work with ZED stereo cameras, adding 3D localization and tracking capabilities. The system uses TensorRT-optimized ONNX models for state-of-the-art performance.

### Supported Models

The solution is compatible with YOLOv5, YOLOv6, YOLOv7, YOLOv9, YOLOv10, YOLOv11, and YOLOv12. Models with matching output formats to supported versions should also work.

### Installation Requirements

- ZED SDK with Python API
- TensorRT (installed via ZED SDK's AI module)
- OpenCV
- CUDA

### Two Implementation Approaches

**Recommended Method:** Use the ZED SDK's native `OBJECT_DETECTION_MODEL::CUSTOM_YOLOLIKE_BOX_OBJECTS` mode. This approach provides fully optimized inference with automatic ONNX to TensorRT conversion and integrated 3D object output.

**Advanced Alternative:** For unsupported models, implement external TensorRT inference and feed detection boxes into the ZED SDK -- suitable for users maintaining custom inference code.

### Critical Requirement

Exporting your YOLO model to ONNX format is mandatory before deployment. You can use pre-trained COCO dataset models (80 classes) or custom-trained alternatives.

---

## YOLO Samples

### Key Implementation Approaches

1. **Native Inference (Recommended)**: Use the `OBJECT_DETECTION_MODEL::CUSTOM_YOLOLIKE_BOX_OBJECTS` mode in the ZED SDK API to natively load a YOLO ONNX model.

2. **External Inference**: For advanced users with unsupported models, involving manual TensorRT inference code and bounding box ingestion.

### Supported YOLO Versions

Specific support for:
- TensorRT-optimized C++ implementations
- Python native inference
- YOLOv8 PyTorch integration via Ultralytics

The ZED SDK automatically handles ONNX to TensorRT engine generation (optimized model) for supported models.

### Available Code Samples

- C++ native inference sample
- Python native inference sample
- C++ external TensorRT inference
- PyTorch YOLOv8 integration with point cloud visualization

### Custom Model Training

The documentation references Ultralytics' training guide for custom datasets, enabling users to train proprietary models before integration.

---

## Exporting a YOLO ONNX Model

### Workflow Overview

1. Train a custom model or utilize an existing state-of-the-art model.
2. Export the model to ONNX format.
3. Load the ONNX file into the SDK or sample application, which generates an optimized model using TensorRT.

### Ultralytics YOLO (v5, v8, v10, v11, v12)

#### Installation

```bash
python -m pip install -U ultralytics
```

#### ONNX Export Commands

**YOLOv12:**

```bash
yolo export model=yolo12n.pt format=onnx simplify=True dynamic=False imgsz=608
```

**YOLOv11:**

```bash
yolo export model=yolo11n.pt format=onnx simplify=True dynamic=False imgsz=608
```

**YOLOv10:**

```bash
yolo export model=yolov10n.pt format=onnx simplify=True dynamic=False imgsz=608
```

**YOLOv8:**

```bash
yolo export model=yolov8n.pt format=onnx simplify=True dynamic=False imgsz=608
```

**YOLOv5:**

```bash
yolo export model=yolov5n.pt format=onnx simplify=True dynamic=False imgsz=608
```

#### Model Variants and Customization

Model variants (n, s, m, l, x) can be selected by adjusting the model name. For dynamic dimensions:

```bash
yolo export model=yolo12m.pt format=onnx simplify=True dynamic=True
```

For custom models, replace the weight file accordingly:

```bash
yolo export model=yolov8l_custom_model.pt format=onnx simplify=True dynamic=False imgsz=512
```

### YOLOv6

#### Installation

```bash
git clone https://github.com/meituan/YOLOv6
cd YOLOv6
pip install -r requirements.txt
pip install onnx>=1.10.0
```

#### ONNX Export

```bash
wget https://github.com/meituan/YOLOv6/releases/download/0.3.0/yolov6s.pt
python ./deploy/ONNX/export_onnx.py \
    --weights yolov6s.pt \
    --img 640 \
    --batch 1 \
    --simplify
```

For custom models, adjust the weights parameter.

### YOLOv7

#### Installation

```bash
git clone https://github.com/WongKinYiu/yolov7.git
cd yolov7
python -m pip install -r requirements.txt
```

#### ONNX Export

```bash
python export.py --weights ./yolov7-tiny.pt --grid --simplify --topk-all 100 --iou-thres 0.65 --conf-thres 0.35 --img-size 640 640
```

> **Important**: The `--end2end` option must NOT be used for ZED SDK compatibility.

### YOLOv5 (standalone repo)

#### Installation

```bash
git clone https://github.com/ultralytics/yolov5
cd yolov5
pip install -r requirements.txt
```

#### ONNX Export

```bash
python export.py --weights yolov5s.pt --include onnx --imgsz 640
```

For custom models:

```bash
python export.py --weights yolov8l_custom_model.pt --include onnx
```

This process enables 3D localization and tracking capabilities when combining exported YOLO models with ZED stereoscopic cameras, supporting custom object detection classes trained on your specific datasets.
