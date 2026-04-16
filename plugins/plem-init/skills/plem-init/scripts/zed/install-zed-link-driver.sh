#!/bin/bash
# =============================================================================
# ZED Link Driver 설치 스크립트 (GMSL2 카메라 전용, Jetson Native)
#
# GMSL2 카메라(ZED X, ZED X Mini 등)를 사용하기 위한 커널 모듈 + daemon 설치.
# ZED SDK와는 별도 설치가 필요하다. USB 카메라(ZED 2, ZED Mini)는 불필요.
#
# 검증: Jetson Orin (L4T 36.4, JetPack 6.x, PREEMPT_RT / 표준 커널)
#
# 사용법:
#   sudo bash install-zed-link-driver.sh --card duo        # ZED Link Duo (2포트)
#   sudo bash install-zed-link-driver.sh --card mono       # ZED Link Mono (1포트)
#   sudo bash install-zed-link-driver.sh --card quad       # ZED Link Quad (4포트)
#   sudo bash install-zed-link-driver.sh --card duo --force  # 기존 설치 덮어쓰기
# =============================================================================

set -euo pipefail
trap 'error "Step 실패. 이 스크립트를 다시 실행하면 실패 지점부터 재시도합니다."' ERR

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
CARD_TYPE=""
FORCE_REINSTALL=false
DRIVER_VERSION="1.4.1"

while [ $# -gt 0 ]; do
    case "$1" in
        --card)
            CARD_TYPE="$2"
            shift 2
            ;;
        --card=*)
            CARD_TYPE="${1#*=}"
            shift
            ;;
        --force) FORCE_REINSTALL=true; shift ;;
        --driver-version)
            DRIVER_VERSION="$2"
            shift 2
            ;;
        --driver-version=*)
            DRIVER_VERSION="${1#*=}"
            shift
            ;;
        --help|-h)
            echo "Usage: sudo bash $0 --card <mono|duo|quad> [OPTIONS]"
            echo ""
            echo "GMSL2 카메라(ZED X, ZED X Mini)용 ZED Link 드라이버 설치."
            echo "USB 카메라(ZED 2, ZED Mini)는 이 드라이버가 필요 없습니다."
            echo ""
            echo "Options:"
            echo "  --card TYPE          필수. mono(1포트), duo(2포트), quad(4포트)"
            echo "  --force              기존 설치 덮어쓰기"
            echo "  --driver-version VER 드라이버 버전 지정 (기본: $DRIVER_VERSION)"
            echo ""
            echo "카드 타입 확인:"
            echo "  Mono (SL-MAX9296)  — GMSL2 1포트"
            echo "  Duo  (LI-MAX96712) — GMSL2 2포트"
            echo "  Quad (SL-MAX96712) — GMSL2 4포트"
            echo ""
            echo "다운로드 페이지: https://www.stereolabs.com/developers/drivers"
            exit 0
            ;;
        *) die "알 수 없는 옵션: $1 (--help 참고)" ;;
    esac
done

# ---------------------------------------------------------------------------
# 카드 타입 검증
# ---------------------------------------------------------------------------
if [ -z "$CARD_TYPE" ]; then
    die "--card 옵션 필수. 사용법: sudo bash $0 --card <mono|duo|quad>
  카드 타입을 모르면 ZED Link 보드에 인쇄된 모델명을 확인하세요.
  Mono=1포트, Duo=2포트, Quad=4포트"
fi

case "$CARD_TYPE" in
    mono) DESER="SL-MAX9296" ;;
    duo)  DESER="LI-MAX96712" ;;
    quad) DESER="SL-MAX96712" ;;
    *)    die "지원하지 않는 카드 타입: $CARD_TYPE. mono, duo, quad 중 선택" ;;
esac

# ---------------------------------------------------------------------------
# 루트 권한 확인
# ---------------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    die "루트 권한 필요: sudo bash $0 --card $CARD_TYPE"
fi

# ---------------------------------------------------------------------------
# Step 1: 환경 확인
# ---------------------------------------------------------------------------
info "Step 1: 환경 확인"

ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    die "aarch64 전용 스크립트 (현재: $ARCH)"
fi

if [ ! -f /etc/nv_tegra_release ]; then
    die "/etc/nv_tegra_release 없음 — Jetson/L4T 환경이 아닙니다"
fi

# L4T 버전 파싱
L4T_RELEASE=$(sed -n 's/# R\([0-9]*\).*/\1/p' /etc/nv_tegra_release)
L4T_REVISION=$(sed -n 's/.*REVISION: \([0-9]*\.[0-9]*\).*/\1/p' /etc/nv_tegra_release)
L4T_MAJOR=$(echo "$L4T_REVISION" | cut -d. -f1)

info "  L4T: R${L4T_RELEASE}, REVISION: ${L4T_REVISION}"
info "  카드: ${CARD_TYPE} (${DESER})"

# L4T → URL 경로 매핑
case "${L4T_RELEASE}.${L4T_MAJOR}" in
    36.3) URL_L4T="R36.3"; DEB_L4T="L4T36.3.0" ;;
    36.4) URL_L4T="R36.4"; DEB_L4T="L4T36.4.0" ;;
    36.5) URL_L4T="R36.5"; DEB_L4T="L4T36.5.0" ;;
    *)    die "지원하지 않는 L4T 버전: R${L4T_RELEASE}.${L4T_REVISION}. 지원: 36.3, 36.4, 36.5" ;;
