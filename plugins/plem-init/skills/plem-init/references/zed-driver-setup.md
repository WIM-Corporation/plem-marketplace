# ZED Driver Setup

ZED SDK + GMSL2 드라이버 + zed-ros2-wrapper workspace 설치는 **wim_control 의 통합 `zed-setup` CLI** 로 일원화되었다.

```bash
# 대화형 (권장)
./packaging/zed-setup/zed-setup

# 또는 preset 기반 비대화형
./packaging/zed-setup/zed-setup install --preset=gmsl-zed-x-stereo --yes
```

## 범위 분리

| 단계 | 담당 |
|------|------|
| **시스템 환경** (ROS 2, SDK, Link 드라이버) | `packaging/zed-setup/` |
| **사용자 프로젝트 자산** (RViz 설정) | 본 skill 의 `scripts/zed/config/zedxm_display.rviz` 을 프로젝트로 복사 |
| **설치 후 개발 가이드** (QoS, subscribe, VisionInspection) | 본 skill 의 `references/zed-dev-quickstart.md` |

## 전체 문서

- **설치 + 호환성 매트릭스 + 커널 Gate + 트러블슈팅**: `packaging/zed-setup/README.md`
- **설치 후 개발 워크플로우**: `references/zed-dev-quickstart.md`
- **`doctor-kernel` 진단**: `./packaging/zed-setup/zed-setup doctor-kernel` (read-only)

## 레거시 트러블슈팅 (zed-setup 외 영역)

아래는 `zed-setup` 의 범위를 벗어나는 운영 상황별 복구 가이드다. `zed-setup doctor-kernel` 로 1차 진단 후 해당 증상이면 참조.

### Isaac ROS GXF 라이브러리 경로 미등록 (호스트 설치 시)

Isaac ROS 를 Docker 없이 호스트에 직접 설치한 경우, GXF 라이브러리들이 `/opt/ros/humble/share/*/gxf/lib/` 하위에 설치되지만 ldconfig 에 등록되지 않는다.

```bash
sudo bash -c 'find /opt/ros/humble/share -path "*/gxf/lib" -type d > /etc/ld.so.conf.d/isaac-ros-gxf.conf'
sudo ldconfig
```

### ZED X Daemon 서비스 파일 복구

ZED SDK 또는 ZED Link 설치 과정에서 `/etc/systemd/system/zed_x_daemon.service` 가 파일이 아닌 디렉토리로 잘못 생성되는 경우가 있다. `ZED_Explorer -a` 에서 카메라 State 가 `NOT AVAILABLE` 로 표시된다.

```bash
# 1. 손상 여부 확인
file /etc/systemd/system/zed_x_daemon.service
# "directory" 로 나오면 손상됨

# 2. 백업에서 복구 (설치 시 /tmp 에 백업이 남아있을 수 있음)
sudo rm -r /etc/systemd/system/zed_x_daemon.service
sudo cp /tmp/zed_x_daemon.service.bak /etc/systemd/system/zed_x_daemon.service

# 3. 재시작
sudo systemctl daemon-reload
sudo systemctl restart zed_x_daemon
ZED_Explorer -a     # "AVAILABLE" 확인
```

**참고**: 백업이 없으면 ZED SDK 재설치 (`zed-setup install --force-reinstall`).

### GMSL2 ISP daemon 재시작 절차

**증상**: ISP 설정 변경 후 카메라 출력이 이전 설정 유지.
**원인**: 단순 systemctl restart 로는 부족. 커널 모듈 reload 필요.

```bash
sudo systemctl restart nvargus-daemon.service
sudo rmmod sl_zedx
sudo rmmod max96712
sleep 1
sudo insmod /usr/lib/modules/$(uname -r)/kernel/drivers/stereolabs/max96712/max96712.ko
sudo insmod /usr/lib/modules/$(uname -r)/kernel/drivers/stereolabs/zedx/sl_zedx.ko
```

`rmmod` 실패 시 (`Module is in use`) → `sudo systemctl stop zed_x_daemon` 후 ZED 프로세스 모두 종료 뒤 재시도.

### 시스템 업데이트 후 blurry image (libnvisppg.so 복원)

**증상**: apt upgrade 등 시스템 업데이트 후 카메라 이미지가 흐릿해짐.
**원인**: 시스템 업데이트가 `libnvisppg.so` 를 덮어쓸 수 있음.
**해결**: ZED SDK `.deb` 에서 복원 (필요 시 stereolabs.com/developers/release 에서 재다운로드).

```bash
# 예: stereolabs-zedxm_5.2.1-max96712-l4t36.4_arm64.deb
ar x stereolabs-zed<model>_<ver>-<deser>-<l4t_version>_arm64.deb
tar xvf data.tar.xz
sudo cp ./tmp/R<l4t_version>/libnvisppg.so /usr/lib/aarch64-linux-gnu/tegra/libnvisppg.so
sudo reboot
```

### 하드웨어 변경 후 카메라 미인식

카메라 플러그/언플러그 또는 순서 변경 후 카메라가 인식되지 않음.
→ 위 **ISP daemon 재시작 절차** 참조 또는 리부트.

## 참고

- Stereolabs 공식: [Developer Releases](https://www.stereolabs.com/developers/release), [GMSL2 Drivers](https://www.stereolabs.com/developers/drivers), [ZED Link Cards](https://www.stereolabs.com/docs/embedded/zed-link)
- [Mono 카드로 ZED X 스테레오 사용 가능? (forum)](https://community.stereolabs.com/t/do-you-need-the-duo-capture-card-for-a-zed-x-mini-or-is-the-mono-sufficient/11013)
