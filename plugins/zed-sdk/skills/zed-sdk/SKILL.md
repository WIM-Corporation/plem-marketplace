---
name: zed-sdk
description: "ZED SDK official docs — sl::Camera API, depth modes, object detection, body tracking, positional tracking, YOLO ONNX, ZED X/X One hardware, SDK install, ROS 2 wrapper params/topics/services, Docker, Isaac ROS. Use for Stereolabs SDK questions."
argument-hint: "[topic]"
---

# ZED SDK — Official Documentation Reference

Stereolabs ZED SDK 공식문서 기반 레퍼런스. ~70페이지를 체계적으로 정리한 reference 파일을 제공한다.
인자로 토픽을 지정하면 해당 문서를 바로 참조한다.

## Quick Routing

사용자 질문에 따라 적절한 reference 문서를 읽어 답변한다:

| 사용자가 묻는 것 | 읽어야 할 문서 | 핵심 키워드 |
|----------------|--------------|------------|
| **SDK Overview** | | |
| 카메라 열기, 이미지 캡처, 해상도, 비디오 설정, 녹화, 스트리밍, 멀티카메라 | `references/sdk-overview/camera.md` | Camera, grab, resolution, SVO, streaming, multi-camera, PTP |
| IMU, 자이로, 기압계, 온도, 자기계, 센서 시간동기화 | `references/sdk-overview/sensors.md` | IMU, gyroscope, barometer, magnetometer, temperature, sensor |
| 깊이 감지, depth mode, 포인트 클라우드, 신뢰도, depth settings | `references/sdk-overview/depth-sensing.md` | depth, NEURAL, NEURAL_PLUS, point cloud, confidence, 깊이 |
| 위치 추적, VSLAM, 좌표계, area memory, 포즈 | `references/sdk-overview/positional-tracking.md` | tracking, pose, VSLAM, coordinate frame, odometry, 위치 추적 |
| 객체 탐지, 커스텀 디텍터, 바운딩박스 | `references/sdk-overview/object-detection.md` | object detection, custom detector, bounding box, 객체 탐지 |
| 바디 트래킹, 스켈레톤, 관절 | `references/sdk-overview/body-tracking.md` | body tracking, skeleton, keypoint, BODY_18, BODY_34, BODY_38 |
| 공간 매핑, 메시, 평면 탐지 | `references/sdk-overview/spatial-mapping.md` | spatial mapping, mesh, fused point cloud, plane detection |
| GNSS, RTK, 글로벌 위치, 좌표 변환 | `references/sdk-overview/global-localization.md` | GNSS, RTK, geo, UTM, ECEF, global localization |
| Fusion API, ZED360, 멀티카메라 퓨전 | `references/sdk-overview/fusion.md` | fusion, ZED360, multi-camera fusion |
| **ROS 2 Integration** | | |
| ZED ROS 2 노드, 토픽 목록, 파라미터, 서비스, QoS, 커스텀 메시지 | `references/ros2/zed-node.md` | ros2 node, topic, parameter, service, QoS, zed_interfaces |
| DDS 튜닝, 주파수 조절, 하드웨어 인코딩 브릿지, Composition/IPC | `references/ros2/network-tuning.md` | DDS, Cyclone, frequency, bridge, composition, IPC |
| RViz, 비디오 캡처, 깊이, 위치추적, Geo, 평면, ROI, 녹화/재생 | `references/ros2/features.md` | rviz, video, depth ros2, tracking ros2, geo, ROI, recording, rosbag |
| ROS 2 객체탐지, 커스텀 YOLO, 바디 트래킹 | `references/ros2/detection.md` | ros2 object detection, custom yolo ros2, body tracking ros2 |
| 멀티카메라 설정, 로봇 통합, URDF/TF | `references/ros2/advanced.md` | multi-camera ros2, robot integration, xacro, TF |
| **Camera Hardware** | | |
| ZED, ZED Mini, ZED 2, ZED 2i (USB 카메라) | `references/cameras/zed-usb.md` | ZED 2, ZED Mini, ZED 2i, USB 3.0 |
| ZED X, ZED X Mini (GMSL2), ISP, NV12, 트러블슈팅 | `references/cameras/zed-x.md` | ZED X, GMSL2, ISP, NV12, zed_x_daemon |
| ZED X One (단안 GMSL2), 모노/스테레오, 캘리브레이션 | `references/cameras/zed-x-one.md` | ZED X One, monocular, CameraOne, virtual stereo |
| **Development** | | |
| SDK 설치 (Windows/Linux/Jetson/Docker), 스펙 | `references/development/sdk-install.md` | install, SDK, Jetson, JetPack, CUDA |
| ZED 도구 (Explorer, Studio, Depth Viewer, 캘리브레이션) | `references/development/zed-tools.md` | ZED Explorer, ZED Studio, ZEDfu, calibration |
| C++/Python/C#/C 개발, 빌드 환경 설정 | `references/development/programming.md` | C++, Python, pyzed, CMake, build, virtual env |
| **Embedded Devices** | | |
| ZED Link 캡처카드 (Mono/Duo/Quad), 드라이버 | `references/embedded/zed-link.md` | ZED Link, capture card, GMSL2 power |
| ZED Box Mini, ZED Box Orin, RT 커널 | `references/embedded/zed-box.md` | ZED Box, Orin, embedded, real-time kernel |
| **Integrations** | | |
| Docker (Linux/Jetson), ROS 2 이미지, ARM 크로스빌드 | `references/integrations/docker.md` | Docker, container, nvidia-container-toolkit |
| YOLO 통합, ONNX 모델 익스포트 | `references/integrations/yolo.md` | YOLO, ONNX, export, YOLOv5, YOLOv8 |
| Isaac ROS, NITROS, AprilTag | `references/integrations/isaac-ros.md` | Isaac ROS, NITROS, AprilTag |
| **plem 실무 가이드** | | |
| plem manipulator TF 정합, depth_stabilization, URDF, mount YAML, Hand-Eye | `references/plem/robot-integration.md` | plem TF, manipulator, publish_tf, depth_stabilization, URDF, mount, calibration |
| plem 네임스페이스, /{robot_id}/cam, QoS, param_overrides, 전체 토픽 목록 | `references/plem/namespace-conventions.md` | plem namespace, /{robot_id}/, QoS silent failure, param_overrides |
| plem DDS 튜닝, 커널 버퍼, CycloneDDS XML, cross-DDS 크래시 | `references/plem/dds-tuning.md` | plem DDS, 커널 버퍼, CycloneDDS, cross-DDS |
| plem YOLO 3D 통합, 농작물 config, imgsz 일치, TensorRT 캐시, OD 3D bbox 근거리 불안정/거리 의존성, depth median 미티게이션 | `references/plem/yolo-plem.md` | plem YOLO, 농작물, cucumber, is_grounded, TensorRT cache, OD bbox 튐, corners 점프, 근거리 안정성, depth median |
| plem 성능 최적화, ROI 마스킹, grab_compute_capping, pub_downscale | `references/plem/optimization.md` | plem 최적화, ROI, capping, frequency |
| plem headless SIGSEGV, RViz, SVO, Jetson HW 인코딩, 벤치마크 | `references/plem/usage-recording.md` | plem headless, SIGSEGV, NITROS, SVO, rosbag, 벤치마크 |

