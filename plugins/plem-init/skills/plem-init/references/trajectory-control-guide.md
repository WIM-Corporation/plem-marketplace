# Trajectory Control Guide — Custom Planner Integration

plem은 하위 제어(궤적 수신 → 1kHz 실시간 실행)를 담당한다.
궤적 생성(상위 제어)은 사용자 프로젝트의 책임이다. MoveIt을 쓸 수도 있고, 자체 플래너를 쓸 수도 있다.

이 가이드는 **MoveIt 없이** 자체 플래너로 궤적을 생성하여 로봇을 제어하는 방법을 설명한다.

## Architecture

```
User project (custom planner)
  ① SetMode → TRAJECTORY           # 컨트롤러 활성화
  ② FollowJointTrajectory          # 궤적 전송
    → joint_trajectory_controller   # ros2_control (항상 존재)
      → neuromeka_robot_driver      # HW Interface
        → plem RT engine (1kHz)     # 실시간 보간 + 실행
          → EtherCAT → robot
```

핵심: `FollowJointTrajectory`는 ros2_control의 `joint_trajectory_controller`가 제공한다. MoveIt 활성화 여부와 무관하게 항상 존재한다.

## Step 1: SetMode → TRAJECTORY

로봇은 기본적으로 BRAKED 상태다. 궤적을 전송하려면 먼저 TRAJECTORY 모드로 전환해야 한다.

**RobotMode 값:**

| Mode | Value | 설명 |
|------|-------|------|
| BRAKED | 0 | 브레이크 ON, 서보 OFF |
| TRAJECTORY | 2 | 자율 궤적 실행 (joint_trajectory_controller 활성화) |
| FREEDRIVE | 3 | 수동 안내 (중력보상) |

**SetMode 액션:**
- 타입: `plem_msgs/action/SetMode`
- 경로: `/{robot_id}/plem/set_mode`

```python
from plem_msgs.action import SetMode
from plem_msgs.msg import RobotMode
from rclpy.action import ActionClient

# SetMode 클라이언트 생성
set_mode_client = ActionClient(node, SetMode, '/{robot_id}/plem/set_mode')
set_mode_client.wait_for_server()

# TRAJECTORY 모드로 전환
goal = SetMode.Goal()
goal.target_robot_mode = RobotMode(mode=RobotMode.TRAJECTORY)  # value: 2
future = set_mode_client.send_goal_async(goal)

# 결과 대기 (내부적으로 controller_manager가 joint_trajectory_controller를 활성화)
result = future.result().get_result_async()
```

SetMode는 내부적으로 `controller_manager/switch_controller`를 호출하여 `joint_trajectory_controller`를 활성화한다. 사용자가 직접 컨트롤러를 전환할 필요 없다.

## Step 2: Build Trajectory

`trajectory_msgs/msg/JointTrajectory` 메시지를 구성한다.

**Joint Names (Neuromeka 6-DOF):**
```python
joint_names = ["joint0", "joint1", "joint2", "joint3", "joint4", "joint5"]
```

**궤적 포인트 구성:**

```python
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint
from builtin_interfaces.msg import Duration

traj = JointTrajectory()
traj.joint_names = ["joint0", "joint1", "joint2", "joint3", "joint4", "joint5"]

# Waypoint 1: 시작 위치 → 목표 위치 (2초)
point1 = JointTrajectoryPoint()
point1.positions = [0.0, -0.3, 0.5, 0.0, 0.8, 0.0]  # 6개 조인트, 라디안
point1.velocities = [0.0] * 6
point1.accelerations = [0.0] * 6
point1.time_from_start = Duration(sec=2, nanosec=0)

# Waypoint 2: 목표 위치 → 복귀 (4초)
point2 = JointTrajectoryPoint()
point2.positions = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
point2.velocities = [0.0] * 6
point2.accelerations = [0.0] * 6
point2.time_from_start = Duration(sec=4, nanosec=0)

traj.points = [point1, point2]
```

**주의사항:**
- positions 단위는 **라디안** (degree가 아님)
- velocities/accelerations를 제공하면 보간 품질이 향상됨 (0으로 두면 cubic spline 적용)
- time_from_start는 궤적 시작 기준 누적 시간 (상대값 아님)
- joint_names 순서는 controllers.yaml의 joints 순서와 일치해야 함

## Step 3: Send via FollowJointTrajectory

**FJT 액션:**
- 타입: `control_msgs/action/FollowJointTrajectory`
- 경로: `/{robot_id}/joint_trajectory_controller/follow_joint_trajectory`

```python
from control_msgs.action import FollowJointTrajectory
from rclpy.action import ActionClient

# FJT 클라이언트 생성
fjt_client = ActionClient(
    node, FollowJointTrajectory,
    '/{robot_id}/joint_trajectory_controller/follow_joint_trajectory'
)
fjt_client.wait_for_server()

# 궤적 전송
goal = FollowJointTrajectory.Goal()
goal.trajectory = traj
# goal.goal_time_tolerance = Duration(sec=1, nanosec=0)  # 선택사항

future = fjt_client.send_goal_async(goal)
goal_handle = future.result()

# 실행 완료 대기
result = goal_handle.get_result_async().result()
if result.result.error_code == FollowJointTrajectory.Result.SUCCESSFUL:
    print("Trajectory completed successfully")
```