esac

# RT 커널 감지
RT_SUFFIX=""
if uname -v | grep -q "PREEMPT_RT"; then
    info "  PREEMPT_RT 커널 감지 → RT 변형 드라이버 선택"
    RT_SUFFIX="rt-"
else
    info "  표준 커널"
fi

info "  커널: $(uname -r)"

# 이미 설치 확인
PKG_NAME="stereolabs-zedlink-${CARD_TYPE}"
if dpkg -l "$PKG_NAME" 2>/dev/null | grep -q "^ii" && [ "$FORCE_REINSTALL" = false ]; then
    INSTALLED_VER=$(dpkg-query -W -f='${Version}' "$PKG_NAME" 2>/dev/null)
    warn "${PKG_NAME} 이미 설치됨 (${INSTALLED_VER})"
    warn "재설치하려면 --force 옵션 사용"
    if [ -t 0 ]; then
        read -rp "계속 진행하시겠습니까? (y/N): " CONTINUE
        if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
            info "설치 취소"
            exit 0
        fi
    else
        die "비대화형 환경에서 재설치하려면 --force 사용"
    fi
fi

# ---------------------------------------------------------------------------
# Step 2: 다운로드
# ---------------------------------------------------------------------------
info "Step 2: ZED Link 드라이버 다운로드"

DEB_FILE="stereolabs-zedlink-${CARD_TYPE}_${DRIVER_VERSION}-${DESER}-${RT_SUFFIX}${DEB_L4T}_arm64.deb"
DOWNLOAD_URL="https://download.stereolabs.com/drivers/zedx/${DRIVER_VERSION}/${URL_L4T}/${DEB_FILE}"
INSTALLER="/tmp/${DEB_FILE}"

info "  URL: ${DOWNLOAD_URL}"

HTTP_CODE=$(curl -L -I "${DOWNLOAD_URL}" -o /dev/null -s -w '%{http_code}\n' | head -n 1)
if [ "$HTTP_CODE" != "200" ]; then
    die "다운로드 URL 무효 (HTTP ${HTTP_CODE}): ${DOWNLOAD_URL}
  버전/L4T 조합을 확인하세요: https://www.stereolabs.com/developers/drivers"
fi

wget -q --show-progress -O "$INSTALLER" "$DOWNLOAD_URL"

if [ ! -f "$INSTALLER" ]; then
    die "다운로드 실패"
fi

FILE_SIZE=$(stat -c%s "$INSTALLER")
info "  다운로드 완료: $(( FILE_SIZE / 1024 ))KB"

# ---------------------------------------------------------------------------
# Step 3: 설치
# ---------------------------------------------------------------------------
info "Step 3: ZED Link 드라이버 설치"

# 기존 드라이버 제거 (force 시)
if [ "$FORCE_REINSTALL" = true ] && dpkg -l "$PKG_NAME" 2>/dev/null | grep -q "^ii"; then
    info "  기존 드라이버 제거 중..."
    dpkg -r "$PKG_NAME" || true
fi

dpkg -i "$INSTALLER"
apt-get install -f -y

rm -f "$INSTALLER"
info "  드라이버 설치 완료"

# ---------------------------------------------------------------------------
# Step 4: 설치 검증
# ---------------------------------------------------------------------------
info "Step 4: 설치 검증"

PASS=0
FAIL=0

check() {
    if eval "$1" > /dev/null 2>&1; then
        info "  [OK] $2"
        PASS=$((PASS + 1))
    else
        warn "  [PENDING] $2 (리부트 후 확인)"
        FAIL=$((FAIL + 1))
    fi
}

check "dpkg -l $PKG_NAME 2>/dev/null | grep -q '^ii'" "패키지 설치됨"
check "systemctl list-unit-files | grep -q zed_x_daemon" "zed_x_daemon 서비스 등록"
check "systemctl list-unit-files | grep -q driver_zed_loader" "driver_zed_loader 서비스 등록"

# 모듈 파일은 리부트 전에도 존재할 수 있음
MODULE_DIR="/usr/lib/modules/$(uname -r)/kernel/drivers/stereolabs"
if [ -d "$MODULE_DIR" ]; then
    check "[ -d $MODULE_DIR/zedx ]" "sl_zedx 모듈 파일"
    check "[ -d $MODULE_DIR/max96712 ]" "max96712 모듈 파일"
else
    warn "  [PENDING] 모듈 디렉토리 — 리부트 후 생성됨"
fi

# ---------------------------------------------------------------------------
# 결과 요약
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
info "ZED Link 드라이버 설치 완료"
echo ""
info "카드:     ${CARD_TYPE} (${DESER})"
info "커널:     $(uname -r) (${RT_SUFFIX:-standard})"
info "L4T:      R${L4T_RELEASE}.${L4T_REVISION}"
info "드라이버: v${DRIVER_VERSION}"
echo ""
warn "리부트가 필요합니다 (커널 모듈 로드 + DTB 적용)"
echo ""
info "  sudo reboot"
echo ""
info "리부트 후 확인:"
info "  lsmod | grep -E 'sl_zedx|max96712'"
info "  sudo systemctl status zed_x_daemon"
info "  ZED_Explorer -a   # State: AVAILABLE 확인"
echo "=========================================="
