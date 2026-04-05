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
./launch.sh

# Override arguments
./launch.sh use_fake_hardware:=true
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

## MoveIt (upper-layer trajectory planning)

MoveIt is the user's responsibility. `neuromeka_moveit_config` is a reference implementation — copy and customize.

```bash
# Launch MoveIt (wait 4+ seconds after lower control process)
ros2 launch neuromeka_moveit_config move_group.launch.py \
  robot_type:={robot_model} robot_id:={robot_id}
```

CAMERA_SECTION

## Rules

Rules in `.claude/rules/` are automatically applied during development.
These are vendor-validated guidelines — do not modify the symlinked files.

REFERENCES_SECTION
```

---

## Conditional Sections

### GRIPPER_ROW (gripper != none)

Replace `GRIPPER_ROW` with:
```
| GripperCommand | action | `/{robot_id}/gripper_action_server/gripper_command` | plem |
| GripperStatus | topic | `/{robot_id}/gripper_status` | plem |
```

If gripper == none, remove the `GRIPPER_ROW` line entirely.

### CAMERA_VISION_ROW (camera != none)

Replace `CAMERA_VISION_ROW` with:
```
| VisionInspection | action | `/{robot_id}/plem/vision_inspect` | **developer implements** |
```

If camera == none, remove the `CAMERA_VISION_ROW` line entirely.

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
## References

Detailed reference docs in `.claude/references/` — not auto-loaded, read when needed:

| Document | Content |
|----------|---------|
| `zed-ros2-api-reference.md` | 전체 토픽/서비스/파라미터 레퍼런스 |
| `zed-yolo-integration.md` | YOLO 3D detection 통합 가이드 |
| `zed-usage-guide.md` | RViz, SVO recording, OD 데모 |
| `zed-yolo-config.md` | YOLO ONNX config, class 정의 규칙 |
| `zed-dds-network.md` | DDS/커널/MTU 네트워크 튜닝 (대용량 토픽 필수) |
| `zed-optimization.md` | Frequency/latency/ROI 성능 최적화 |
| `zed-robot-integration.md` | Manipulator TF, multi-camera, streaming |
| `zed-recording.md` | SVO/rosbag 녹화·재생·벤치마크 |
```

If camera == none, remove the `REFERENCES_SECTION` line entirely.
