---
description: "ROS 2 QoS (Quality of Service) — 정책, 프로파일, 호환성 테이블, 이벤트, Silent Failure 원인과 해결"
---

# Quality of Service (QoS)

출처: https://docs.ros.org/en/humble/Concepts/Intermediate/About-Quality-of-Service-Settings.html

## 개요

ROS 2는 DDS 기반으로 QoS 정책을 통해 통신 신뢰도를 세밀하게 조절한다.
ROS 1이 TCP 중심이었던 것과 달리, ROS 2는 TCP-like(Reliable)부터 UDP-like(Best Effort)까지 선택 가능하다.

## QoS 정책 8가지

### History
- **Keep Last**: 최근 N개 샘플만 저장 (depth로 N 지정)
- **Keep All**: 미들웨어 리소스 한도 내 모든 샘플 저장

### Depth
- Keep Last의 큐 크기. Keep All에서는 무시됨

### Reliability
- **Best Effort**: 전송 시도하되 손실 허용
- **Reliable**: 재전송으로 전달 보장

### Durability
- **Volatile**: 늦게 참여한 구독자에게 과거 데이터 미전달
- **Transient Local**: 늦게 참여한 구독자에게 과거 데이터 전달

### Deadline
- 메시지 간 최대 허용 시간

### Lifespan
- 메시지 유효 기간 (초과 시 폐기)

### Liveliness
- **Automatic**: 프로세스 내 아무 publisher가 alive면 OK
- **Manual by Topic**: publisher가 명시적으로 alive 선언 필요

### Lease Duration
- publisher가 alive임을 알려야 하는 최대 시간

## 기본 프로파일

| 프로파일 | History | Depth | Reliability | Durability |
|----------|---------|-------|-------------|------------|
| **Default** | Keep Last | 10 | Reliable | Volatile |
| **Sensor Data** | Keep Last | 5 | Best Effort | Volatile |
| **Services** | Keep Last | 10 | Reliable | Volatile |
| **Parameters** | Keep Last | 1000 | Reliable | Volatile |
| **System Default** | RMW 구현체 기본값 | | | |

## 호환성 — 핵심 규칙

**모든 정책이 호환되어야** 연결이 수립된다. 하나라도 불일치하면 Silent Failure.

### Reliability 호환

| Publisher | Subscriber | 호환 |
|-----------|------------|------|
| Best Effort | Best Effort | O |
| Best Effort | Reliable | **X — 연결 불가** |
| Reliable | Best Effort | O (데이터 손실 가능) |
| Reliable | Reliable | O |

### Durability 호환

| Publisher | Subscriber | 호환 |
|-----------|------------|------|
| Volatile | Volatile | O |
| Volatile | Transient Local | **X — 연결 불가** |
| Transient Local | Volatile | O (과거 데이터 미전달) |
| Transient Local | Transient Local | O (과거+신규 데이터 모두) |

> "Latched" 토픽 구현: Publisher와 Subscriber 모두 Transient Local 사용

### Deadline / Lease Duration 호환

| Publisher | Subscriber | 호환 |
|-----------|------------|------|
| Default | Default | O |
| Default | x | X |
| x | Default | O |
| x | y (y > x) | O |
| x | y (y < x) | X |

### Liveliness 호환

| Publisher | Subscriber | 호환 |
|-----------|------------|------|
| Automatic | Automatic | O |
| Automatic | Manual by Topic | X |
| Manual by Topic | Automatic | O |
| Manual by Topic | Manual by Topic | O |

## QoS 이벤트

### Publisher 이벤트
- Offered Deadline Missed: deadline 내 메시지 미발행
- Liveliness Lost: lease duration 내 alive 미선언
- Offered Incompatible QoS: 호환되지 않는 subscriber 발견

### Subscriber 이벤트
- Requested Deadline Missed: deadline 내 메시지 미수신
- Liveliness Changed: publisher liveliness 상태 변경
- Requested Incompatible QoS: 호환되지 않는 publisher 발견

## 실전 가이드

### 이미지/포인트클라우드 구독 시

```python
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy

qos = QoSProfile(
    reliability=ReliabilityPolicy.BEST_EFFORT,
    history=HistoryPolicy.KEEP_LAST,
    depth=1
)
sub = node.create_subscription(Image, '/camera/image', callback, qos)
```

센서 데이터는 최신 프레임이 중요하므로 Best Effort + depth=1이 적합하다.

### 토픽 데이터가 안 올 때 체크리스트

1. `ros2 topic info -v /topic_name` → QoS 프로파일 확인
2. Publisher와 Subscriber의 Reliability, Durability 호환 확인
3. `ROS_DOMAIN_ID` 일치 확인
4. 네트워크 멀티캐스트 허용 확인

> **`ros2 topic echo`는 되는데 코드에서 안 될 때**: `ros2 topic echo`는 내부적으로 Publisher의 QoS에 자동 매칭된다.
> 하지만 사용자 코드의 기본 QoS는 Default 프로파일(Reliable, Volatile)이므로,
> Publisher가 Best Effort이면 연결 자체가 안 된다. `ros2 topic info -v`로 확인 후 코드의 QoS를 맞춘다.