## Step 4: Return to BRAKED (작업 완료 시)

```python
goal = SetMode.Goal()
goal.target_robot_mode = RobotMode(mode=RobotMode.BRAKED)  # value: 0
set_mode_client.send_goal_async(goal)
```

## Complete Minimal Example

```python
#!/usr/bin/env python3
"""Custom planner → FollowJointTrajectory minimal example."""
import rclpy
from rclpy.node import Node
from rclpy.action import ActionClient
from plem_msgs.action import SetMode
from plem_msgs.msg import RobotMode
from control_msgs.action import FollowJointTrajectory
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint
from builtin_interfaces.msg import Duration
import math


class CustomTrajectoryNode(Node):
    JOINT_NAMES = ["joint0", "joint1", "joint2", "joint3", "joint4", "joint5"]

    def __init__(self, robot_id: str = "indy"):
        super().__init__("custom_trajectory_node")
        self._robot_id = robot_id

        self._set_mode = ActionClient(
            self, SetMode, f"/{robot_id}/plem/set_mode"
        )
        self._fjt = ActionClient(
            self, FollowJointTrajectory,
            f"/{robot_id}/joint_trajectory_controller/follow_joint_trajectory",
        )

    async def set_mode(self, mode: int) -> bool:
        self._set_mode.wait_for_server()
        goal = SetMode.Goal()
        goal.target_robot_mode = RobotMode(mode=mode)
        handle = await self._set_mode.send_goal_async(goal)
        result = await handle.get_result_async()
        return result.result.success

    async def send_trajectory(self, waypoints: list[dict]) -> int:
        """Send trajectory. waypoints: [{"positions": [...], "time": sec}, ...]"""
        self._fjt.wait_for_server()

        traj = JointTrajectory()
        traj.joint_names = self.JOINT_NAMES
        for wp in waypoints:
            pt = JointTrajectoryPoint()
            pt.positions = wp["positions"]
            pt.velocities = wp.get("velocities", [0.0] * 6)
            pt.accelerations = wp.get("accelerations", [0.0] * 6)
            sec = int(wp["time"])
            pt.time_from_start = Duration(sec=sec, nanosec=int((wp["time"] - sec) * 1e9))
            traj.points.append(pt)

        goal = FollowJointTrajectory.Goal()
        goal.trajectory = traj
        handle = await self._fjt.send_goal_async(goal)
        result = await handle.get_result_async()
        return result.result.error_code

    async def run(self):
        # 1. TRAJECTORY 모드 전환
        if not await self.set_mode(RobotMode.TRAJECTORY):
            self.get_logger().error("Failed to set TRAJECTORY mode")
            return

        # 2. 궤적 실행 (예시: joint1을 30도 이동 후 복귀)
        error_code = await self.send_trajectory([
            {"positions": [0.0, math.radians(30), 0.0, 0.0, 0.0, 0.0], "time": 3.0},
            {"positions": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], "time": 6.0},
        ])
        self.get_logger().info(f"Result: {error_code}")

        # 3. BRAKED 모드 복귀
        await self.set_mode(RobotMode.BRAKED)


def main():
    rclpy.init()
    node = CustomTrajectoryNode(robot_id="indy")
    rclpy.get_default_context().executor.spin_until_future_complete(node.run())
    node.destroy_node()
    rclpy.shutdown()
```

## External MoveIt Integration

별도 프로젝트에서 MoveIt을 실행하여 궤적을 생성하고, 위와 동일하게 `FollowJointTrajectory`로 전송할 수도 있다.

1. 외부 프로젝트에서 `move_group` 노드 실행 (MoveIt planner)
2. MoveIt이 생성한 궤적을 `FollowJointTrajectory`로 전송
3. plem의 `joint_trajectory_controller`가 수신 → 실시간 실행

이 경우 plem 측에서는 MoveIt 토글을 활성화할 필요가 없다. MoveIt은 순수 궤적 생성기 역할만 하고, 실행은 동일하게 ros2_control을 통해 이루어진다.

## Monitoring

궤적 실행 중 상태 모니터링:

| Topic | Type | 내용 |
|-------|------|------|
| `/{robot_id}/joint_states` | `sensor_msgs/msg/JointState` | 현재 관절 위치/속도/토크 |
| `/{robot_id}/status_broadcaster/robot_mode` | `plem_msgs/msg/RobotMode` | 현재 로봇 모드 |
| `/{robot_id}/joint_trajectory_controller/state` | `control_msgs/msg/JointTrajectoryControllerState` | 궤적 추적 상태 |

## Safety

- 궤적 전송 전 반드시 로봇 작업 공간이 안전한지 확인
- 비상 시 `SetMode → BRAKED` (value: 0) 전송으로 즉시 정지
- `allow_nonzero_velocity_at_trajectory_end: true`로 설정되어 있어 궤적 마지막 포인트에서 velocity가 0이 아니어도 에러가 발생하지 않음 — 하지만 안전을 위해 마지막 포인트의 velocity는 0으로 설정하는 것을 권장
