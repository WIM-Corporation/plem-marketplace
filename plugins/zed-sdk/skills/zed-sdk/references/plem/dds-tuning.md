---
description: "plem 환경 DDS 튜닝 — CycloneDDS 강제, 커널 버퍼 권장값, DDS XML 설정, cross-DDS 크래시 방지, packaging/zed-setup 자동 설정"
source: "zed-docs/references/dds-network.md"
---

# ZED DDS 네트워크 튜닝

ZED 카메라의 대용량 메시지(이미지, 포인트 클라우드)를 안정적으로 전송하기 위한 DDS 미들웨어 및 Linux 커널 네트워크 설정.
**설정 누락 시 이미지/포인트 클라우드 토픽이 silently drop되거나 수신률이 급격히 저하된다.**

## 1. Cyclone DDS (필수 — Stereolabs 공식 권장)

ROS 2 Humble 기본 FastDDS는 ZED 대용량 메시지에서 직렬화 오류(`serdata.cpp: invalid data size`)가 발생한다.
**모든 ROS 2 프로세스가 동일 DDS를 사용해야 하며**, CycloneDDS로 통일한다.

```bash
sudo apt install ros-humble-rmw-cyclonedds-cpp
```

`~/.bashrc`에 추가 (모든 터미널에 적용):
```bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export CYCLONEDDS_URI=file://$HOME/.ros/cyclonedds.xml
```

> **주의**: launch, TUI, ZED 카메라 등 모든 ROS 2 노드가 같은 DDS를 써야 한다.
> 일부만 CycloneDDS로 바꾸면 cross-DDS 직렬화 충돌로 노드 크래시 발생.

## 2. Linux 커널 네트워크 버퍼

즉시 적용:
```bash
sudo sysctl -w net.ipv4.ipfrag_time=3
sudo sysctl -w net.ipv4.ipfrag_high_thresh=134217728   # 128MB
sudo sysctl -w net.core.rmem_max=2147483647            # 2GiB
```

영구 설정 — `/etc/sysctl.d/60-zed-dds-buffers.conf`:
```ini
net.ipv4.ipfrag_time = 3
net.ipv4.ipfrag_high_thresh = 134217728
net.core.rmem_max = 2147483647
```

> **참고**: `./packaging/zed-setup/zed-setup install` 이 이 파일을 자동 생성한다 (deps 단계). 수동 설정은 통합 CLI 를 사용하지 않을 때만 필요.

```bash
sudo sysctl --system
```

## 3. Cyclone DDS XML 설정

`~/.ros/cyclonedds.xml` 생성:
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<CycloneDDS xmlns="https://cdds.io/config"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="https://cdds.io/config
            https://raw.githubusercontent.com/eclipse-cyclonedds/cyclonedds/master/etc/cyclonedds.xsd">
  <Domain id="any">
    <General>
      <Interfaces>
        <NetworkInterface autodetermine="true" />
      </Interfaces>
      <AllowMulticast>default</AllowMulticast>
      <MaxMessageSize>65500B</MaxMessageSize>
    </General>
    <Internal>
      <SocketReceiveBufferSize min="10MB"/>
      <Watermarks>
        <WhcHigh>500kB</WhcHigh>
      </Watermarks>
    </Internal>
  </Domain>
</CycloneDDS>
```

`~/.bashrc`에 URI 설정 (1단계에서 이미 추가됨):
```bash
export CYCLONEDDS_URI=file://$HOME/.ros/cyclonedds.xml
```

## 4. ROS Domain ID

동일 네트워크의 모든 노드(Jetson, 개발 PC, Docker)는 같은 Domain ID 공유 필수:
```bash
export ROS_DOMAIN_ID=<0-101>
```

## 5. MTU / Jumbo Frames

NIC/스위치가 지원하는 경우에만:
```bash
# 즉시 적용
sudo ip link set dev eth0 mtu 9000

# 영구: /etc/netplan/<config>.yaml에 mtu: 9000 추가
sudo netplan apply
```

## 6. Compressed Topics — 대역폭 절감

### Image Transport

| 토픽 접미사 | 포맷 | 특성 |
|---|---|---|
| `compressed` | JPEG | 손실, 최저 대역폭 |
| `compressedDepth` | PNG | 무손실, depth 전용 |

### Point Cloud Transport

```bash
sudo apt install ros-humble-point-cloud-transport \
  ros-humble-point-cloud-transport-plugins \
  ros-humble-zlib-point-cloud-transport \
  ros-humble-zstd-point-cloud-transport \
  ros-humble-draco-point-cloud-transport
```

| 포맷 | 특성 |
|---|---|
| `draco` | 손실 압축, 최대 압축률 |
| `zlib` | 무손실 |
| `zstd` | 무손실, zlib보다 빠름 |

## 7. 데이터 크기 축소 (ZED 파라미터)

```yaml
general:
  pub_resolution: 'CUSTOM'
  pub_downscale_factor: 2.0    # HD1200 → 960x608
  pub_frame_rate: 15           # 이미지/depth Hz
depth:
  point_cloud_freq: 5          # 포인트 클라우드 Hz
```

## 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| 이미지/포인트 클라우드 미수신 | 커널 수신 버퍼 부족 | `rmem_max`, `ipfrag_high_thresh` 설정 |
| 토픽 보이나 데이터 끊김 | DDS 버퍼 부족 | `60-zed-dds-buffers.conf` 설정 확인 |
| `serdata.cpp: invalid data size` 크래시 | 노드간 DDS 불일치 | 모든 프로세스 `RMW_IMPLEMENTATION` 통일 확인 |
| 노드 서로 미발견 | `ROS_DOMAIN_ID` 불일치 | 모든 노드/컨테이너 ID 통일 |
| Docker에서 외부 노드 미발견 | 컨테이너 환경변수 미설정 | `-e ROS_DOMAIN_ID=<id>` 추가 |
| CPU/대역폭 포화 | 비압축 고해상도 | `pub_downscale_factor` + compressed transport |
| Jumbo Frame 후 패킷 손실 | 스위치 미지원 | MTU 1500 복원, DDS 버퍼로 대체 |
