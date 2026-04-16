---
name: plem-init
description: "Use when starting a new plem-based robot project, setting up a ROS2 workspace for industrial robot control, or creating a project that uses plem platform for Neuromeka manipulators."
argument-hint: "[project-name]"
disable-model-invocation: true
---

# plem-init: Project Initialization Guide

Initialize a plem-based robot project from an empty ROS2 workspace.
The developer does not need to read docs directly — this skill guides the entire workflow.

**Language adaptation:** Present all user-facing text (questions, labels, descriptions, summaries) in the user's language. The examples below use English as a reference; adapt to the session language.

## Prerequisites

plem 코어 라이브러리가 `/opt/plem/`에 설치되어 있어야 한다. 설치 방법은 환경에 따라 다르다:

| 환경 | 설치 방법 |
|------|----------|
| Jetson (배포된 장비) | 사전 설치됨 — 별도 조치 불필요 |
| Jetson (신규) | `./packaging/plem-deploy remote <ip>` |
| 개발 장비 (WIM_CONTROL 있음) | `./packaging/plem-deploy install` |

설치 확인: `ls /opt/plem/setup.bash` — 파일이 없으면 설치가 필요하다.

plem-init은 `/opt/plem`이 준비된 상태에서 **사용자 프로젝트를 초기화**하는 스킬이다. plem 자체의 설치는 다루지 않는다.

## Core Principles

1. **Wizard-style** — One question at a time. Never dump all parameters in a single message.
2. **Vendor-defined rules** — Rules are not LLM-generated. Copy pre-validated rules from package repositories.
3. **Conditional installation** — Do not install rules/dependencies for unselected features (gripper, camera).
4. **Verification required** — Confirm `colcon build` succeeds before declaring initialization complete.

## Parameter Collection — AskUserQuestion Wizard

**Use the `AskUserQuestion` tool for clickable selection UI.** Skip parameters already provided via $ARGUMENTS or mentioned in conversation.
AskUserQuestion supports up to 4 questions per call — group related items efficiently.

### Round 1: Project Name

If not provided as argument, ask as plain text (free-form input, AskUserQuestion not needed):

> What is your project name? (lowercase + underscores, e.g. `my_pick_app`)

### Round 2: Robot + Peripherals

Read `references/peripheral-mapping.md` and present **3 questions in a single AskUserQuestion call**.

로봇 모델 선택 결과에서 vendor를 자동 유도한다 (peripheral-mapping.md의 Vendor 컬럼 참조).
현재는 모든 모델이 Neuromeka이므로 vendor는 항상 `neuromeka`가 되지만,
새 벤더 추가 시 이 매핑이 자동으로 확장된다. vendor를 별도 질문으로 묻지 않는다.

```
AskUserQuestion:
  questions:
    - question: "Which robot model?"
      header: "Robot"
      multiSelect: false
      options:
        - label: "indy7 (Recommended)"
          description: "Neuromeka Indy7 — 6-axis cobot, most common"
        - label: "indy7_v2"
          description: "Neuromeka Indy7 v2 — 6-axis, latest revision"
        - label: "indy12"
          description: "Neuromeka Indy12 — 6-axis, heavy payload (12kg)"
        - label: "indy12_v2"
          description: "Neuromeka Indy12 v2 — 6-axis heavy, latest revision"

    - question: "Use a gripper?"
      header: "Gripper"
      multiSelect: false
      options:
        - label: "None (Recommended)"
          description: "Start without gripper. Can be added later"
        - label: "rg6"
          description: "OnRobot RG6 — electric 2-finger gripper, auto-launched by plem"

    - question: "Use a camera?"
      header: "Camera"
      multiSelect: false
      options:
        - label: "None (Recommended)"
          description: "Start without camera. No URDF camera geometry"
        - label: "zedxm"
          description: "Stereolabs ZED X Mini — depth camera, adds TF frames to URDF (driver installed separately)"
```

**Vendor 유도 규칙**: 모델 선택 후 `peripheral-mapping.md`의 Robot Models 테이블에서
해당 모델의 Vendor 컬럼을 읽어 `robot_vendor` 값을 설정한다. 이 값은 이후 단계
(MoveIt, rules, .repos 생성)에서 벤더별 패키지명을 참조하는 데 사용된다.

