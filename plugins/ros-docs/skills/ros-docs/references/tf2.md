---
description: "TF2 좌표 변환, 프레임 트리, broadcasting/listening, static vs dynamic, URDF/Xacro 종합 레퍼런스"
---

# TF2 & URDF

출처: https://docs.ros.org/en/humble/Concepts/Intermediate/About-Tf2.html,
https://docs.ros.org/en/humble/Tutorials/Intermediate/Tf2/

## TF2 개요

tf2는 **여러 좌표 프레임 간의 관계를 시간에 따라 추적**하는 라이브러리이다.
트리 구조로 프레임을 관리하며, 임의 두 프레임 간 변환을 임의 시점에서 조회할 수 있다.

분산 시스템에서 동작: 모든 ROS 2 노드가 네트워크를 통해 전체 TF 정보에 접근 가능.

## 핵심 개념

### Transform 의미론

`geometry_msgs/msg/Transform`로 발행되는 transform은 **프레임 자체의 변환**이다.
데이터 변환이 아니다. 이 둘은 수학적으로 역관계이다.

> transform을 publish하면 "child_frame은 parent_frame 기준으로 이 위치에 있다"는 의미.
> 데이터를 child_frame에서 parent_frame으로 변환하려면 이 transform의 **역행렬**을 적용한다.

### Static vs Dynamic Transform

| 구분 | Static | Dynamic |
|------|--------|---------|
| 변경 여부 | 불변 (한 번 발행) | 시간에 따라 변경 |
| 히스토리 | 저장 안 함 | 시간 버퍼 유지 |
| 성능 | 저장/조회/발행 오버헤드 최소 | 일반적 |
| 용도 | 카메라 마운트, 센서 고정 위치 | 로봇 관절, 이동체 |

### Broadcasting (발행)

```python
# Static broadcaster
from tf2_ros import StaticTransformBroadcaster
static_br = StaticTransformBroadcaster(node)
t = TransformStamped()
t.header.stamp = node.get_clock().now().to_msg()
t.header.frame_id = 'parent_frame'
t.child_frame_id = 'child_frame'
t.transform.translation.x = 1.0
# ... rotation ...
static_br.sendTransform(t)
```

```python
# Dynamic broadcaster
from tf2_ros import TransformBroadcaster
br = TransformBroadcaster(node)
# 타이머 콜백에서 주기적으로 sendTransform()
```

### Listening (조회)

```python
from tf2_ros import Buffer, TransformListener

tf_buffer = Buffer()
tf_listener = TransformListener(tf_buffer, node)

# 특정 시점의 transform 조회
try:
    t = tf_buffer.lookup_transform('target_frame', 'source_frame',
                                    rclpy.time.Time())
except (LookupException, ConnectivityException, ExtrapolationException):
    node.get_logger().warn('Transform not available')
```

### CLI 도구

```bash
# TF 트리 시각화
ros2 run tf2_tools view_frames       # frames.pdf 생성

# 두 프레임 간 transform 실시간 확인
ros2 run tf2_ros tf2_echo target_frame source_frame

# 특정 프레임의 부모/자식 관계
ros2 run tf2_ros tf2_monitor
```

### 디버깅 주의사항

발행된 transform은 **프레임 변환**이므로, lookup으로 얻는 값과 방향이 반대일 수 있다.
"Keep this in mind when debugging published transforms they are the inverse of what you will lookup depending on what direction you're traversing the transform tree."

## 흔한 문제

### 같은 프레임에 두 부모

TF는 **트리** 구조이므로 하나의 프레임에 부모가 둘이면 안 된다.
예: URDF의 `robot_state_publisher`와 카메라 드라이버가 같은 프레임에 TF를 발행하면 충돌.

**해결**: 한쪽을 비활성화. 로봇 통합 시 보통 드라이버의 TF 발행을 끈다.

### "No transform" 에러

1. broadcaster가 실행 중인지 확인
2. `ros2 run tf2_tools view_frames`로 트리 확인
3. 프레임 이름 정확히 일치하는지 확인 (대소문자 구분)
4. 시간 동기화 문제 확인

---

## URDF (Unified Robot Description Format)

URDF는 로봇의 기하학과 구조를 XML로 정의하는 형식이다.

### 핵심 요소

**Link**: 로봇의 강체 부분
```xml
<link name="base_link">
  <visual>
    <geometry><box size="0.6 0.1 0.2"/></geometry>
    <material name="blue"><color rgba="0 0 0.8 1"/></material>
  </visual>
  <collision>
    <geometry><box size="0.6 0.1 0.2"/></geometry>
  </collision>
  <inertial>
    <mass value="10"/>
    <inertia ixx="1.0" ixy="0.0" ixz="0.0" iyy="1.0" iyz="0.0" izz="1.0"/>
  </inertial>
</link>
```

**Joint**: 두 link를 연결
```xml
<joint name="joint1" type="revolute">
  <parent link="base_link"/>
  <child link="child_link"/>
  <origin xyz="0 0 0.5" rpy="0 0 0"/>
  <axis xyz="0 0 1"/>
  <limit lower="-3.14" upper="3.14" effort="100" velocity="1.0"/>
</joint>
```

### Joint 타입

| 타입 | 설명 |
|------|------|
| `revolute` | 회전 (각도 제한 있음) |
| `continuous` | 회전 (무제한) |
| `prismatic` | 직선 이동 |
| `fixed` | 고정 (움직이지 않음) |
| `floating` | 6자유도 |
| `planar` | 평면 이동 |

### Xacro

URDF의 매크로 확장. 반복 줄이고, 파라미터화 가능.

```xml
<xacro:macro name="leg" params="prefix reflect">
  <link name="${prefix}_leg">
    <visual>
      <geometry><box size="0.6 0.1 0.2"/></geometry>
      <origin xyz="0 0 ${reflect*0.3}"/>
    </visual>
  </link>
</xacro:macro>

<xacro:leg prefix="right" reflect="1" />
<xacro:leg prefix="left" reflect="-1" />
```

### robot_state_publisher

URDF + joint_states → TF 발행

```python
# launch 파일에서
Node(
    package='robot_state_publisher',
    executable='robot_state_publisher',
    parameters=[{'robot_description': robot_description_content}]
)
```

`/joint_states` 토픽을 구독하여 movable joint의 TF를 발행한다.
fixed joint는 static TF로 한 번만 발행한다.
