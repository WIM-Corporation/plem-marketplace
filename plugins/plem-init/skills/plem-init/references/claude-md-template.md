# CLAUDE.md Template

Used when generating CLAUDE.md in Step 6.
Replace `{...}` placeholders with the collected parameter values.
Conditional sections are included only when the corresponding feature is selected.

---

```markdown
# {project_name} — plem project

## Project Configuration

| Setting | Value |
|---------|-------|
| Project | `{project_name}` |
| Robot | {robot_vendor} {robot_model} |
| Gripper | {gripper_display} |
| Camera | {camera_display} |
| Namespace | /{robot_id}/ |

## Package Structure

```
src/
  {project_name}/         # User package (upper-layer control logic)
  plem-msgs/              # Standard interfaces (do not modify)
  plem-neuromeka/         # Neuromeka driver + launch (do not modify)
  # plem-onrobot/         # (gripper selected only)
  # plem-stereolabs/      # (camera selected only)
```

## Build / Run

```bash
colcon build
source install/setup.bash

# Launch lower control process
ros2 launch neuromeka_robot_driver plem_launch.py \
  robot_type:={robot_model} robot_id:={robot_id} \
  gripper:={gripper} camera:={camera}

# Simulation (no real hardware)
ros2 launch neuromeka_robot_driver plem_launch.py \
  robot_type:={robot_model} robot_id:={robot_id} \
  use_fake_hardware:=true
```

## Key Interfaces

| Interface | Type | Topic/Action Path | Provider |
|-----------|------|-------------------|----------|
| FollowJointTrajectory | action | `/{robot_id}/joint_trajectory_controller/follow_joint_trajectory` | plem |
| SetMode | action | `/{robot_id}/plem/set_mode` | plem |
| JointState | topic | `/{robot_id}/joint_states` | plem |
| RobotMode | topic | `/{robot_id}/status_broadcaster/robot_mode` | plem |
| SafetyMode | topic | `/{robot_id}/status_broadcaster/safety_mode` | plem |
GRIPPER_ROW
CAMERA_VISION_ROW

> plem 인터페이스는 `/{robot_id}/plem/` 네임스페이스 아래에 위치한다.

User code calls these interfaces to control the robot. Do not call plem internals directly.

MOVEIT_SECTION

CAMERA_SECTION

## Rules

Rules in `.claude/rules/` are automatically applied during development.
These are vendor-validated guidelines — do not modify directly. Update by re-running `/plem-init` or copying from `src/` packages.

REFERENCES_SECTION
```

---

## Conditional Sections

### GRIPPER_ROW (gripper != none)

Replace `GRIPPER_ROW` with:
```
| GripperCommand | action | `/{robot_id}/onrobot_driver/gripper_command` | plem |
| GripperStatus | topic | `/{robot_id}/gripper_status` | plem |
```

If gripper == none, remove the `GRIPPER_ROW` line entirely.

### CAMERA_VISION_ROW (camera != none)

Replace `CAMERA_VISION_ROW` with:
```
| VisionInspection | action | `/{robot_id}/plem/vision_inspect` | **developer implements** |
```

If camera == none, remove the `CAMERA_VISION_ROW` line entirely.

### MOVEIT_SECTION (MoveIt selected)

Replace `MOVEIT_SECTION` with:
```markdown
## MoveIt (upper-layer trajectory planning)

MoveIt is the user's responsibility. `{project_name}_moveit_config` is your project's MoveIt configuration — customize planner, SRDF, kinematics as needed.

```bash
# Launch MoveIt (wait 4+ seconds after lower control process)
ros2 launch {project_name}_moveit_config move_group.launch.py \
  robot_type:={robot_model} robot_id:={robot_id}
```
```

If MoveIt was NOT selected, remove the `MOVEIT_SECTION` line entirely.

### CAMERA_SECTION (camera != none)

Replace `CAMERA_SECTION` with:
```markdown
## Camera

`camera:={camera}` adds TF frames to the URDF for collision avoidance.
Camera image streaming requires a separate driver (e.g., zed-ros2-wrapper for Stereolabs).

### VisionInspection (developer-implemented)

plem은 `plem_msgs/action/VisionInspection` 인터페이스만 정의한다. 비전 처리 노드(액션 서버)는 개발자가 구현한다.
인터페이스 확인: `ros2 interface show plem_msgs/action/VisionInspection`
```

If camera == none, remove the `CAMERA_SECTION` line entirely.

### REFERENCES_SECTION (camera != none)

Replace `REFERENCES_SECTION` with:
```markdown
## ZED Camera References

ZED 카메라 관련 상세 레퍼런스는 `/zed-sdk` 스킬이 자동 제공한다.
ZED 관련 질문 시 스킬이 자동 트리거되어 QoS, 토픽명, TF, DDS 튜닝, YOLO 통합 등을 안내한다.

주요 레퍼런스 토픽:
- **API**: 토픽/서비스/파라미터 전체 목록 (`/zed-sdk api`)
- **DDS 튜닝**: 대용량 토픽 수신 필수 설정 (`/zed-sdk dds`)
- **YOLO 통합**: 3D Object Detection (`/zed-sdk yolo`)
- **TF/마운트**: Manipulator TF 정합, Hand-Eye 캘리브레이션 (`/zed-sdk tf`)
- **성능 최적화**: Frequency, ROI, 해상도 조절 (`/zed-sdk optimization`)
```

If camera == none, remove the `REFERENCES_SECTION` line entirely.
