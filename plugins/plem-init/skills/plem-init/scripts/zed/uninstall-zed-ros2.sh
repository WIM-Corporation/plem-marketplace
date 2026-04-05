#!/bin/bash
# =============================================================================
# ZED ROS 2 환경 제거 스크립트 (Jetson Native)
#
# install-ros2-zed-deps.sh, install-zed-sdk.sh, setup-zed-ros2-workspace.sh로
# 설치된 모든 항목을 역순으로 제거한다.
#
# 사용법:
#   sudo bash uninstall-zed-ros2.sh              # 대화형 (단계별 확인)
#   sudo bash uninstall-zed-ros2.sh --all        # ZED + ROS 2 의존성 + ROS 2 전체 제거
#   sudo bash uninstall-zed-ros2.sh --zed-only   # ZED SDK + 워크스페이스만 제거 (ROS 2 유지)
#   sudo bash uninstall-zed-ros2.sh --force      # 확인 없이 전체 제거
#
# 검증: nvcr.io/nvidia/l4t-jetpack:r36.4.0 컨테이너에서 설치→제거 전 과정 통과 확인
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
REMOVE_ROS_DEPS=true
REMOVE_ROS_BASE=true
ZED_ONLY=false
FORCE=false

for arg in "$@"; do
    case "$arg" in
        --zed-only)  ZED_ONLY=true; REMOVE_ROS_DEPS=false; REMOVE_ROS_BASE=false ;;
        --all)       ;;  # 기본 동작
        --force)     FORCE=true ;;
        --help|-h)
            echo "Usage: sudo bash $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --all        ZED + ROS 2 의존성 + ROS 2 전체 제거 (기본)"
            echo "  --zed-only   ZED SDK + 워크스페이스만 제거 (ROS 2 유지)"
            echo "  --force      확인 없이 제거"
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
# 확인 프롬프트
# ---------------------------------------------------------------------------
confirm() {
    if [ "$FORCE" = true ]; then
        return 0
    fi
    if [ -t 0 ]; then
        read -rp "$1 (y/N): " answer
        [ "$answer" = "y" ] || [ "$answer" = "Y" ]
    else
        # 비대화형: --force 없으면 거부
        warn "비대화형 환경에서는 --force 필요"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Step 1: 워크스페이스 제거
# ---------------------------------------------------------------------------
info "Step 1: ZED ROS 2 워크스페이스 제거"

# 일반적인 워크스페이스 경로 탐색
WS_CANDIDATES=()
for user_home in /home/* /root; do
    [ -d "$user_home" ] || continue
    for ws in "$user_home/zed_ws" "$user_home"/*/zed-ros2-wrapper; do
        if [ -d "$ws" ]; then
            # zed-ros2-wrapper가 src/ 안에 있으면 상위 워크스페이스 경로 사용
            case "$ws" in
                */src/zed-ros2-wrapper) WS_CANDIDATES+=("$(dirname "$(dirname "$ws")")") ;;
                *)                      WS_CANDIDATES+=("$ws") ;;
            esac
        fi
    done
done

# 중복 제거
WS_UNIQUE=($(printf '%s\n' "${WS_CANDIDATES[@]}" 2>/dev/null | sort -u))