### Round 3: Additional Setup

Ask conditional questions in a single AskUserQuestion call. Only include questions that apply.
MoveIt 설명에서 벤더 패키지명을 Round 2에서 유도한 `robot_vendor`에 맞게 동적으로 표시한다:

```
AskUserQuestion:
  questions:
    # Always include:
    - question: "Set up MoveIt for motion planning?"
      header: "MoveIt"
      multiSelect: false
      options:
        - label: "Yes (Recommended)"
          description: "Copy {robot_vendor}_moveit_config to your project as a starting point for trajectory planning"
        - label: "No"
          description: "Skip MoveIt setup. Can be added manually later"

```

If MoveIt is selected, Step 3 will copy `{robot_vendor}_moveit_config` to `src/{project_name}_moveit_config/`, rename the package, and include it in the build.

**`robot_id` 유도**: 로봇 모델의 패밀리 이름에서 자동 생성한다.

| 모델 | robot_id (기본값) |
|------|------------------|
| indy7, indy7_v2 | `indy` |
| indy12, indy12_v2 | `indy` |

robot_id는 ROS2 namespace로 사용된다 (`/{robot_id}/joint_states`, `/{robot_id}/controller_manager`).
단일 로봇 프로젝트에서는 기본값을 그대로 쓰면 된다. multi-robot 프로젝트에서는
사용자가 확인 단계에서 커스터마이징할 수 있다 (예: `indy1`, `indy2`).

확인 테이블에 robot_id를 포함하되, 용도를 함께 설명한다:

> | Robot ID | `indy` (ROS2 namespace — 토픽/액션 경로에 사용) |

`plem_install` (default: `apt`)은 묻지 않는다. plem 코어는 Jetson에 사전 설치되어 있다.

### Project Name Validation

Validate the name before proceeding:
- Must match `[a-z][a-z0-9_]*` (lowercase, underscores, start with letter)
- No hyphens (Python/ament_python package naming rule), no spaces, no uppercase
- If invalid, show the issue and suggest a corrected name (e.g. `My-Project` → `my_project`)

### Handling "Other" Selections

AskUserQuestion automatically adds an "Other" option. If the user selects "Other" for **gripper or camera**, ask them to specify the model name. Then check `references/peripheral-mapping.md` — if the model isn't listed, inform the user it's not yet supported and offer to proceed with "none" for that peripheral.

If the user selects "Other" for **robot**, inform that only Neuromeka models are currently supported and ask them to choose from the listed options or cancel initialization. Robot selection is required — there is no "none" option.

### Confirmation

Summarize collected parameters and ask for confirmation before proceeding.
Robot ID의 용도를 함께 설명하여 사용자가 커스터마이징 여부를 판단할 수 있게 한다:

> Initializing project with the following configuration:
>
> | Setting | Value |
> |---------|-------|
> | Project | `my_pick_app` |
> | Robot | Neuromeka Indy7 |
> | Gripper | rg6 (OnRobot) |
> | Camera | None |
> | MoveIt | Yes |
> | Robot ID | `indy` (ROS2 namespace — `/{robot_id}/joint_states` 등 토픽 경로에 사용. 변경하려면 알려주세요) |
>
> Proceed?

## Initialization Workflow (6 Steps)

### Step 1: Parameter Collection

Follow the Wizard Flow above. Read `references/peripheral-mapping.md` for supported models.

### Step 2: .repos Generation + Package Installation

Generate `.repos` based on collected parameters.

**Always included:**
- `plem-msgs` (standard interfaces)

**Conditional:**
- `plem` — only when `plem_install=source` (omit if apt)
- `plem-neuromeka` — when `robot_vendor=neuromeka`
- `plem-onrobot` — when gripper is OnRobot family (rg6, etc.)
- `plem-stereolabs` — when camera is Stereolabs family (zedxm, etc.)
- `zed-ros2-wrapper` + `zed-ros2-examples` — when camera is Stereolabs family **AND** ZED SDK가 설치됨 (`/usr/local/zed/` 존재)

