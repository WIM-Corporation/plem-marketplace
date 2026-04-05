#!/bin/bash
# =============================================================================
# ROS 2 Humble + ZED ROS 2 의존성 설치 스크립트 (Jetson Native)
#
# 대상: Jetson Orin 시리즈 (JetPack 6.x / L4T 36.x)
# 전제: ROS 2 Humble이 설치되어 있지 않아도 됨 (자동 설치)
# 검증: nvcr.io/nvidia/l4t-jetpack:r36.4.0 컨테이너에서 전 단계 통과 확인
#
# 사용법:
#   sudo bash install-ros2-zed-deps.sh              # ROS 2 + ZED 의존성 전체
#   sudo bash install-ros2-zed-deps.sh --ros-only   # ROS 2 base만 설치
#   sudo bash install-ros2-zed-deps.sh --zed-only   # ZED 의존성만 (ROS 2 이미 설치됨)
# =============================================================================

set -euo pipefail

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
# 인자 파싱
# ---------------------------------------------------------------------------
INSTALL_ROS=true
INSTALL_ZED_DEPS=true

for arg in "$@"; do
    case "$arg" in
        --ros-only)  INSTALL_ZED_DEPS=false ;;
        --zed-only)  INSTALL_ROS=false ;;
        --help|-h)
            echo "Usage: sudo bash $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ros-only   ROS 2 Humble base만 설치"
            echo "  --zed-only   ZED ROS 2 의존성만 설치 (ROS 2가 이미 있을 때)"
            exit 0
            ;;
        *) die "알 수 없는 옵션: $arg (--help 참고)" ;;
    esac
done

# ---------------------------------------------------------------------------
# 루트 권한 확인
# ---------------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    die "루트 권한 필요: sudo bash $0"
fi

export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# Step 0: 최소 사전 의존성 (깨끗한 L4T 이미지에 없을 수 있음)
# ---------------------------------------------------------------------------
info "Step 0: 사전 의존성 확인"
apt-get update -qq
apt-get install -y --no-install-recommends curl gnupg2 lsb-release ca-certificates 2>&1 | tail -1
info "  [OK] 사전 의존성 준비 완료"

# ---------------------------------------------------------------------------
# Step 1: ROS 2 Humble 설치
# ---------------------------------------------------------------------------
if [ "$INSTALL_ROS" = true ]; then
    info "Step 1: ROS 2 Humble 설치"

    if [ -f /opt/ros/humble/setup.bash ]; then
        info "  ROS 2 Humble이 이미 설치되어 있음 — 건너뜀"
    else
        info "  apt 저장소 등록..."

        # ROS 2 GPG key
        curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
            -o /usr/share/keyrings/ros-archive-keyring.gpg

        # apt 소스 등록
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") main" \
            > /etc/apt/sources.list.d/ros2.list

        apt-get update -qq

        info "  ros-humble-ros-base 설치 중... (수 분 소요)"
        apt-get install -y ros-humble-ros-base

        if [ -f /opt/ros/humble/setup.bash ]; then
            info "  [OK] ROS 2 Humble 설치 완료"
        else
            die "ROS 2 Humble 설치 실패"
        fi
    fi
else
    info "Step 1: ROS 2 설치 건너뜀 (--zed-only)"
    if [ ! -f /opt/ros/humble/setup.bash ]; then
        die "ROS 2 Humble이 설치되어 있지 않음. --zed-only를 제거하고 다시 실행하세요"
    fi
fi

# ---------------------------------------------------------------------------
# Step 2: ZED ROS 2 의존성 설치
# ---------------------------------------------------------------------------
if [ "$INSTALL_ZED_DEPS" = true ]; then
    info "Step 2: ZED ROS 2 의존성 설치"

    apt-get update -qq

    # ZED apt 바이너리 패키지
    info "  ros-humble-zed-msgs, ros-humble-zed-description 설치..."
    apt-get install -y ros-humble-zed-msgs ros-humble-zed-description

    # ROS 2 패키지 의존성
    info "  ROS 2 패키지 의존성 설치..."
    apt-get install -y \
        ros-humble-diagnostic-updater \
        ros-humble-nmea-msgs \
        ros-humble-geographic-msgs \
        ros-humble-robot-localization \
        ros-humble-xacro \
        ros-humble-image-transport \
        ros-humble-image-transport-plugins \
        ros-humble-rmw-cyclonedds-cpp \
        ros-humble-backward-ros

    # 빌드 도구
    info "  빌드 도구 설치..."
    apt-get install -y \
        python3-rosdep \
        python3-colcon-common-extensions \
        python3-vcstool \
        nlohmann-json3-dev \
        git

    info "  [OK] ZED ROS 2 의존성 설치 완료"
