# Camera Driver Setup Guide

In the plem platform, `camera:=zedxm` **only adds camera TF frames to the URDF**.
To receive camera image streams, install the camera vendor's official ROS2 driver separately.

## What plem provides vs what you install

| plem provides | You install |
|--------------|-------------|
| TF frames (URDF geometry for MoveIt collision avoidance) | Camera driver node (image topics) |
| Mount configuration (Hand-Eye calibration YAML, `camera_link` screw-hole 기준) | Vision processing (YOLO, etc.) |
| Standard interface (`plem_msgs/action/VisionInspection`) | VisionInspection action server |

## ZED SDK vs ZED Link Driver

GMSL2 카메라(ZED X, ZED X Mini)를 사용하려면 **두 가지를 별도로 설치**해야 한다:

| 구성요소 | 설치 대상 | 역할 |
|---------|----------|------|
| **ZED SDK** | API 라이브러리 (`libsl_zed.so`, pyzed, ZED Tools) | 카메라 제어 API |
| **ZED Link Driver** | 커널 모듈 (`sl_zedx.ko`, `max96712.ko`) + `zed_x_daemon` | GMSL2 하드웨어 인식 |

USB 카메라(ZED 2, ZED Mini)는 ZED SDK만으로 충분하다. ZED Link Driver는 GMSL2 전용.

**PREEMPT_RT 커널**: ZED Link Driver는 RT 커널용 `.deb`를 별도 배포한다 (파일명에 `-rt-` 포함).
RT 커널에서 표준 커널용 드라이버를 설치하면 커널 모듈이 로드되지 않는다.
`install-zed-link-driver.sh`가 `uname -v`로 커널 종류를 자동 감지하여 올바른 변형을 선택한다.

**L4T 호환성**: 드라이버 URL은 L4T minor 버전(36.3, 36.4, 36.5)으로 매핑된다.
같은 minor 내 patch 버전(36.4.0, 36.4.4, 36.4.7 등)은 동일 드라이버를 사용한다.

> 검증 이력: L4T 36.4 (PREEMPT_RT) 환경에서
> ZED Link Duo RT 드라이버 (v1.4.1) 설치 후 `sl_zedx`, `max96712` 모듈 정상 로드 확인.

## Installation Scripts (Recommended)

plem-init bundles installation scripts at `scripts/zed/`. Run them in order:

| # | Script | Purpose | 범위 |
|---|--------|---------|------|
| 1 | `install-ros2-zed-deps.sh` | ROS 2 Humble + ZED ROS 2 dependency packages | 시스템 |
| 2 | `install-zed-sdk.sh` | ZED SDK + Tools (auto-detects Jetson L4T version) | 시스템 |
| 3 | `install-zed-link-driver.sh` | GMSL2 커널 모듈 + zed_x_daemon (ZED X/X Mini 전용) | 시스템 |
| 4 | `setup-zed-ros2-workspace.sh` | Clone zed-ros2-wrapper, apply Jetson cmake flags, build | 유저 |
| - | `uninstall-zed-ros2.sh` | ZED SDK + ROS 2 환경 역순 제거 (`--zed-only`, `--all`, `--force`) | - |

시스템 스크립트(1~3)는 장비당 1회, sudo 필요. 유저 스크립트(4)는 프로젝트별.
USB 카메라(ZED 2, ZED Mini)는 스크립트 3을 건너뛴다.

Each script verifies prerequisites before proceeding. Use `--help` for options.

```bash
# Example: GMSL2 카메라 전체 설치 (ZED X, ZED X Mini)
bash scripts/zed/install-ros2-zed-deps.sh
sudo bash scripts/zed/install-zed-sdk.sh
sudo bash scripts/zed/install-zed-link-driver.sh --card duo   # mono|duo|quad
sudo reboot
# 리부트 후:
bash scripts/zed/setup-zed-ros2-workspace.sh

# Example: USB 카메라 (ZED 2, ZED Mini) — ZED Link 드라이버 불필요
bash scripts/zed/install-ros2-zed-deps.sh
sudo bash scripts/zed/install-zed-sdk.sh
bash scripts/zed/setup-zed-ros2-workspace.sh
```

