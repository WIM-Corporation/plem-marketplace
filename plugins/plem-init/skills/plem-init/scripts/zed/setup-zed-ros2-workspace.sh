#!/bin/bash
# =============================================================================
# ZED ROS 2 워크스페이스 구성 스크립트 (Jetson Native)
#
# ZED SDK + ROS 2 Humble 설치 후, zed-ros2-wrapper를 포함한
# 워크스페이스를 생성·빌드한다.
#
# 전제:
#   - ZED SDK 설치 완료 (/usr/local/zed/)
#   - ROS 2 Humble 설치 완료 (/opt/ros/humble/)
#   - ZED ROS 2 의존성 설치 완료 (install-ros2-zed-deps.sh)
#
# 사용법:
#   bash setup-zed-ros2-workspace.sh                    # ~/zed_ws에 생성
#   bash setup-zed-ros2-workspace.sh /path/to/my_ws     # 지정 경로에 생성
#
# 검증: nvcr.io/nvidia/l4t-jetpack:r36.4.0 컨테이너에서 전 단계 통과 확인
# =============================================================================

set -euo pipefail
trap 'error "Step 실패. 이 스크립트를 다시 실행하면 이전 단계는 건너뛰고 실패 지점부터 재시도합니다."' ERR

# ---------------------------------------------------------------------------
# 색상 및 유틸
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()   { error "$*"; exit 1; }

# ---------------------------------------------------------------------------
# 인자
# ---------------------------------------------------------------------------
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: bash $0 [WORKSPACE_PATH]"
    echo ""
    echo "  WORKSPACE_PATH  워크스페이스 경로 (기본: ~/zed_ws)"
    echo ""
    echo "전제: install-ros2-zed-deps.sh + install-zed-sdk.sh 실행 완료"
    exit 0
fi

WS_DIR="${1:-$HOME/zed_ws}"

# ---------------------------------------------------------------------------
# 사전 확인
# ---------------------------------------------------------------------------
info "사전 확인"

if [ ! -f /usr/local/zed/lib/libsl_zed.so ]; then
    die "ZED SDK 미설치. 먼저 install-zed-sdk.sh를 실행하세요"
fi

if [ ! -f /opt/ros/humble/setup.bash ]; then
    die "ROS 2 Humble 미설치. 먼저 install-ros2-zed-deps.sh를 실행하세요"
fi

if ! command -v colcon &> /dev/null; then
    die "colcon 미설치. 먼저 install-ros2-zed-deps.sh를 실행하세요"
fi

# ROS 2 setup.bash는 미정의 변수를 참조하므로 nounset 일시 해제
set +u
# shellcheck source=/dev/null
source /opt/ros/humble/setup.bash
set -u

info "  ZED SDK: $(ls /usr/local/zed/lib/libsl_zed.so)"
info "  ROS 2:   /opt/ros/humble/"
info "  워크스페이스: $WS_DIR"

# ---------------------------------------------------------------------------
# Step 1: 워크스페이스 생성
# ---------------------------------------------------------------------------
info "Step 1: 워크스페이스 생성"

if [ -d "$WS_DIR/src/zed-ros2-wrapper" ]; then
    warn "  $WS_DIR/src/zed-ros2-wrapper 이미 존재 — clone 건너뜀"
else
    mkdir -p "$WS_DIR/src"
    cd "$WS_DIR/src"
    git clone --depth 1 --recursive --branch master https://github.com/stereolabs/zed-ros2-wrapper.git
    info "  [OK] zed-ros2-wrapper clone 완료"
fi

# ---------------------------------------------------------------------------
# Step 2: rosdep 의존성 해결
# ---------------------------------------------------------------------------
info "Step 2: rosdep 의존성 해결"

cd "$WS_DIR"
rosdep install --from-paths src --ignore-src -r -y 2>&1 | tail -1

info "  [OK] rosdep install 완료"

# ---------------------------------------------------------------------------
# Step 3: colcon build (Jetson 전용 cmake 플래그)
# ---------------------------------------------------------------------------
info "Step 3: colcon build (Jetson에서 10-30분 소요 — 중단하지 마세요)"
info "  Jetson 전용 cmake 플래그 적용"
info "    -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs"
info "    -DCMAKE_CXX_FLAGS=-Wl,--allow-shlib-undefined"

cd "$WS_DIR"

set +e
colcon build \
    --symlink-install \
    --cmake-args \
        '-DCMAKE_BUILD_TYPE=Release' \
        '-DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs' \
        '-DCMAKE_CXX_FLAGS=-Wl,--allow-shlib-undefined' \
        '--no-warn-unused-cli' \
    --parallel-workers "$(nproc)"
BUILD_RESULT=$?
set -e

if [ $BUILD_RESULT -ne 0 ]; then
    die "colcon build 실패 (exit code: $BUILD_RESULT). 재시도: rm -rf build/ install/ log/ && 이 스크립트 재실행"
fi

info "  [OK] colcon build 성공"

# ---------------------------------------------------------------------------
# Step 4: 검증
# ---------------------------------------------------------------------------
info "Step 4: 빌드 검증"

set +u
# shellcheck source=/dev/null
source "$WS_DIR/install/setup.bash"
set -u

PASS=0
FAIL=0

check() {
    if eval "$1" > /dev/null 2>&1; then
        info "  [OK] $2"
        PASS=$((PASS + 1))
    else
        error "  [FAIL] $2"
        FAIL=$((FAIL + 1))
    fi
}

check "ros2 pkg prefix zed_wrapper"     "zed_wrapper 패키지"
check "ros2 pkg prefix zed_components"  "zed_components 패키지"
check "ros2 pkg prefix zed_msgs"        "zed_msgs 패키지"
check "ros2 pkg prefix zed_description" "zed_description 패키지 (apt)"

LAUNCH_DIR="$(ros2 pkg prefix zed_wrapper)/share/zed_wrapper/launch"
check "[ -f $LAUNCH_DIR/zed_camera.launch.py ]" "zed_camera.launch.py"

# ---------------------------------------------------------------------------
# Step 5: bashrc 등록
# ---------------------------------------------------------------------------
SETUP_LINE="source $WS_DIR/install/local_setup.bash"
if ! grep -qF "$SETUP_LINE" "$HOME/.bashrc" 2>/dev/null; then
    echo "$SETUP_LINE" >> "$HOME/.bashrc"
    info "  ~/.bashrc에 워크스페이스 등록 완료"
else
    info "  ~/.bashrc에 이미 등록됨"
fi

# ---------------------------------------------------------------------------
# 결과 요약
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
if [ "$FAIL" -eq 0 ]; then
    info "워크스페이스 구성 완료 ($PASS/$((PASS + FAIL)) 검증 통과)"
else
    error "워크스페이스 구성 완료 — $FAIL개 검증 실패"
fi
echo ""
info "워크스페이스: $WS_DIR"
info ""
info "실행 방법:"
info "  source $WS_DIR/install/setup.bash"
info "  ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxm"
echo ""
info "RViz 시각화:"
info "  rviz2 -d scripts/zed/config/zedxm_display.rviz"
echo ""
info "카메라 모델별 launch 인자:"
info "  ZED X Mini:  camera_model:=zedxm"
info "  ZED X:       camera_model:=zedx"
info "  ZED 2i:      camera_model:=zed2i"
info "  ZED 2:       camera_model:=zed2"
echo "=========================================="
