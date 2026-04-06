---
description: "ROS 2 핵심 개념 — Node, Topic, Service, Action, Parameter, Discovery 종합 레퍼런스"
---

# Core Concepts

출처: https://docs.ros.org/en/humble/Concepts/Basic/

## Node

노드는 ROS 2 그래프의 참여자이며, 하나의 논리적 기능을 담당한다.
노드는 같은 프로세스, 다른 프로세스, 다른 머신의 노드와 통신할 수 있다.

노드는 동시에 여러 역할을 가질 수 있다:
- Publisher + Subscriber
- Service Server + Service Client
- Action Server + Action Client
- Parameter provider

```bash
ros2 node list                    # 실행 중인 노드 목록
ros2 node info /node_name         # 노드 상세 정보
```

## Topic (Publish/Subscribe)

**연속 데이터 스트림** 용도. 센서 데이터, 로봇 상태 등.

- 다대다 통신 (0..N Publisher, 0..N Subscriber)
- 익명 통신: Subscriber는 Publisher를 몰라도 된다
- 강타입: 메시지 필드 타입이 엄격히 검증됨

```bash
ros2 topic list                   # 전체 토픽
ros2 topic info /topic            # pub/sub 수, 타입
ros2 topic echo /topic            # 실시간 데이터 확인
ros2 topic hz /topic              # 발행 주파수
ros2 topic info -v /topic         # QoS 정보 포함
```

## Service (Request/Response)

**짧은 원격 프로시저 호출** 용도. 조회, 계산 등.

- 1:1 요청/응답
- Service Server는 토픽당 **하나만** 존재해야 함 (복수 서버 시 undefined behavior)
- Service Client는 여러 개 가능
- **장시간 작업에 사용 금지** — 취소/preemption 불가

```bash
ros2 service list                 # 전체 서비스
ros2 service type /service        # 서비스 타입
ros2 service call /service type "{field: value}"   # 서비스 호출
```

## Action (Goal/Result/Feedback)

**장시간 작업** 용도. 네비게이션, 매니퓰레이션 등.

- Goal(요청) + Result(최종 결과) + Feedback(중간 진행)
- **preemption(취소) 가능** — 반드시 깨끗한 취소 구현 권장
- Action Server는 토픽당 하나, Client는 여러 개 가능
- 내부적으로 Topic + Service 조합으로 구현됨

```bash
ros2 action list                  # 전체 액션
ros2 action info /action          # 액션 상세
ros2 action send_goal /action type "{goal_field: value}"
```

## 통신 패턴 선택 가이드

```
연속 데이터 (센서, 상태)?        → Topic
짧은 요청/응답 (조회, 계산)?     → Service
장시간 + 피드백 + 취소 필요?     → Action
```

- Service에서 장시간 작업 → 클라이언트가 블로킹되어 시스템 정지 위험
- Action은 오버헤드가 있으므로 짧은 작업에는 Service가 적합

## Parameter

노드의 구성 값. 노드 수명에 종속된다 (노드 종료 시 소멸).

### 타입

`bool`, `int64`, `float64`, `string`, `byte[]`, `bool[]`, `int64[]`, `float64[]`, `string[]`

### 선언

기본적으로 노드는 **선언된 파라미터만 허용**한다 (타입 안전성).
`allow_undeclared_parameters=True`로 동적 파라미터 허용 가능.

### 자동 생성 서비스 (6개)

모든 노드에 자동 생성됨:
1. `describe_parameters`
2. `get_parameter_types`
3. `get_parameters`
4. `list_parameters`
5. `set_parameters` (개별 성공/실패)
6. `set_parameters_atomically` (전부 성공 또는 전부 실패)

### 설정 방법

```bash
# 명령줄
ros2 run my_pkg my_node --ros-args -p param_name:=value

# YAML 파일
ros2 run my_pkg my_node --ros-args --params-file params.yaml

# 런타임 변경
ros2 param set /node_name param_name value

# 목록 / 덤프
ros2 param list /node_name
ros2 param dump /node_name
```

### 파라미터 사용 예시 (Python)

```python
class MyNode(Node):
    def __init__(self):
        super().__init__('my_node')
        self.declare_parameter('my_param', 'default_value')
        self.timer = self.create_timer(1.0, self.timer_callback)

    def timer_callback(self):
        value = self.get_parameter('my_param').get_parameter_value().string_value
        self.get_logger().info(f'Param: {value}')
```

### 콜백

- **Set Parameter Callback**: 변경 전 검증 (거부 가능, 부작용 없어야 함)
- **Parameter Event Callback**: 변경 후 실행 (선언/변경/삭제 이벤트)