ZED SDK 감지:
```bash
if [ -d /usr/local/zed ]; then
    # SDK 설치됨 → .repos에 zed-ros2-wrapper, zed-ros2-examples 포함
    # 같은 workspace에서 빌드되어 source install/setup.bash 하나로 사용 가능
fi
```

SDK 미설치 시 wrapper를 `.repos`에서 제외한다 (빌드 시 ZED SDK 헤더가 필요하므로 실패).
이 경우 `scripts/zed/` 스크립트로 SDK를 먼저 설치한 후, `.repos`에 수동 추가하거나
`setup-zed-ros2-workspace.sh`로 별도 workspace에 빌드할 수 있다.

Model-to-vendor-package mapping: see `references/peripheral-mapping.md`.

```bash
vcs import src < .repos
```

**If `vcs import` fails:**
- Authentication error → check SSH key or HTTPS credentials for GitHub
- Network error → verify internet connectivity, retry
- Repository not found → confirm repo URL in `references/peripheral-mapping.md` is current

### Step 3: User ROS2 Package Scaffolding + MoveIt Setup

ROS2 CLI(`ros2 pkg create`)는 `source /opt/ros/humble/setup.bash` 이후에만 사용 가능하다.
Step 3의 모든 bash 명령은 반드시 source chain을 포함해야 한다:

```bash
source /opt/ros/humble/setup.bash && source /opt/plem/setup.bash
cd src && ros2 pkg create --build-type ament_python {project_name} \
  --dependencies rclpy control_msgs plem_msgs trajectory_msgs
```

Add `neuromeka_msgs` if `robot_vendor=neuromeka`.

**If MoveIt was selected**, copy the vendor's reference implementation and rename.
vendor 패키지명은 `{robot_vendor}_moveit_config`로 유도한다.

리네이밍은 **한 번에 완결**해야 한다. 하나씩 발견하며 고치는 방식은 사용자에게 불안감을 준다.
다음 4가지를 빠짐없이 처리한다:

```bash
# 1. 디렉토리 복사
cp -r src/plem-{robot_vendor}/{robot_vendor}_moveit_config src/{project_name}_moveit_config

# 2. Python 패키지 디렉토리 rename (colcon/ament이 패키지명으로 디렉토리를 기대)
mv src/{project_name}_moveit_config/{robot_vendor}_moveit_config \
   src/{project_name}_moveit_config/{project_name}_moveit_config

# 3. package.xml: <name> 변경
# 4. CMakeLists.txt: project(), ament_python_install_package(), install(PROGRAMS ...) 경로 모두 변경
#    — {robot_vendor}_moveit_config → {project_name}_moveit_config 전역 치환
```

This gives the user a working MoveIt config they can customize (planner, SRDF, kinematics).

### Step 3.5: Camera Driver Setup (if camera selected)

If a Stereolabs camera was selected, guide the user through ZED SDK + ROS 2 wrapper installation.
Read `references/zed-driver-setup.md` for detailed instructions.

Copy bundled installation scripts to the user's project:

```bash
cp -r <skill-dir>/scripts/zed scripts/zed
```

Where `<skill-dir>` is the plem-init skill directory (the directory containing this SKILL.md).
The scripts are then available at `scripts/zed/` in the user's project:

**시스템 스크립트** (장비당 1회, sudo 필요):
- `install-ros2-zed-deps.sh` — ROS 2 + ZED ROS 2 dependencies (includes `zed_msgs`, `zed_description`)
- `install-zed-sdk.sh` — ZED SDK + Tools (auto-detects Jetson L4T version)
- `install-zed-link-driver.sh` — GMSL2 커널 모듈 + zed_x_daemon (ZED X/X Mini 전용, RT 커널 자동 감지)

**유저 스크립트** (프로젝트별):
- `setup-zed-ros2-workspace.sh` — ZED ROS 2 workspace build (applies Jetson cmake flags automatically)

**설정 파일**:
- `config/zedxm_display.rviz` — RViz2 display config for ZED X Mini (Point Cloud, RGB, Depth, TF)