## Manual Installation

### ZED SDK

**Jetson (aarch64):**
```bash
# SDK auto-download for your L4T version
bash scripts/zed/install-zed-sdk.sh
# Or manual: https://www.stereolabs.com/developers/release
```

**Desktop (x86_64):**
```bash
# Download from https://www.stereolabs.com/developers/release
chmod +x ZED_SDK_*.run
./ZED_SDK_*.run -- silent skip_drivers
```

### zed-ros2-wrapper (Source Build)

Source build is required — apt packages are not available for all platforms.

```bash
mkdir -p ~/zed_ws/src && cd ~/zed_ws/src
git clone --recursive https://github.com/stereolabs/zed-ros2-wrapper.git
cd ~/zed_ws
rosdep install --from-paths src --ignore-src -r -y
```

**Jetson-specific cmake flags (critical):**

| Flag | Purpose |
|------|---------|
| `-DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs` | Resolve CUDA stub libraries during cross-build |
| `-DCMAKE_CXX_FLAGS=-Wl,--allow-shlib-undefined` | Allow unresolved symbols (resolved at runtime by driver) |

```bash
# Desktop
colcon build --packages-up-to zed_wrapper

# Jetson (MUST include cmake flags)
colcon build --packages-up-to zed_wrapper \
  --cmake-args \
  -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
  -DCMAKE_CXX_FLAGS="-Wl,--allow-shlib-undefined"
```

### ZED X Daemon (GMSL2 cameras only)

ZED X and ZED X Mini use GMSL2 interface, requiring a system daemon:

```bash
sudo systemctl enable zed_x_daemon
sudo systemctl start zed_x_daemon
```

## Launch

```bash
# ZED X Mini
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm

# With custom config
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm config_path:=/path/to/config.yaml

# Headless (SSH) 환경에서는 disable_nitros 필수 (SIGSEGV 방지)
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    param_overrides:="debug.disable_nitros:=true"

# Object Detection 활성화 (param_overrides 사용, 직접 launch arg 전달 불가)
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm \
    param_overrides:="object_detection.od_enabled:=true;debug.disable_nitros:=true"
```

> **주의**: `object_detection.od_enabled:=true`를 launch argument로 직접 전달하면 효과 없음. `param_overrides`를 통해 전달할 것.

> 상세 문법은 `/zed-sdk` 스킬 참조 (파라미터 오버라이드, 토픽명, QoS 등).

## TF Frame Alignment

Camera URDF TF frames must match the driver-published frames.

**ZED X Mini (vendored official macro):**
- URDF frame: `{cam_name}_left_camera_frame_optical` (cam_name = `{prefix}cam`)
- Driver frame: `{camera_name}_left_camera_frame_optical` (set `camera_name:={cam_name}` in driver launch)
- Frame names match 100% when camera_name equals cam_name

To avoid TF conflicts, disable driver TF publishing when using plem URDF:

```bash
ros2 launch zed_wrapper zed_camera.launch.py \
  camera_model:=zedxm \
  publish_tf:=false \
  publish_map_tf:=false
```