if [ ${#WS_UNIQUE[@]} -gt 0 ]; then
    for ws in "${WS_UNIQUE[@]}"; do
        if confirm "  워크스페이스 삭제: $ws?"; then
            rm -rf "$ws"
            info "  [OK] $ws 삭제됨"
        else
            warn "  건너뜀: $ws"
        fi
    done
else
    info "  워크스페이스 미발견 — 건너뜀"
fi

# bashrc에서 워크스페이스 source 제거
for bashrc in /home/*/.bashrc /root/.bashrc; do
    [ -f "$bashrc" ] || continue
    if grep -q "zed_ws\|zed-ros2-wrapper" "$bashrc" 2>/dev/null; then
        sed -i '/zed_ws\|zed-ros2-wrapper/d' "$bashrc"
        info "  [OK] $(basename "$(dirname "$bashrc")")/.bashrc에서 워크스페이스 참조 제거"
    fi
done

# ---------------------------------------------------------------------------
# Step 2: pyzed 제거
# ---------------------------------------------------------------------------
info "Step 2: pyzed 제거"

if python3 -c "import pyzed" 2>/dev/null; then
    pip3 uninstall -y pyzed 2>/dev/null || true
    info "  [OK] pyzed 제거됨"
else
    info "  pyzed 미설치 — 건너뜀"
fi

# ---------------------------------------------------------------------------
# Step 3: ZED SDK 제거
# ---------------------------------------------------------------------------
info "Step 3: ZED SDK 제거"

if [ -d /usr/local/zed ]; then
    if confirm "  /usr/local/zed/ 삭제?"; then
        # zed_x_daemon 중지 및 비활성화
        if systemctl list-unit-files 2>/dev/null | grep -q zed_x_daemon; then
            systemctl stop zed_x_daemon 2>/dev/null || true
            systemctl disable zed_x_daemon 2>/dev/null || true
            info "  [OK] zed_x_daemon 중지 및 비활성화"
        fi

        # SDK 디렉토리 삭제
        rm -rf /usr/local/zed
        info "  [OK] /usr/local/zed/ 삭제됨"

        # udev 규칙 정리 (SDK가 설치한 것)
        rm -f /etc/udev/rules.d/99-zed*.rules 2>/dev/null
        rm -f /etc/udev/rules.d/zed*.rules 2>/dev/null

        # 공유 라이브러리 캐시 갱신
        ldconfig 2>/dev/null || true
        info "  [OK] ldconfig 갱신"
    else
        warn "  건너뜀"
    fi
else
    info "  ZED SDK 미설치 — 건너뜀"
fi

# ---------------------------------------------------------------------------
# Step 4: ZED ROS 2 의존성 제거
# ---------------------------------------------------------------------------
if [ "$ZED_ONLY" = false ] && [ "$REMOVE_ROS_DEPS" = true ]; then
    info "Step 4: ZED ROS 2 의존성 패키지 제거"

    ZED_DEPS=(
        ros-humble-zed-msgs
        ros-humble-diagnostic-updater
        ros-humble-nmea-msgs
        ros-humble-geographic-msgs
        ros-humble-robot-localization
        ros-humble-xacro
        ros-humble-image-transport
        ros-humble-theora-image-transport
        ros-humble-backward-ros
        nlohmann-json3-dev
        python3-vcstool
    )

    # 설치된 것만 필터링
    INSTALLED=()
    for pkg in "${ZED_DEPS[@]}"; do
        if dpkg -s "$pkg" > /dev/null 2>&1; then
            INSTALLED+=("$pkg")
        fi
    done

    if [ ${#INSTALLED[@]} -gt 0 ]; then
        if confirm "  ${#INSTALLED[@]}개 패키지 제거?"; then
            apt-get remove -y "${INSTALLED[@]}" 2>&1 | tail -3
            info "  [OK] ZED 의존성 패키지 제거됨"
        else
            warn "  건너뜀"
        fi
    else
        info "  제거 대상 패키지 없음 — 건너뜀"
    fi
else
    info "Step 4: 건너뜀 (--zed-only)"
fi

# ---------------------------------------------------------------------------
# Step 5: ROS 2 Humble 제거 (선택)
# ---------------------------------------------------------------------------
if [ "$ZED_ONLY" = false ] && [ "$REMOVE_ROS_BASE" = true ]; then
    info "Step 5: ROS 2 Humble 제거"

    if dpkg -s ros-humble-ros-base > /dev/null 2>&1; then
        if confirm "  ROS 2 Humble 전체 제거? (다른 ROS 패키지도 함께 제거됨)"; then
            apt-get remove -y 'ros-humble-*' 2>&1 | tail -3
            apt-get autoremove -y 2>&1 | tail -3

            # apt 소스 정리
            rm -f /etc/apt/sources.list.d/ros2.list 2>/dev/null
            rm -f /usr/share/keyrings/ros-archive-keyring.gpg 2>/dev/null

            # bashrc에서 ROS source 제거
            for bashrc in /home/*/.bashrc /root/.bashrc; do
                [ -f "$bashrc" ] || continue
                if grep -q "/opt/ros/humble" "$bashrc" 2>/dev/null; then
                    sed -i '/\/opt\/ros\/humble/d' "$bashrc"
                    info "  [OK] $(basename "$(dirname "$bashrc")")/.bashrc에서 ROS 참조 제거"
                fi
            done

            info "  [OK] ROS 2 Humble 제거됨"
        else
            warn "  건너뜀"
        fi
    else
        info "  ROS 2 Humble 미설치 — 건너뜀"
    fi
else
    info "Step 5: 건너뜀 (--zed-only)"
fi

# ---------------------------------------------------------------------------
# Step 6: 잔여 파일 정리
# ---------------------------------------------------------------------------
info "Step 6: 잔여 파일 정리"

# rosdep 캐시
if [ -d /root/.ros/rosdep ]; then
    rm -rf /root/.ros/rosdep
    info "  [OK] rosdep 캐시 제거"
fi
if [ -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    rm -f /etc/ros/rosdep/sources.list.d/20-default.list
    info "  [OK] rosdep 소스 리스트 제거"
fi

# colcon 빌드 도구
if dpkg -s python3-colcon-common-extensions > /dev/null 2>&1; then
    apt-get remove -y python3-colcon-common-extensions python3-rosdep 2>&1 | tail -1
    info "  [OK] colcon + rosdep 제거"
fi

# 자동 제거
apt-get autoremove -y 2>&1 | tail -1

info "  [OK] 잔여 파일 정리 완료"

# ---------------------------------------------------------------------------
# Step 7: 제거 검증
# ---------------------------------------------------------------------------
info "Step 7: 제거 검증"

PASS=0
FAIL=0

check_removed() {
    if eval "$1" > /dev/null 2>&1; then
        error "  [REMAIN] $2"
        FAIL=$((FAIL + 1))
    else
        info "  [OK] $2 제거 확인"
        PASS=$((PASS + 1))
    fi
}

check_removed "[ -d /usr/local/zed ]"                    "ZED SDK (/usr/local/zed/)"
check_removed "python3 -c 'import pyzed'"                "pyzed"

if [ "$ZED_ONLY" = false ]; then
    check_removed "dpkg -s ros-humble-zed-msgs"          "ros-humble-zed-msgs"
    check_removed "[ -f /opt/ros/humble/setup.bash ]"    "ROS 2 Humble"
fi

# ---------------------------------------------------------------------------
# 결과 요약
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
if [ "$FAIL" -eq 0 ]; then
    info "제거 완료 ($PASS/$((PASS + FAIL)) 항목 정상 제거)"
else
    warn "제거 완료 — $FAIL개 항목 잔존"
fi
echo "=========================================="
