# Camera Driver Setup Guide

In the plem platform, `camera:=zedxm` **only adds camera TF frames to the URDF**.
To receive camera image streams, install the camera vendor's official ROS2 driver separately.

## What plem provides vs what you install

| plem provides | You install |
|--------------|-------------|
| TF frames (URDF geometry for MoveIt collision avoidance) | Camera driver node (image topics) |
| Mount configuration (Hand-Eye calibration YAML, `camera_link` screw-hole 기준) | Vision processing (YOLO, etc.) |
| Standard interface (`plem_msgs/action/VisionInspection`) | VisionInspection action server |

## Installation Scripts (Recommended)

plem-init bundles installation scripts at `scripts/zed/`. Run them in order:

| # | Script | Purpose |
|---|--------|---------|
| 1 | `install-ros2-zed-deps.sh` | ROS 2 Humble + ZED ROS 2 dependency packages |
| 2 | `install-zed-sdk.sh` | ZED SDK (auto-detects Jetson L4T version) |
| 3 | `setup-zed-ros2-workspace.sh` | Clone zed-ros2-wrapper, apply Jetson cmake flags, build |
| - | `uninstall-zed-ros2.sh` | ZED SDK + ROS 2 환경 역순 제거 (`--zed-only`, `--all`, `--force`) |

Each script verifies prerequisites before proceeding. Use `--help` for options.

```bash
# Example: full installation sequence
bash scripts/zed/install-ros2-zed-deps.sh
bash scripts/zed/install-zed-sdk.sh
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

> 상세 문법은 `.claude/rules/zed-camera.md` 참조.

## TF Frame Alignment

Camera URDF TF frames must match the driver-published frames.

**ZED X Mini (vendored official macro):**
- URDF frame: `{cam_name}_left_camera_frame_optical` (cam_name = `{prefix}{name}_cam`)
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
- **YOLO integration**: See `.claude/references/zed-yolo-integration.md` for ZED + YOLO 3D detection
- **API reference**: See `.claude/references/zed-ros2-api-reference.md` for complete topic/service/parameter list