시스템 스크립트를 순서대로 실행한 뒤, GMSL2 카메라의 경우 리부트 후 유저 스크립트를 실행한다.
USB 카메라(ZED 2, ZED Mini)는 `install-zed-link-driver.sh`를 건너뛴다.
각 스크립트는 사전 조건을 검증한 뒤 진행한다.

### Step 4: colcon build + Verification

```bash
source /opt/ros/humble/setup.bash
source /opt/plem/setup.bash   # plem 코어 라이브러리를 CMAKE_PREFIX_PATH에 등록
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
source install/setup.bash
```

`--symlink-install`은 Python 패키지를 symlink로 설치하여 소스 수정이 재빌드 없이 즉시 반영되게 한다. 개발 중 권장.

`source /opt/plem/setup.bash`를 빌드 전에 실행해야 한다. 이 단계를 빠뜨리면 `find_package(plem_robot)` 등이 실패한다. 이미 빌드한 적이 있다면 `rm -rf build install log` 후 재빌드가 필요하다 (colcon이 생성한 prefix chain에 `/opt/plem`이 누락되기 때문).

`rosdep install`이 시스템 의존성(rosbridge 등)을 자동 해결한다. Diagnose and retry on failure. Guide system dependency installation if `plem_install=source` build fails.

### Step 5: Rules Collection + Installation

Read `references/rules-inventory.md` and **copy** rules from imported packages to project `.claude/rules/`.

Copy를 사용한다 (symlink 아님). 규칙 원본은 `.repos`로 버전 고정된 `src/` 저장소에 있으므로, symlink의 자동 동기화 이점이 없고 상대경로 해석 오류 위험만 있다.

```bash
mkdir -p .claude/rules
cp src/plem-msgs/.claude/rules/interface-standards.md .claude/rules/
cp src/plem-neuromeka/.claude/rules/launch-conventions.md .claude/rules/
# ... add per selection
```

**Embedded rules** (generate directly):
- `project-overview.md` — platform architecture summary, interface table

**Conditional rules:**
- `gripper != none` → copy `gripper-integration.md`
- `camera` is Stereolabs family → copy `zed-camera.md` (always-on 코딩 가드레일: QoS, 토픽명, TF 정합)

**ZED References**: `/zed-sdk` 스킬이 상세 레퍼런스를 on-demand로 제공한다. `zed-camera.md` rule과는 역할이 다르다 (rule = 항상 활성, skill = 호출 시 활성).

Full rules list: see `references/rules-inventory.md`.

### Step 6: CLAUDE.md + README.md + Final Verification

**`.claude/CLAUDE.md`** — agent context file. Read `references/claude-md-template.md` and generate by replacing `{...}` placeholders with actual parameter values.

**파라미터 전파 규칙**: 확인 테이블에서 사용자가 승인한 값을 그대로 사용한다.
특히 `{robot_id}`는 확인 테이블의 Robot ID 값과 정확히 일치해야 한다.
다른 프로젝트(zed-yolo 등)의 `robot_id` 값이나 시스템 환경의 값을 사용하지 않는다.
`/{robot_id}/`를 사용하되, 절대 리터럴 값(예: `/indy/`, `/robot2/`)을 하드코딩하지 않는다.

Conditional sections (GRIPPER_ROW, CAMERA_VISION_ROW, MOVEIT_SECTION, CAMERA_SECTION, REFERENCES_SECTION) are included or removed based on user selections. TRAJECTORY_SECTION is always included — it documents the fundamental trajectory control interface.

**`README.md`** (workspace root) — human-readable project documentation. Include:
- Project overview (what robot, what peripherals)
- Build instructions (`source /opt/plem/setup.bash && colcon build --symlink-install && source install/setup.bash`)
- **plem TUI** (`plem`, `plem-kill`) — 권장 실행 방법. TUI가 launch/stop/brake/freedrive를 관리한다.
  `PLEM_WORKSPACE` 설정과 기본 조작 키(`s`/`r`/`f`)를 안내한다.
- 직접 Launch (TUI 없이 `ros2 launch`) — `source install/setup.bash` 필수 안내 포함.
  이 안내 없이 `ros2 launch`만 보여주면 사용자가 `package not found`를 만난다.
