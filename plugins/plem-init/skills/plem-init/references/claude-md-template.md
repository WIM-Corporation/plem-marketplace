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
| Robot ID (namespace) | `{robot_id}` — 모든 ROS2 토픽/액션이 `/{robot_id}/...` 하위에 격리됨 |

## Package Structure

```
src/
  {project_name}/         # User package (upper-layer control logic)
  plem-msgs/              # Standard interfaces (do not modify)
  plem-neuromeka/         # Neuromeka driver + launch (do not modify)
  # plem-onrobot/         # (gripper selected only)
  # plem-stereolabs/      # (camera selected only)
```

## Build

```bash
source /opt/plem/setup.bash     # 빌드 전 필수 — plem 코어 라이브러리 경로 등록
colcon build --symlink-install
source install/setup.bash
```

## Quick Start

```bash
# ~/.bashrc에 1회 추가
export PLEM_WORKSPACE="<이 프로젝트의 절대 경로>"

# 실행
plem
```

`{absolute_project_path}` placeholder를 실제 프로젝트 경로로 치환한다. 예: `$HOME/workspace/{project_name}`

별도 source 명령이나 ros2 launch 인자를 외울 필요 없다.
TUI가 ROS2 환경 source와 launch 인자 구성을 자동으로 처리한다.

## Run

### plem TUI (권장)

`plem` TUI는 launch/stop/brake/freedrive/RViz/PlotJuggler를 키보드 단축키로 제어하는
터미널 앱이다. `/opt/plem/tui/`에 설치되어 있으면 사용할 수 있다.

```bash
plem                             # TUI 실행
plem-kill                        # 모든 plem 프로세스 강제 종료
```

TUI에서 robot 프로필 선택 → `s`(Start) → `r`(Brake release) → `f`(FreeDrive) 순으로 조작.
TUI가 launch 인자(robot_type, robot_id, gripper, camera)를 로봇 프로필에서 자동 구성하므로
사용자가 인자를 직접 지정할 필요 없다.

### 직접 Launch (고급 — TUI 없이 수동 실행)

launch 인자가 복잡하므로 일반적으로 TUI 사용을 권장한다. 디버깅이나 자동화 스크립트 등
특수한 경우에만 직접 실행한다.

```bash
source install/setup.bash        # 매 터미널마다 필수 (TUI는 자동 처리)

ros2 launch neuromeka_robot_driver plem_launch.py \
  robot_type:={robot_model} robot_id:={robot_id} \
  gripper_model:={gripper_model} camera_model:={camera_model}

# Simulation (no real hardware)
ros2 launch neuromeka_robot_driver plem_launch.py \
  robot_type:={robot_model} robot_id:={robot_id} \
  use_fake_hardware:=true
```

> `source install/setup.bash` 없이 실행하면 `package not found` 에러가 발생한다.

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

TRAJECTORY_SECTION

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

### TRAJECTORY_SECTION (always included)

Replace `TRAJECTORY_SECTION` with:
```markdown
## Trajectory Control (custom planner integration)

plem은 `FollowJointTrajectory` 액션으로 궤적을 수신하여 1kHz 실시간 루프에서 실행한다.
MoveIt 또는 자체 플래너로 궤적을 생성하여 이 인터페이스로 전송하면 된다.

**워크플로우:**
1. `SetMode → TRAJECTORY` (mode: 2) — 컨트롤러 활성화
2. `FollowJointTrajectory` 액션으로 궤적 전송
3. 작업 완료 시 `SetMode → BRAKED` (mode: 0)

| Interface | Path |
|-----------|------|
| SetMode | `/{robot_id}/plem/set_mode` |
| FollowJointTrajectory | `/{robot_id}/joint_trajectory_controller/follow_joint_trajectory` |
| JointState (모니터링) | `/{robot_id}/joint_states` |

Joint names: `joint0` ~ `joint5` (6-DOF), positions 단위는 **라디안**.

상세 가이드 (Python 예제 포함): `references/trajectory-control-guide.md` 참조.
```

This section is always included regardless of MoveIt selection. It documents the fundamental trajectory control interface that every plem project needs.

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

`camera_model:={camera_model}` adds TF frames to the URDF for collision avoidance.
Camera image streaming requires ZED SDK + (GMSL2 시) Link 드라이버 + zed-ros2-wrapper —
아직 설치되지 않았다면 wim_control 의 `./packaging/zed-setup/zed-setup` 으로 한 번에 설치.

개발 중 ZED 관련 질문(QoS, 토픽명, YOLO, TF 등)은 **`/zed-sdk`를 호출**하면 상세 레퍼런스를 제공한다.

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
