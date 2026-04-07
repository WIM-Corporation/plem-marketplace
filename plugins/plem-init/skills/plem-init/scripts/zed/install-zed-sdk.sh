#!/bin/bash
# =============================================================================
# ZED SDK 자동 설치 스크립트 (Jetson Native)
#
# 대상: Jetson Orin 시리즈 (JetPack 6.x / L4T 36.x)
# 검증: nvcr.io/nvidia/l4t-jetpack:r36.4.0 컨테이너에서 전 단계 통과 확인
#
# 사용법:
#   sudo bash install-zed-sdk.sh              # 기본 설치 (AI 모듈 포함, Python 포함)
#   sudo bash install-zed-sdk.sh --no-python  # Python 바인딩 제외
#   sudo bash install-zed-sdk.sh --no-ai      # AI 모듈 제외 (디스크 절약)
#   sudo bash install-zed-sdk.sh --minimal    # AI + Python + Tools 모두 제외
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
# 인자 파싱
# ---------------------------------------------------------------------------
SKIP_PYTHON=false
SKIP_AI=false
SKIP_TOOLS=true  # tools는 기본적으로 제외 (ZED Explorer 등 GUI 도구)
FORCE_REINSTALL=false
SDK_VERSION="5.2"

while [ $# -gt 0 ]; do
    case "$1" in
        --no-python) SKIP_PYTHON=true; shift ;;
        --no-ai)     SKIP_AI=true; shift ;;
        --minimal)   SKIP_PYTHON=true; SKIP_AI=true; shift ;;
        --with-tools) SKIP_TOOLS=false; shift ;;
        --force)     FORCE_REINSTALL=true; shift ;;
        --sdk-version)
            SDK_VERSION="$2"
            shift 2
            ;;
        --sdk-version=*)
            SDK_VERSION="${1#*=}"
            shift
            ;;
        --help|-h)
            echo "Usage: sudo bash $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-python         Python 바인딩(pyzed) 제외"
            echo "  --no-ai             AI 모듈(Object Detection) 제외"
            echo "  --minimal           AI + Python + Tools 모두 제외"
            echo "  --with-tools        ZED Tools(Explorer, Diagnostic 등) 포함"
            echo "  --force             기존 설치 덮어쓰기"
            echo "  --sdk-version VER   ZED SDK 버전 지정 (기본: 5.2)"
            exit 0
            ;;
        *) die "알 수 없는 옵션: $1 (--help 참고)" ;;
    esac
done

# ---------------------------------------------------------------------------
# 루트 권한 확인
# ---------------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    die "루트 권한 필요: sudo bash $0"
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

# L4T → SDK URL 매핑
case "${L4T_RELEASE}.${L4T_MAJOR}" in
    36.3) SDK_L4T="l4t36.3" ;;
    36.4) SDK_L4T="l4t36.4" ;;
    36.5) SDK_L4T="l4t36.5" ;;
    *)    die "지원하지 않는 L4T 버전: R${L4T_RELEASE}.${L4T_REVISION}. 지원 버전: 36.3, 36.4, 36.5 (JetPack 6.x). JetPack 확인: sudo apt-cache show nvidia-jetpack | grep Version" ;;
esac

info "  SDK URL 경로: ${SDK_L4T}"

# CUDA 확인
if ! command -v nvcc &> /dev/null; then
    warn "nvcc 미발견 — CUDA가 PATH에 없을 수 있음"
    warn "JetPack SDK Manager로 플래싱한 환경이라면 정상"
fi

# Python 확인
PYTHON_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "none")
if [ "$PYTHON_VER" = "none" ]; then
    die "python3 미설치"
fi
info "  Python: ${PYTHON_VER}"

# RT 커널 감지
if uname -v | grep -q "PREEMPT_RT"; then
    warn "PREEMPT_RT 커널 감지"
    warn "ZED X (GMSL2) 카메라 사용 시 커널 모듈 호환성 확인 필요:"
    warn "  ls /usr/lib/modules/$(uname -r)/kernel/drivers/stereolabs/"
    warn "  GMSL2 모듈(sl_zedx.ko, max96712.ko)이 RT 커널에서 로드되지 않을 수 있음"
    warn "  USB 카메라(ZED 2, ZED Mini)는 RT 커널에서도 정상 동작"
fi

