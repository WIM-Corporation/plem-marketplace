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

## Core Principles

1. **Wizard-style** — One question at a time. Never dump all parameters in a single message.
2. **Vendor-defined rules** — Rules are not LLM-generated. Symlink pre-validated rules from package repositories.
3. **Conditional installation** — Do not install rules/dependencies for unselected features (gripper, camera).
4. **Verification required** — Confirm `colcon build` succeeds before declaring initialization complete.

## Parameter Collection — AskUserQuestion Wizard

**Use the `AskUserQuestion` tool for clickable selection UI.** Skip parameters already provided via $ARGUMENTS or mentioned in conversation.
AskUserQuestion supports up to 4 questions per call — group related items efficiently.

### Round 1: Project Name

If not provided as argument, ask as plain text (free-form input, AskUserQuestion not needed):

> What is your project name? (lowercase + underscores, e.g. `my_pick_app`)

### Round 2: Robot + Peripherals

Read `references/peripheral-mapping.md` and present **3 questions in a single AskUserQuestion call**:

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

### Round 3: Additional Setup

Ask conditional questions in a single AskUserQuestion call. Only include questions that apply:

```
AskUserQuestion:
  questions:
    # Always include:
    - question: "Set up MoveIt for motion planning?"
      header: "MoveIt"
      multiSelect: false
      options:
        - label: "Yes (Recommended)"
          description: "Copy neuromeka_moveit_config to your project as a starting point for trajectory planning"
        - label: "No"
          description: "Skip MoveIt setup. Can be added manually later"

```

If MoveIt is selected, Step 3 will copy `neuromeka_moveit_config` to `src/{project_name}_moveit_config/`, rename the package, and include it in the build.

`robot_id` (default: `indy`) and `plem_install` (default: `apt`) use defaults without asking. plem core is pre-installed on Jetson devices — source build is only for internal development.

### Handling "Other" Selections

AskUserQuestion automatically adds an "Other" option. If the user selects "Other" for robot/gripper/camera, ask them to specify the model name. Then check `references/peripheral-mapping.md` — if the model isn't listed, inform the user it's not yet supported and offer to proceed with "none" for that peripheral, or cancel initialization.

### Confirmation

Summarize collected parameters and ask for confirmation before proceeding:

> Initializing project with the following configuration:
>
> | Setting | Value |
> |---------|-------|
> | Project | `my_pick_app` |
> | Robot | neuromeka indy7 |
> | Gripper | rg6 (OnRobot) |
> | Camera | None |
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

Model-to-vendor-package mapping: see `references/peripheral-mapping.md`.

```bash
vcs import src < .repos
```

**If `vcs import` fails:**
- Authentication error → check SSH key or HTTPS credentials for GitHub
- Network error → verify internet connectivity, retry
- Repository not found → confirm repo URL in `references/peripheral-mapping.md` is current

### Step 3: User ROS2 Package Scaffolding + MoveIt Setup

```bash
cd src && ros2 pkg create --build-type ament_python {project_name} \
  --dependencies rclpy control_msgs plem_msgs trajectory_msgs
```

Add `neuromeka_msgs` if `robot_vendor=neuromeka`.

**If MoveIt was selected**, copy the reference implementation and rename:

```bash
cp -r src/plem-neuromeka/neuromeka_moveit_config src/{project_name}_moveit_config
# Update package.xml: <name>{project_name}_moveit_config</name>
# Update CMakeLists.txt: project({project_name}_moveit_config)
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
- `install-ros2-zed-deps.sh` — ROS 2 + ZED ROS 2 dependencies (includes `zed_msgs`, `zed_description`)
- `install-zed-sdk.sh` — ZED SDK (auto-detects Jetson L4T version)
- `setup-zed-ros2-workspace.sh` — ZED ROS 2 workspace build (applies Jetson cmake flags automatically)
- `config/zedxm_display.rviz` — RViz2 display config for ZED X Mini (Point Cloud, RGB, Depth, TF)

Run scripts in order. Each script verifies prerequisites before proceeding.

### Step 4: colcon build + Verification

```bash
colcon build
source install/setup.bash
```

Diagnose and retry on failure. Guide system dependency installation if `plem_install=source` build fails.

### Step 5: Rules Collection + Installation

Read `references/rules-inventory.md` and symlink rules from imported packages to project `.claude/rules/`.

```bash
mkdir -p .claude/rules
ln -sf src/plem-msgs/.claude/rules/interface-standards.md .claude/rules/
ln -sf src/plem-neuromeka/.claude/rules/launch-conventions.md .claude/rules/
# ... add per selection
```

**Embedded rules** (write as files, not symlinks):
- `project-overview.md` — platform architecture summary, interface table

**Conditional rules:**
- `gripper != none` → symlink `gripper-integration.md`

**ZED References**: `/zed-docs` 스킬이 ZED 레퍼런스를 자동 제공한다. symlink 불필요.

Full rules list: see `references/rules-inventory.md`.

### Step 6: CLAUDE.md + README.md + Final Verification

**`.claude/CLAUDE.md`** — agent context file. Read `references/claude-md-template.md` and generate by replacing `{...}` placeholders with actual parameter values. All topic/action paths use `/{robot_id}/` — never hardcode a specific robot_id like `/indy/`. Conditional sections (GRIPPER_ROW, CAMERA_VISION_ROW, CAMERA_SECTION, REFERENCES_SECTION) are included or removed based on user selections.

**`README.md`** (workspace root) — human-readable project documentation. Include:
- Project overview (what robot, what peripherals)
- Build instructions (`colcon build && source install/setup.bash`)
- Launch command with actual parameters:
  ```
  ros2 launch neuromeka_robot_driver plem_launch.py \
    robot_type:={robot_model} robot_id:={robot_id} \
    gripper:={gripper} camera:={camera}
  ```
- MoveIt launch command (if MoveIt was selected)
- Key ROS2 interfaces table
- Package structure overview

**Final verification:** `colcon build` succeeds.

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
- [ ] `.claude/rules/` contains symlinks matching selected configuration
- [ ] `.claude/CLAUDE.md` generated (reflects project configuration)
- [ ] `README.md` generated (build/launch/interfaces documented)
- [ ] User package `src/{project_name}/` exists
- [ ] `/zed-docs` 스킬이 available skills에 표시됨 (if camera selected)
- [ ] `scripts/zed/` copied with installation scripts (if camera selected)
- [ ] MoveIt config copied (if selected in Round 3)