인자가 없으면 위 라우팅 테이블을 기반으로 가장 관련된 문서를 읽어 답변한다.
질문이 여러 영역에 걸치면 관련 문서를 순서대로 읽는다.
plem 생태계 관련 질문은 `references/plem/` 하위 문서를 우선 참조한다.

### 보조 라우팅 (주 라우팅으로 부족할 때)

| 상황 | 추가 참조 |
|------|----------|
| 멀티카메라 GPU/CPU 리소스 사용량, FPS 벤치마크 | `references/sdk-overview/depth-sensing.md` (플랫폼별 성능 테이블) |
| Jetson colcon build 에러 (libcuda.so, cmake 플래그) | `references/development/programming.md` (C++ Linux/Jetson 빌드) |

## 관련 도구

| 도구 | 역할 | 언제 사용 |
|------|------|----------|
| **zed-sdk** (이 스킬) | SDK 공식문서 + plem 실무 가이드 통합 레퍼런스 | SDK API, 하드웨어, 설치, plem 통합 |
| **Context7 MCP** (`resolve-library-id` → `query-docs`) | 최신 API 시그니처, 함수 파라미터, 코드 예제 | `sl::Camera`, `pyzed` 등 **실제 코드 작성** 시 (C++/Python) |

실제 `sl::Camera` C++ API나 `pyzed` Python 코드를 작성할 때는 Context7 MCP를 통해 최신 API 문서를 조회하는 것을 권장한다 — 함수 시그니처, 파라미터 타입, 반환값은 SDK 버전에 따라 달라질 수 있다.