Hand-Eye calibration result: `neuromeka_integrations/urdf/sensors/config/zedxm_mount.yaml`

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `PackageNotFoundError: 'zed_description'` | ZED wrapper v5.2+가 URDF용 `zed_description`에 의존하지만 별도 apt 설치 필요 | `sudo apt install ros-humble-zed-description` |
| `libgxf_isaac_optimizer.so: cannot open shared object file` | Isaac ROS GXF 라이브러리가 ldconfig에 미등록 (호스트 설치 시) | 아래 Isaac ROS GXF 항목 참조 |
| `zed_x_daemon` systemctl 실패 (`Is a directory`) | ZED SDK/Link 설치 과정에서 서비스 파일이 디렉토리로 잘못 생성됨 | 아래 ZED X Daemon 복구 항목 참조 |
| `rviz2 -d .../config/rviz2/<model>.rviz` 파일 없음 | 공식 README 문서 오류. RViz 파일이 별도 저장소로 분리됨 | plem-init 번들 `scripts/zed/config/zedxm_display.rviz` 사용 |
| `libcuda.so not found` during build | Missing CUDA stubs | Add `-DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs` |
| `undefined symbol` link error on Jetson | Strict linker on aarch64 | Add `-Wl,--allow-shlib-undefined` to cmake flags |
| No image topics after launch | ZED X daemon not running | `sudo systemctl start zed_x_daemon` |
| NumPy version conflict | pyzed vs JetPack PyTorch | Use separate venv, or access via ROS topics only |
| `SCHED_FIFO` permission error | Missing RT privileges | `sudo` or set `thread_sched_policy: SCHED_BATCH` in config |
| SIGSEGV (`Could not get EGL display connection`) | Headless(SSH) 환경에서 NITROS가 EGL 초기화 실패 | `param_overrides:="debug.disable_nitros:=true"` 또는 DISPLAY 설정된 환경에서 실행 |
| `modprobe: FATAL: Module sl_zedx not found` | ZED Link 드라이버 미설치 또는 RT/표준 커널 불일치 | `sudo bash install-zed-link-driver.sh --card <type>` 실행. RT 커널이면 `-rt-` 변형 자동 선택됨 |
| `zed_x_daemon` 서비스 없음 | ZED Link 드라이버 미설치 (SDK만 설치됨) | ZED Link 드라이버 설치 필요. SDK와 별도 패키지 |
| `ZED_Explorer: command not found` | SDK 설치 시 `--no-tools` 또는 `--minimal` 사용 | `sudo bash install-zed-sdk.sh --force` 재설치 (기본값: Tools 포함) |
| `Object Det. enabled: FALSE` (od_enabled 무시됨) | `od_enabled:=true`는 launch argument가 아님 | `param_overrides:="object_detection.od_enabled:=true"` 사용 |

### Isaac ROS GXF 라이브러리 경로 미등록 (호스트 설치 시)

Isaac ROS를 Docker 없이 호스트에 직접 설치한 경우, GXF 라이브러리들이 `/opt/ros/humble/share/*/gxf/lib/` 하위에 설치되지만 ldconfig에 등록되지 않는다. Isaac ROS가 Docker 컨테이너 기반 사용을 전제로 설계되어 있기 때문.

```bash
sudo bash -c 'find /opt/ros/humble/share -path "*/gxf/lib" -type d > /etc/ld.so.conf.d/isaac-ros-gxf.conf'
sudo ldconfig
```

### ZED X Daemon 서비스 파일 복구

ZED SDK 또는 ZED Link 설치 과정에서 `/etc/systemd/system/zed_x_daemon.service`가 파일이 아닌 디렉토리로 잘못 생성되는 경우가 있다. `ZED_Explorer -a`에서 카메라 State가 `NOT AVAILABLE`로 표시된다.

```bash
# 1. 손상된 서비스 확인
file /etc/systemd/system/zed_x_daemon.service
# "directory"로 나오면 손상됨

# 2. 백업에서 복구 (설치 시 /tmp에 백업이 남아있을 수 있음)
sudo rm -r /etc/systemd/system/zed_x_daemon.service
sudo cp /tmp/zed_x_daemon.service.bak /etc/systemd/system/zed_x_daemon.service
# 백업이 없으면 ZED SDK 재설치 필요

# 3. 데몬 재시작
sudo systemctl daemon-reload
sudo systemctl restart zed_x_daemon

# 4. 확인
ZED_Explorer -a  # State: "AVAILABLE" 확인
```

**참고:** ZED SDK/ZED Link 재설치 시 재발 가능성 있음. 설치 후 서비스 파일 상태를 확인할 것.

## GMSL2 카메라 전용 트러블슈팅

### ISP daemon 재시작 절차

