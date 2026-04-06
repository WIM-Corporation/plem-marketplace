---
description: "DDS 네트워크 튜닝 — Cyclone DDS, Fast DDS, RTI Connext, 커널 버퍼, 대용량 메시지, WiFi 환경"
---

# DDS Tuning

출처: https://docs.ros.org/en/humble/How-To-Guides/DDS-tuning.html

> "Tuning parameters can come at a cost to resources, and may affect parts of your system beyond the scope of the desired improvements."

## 공통 (모든 DDS 구현체)

### WiFi 환경에서 IP Fragment 손실

UDP 패킷의 IP fragment가 손실되면 커널이 30초간 재조립을 시도하며 버퍼가 차서 연결이 끊긴다.

**해결 1: Best Effort QoS 사용**
acknowledgement와 재전송이 없어 네트워크 오버헤드 감소.

**해결 2: ipfrag_time 축소**
```bash
sudo sysctl net.ipv4.ipfrag_time=3    # 기본 30초 → 3초
```

**해결 3: ipfrag_high_thresh 증가**
```bash
sudo sysctl net.ipv4.ipfrag_high_thresh=134217728   # 128MB
```

### 대용량 가변 배열 직렬화 문제

복잡한 타입의 대용량 가변 배열은 직렬화 오버헤드가 크다.

**해결**: 메시지 구조 변경 (PointCloud2 패턴)
```
# 나쁜 예
Foo[] my_large_array

# 좋은 예 (PointCloud2 패턴)
uint64[] foo_1_array
uint32[] foo_2_array
```

## Cyclone DDS

### 대용량 메시지 전송 실패

Reliable QoS에서도 대용량 메시지가 유실된다.

**해결**:

1. 커널 수신 버퍼 최대값 증가:
```bash
sudo sysctl -w net.core.rmem_max=2147483647
```

영구 적용 (`/etc/sysctl.d/10-cyclone-max.conf`):
```
net.core.rmem_max=2147483647
```

2. Cyclone DDS 설정 파일:
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<CycloneDDS xmlns="https://cdds.io/config"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="https://cdds.io/config
    https://raw.githubusercontent.com/eclipse-cyclonedds/cyclonedds/master/etc/cyclonedds.xsd">
    <Domain id="any">
        <Internal>
            <SocketReceiveBufferSize min="10MB"/>
        </Internal>
    </Domain>
</CycloneDDS>
```

3. 환경 변수:
```bash
export CYCLONEDDS_URI=file:///absolute/path/to/config.xml
```

## RTI Connext DDS

### 대용량 메시지 전송 실패

**해결**: 커널 버퍼 + Flow Controller

```bash
sudo sysctl -w net.core.rmem_max=4194304   # 4MB
```

테스트 결과 (1Gbps 이더넷):
- rmem_max=4MB: 평균 700ms (4MB 메시지)
- rmem_max=20MB: 평균 371ms
- Flow Controller만 (커널 미조정): 최대 12초, 드롭 없음

## RMW 구현체 선택

```bash
# 현재 RMW 확인
echo $RMW_IMPLEMENTATION

# 먼저 설치 (최초 1회)
sudo apt install ros-humble-rmw-cyclonedds-cpp

# 환경 변수 설정 (노드 실행 전)
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
```

ROS 2 Humble 기본 RMW: `rmw_fastrtps_cpp` (Fast DDS)

## 멀티캐스트 확인

```bash
# 터미널 1
ros2 multicast receive

# 터미널 2
ros2 multicast send
```

UFW 방화벽 허용:
```bash
sudo ufw allow in proto udp to 224.0.0.0/4
sudo ufw allow in proto udp from 224.0.0.0/4
```