## 문서 구조

```
zed-sdk/
├── SKILL.md                          # 이 파일 (라우팅 + 개요)
└── references/
    ├── sdk-overview/                  # ZED SDK 핵심 기능
    │   ├── camera.md                  # Camera/Video API (7 pages)
    │   ├── sensors.md                 # Sensors API (7 pages)
    │   ├── depth-sensing.md           # Depth Sensing (4 pages)
    │   ├── positional-tracking.md     # Positional Tracking (8 pages)
    │   ├── object-detection.md        # Object Detection (3 pages)
    │   ├── body-tracking.md           # Body Tracking (2 pages)
    │   ├── spatial-mapping.md         # Spatial Mapping (3 pages)
    │   ├── global-localization.md     # Global Localization/GNSS (6 pages)
    │   └── fusion.md                  # Fusion/ZED360 (2 pages)
    ├── ros2/                          # ZED ROS 2 Wrapper
    │   ├── zed-node.md                # Node, topics, params, services (5 pages)
    │   ├── network-tuning.md          # DDS, frequency, bridge, IPC (4 pages)
    │   ├── features.md                # RViz, video, depth, tracking, geo, ROI, recording (8 pages)
    │   ├── detection.md               # OD, custom YOLO, body tracking (3 pages)
    │   └── advanced.md                # Multi-camera, robot integration (2 pages)
    ├── cameras/                       # Camera Hardware
    │   ├── zed-usb.md                 # ZED/Mini/2/2i USB cameras (1 page)
    │   ├── zed-x.md                   # ZED X GMSL2 (6 pages)
    │   └── zed-x-one.md              # ZED X One GMSL2 (7 pages)
    ├── development/                   # SDK Installation & Development
    │   ├── sdk-install.md             # SDK install Win/Linux/Jetson/Docker (7 pages)
    │   ├── zed-tools.md               # ZED Explorer, Studio, etc. (8 pages)
    │   └── programming.md             # C++/Python/C#/C dev (9 pages)
    ├── embedded/                      # Embedded Devices
    │   ├── zed-link.md                # ZED Link capture cards (7 pages)
    │   └── zed-box.md                 # ZED Box Mini/Orin (9 pages)
    ├── integrations/                  # Third-party Integrations
    │   ├── docker.md                  # Docker for ZED (7 pages)
    │   ├── yolo.md                    # YOLO integration (3 pages)
    │   └── isaac-ros.md               # Isaac ROS (5 pages)
    └── plem/                          # plem 생태계 실무 가이드
        ├── robot-integration.md       # TF 정합, depth_stabilization, URDF, mount YAML
        ├── namespace-conventions.md   # /{robot_id}/cam, QoS, param_overrides, 토픽 목록
        ├── dds-tuning.md              # CycloneDDS, 커널 버퍼, cross-DDS 크래시
        ├── yolo-plem.md               # 농작물 config, imgsz 일치, TensorRT 캐시
        ├── optimization.md            # ROI 마스킹, grab_compute_capping, RViz 주의
        └── usage-recording.md         # headless SIGSEGV, SVO, HW 인코딩, 벤치마크
```

총 31개 reference 파일: 공식문서 25개 + plem 실무 가이드 6개.

## 사용 패턴

```
# 특정 토픽 조회
/zed-sdk depth mode
/zed-sdk ros2 node parameters
/zed-sdk yolo export

# 일반 질문 (자동 라우팅)
/zed-sdk  → 질문 내용에서 키워드를 매칭하여 적절한 reference를 읽음
```