else
    info "Step 2: ZED 의존성 설치 건너뜀 (--ros-only)"
fi

# ---------------------------------------------------------------------------
# Step 2.5: DDS 커널 버퍼 튜닝 (대용량 토픽 수신 필수)
# ---------------------------------------------------------------------------
if [ "$INSTALL_ZED_DEPS" = true ]; then
    info "Step 2.5: DDS 커널 버퍼 튜닝"

    SYSCTL_CONF="/etc/sysctl.d/60-zed-dds-buffers.conf"
    if [ -f "$SYSCTL_CONF" ]; then
        info "  $SYSCTL_CONF 이미 존재 — 건너뜀"
    else
        tee "$SYSCTL_CONF" > /dev/null << 'SYSCTL_EOF'
# ZED ROS 2 대용량 토픽 (PointCloud, RGB) DDS 수신 버퍼
# 미설정 시 토픽이 silent drop됨
net.ipv4.ipfrag_time = 3
net.ipv4.ipfrag_high_thresh = 134217728
net.core.rmem_max = 2147483647
SYSCTL_EOF
        sysctl --system > /dev/null 2>&1
        info "  [OK] $SYSCTL_CONF 생성 및 적용 완료"
    fi
fi

# ---------------------------------------------------------------------------
# Step 3: rosdep 초기화
# ---------------------------------------------------------------------------
info "Step 3: rosdep 초기화"

if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    rosdep init
fi
# rosdep update는 root가 아닌 사용자로 실행해야 경고가 안 뜸
# 스크립트에서는 root로 실행하므로 허용
rosdep update 2>&1 | tail -1

info "  [OK] rosdep 초기화 완료"

# ---------------------------------------------------------------------------
# Step 4: 설치 검증
# ---------------------------------------------------------------------------
info "Step 4: 설치 검증"

# ROS 2 setup.bash는 미정의 변수를 참조하므로 nounset 일시 해제
set +u
# shellcheck source=/dev/null
source /opt/ros/humble/setup.bash
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

check "[ -f /opt/ros/humble/setup.bash ]"             "ROS 2 Humble"

if [ "$INSTALL_ZED_DEPS" = true ]; then
    check "dpkg -s ros-humble-zed-msgs"                "ros-humble-zed-msgs"
    check "dpkg -s ros-humble-zed-description"         "ros-humble-zed-description"
    check "dpkg -s ros-humble-diagnostic-updater"      "ros-humble-diagnostic-updater"
    check "dpkg -s ros-humble-nmea-msgs"               "ros-humble-nmea-msgs"
    check "dpkg -s ros-humble-geographic-msgs"         "ros-humble-geographic-msgs"
    check "dpkg -s ros-humble-robot-localization"      "ros-humble-robot-localization"
    check "dpkg -s ros-humble-xacro"                   "ros-humble-xacro"
    check "dpkg -s ros-humble-image-transport"         "ros-humble-image-transport"
    check "dpkg -s ros-humble-image-transport-plugins"  "ros-humble-image-transport-plugins"
    check "dpkg -s ros-humble-rmw-cyclonedds-cpp"      "ros-humble-rmw-cyclonedds-cpp"
    check "[ -f /etc/sysctl.d/60-zed-dds-buffers.conf ]" "DDS 커널 버퍼 설정"
    check "which vcs"                                  "vcstool"
    check "which colcon"                               "colcon"
fi

# ---------------------------------------------------------------------------
# 결과 요약
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
if [ "$FAIL" -eq 0 ]; then
    info "설치 완료 ($PASS/$((PASS + FAIL)) 검증 통과)"
else
    error "설치 완료 — $FAIL개 검증 실패"
fi
echo ""
info "다음 단계:"
info "  1. ZED SDK 설치:  sudo bash install-zed-sdk.sh"
info "  2. 워크스페이스:  bash setup-zed-ros2-workspace.sh"
echo "=========================================="
