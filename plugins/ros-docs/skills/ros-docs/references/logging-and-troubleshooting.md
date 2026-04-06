---
description: "ROS 2 로깅 시스템, 디버깅 도구, 설치/실행 트러블슈팅 종합 레퍼런스"
---

# Logging & Troubleshooting

출처: https://docs.ros.org/en/humble/Concepts/Intermediate/About-Logging.html,
https://docs.ros.org/en/humble/How-To-Guides/Installation-Troubleshooting.html

## 로깅 시스템

### 출력 대상 (기본 3곳)

1. **콘솔** (stdout/stderr)
2. **디스크** (`~/.ros/log/` 또는 `$ROS_LOG_DIR`)
3. **`/rosout` 토픽** (ROS 2 네트워크)

각각 노드별로 개별 비활성화 가능.

### 심각도 수준

`DEBUG` < `INFO` < `WARN` < `ERROR` < `FATAL`

로거 이름은 계층적: `abc.def`는 `abc`의 자식. 부모 로거 수준이 자식에 상속됨 (자식이 명시 설정하지 않은 경우).

### C++ 매크로

```cpp
RCLCPP_DEBUG(node->get_logger(), "Debug: %d", value);
RCLCPP_INFO(node->get_logger(), "Info message");
RCLCPP_WARN(node->get_logger(), "Warning");
RCLCPP_ERROR(node->get_logger(), "Error");
RCLCPP_FATAL(node->get_logger(), "Fatal");

// 변형
RCLCPP_INFO_ONCE(...)           // 최초 1회만
RCLCPP_INFO_THROTTLE(..., 1000) // 1초 간격
RCLCPP_INFO_EXPRESSION(..., condition)  // 조건부
RCLCPP_INFO_SKIPFIRST(...)      // 첫 번째 스킵

// Stream 스타일
RCLCPP_INFO_STREAM(node->get_logger(), "Value: " << value);
```

### Python

```python
self.get_logger().debug('Debug')
self.get_logger().info('Info')
self.get_logger().warning('Warning')
self.get_logger().error('Error')
self.get_logger().fatal('Fatal')

# 변형
self.get_logger().info('msg', throttle_duration_sec=1.0)
self.get_logger().info('msg', once=True)
self.get_logger().info('msg', skip_first=True)
```

### 환경 변수

| 변수 | 용도 | 기본값 |
|------|------|--------|
| `ROS_LOG_DIR` | 로그 디렉토리 | `$ROS_HOME/.log` |
| `ROS_HOME` | ROS 홈 | `~/.ros` |
| `RCUTILS_LOGGING_USE_STDOUT` | stdout 사용 (1) / stderr (0) | 0 |
| `RCUTILS_LOGGING_BUFFERED_STREAM` | 버퍼링 강제 | 자동 |
| `RCUTILS_COLORIZED_OUTPUT` | 컬러 출력 | 자동 |
| `RCUTILS_CONSOLE_OUTPUT_FORMAT` | 출력 포맷 | `[{severity}] [{time}] [{name}]: {message}` |

포맷 토큰: `{severity}`, `{name}`, `{message}`, `{function_name}`, `{file_name}`, `{time}`, `{time_as_nanoseconds}`, `{line_number}`

### 명령줄 설정

```bash
# 로그 수준 설정
ros2 run my_pkg my_node --ros-args --log-level debug
ros2 run my_pkg my_node --ros-args --log-level my_node:=debug

# 콘솔 출력 비활성화
ros2 run my_pkg my_node --ros-args --disable-stdout-logs

# /rosout 비활성화
ros2 run my_pkg my_node --ros-args --disable-rosout-logs

# 디스크 로깅 비활성화
ros2 run my_pkg my_node --ros-args --disable-external-lib-logs
```

---

## 트러블슈팅

### 멀티캐스트 실패

DDS 통신에 멀티캐스트가 필요. 확인:
```bash
ros2 multicast receive   # 터미널 1
ros2 multicast send      # 터미널 2
```

UFW 방화벽 허용:
```bash
sudo ufw allow in proto udp to 224.0.0.0/4
sudo ufw allow in proto udp from 224.0.0.0/4
```

### 같은 네트워크의 다른 ROS 2 인스턴스와 간섭

```bash
export ROS_DOMAIN_ID=42    # 기본 0과 다른 값
```

### 빌드 시 메모리 부족 (Raspberry Pi 등)

```bash
MAKEFLAGS=-j1 colcon build     # 단일 코어 빌드
```

`ros1_bridge`는 컴파일에 4GB RAM 필요 → `COLCON_IGNORE`로 스킵

### rclpy import 실패

원인: C extension이 다른 Python 인터프리터로 빌드됨 (OS 업데이트 후 흔함)
해결: 같은 Python 인터프리터로 워크스페이스 재빌드

### source 후 예외 발생

```bash
colcon version-check
sudo apt install python3-colcon* --only-upgrade
```

### Conda + apt 패키지 충돌

`PATH`에서 conda 경로 제거. `.bashrc`에서 conda init 주석 처리.

### RViz on WSL2 크래시

```bash
export LIBGL_ALWAYS_SOFTWARE=true
rviz2
```

### 디버깅 도구

```bash
# 노드/토픽/서비스 탐색
ros2 node list
ros2 topic list
ros2 service list
ros2 topic info -v /topic    # QoS 상세

# 토픽 실시간 확인
ros2 topic echo /topic
ros2 topic hz /topic
ros2 topic bw /topic          # 대역폭

# 파라미터 확인
ros2 param list /node
ros2 param get /node param
```

### ros2 doctor

시스템 전체를 진단하는 도구. 네트워크 설정, 미들웨어 상태, 토픽 통계, 플랫폼 정보를 검사한다.

```bash
ros2 doctor                   # 전체 진단 (WARNING/ERROR 출력)
ros2 doctor --report          # 상세 보고서 (네트워크, 미들웨어, 토픽별)
ros2 doctor --report -iw      # WARNING 포함 전체 리포트
```

주요 검사 항목: RMW 구현체 상태, 네트워크 인터페이스, QoS 호환성, 토픽 발행률 이상 등.