**증상**: ISP 설정 변경 후 카메라 출력이 이전 설정 유지.
**원인**: 단순 systemctl restart로는 부족. 커널 모듈 reload 필요.
**해결**:

```bash
# rmmod 실패 시("Module is in use") → sudo systemctl stop zed_x_daemon 후 ZED 프로세스 모두 종료 뒤 재시도
sudo systemctl restart nvargus-daemon.service
sudo rmmod sl_zedx
sudo rmmod max96712
sleep 1
sudo insmod /usr/lib/modules/$(uname -r)/kernel/drivers/stereolabs/max96712/max96712.ko
sudo insmod /usr/lib/modules/$(uname -r)/kernel/drivers/stereolabs/zedx/sl_zedx.ko
```

GMSL2 커널 모듈 경로:
- 디시리얼라이저: `/usr/lib/modules/$(uname -r)/kernel/drivers/stereolabs/max96712/max96712.ko`
- ZED X 드라이버: `/usr/lib/modules/$(uname -r)/kernel/drivers/stereolabs/zedx/sl_zedx.ko`

### 시스템 업데이트 후 blurry image

**증상**: apt upgrade 등 시스템 업데이트 후 카메라 이미지가 흐릿해짐.
**원인**: 시스템 업데이트가 `libnvisppg.so`를 덮어쓸 수 있음.
**해결**: ZED SDK `.deb`에서 복원 (설치 시 다운로드한 파일 사용, 없으면 stereolabs.com/developers/release에서 재다운로드):

```bash
# 예: stereolabs-zedxm_5.2.1-max96712-l4t36.4_arm64.deb
ar x stereolabs-zed<model>_<version>-<deser>-<l4t_version>_arm64.deb
tar xvf data.tar.xz
sudo cp ./tmp/R<l4t_version>/libnvisppg.so /usr/lib/aarch64-linux-gnu/tegra/libnvisppg.so
sudo reboot
```

### 하드웨어 변경 후 카메라 미인식

**증상**: 카메라 플러그/언플러그 또는 순서 변경 후 카메라가 인식되지 않음.
**해결**: daemon 재시작(ISP daemon 재시작 절차 참조) 또는 리부트.

## Post-Installation Verification

설치 완료 후 정상 동작을 확인하는 순서:

```bash
# 1. 카메라 하드웨어 상태 확인 (GMSL2 카메라만 해당)
ZED_Explorer -a          # State: "AVAILABLE" 확인

# 2. ZED wrapper 실행
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm

# 3. 다른 터미널에서 RViz 시각화 (plem-init 번들 설정 파일 사용)
rviz2 -d scripts/zed/config/zedxm_display.rviz
```

카메라가 `NOT AVAILABLE`이면 Troubleshooting의 ZED X Daemon 항목 참조.

### RViz 시각화 설정

plem-init이 `scripts/zed/config/zedxm_display.rviz` 파일을 번들로 제공한다. Point Cloud, RGB Image, Depth Image, TF 디스플레이를 포함한다.

**주의:** zed-ros2-wrapper 공식 README에서 안내하는 `zed_wrapper/config/rviz2/<model>.rviz` 경로는 존재하지 않는 문서 오류다. 해당 파일은 별도 저장소 `zed-ros2-examples`에 있으나, 전체 레포를 clone하는 것은 과하므로 번들 설정 파일을 사용한다.

커스텀이 필요하면 RViz GUI에서 디스플레이를 추가/수정한 뒤 `File → Save Config`으로 저장.

카메라 모델별 launch 파일: `display_zedxm.launch.py`, `display_zedx.launch.py`, `display_zed2i.launch.py`, `display_zed2.launch.py`

## Next Steps

- **Vision node development**: Implement `plem_msgs/action/VisionInspection` action server (`ros2 interface show plem_msgs/action/VisionInspection`)
- **YOLO integration**: `/zed-sdk yolo` — ZED + YOLO 3D detection 통합 가이드
- **API reference**: `/zed-sdk api` — 전체 토픽/서비스/파라미터 레퍼런스
