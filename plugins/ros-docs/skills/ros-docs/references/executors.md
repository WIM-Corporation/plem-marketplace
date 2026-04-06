---
description: "ROS 2 Executor, Callback Group — SingleThreaded, MultiThreaded, 데드락 방지, 병렬 실행 제어"
---

# Executors & Callback Groups

출처: https://docs.ros.org/en/humble/Concepts/Intermediate/About-Executors.html,
https://docs.ros.org/en/humble/How-To-Guides/Using-callback-groups.html

## Executor 개요

Executor는 OS 스레드를 사용하여 subscription, timer, service server, action server 등의 콜백을 실행한다.

```cpp
rclcpp::executors::SingleThreadedExecutor executor;
executor.add_node(node);
executor.spin();
```

메시지는 콜백 처리 시점까지 미들웨어에 남아있다 (QoS 설정 유지).

## Executor 종류

### SingleThreadedExecutor
- 콜백을 **순차** 처리
- `rclcpp::spin()`의 기본 동작
- component container의 기본 executor

### MultiThreadedExecutor
- 설정 가능한 수의 스레드로 **병렬** 콜백 처리
- 실제 병렬성은 callback group 설정에 따라 결정

```cpp
rclcpp::executors::MultiThreadedExecutor executor;
// 또는 스레드 수 지정
rclcpp::executors::MultiThreadedExecutor executor(
    rclcpp::ExecutorOptions(), 4);  // 4 threads
```

### StaticSingleThreadedExecutor
- 노드 구조를 **초기화 시 한 번만** 스캔
- 런타임 오버헤드 크게 감소
- **제약**: startup 이후 subscription/timer 추가 불가

## Callback Group

### 두 가지 타입

**MutuallyExclusiveCallbackGroup**: 그룹 내 콜백이 **절대 병렬 실행되지 않음**

**ReentrantCallbackGroup**: 그룹 내 콜백이 **자유롭게 병렬 실행** (같은 콜백의 다중 인스턴스 포함)

> "Callbacks belonging to different callback groups (of any type) can always be executed parallel to each other."
> 다른 그룹의 콜백은 항상 병렬 실행 가능.

### 생성 및 사용

**C++:**
```cpp
auto my_group = create_callback_group(
    rclcpp::CallbackGroupType::MutuallyExclusive);

rclcpp::SubscriptionOptions options;
options.callback_group = my_group;
auto sub = create_subscription<Int32>("/topic", 10, callback, options);
```

**Python:**
```python
from rclpy.callback_groups import MutuallyExclusiveCallbackGroup, ReentrantCallbackGroup

my_group = MutuallyExclusiveCallbackGroup()
self.sub = self.create_subscription(
    Int32, '/topic', self.callback,
    callback_group=my_group)
```

기본값: callback group 미지정 시 노드의 기본 그룹 사용 (MutuallyExclusive)

## 데드락 방지 — 핵심 규칙

**"Almost everything in ROS 2 is a callback!"** — synchronous call의 done-callback도 포함.

### 데드락 발생 조건

Timer 콜백 안에서 동기 서비스 호출 → 같은 MutuallyExclusive 그룹 → **데드락**

```python
# 데드락! timer와 client가 같은 그룹
self.timer = self.create_timer(1.0, self.timer_callback)  # 기본 그룹
self.client = self.create_client(AddTwoInts, 'add')       # 기본 그룹

def timer_callback(self):
    future = self.client.call_async(req)
    result = future.result()  # 여기서 블로킹 → 데드락
```

### 해결 방법

timer와 client를 **다른 callback group**에 배치:

```python
self.timer_group = MutuallyExclusiveCallbackGroup()
self.client_group = MutuallyExclusiveCallbackGroup()

self.timer = self.create_timer(1.0, self.timer_callback,
                                callback_group=self.timer_group)
self.client = self.create_client(AddTwoInts, 'add',
                                  callback_group=self.client_group)
```

