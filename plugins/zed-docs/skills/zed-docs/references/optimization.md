---
description: "ZED performance optimization — frequency tuning, latency, ROI masking, resolution scaling, IPC composition"
---

# ZED 성능 최적화

## 1. Frequency Tuning 파라미터

| 파라미터 | 동적 | 설명 |
|---------|------|------|
| `general.grab_frame_rate` | N | 최대 프레임 수집 속도 (end-to-end latency 결정) |
| `general.grab_compute_capping_fps` | N | 상위 연산 제한 (0.0=비활성). **grab latency에 영향 없이** CPU 절감 |
| `general.pub_frame_rate` | **Y** | 이미지/depth publish Hz |
| `depth.point_cloud_freq` | **Y** | 포인트 클라우드 publish Hz |
| `sensors.sensors_pub_rate` | **Y** | 센서 데이터 Hz (최대 400) |

`grab_compute_capping_fps`가 핵심: grab_frame_rate는 최대로 유지(low latency)하면서 compute만 줄여 CPU를 절감.

## 2. Latency 참조 테이블

| 카메라 | 해상도 | Max FPS | End-to-end Latency |
|--------|--------|---------|-------------------|
| ZED X / X Mini | SVGA | 120 | ~17–25ms |
| ZED X / X Mini | HD1080/HD1200 | 60 | ~33–50ms |
| ZED 2i | VGA | 100 | ~30–40ms |
| ZED 2i | HD720 | 60 | ~50–67ms |
| ZED 2i | HD1080 | 30 | ~100–133ms |

Latency는 GMSL2=2-3프레임, USB3=3-4프레임으로 고정.

## 3. CPU 최적화 전략

1. `grab_frame_rate` → 최대값 (low latency)
2. `grab_compute_capping_fps` → 필요한 만큼만 (CPU 절감)
3. `/diagnostics` 모니터링: "Data Capture - Mean Frequency" > grab_frame_rate의 99.5%
4. 동적 파라미터로 런타임 튜닝:
   ```bash
   ros2 param set /zed/zed_node general.pub_frame_rate 15.0
   ros2 param set /zed/zed_node depth.point_cloud_freq 5.0
   ```

## 4. ROI (Region of Interest) — Manipulator FOV 마스킹

ZED가 manipulator에 마운트되면 로봇 팔이 FOV에 보임.
ROI 마스킹으로 해당 픽셀을 제외하면 depth/tracking 품질이 개선됨.

### 파라미터 설정

```yaml
region_of_interest:
  # 정규화 좌표 다각형 (해상도 독립)
  manual_polygon: "[[0.5,0.25],[0.75,0.5],[0.5,0.75],[0.25,0.5]]"
  # 전체 이미지 (마스크 없음): "" 또는 "[]"

  # 적용 대상 선택
  apply_to_depth: true
  apply_to_positional_tracking: true
  apply_to_object_detection: true
  apply_to_body_tracking: true
  apply_to_spatial_mapping: true

  # 자동 ROI (로봇 부위 자동 감지/마스킹)
  automatic_roi: true
```

### 런타임 서비���

```bash
# ROI 설정
ros2 service call /zed/zed_node/set_roi zed_interfaces/srv/SetROI \
    "{roi: '[[0.1,0.1],[0.9,0.1],[0.9,0.9],[0.1,0.9]]'}"

# ROI 초기화
ros2 service call /zed/zed_node/reset_roi std_srvs/srv/Trigger
```

## 5. 해상도 축소

Grab 품질을 유지하면서 publish 데이터량만 축소:

```yaml
general:
  pub_resolution: 'CUSTOM'
  pub_downscale_factor: 2.0    # HD1200 → 960x608
```

대역폭·CPU·저장 용량 모두 절감. `zed-dds-network.md`의 네트워크 튜닝과 병행 시 효과적.

## 6. Composition & IPC (Zero-Copy)

`zed_camera.launch.py`는 이미 component container + IPC 활성화(`use_intra_process_comms: True`).
커스텀 subscriber를 동일 컨테이너에 로드하면 zero-copy 데이터 전달:

- 컨테이너 이름: `/<camera_name>/zed_container`
- 확인: `ros2 component list`
- 다중 카메라 IPC: `zed_ipc` 패키지 사용

## 7. RViz on Jetson 주의

RViz2는 GPU 집약적이며 ZED SDK와 GPU를 공유. Jetson에서 RViz 직접 실행은 권장하지 않음.
별도 PC에서 ROS 2 네트워크 경유 실행. 네트워크 설정: `zed-dds-network.md` 참조.

## 시나리오별 권장 설정

| 시나리오 | 핵심 설정 |
|---------|----------|
| 장애물 회피 | `point_cloud_freq` = 로봇 속도 기반 안전 요구 |
| 시각화 전용 | `pub_frame_rate` 낮게 (5–10Hz) |
| SLAM | image/depth rate ↔ CPU 균형 |
| 상태 추정 | `sensors_pub_rate` = 필터 요구에 맞춤 |
| 대역폭 제한 | `pub_downscale_factor: 2.0` + compressed transport |
