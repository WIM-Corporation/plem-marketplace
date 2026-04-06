---
description: "ROS 2 Launch 시스템 — Python/XML/YAML 형식, substitution, event handler, 대규모 프로젝트 관리"
---

# Launch System

출처: https://docs.ros.org/en/humble/How-To-Guides/Launch-file-different-formats.html,
https://docs.ros.org/en/humble/Concepts/Basic/About-Launch.html

## 개요

Launch 시스템은 여러 노드를 하나의 명령으로 실행하는 자동화 도구이다.

핵심 기능:
- 노드 실행 및 설정
- 파라미터 전달
- 프로세스 모니터링
- 컴포넌트 재사용 (include)

## 세 가지 형식

### Python (.launch.py)

가장 유연. Python 로직으로 조건부 설정, 동적 구성 가능.

```python
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, GroupAction, IncludeLaunchDescription
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node, PushRosNamespace
from launch_ros.substitutions import FindPackageShare

def generate_launch_description():
    return LaunchDescription([
        DeclareLaunchArgument('background_r', default_value='0'),

        Node(
            package='turtlesim',
            executable='turtlesim_node',
            name='sim',
            namespace='turtlesim1',
            parameters=[{
                'background_r': LaunchConfiguration('background_r'),
            }],
            remappings=[
                ('/input/pose', '/turtlesim1/turtle1/pose'),
            ],
            arguments=['--ros-args', '--log-level', 'info'],
        ),

        IncludeLaunchDescription(
            PathJoinSubstitution([
                FindPackageShare('demo_nodes_cpp'),
                'launch', 'topics', 'talker_listener.launch.py'
            ])
        ),

        GroupAction(actions=[
            PushRosNamespace('my_ns'),
            # ... 그룹 내 노드들
        ]),
    ])
```

### XML (.launch.xml)

ROS 1에서 온 사용자에게 친숙. 선언적 구조.

```xml
<launch>
  <arg name="background_r" default="0" />

  <node pkg="turtlesim" exec="turtlesim_node" name="sim" namespace="turtlesim1">
    <param name="background_r" value="$(var background_r)" />
    <remap from="/input/pose" to="/turtlesim1/turtle1/pose" />
  </node>

  <include file="$(find-pkg-share demo_nodes_cpp)/launch/topics/talker_listener.launch.py" />

  <group>
    <push_ros_namespace namespace="my_ns" />
  </group>
</launch>
```

### YAML (.launch.yaml)

간결한 구조.

```yaml
launch:
- arg:
    name: "background_r"
    default: "0"

- node:
    pkg: "turtlesim"
    exec: "turtlesim_node"
    name: "sim"
    namespace: "turtlesim1"
    param:
    - name: "background_r"
      value: "$(var background_r)"
```

## 형식 선택 가이드

"For most applications the choice of which ROS 2 launch format comes down to developer preference."

| 형식 | 장점 | 적합한 경우 |
|------|------|------------|
| **Python** | Python 라이브러리 활용, 저수준 launch API 접근 | 복잡한 조건부 로직 |
| **XML** | ROS 1 사용자에게 친숙, 간결 | 단순한 노드 실행 |
| **YAML** | 가장 간결 | 단순한 설정 |

## Substitution

모든 형식에서 사용 가능:

| Substitution | 용도 |
|-------------|------|
| `$(find-pkg-share pkg)` | 패키지의 share 디렉토리 경로 |
| `$(var name)` | launch argument 값 참조 |
| `$(env ENV_VAR)` | 환경 변수 |
| Python: `LaunchConfiguration('name')` | launch argument (Python) |
| Python: `FindPackageShare('pkg')` | 패키지 경로 (Python) |
| Python: `PathJoinSubstitution([...])` | 경로 조합 (Python) |
| `$(eval 'expr')` | Python 표현식 평가 (XML/YAML) |
| Python: `PythonExpression([...])` | Python 표현식 (Python) |
| Python: `EnvironmentVariable('VAR')` | 환경 변수 (Python) |

### Launch 인자 전달 (include 시)

**XML:**
```xml
<include file="$(find-pkg-share pkg)/launch/file.launch.py">
  <let name="arg_name" value="value" />
</include>
```

**Python:**
```python
IncludeLaunchDescription(
    PythonLaunchDescriptionSource([launch_file_path]),
    launch_arguments={'arg_name': 'value'}.items()
)
```

### 인자 확인

```bash
ros2 launch my_pkg my_launch.py --show-args
```

## Event Handlers

출처: https://docs.ros.org/en/humble/Tutorials/Intermediate/Launch/Using-Event-Handlers.html

프로세스 상태 변화에 반응하는 메커니즘:

```python
from launch.actions import RegisterEventHandler, LogInfo, TimerAction, EmitEvent
from launch.event_handlers import OnProcessStart, OnProcessExit, OnProcessIO, OnExecutionComplete, OnShutdown
from launch.events import Shutdown

# 프로세스 시작 시
RegisterEventHandler(OnProcessStart(
    target_action=node,
    on_start=[LogInfo(msg='Node started')]
))

# 프로세스 종료 시
RegisterEventHandler(OnProcessExit(
    target_action=node,
    on_exit=[EmitEvent(event=Shutdown(reason='Node exited'))]
))

# 실행 완료 시 (지연 실행 포함)
RegisterEventHandler(OnExecutionComplete(
    target_action=node,
    on_completion=[TimerAction(period=2.0, actions=[next_action])]
))

# stdout 캡처
RegisterEventHandler(OnProcessIO(
    target_action=node,
    on_stdout=lambda event: LogInfo(msg=event.text.decode().strip())
))
```

## 실행

```bash
# 패키지 내 launch 파일
ros2 launch <package_name> <launch_file>

# 인자 전달
ros2 launch <package_name> <launch_file> background_r:=255

# 직접 경로
ros2 launch path/to/launch_file.py
```

## 주요 패턴

### 파라미터 YAML 로드

```python
Node(
    package='my_pkg',
    executable='my_node',
    parameters=['/path/to/params.yaml']
)
```

### Composable Node (성능 최적화)

```python
from launch_ros.actions import ComposableNodeContainer, LoadComposableNodes
from launch_ros.descriptions import ComposableNode

container = ComposableNodeContainer(
    name='my_container',
    namespace='',
    package='rclcpp_components',
    executable='component_container',
    composable_node_descriptions=[
        ComposableNode(
            package='my_pkg',
            plugin='my_pkg::MyNode',
            name='my_node',
        ),
    ],
)
```

### 조건부 실행

```python
from launch.conditions import IfCondition
from launch.substitutions import LaunchConfiguration

Node(
    package='my_pkg',
    executable='my_node',
    condition=IfCondition(LaunchConfiguration('enable_debug')),
)
```