- MoveIt launch command (if MoveIt was selected)
- Trajectory control quick start (SetMode → FJT workflow, always included)
- Key ROS2 interfaces table
- Package structure overview

**Final verification:** `colcon build` succeeds.

## Trajectory Control Guide

plem은 하위 제어(궤적 수신 → 1kHz 실시간 실행)를 담당한다. 궤적 생성(상위 제어)은 사용자 프로젝트의 책임이다.
MoveIt 선택 여부와 무관하게, `FollowJointTrajectory` 액션은 ros2_control의 `joint_trajectory_controller`가 항상 제공한다.

커스텀 플래너 연동 워크플로우, Python 예제, 모니터링, 안전 가이드: `references/trajectory-control-guide.md` 참조.

## MoveIt Guide

plem provides lower control (trajectory reception → real-time execution). MoveIt (upper-layer trajectory planning) is the user's responsibility.

`neuromeka_moveit_config` is a reference implementation — copy and customize for your project.
For MoveIt setup details, read `references/moveit-setup.md`.

## Camera Driver Guide

`camera:=zedxm` only adds TF frames to the URDF. Actual camera image streaming requires a separate driver installation.
For camera driver setup, read `references/zed-driver-setup.md`.

## Verification Checklist

Before declaring initialization complete:

- [ ] `.repos` file generated + `vcs import` succeeded
- [ ] `colcon build` succeeded
- [ ] `.claude/rules/` contains copied rules matching selected configuration
- [ ] `.claude/CLAUDE.md` generated (reflects project configuration)
- [ ] `README.md` generated (build/launch/interfaces documented)
- [ ] User package `src/{project_name}/` exists
- [ ] `/zed-sdk` 스킬 접근 가능 확인 — 개발 중 ZED 관련 질문 시 자동 참조됨 (if camera selected)
- [ ] `scripts/zed/` copied with installation scripts including `install-zed-link-driver.sh` (if camera selected)
- [ ] MoveIt config copied (if selected in Round 3)

## Post-Initialization — 사용자에게 안내

초기화 완료 후 반드시 "다음 단계" 안내를 제공한다. 사용자가 자연스럽게 첫 실행까지
도달할 수 있어야 한다. 별도 source 명령 없이 `plem` TUI를 바로 실행하는 것이 가장
간단한 경로다:

```
프로젝트 초기화가 완료되었습니다!

다음 단계:

  1. ~/.bashrc에 한 줄 추가 (최초 1회):
     export PLEM_WORKSPACE="{absolute_project_path}"

  2. 새 터미널을 열고 실행:
     plem

TUI에서 로봇 프로필을 선택하고 `s`(Start)로 바로 시작할 수 있습니다.
별도 source 명령이나 ros2 launch 인자를 외울 필요 없습니다.
```

카메라를 선택한 경우 추가 안내:

```
카메라 활용 (ZED):

  카메라 이미지를 사용하려면 ZED SDK + ROS 2 드라이버가 필요합니다.
  이미 설치되어 있다면 바로 사용할 수 있고, 아직이라면:
    bash scripts/zed/install-ros2-zed-deps.sh
    bash scripts/zed/install-zed-sdk.sh
    bash scripts/zed/setup-zed-ros2-workspace.sh

  개발 중 ZED 관련 질문이 있으면 `/zed-sdk` 를 호출하세요.
  QoS 설정, 토픽명, YOLO 통합, TF 정합 등의 레퍼런스를 제공합니다.
```

`ros2 launch ...`로 직접 실행하는 방법은 README.md에 "고급" 옵션으로 문서화되어 있으나,
launch 인자가 복잡하므로 TUI 사용을 권장한다. TUI가 launch 인자를 자동으로 구성해준다.

**`.repos`에 `zed-ros2-wrapper`를 포함하지 않는 이유**: ZED ROS 2 wrapper는 빌드 시
ZED SDK 헤더가 필요하다. `.repos`에 넣으면 SDK 미설치 상태에서 `colcon build`가 실패한다.
따라서 SDK 설치 → wrapper 빌드를 `scripts/zed/` 스크립트로 순차 관리한다.