유효한 조합:
1. 서로 다른 MutuallyExclusive 그룹
2. Reentrant 그룹에 둘 다
3. 하나는 지정, 하나는 기본(None)
4. 핵심: **timer와 client가 같은 MutuallyExclusive 그룹이면 안 됨**

## 실전 가이드

| 상황 | 권장 |
|------|------|
| 단일 스레드, 순차 처리 | SingleThreadedExecutor + 기본 그룹 |
| 센서 콜백 병렬 처리 | MultiThreadedExecutor + Reentrant 그룹 |
| 공유 리소스 보호 | 해당 콜백들을 같은 MutuallyExclusive 그룹 |
| 동기 서비스 호출 | 호출자와 client를 다른 그룹에 |
| 제어 루프 (자기 겹침 방지) | MutuallyExclusive 그룹 |
| 실시간 제어 | rclc Executor 또는 WaitSet 직접 사용 |

## Node Composition

여러 노드를 하나의 프로세스에서 실행하여 오버헤드 감소.

### Container 종류

| Container | Executor |
|-----------|----------|
| `component_container` | SingleThreadedExecutor |
| `component_container_mt` | MultiThreadedExecutor |
| `component_container_isolated` | 컴포넌트별 전용 executor |

`component_container_isolated`는 각 컴포넌트에 전용 `MultiThreadedExecutor`를 할당한다. 컴포넌트 간 콜백이 서로 간섭하지 않으므로, 한 컴포넌트의 무거운 콜백이 다른 컴포넌트를 블로킹하지 않는다. 실시간성이 중요하거나 컴포넌트 간 격리가 필요할 때 사용한다.

### 이점

- 프로세스 간 통신 제거 (intra-process communication)
- 직렬화 오버헤드 감소
- 메모리 공유 가능

### CLI로 동적 로드/언로드

```bash
# 등록된 컴포넌트 확인
ros2 component types

# 컨테이너 실행
ros2 run rclcpp_components component_container

# 컴포넌트 로드
ros2 component load /ComponentManager my_pkg my_pkg::MyNode

# 파라미터 전달
ros2 component load /ComponentManager my_pkg my_pkg::MyNode -p param:=value

# intra-process 활성화
ros2 component load /ComponentManager my_pkg my_pkg::MyNode -e use_intra_process_comms:=true

# 로드된 컴포넌트 확인
ros2 component list

# 언로드 (ID 기반)
ros2 component unload /ComponentManager 1 2
```

### Composable Node 작성 (C++)

출처: https://docs.ros.org/en/humble/Tutorials/Intermediate/Writing-a-Composable-Node.html

```cpp
// 1. NodeOptions를 받는 생성자
class MyNode : public rclcpp::Node {
public:
    MyNode(const rclcpp::NodeOptions & options)
        : Node("my_node", options) { /* ... */ }
};

// 2. main() 대신 등록 매크로
#include <rclcpp_components/register_node_macro.hpp>
RCLCPP_COMPONENTS_REGISTER_NODE(my_pkg::MyNode)
```

**CMakeLists.txt:**
```cmake
find_package(rclcpp_components REQUIRED)
add_library(my_node_component SHARED src/my_node.cpp)
ament_target_dependencies(my_node_component rclcpp rclcpp_components)
rclcpp_components_register_node(my_node_component
    PLUGIN "my_pkg::MyNode"
    EXECUTABLE my_node          # 독립 실행파일도 생성
)
```

### Launch에서 Composition

```python
from launch_ros.actions import ComposableNodeContainer
from launch_ros.descriptions import ComposableNode

ComposableNodeContainer(
    name='my_container',
    namespace='',
    package='rclcpp_components',
    executable='component_container',   # 또는 component_container_mt
    composable_node_descriptions=[
        ComposableNode(
            package='my_pkg',
            plugin='my_pkg::MyNode',
            name='my_node',
            extra_arguments=[{'use_intra_process_comms': True}],
        ),
    ],
)
```