# 이미 설치 확인
if [ -f /usr/local/zed/lib/libsl_zed.so ] && [ "$FORCE_REINSTALL" = false ]; then
    warn "ZED SDK가 이미 설치되어 있음 (/usr/local/zed/)"
    warn "재설치하려면 --force 옵션을 사용하세요"
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
# Step 2: 시스템 패키지 설치
# ---------------------------------------------------------------------------
info "Step 2: 시스템 패키지 설치"

apt-get update -qq
apt-get install -y --no-install-recommends \
    zstd wget less cmake curl gnupg2 \
    build-essential \
    python3 python3-pip python3-dev python3-setuptools \
    libusb-1.0-0-dev \
    libgeographic-dev \
    zlib1g-dev

info "  시스템 패키지 설치 완료"

# ---------------------------------------------------------------------------
# Step 3: SDK 다운로드
# ---------------------------------------------------------------------------
info "Step 3: ZED SDK 다운로드"

ZED_SDK_URL="https://download.stereolabs.com/zedsdk/${SDK_VERSION}/${SDK_L4T}/jetsons"
INSTALLER="/tmp/ZED_SDK_Linux_JP.run"

info "  URL: ${ZED_SDK_URL}"

# URL 유효성 확인
HTTP_CODE=$(curl -L -I "${ZED_SDK_URL}" -o /dev/null -s -w '%{http_code}\n' | head -n 1)
if [ "$HTTP_CODE" != "200" ]; then
    die "SDK 다운로드 URL 무효 (HTTP ${HTTP_CODE}): ${ZED_SDK_URL}"
fi

wget -q --show-progress -O "$INSTALLER" "$ZED_SDK_URL"

if [ ! -f "$INSTALLER" ]; then
    die "SDK 다운로드 실패"
fi

FILE_SIZE=$(stat -c%s "$INSTALLER")
info "  다운로드 완료: $(( FILE_SIZE / 1024 / 1024 ))MB"

# ---------------------------------------------------------------------------
# Step 4: SDK 설치
# ---------------------------------------------------------------------------
info "Step 4: ZED SDK 설치"

chmod +x "$INSTALLER"

# silent 옵션 구성
SILENT_OPTS="silent"
$SKIP_TOOLS  && SILENT_OPTS="$SILENT_OPTS skip_tools"
$SKIP_AI     && SILENT_OPTS="$SILENT_OPTS skip_od_module"
$SKIP_PYTHON && SILENT_OPTS="$SILENT_OPTS skip_python"

info "  옵션: $SILENT_OPTS"

# -- 뒤에 공백 필수
"$INSTALLER" -- $SILENT_OPTS

rm -f "$INSTALLER"
info "  SDK 설치 완료"

# ---------------------------------------------------------------------------
# Step 5: 설치 검증
# ---------------------------------------------------------------------------
info "Step 5: 설치 검증"

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

check "[ -d /usr/local/zed ]"                    "설치 디렉토리 /usr/local/zed/"
check "[ -f /usr/local/zed/lib/libsl_zed.so ]"   "libsl_zed.so"
check "[ -f /usr/local/zed/get_python_api.py ]"  "get_python_api.py"

if [ "$SKIP_PYTHON" = false ]; then
    check "python3 -c 'import pyzed.sl'"         "pyzed import"
fi

# ---------------------------------------------------------------------------
# Step 6: ZED X 카메라 daemon 확인 (GMSL2)
# ---------------------------------------------------------------------------
if systemctl list-unit-files 2>/dev/null | grep -q zed_x_daemon; then
    info "Step 6: ZED X daemon 확인"
    if systemctl is-active --quiet zed_x_daemon; then
        info "  [OK] zed_x_daemon 실행 중"
    else
        warn "  zed_x_daemon 미실행 — ZED X(GMSL2) 카메라 사용 시 시작 필요:"
        warn "    sudo systemctl enable zed_x_daemon"
        warn "    sudo systemctl start zed_x_daemon"
    fi
fi

# ---------------------------------------------------------------------------
# 결과 요약
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
if [ "$FAIL" -eq 0 ]; then
    info "ZED SDK 설치 완료 ($PASS/$((PASS + FAIL)) 검증 통과)"
else
    error "ZED SDK 설치 완료 — $FAIL개 검증 실패"
fi
echo ""
info "설치 경로: /usr/local/zed/"
info "L4T: R${L4T_RELEASE}.${L4T_REVISION} (${SDK_L4T})"
if [ "$SKIP_PYTHON" = false ]; then
    info "pyzed: $(python3 -c 'import pyzed; print(pyzed.__version__)' 2>/dev/null || echo '확인 필요')"
fi
echo "=========================================="