## Discovery

노드는 DDS를 통해 **자동으로** 서로를 발견한다.

1. 노드 시작 시 같은 `ROS_DOMAIN_ID`의 다른 노드에 자신을 알림
2. 주기적으로 재광고하여 새 노드도 발견
3. 노드 종료 시 오프라인 알림

QoS가 호환되어야 실제 연결이 수립된다.

### ROS_DOMAIN_ID

```bash
export ROS_DOMAIN_ID=42   # 같은 값의 노드끼리만 통신
```

- 기본값: 0
- 안전 범위: 0~101 (Linux), 0~166 (macOS/Windows)
- DDS UDP 포트 공식: `7400 + (250 × domain_id) + offset`
- 같은 머신에서 120+ 프로세스 시 포트 충돌 가능

### ROS_LOCALHOST_ONLY

```bash
export ROS_LOCALHOST_ONLY=1   # 같은 머신 내 통신만
```

교실, 실험실 등 여러 로봇이 같은 네트워크를 공유할 때 유용.

## Interfaces (메시지 타입)

출처: https://docs.ros.org/en/humble/Concepts/Basic/About-Interfaces.html

ROS 2는 강타입 시스템. `.msg`, `.srv`, `.action` 파일로 인터페이스를 정의한다.

### 기본 타입

| 타입 | C++ | Python |
|------|-----|--------|
| `bool` | bool | bool |
| `byte` | uint8_t | bytes |
| `float32/64` | float/double | float |
| `int8/16/32/64` | int8_t~int64_t | int |
| `uint8/16/32/64` | uint8_t~uint64_t | int |
| `string` | std::string | str |

### 배열

```
int32[] unbounded_array          # 무제한 배열
int32[5] fixed_array             # 고정 크기
int32[<=5] bounded_array         # 최대 크기 제한
string<=10 bounded_string        # 최대 길이 제한 문자열
```

### .msg 파일 형식

```
# 필드
float64 x
float64 y
geometry_msgs/Point center    # 다른 메시지 참조 가능

# 상수 (UPPERCASE, = 사용)
int32 MAX_SIZE=100
string LABEL="default"
```

### .srv 파일 형식 (--- 로 request/response 구분)

```
int64 a
int64 b
---
int64 sum
```

### .action 파일 형식 (--- 로 goal/result/feedback 구분)

```
int32 order
---
int32[] sequence
---
int32[] partial_sequence
```

### 커스텀 인터페이스 생성

1. **전용 패키지** 생성 (ament_cmake 필수):
```bash
ros2 pkg create --build-type ament_cmake tutorial_interfaces
mkdir tutorial_interfaces/msg tutorial_interfaces/srv
```

2. **CMakeLists.txt**:
```cmake
find_package(rosidl_default_generators REQUIRED)
rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/Num.msg"
  "srv/AddThreeInts.srv"
)
```

3. **package.xml**:
```xml
<buildtool_depend>rosidl_default_generators</buildtool_depend>
<exec_depend>rosidl_default_runtime</exec_depend>
<member_of_group>rosidl_interface_packages</member_of_group>
```

4. **사용**:
```cpp
// C++
#include "tutorial_interfaces/msg/num.hpp"
```
```python
# Python
from tutorial_interfaces.msg import Num
```

### CLI 도구

```bash
ros2 interface list                              # 전체 인터페이스
ros2 interface show std_msgs/msg/String          # 메시지 구조
ros2 interface show example_interfaces/srv/AddTwoInts  # 서비스 구조
```

## Client Libraries

### 최소 Publisher 예시 (Python)

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class MinimalPublisher(Node):
    def __init__(self):
        super().__init__('minimal_publisher')
        self.publisher_ = self.create_publisher(String, 'topic', 10)
        self.timer = self.create_timer(0.5, self.timer_callback)

    def timer_callback(self):
        msg = String()
        msg.data = 'Hello World'
        self.publisher_.publish(msg)

def main():
    rclpy.init()
    node = MinimalPublisher()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()
```

출처: https://docs.ros.org/en/humble/Concepts/Basic/About-Client-Libraries.html

| 라이브러리 | 언어 | 비고 |
|-----------|------|------|
| **rclcpp** | C++ | 공식, C++17 |
| **rclpy** | Python | 공식 |
| **rclc** | C | micro-ROS용 |
| rclrs | Rust | 커뮤니티 |
| rclnodejs | Node.js | 커뮤니티 |

모든 공식 라이브러리는 `rcl` (C 코어)을 기반으로 구현되어 동작이 일관적이다.
ROS 1과 달리 각 언어별로 처음부터 구현하지 않는다.
