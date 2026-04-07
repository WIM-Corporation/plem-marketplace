# Rules Inventory — Package → Rules Mapping

Inventory referenced by plem-init Step 5 when collecting and copying rules.
Lists the rules contained in each package repository's `.claude/rules/` directory and their installation conditions.

## plem-msgs Rules

Always installed. Base rules for all plem projects.

| File | Description | paths | Condition |
|------|-------------|-------|-----------|
| `interface-standards.md` | Message/service/action naming, vendor-neutral design | `**/*.msg`, `**/*.srv`, `**/*.action` | always |
| `namespace-conventions.md` | `/{robot_id}/plem/*` topic/action naming patterns | (none — always active) | always |
| `urdf-srdf-standards.md` | URDF/SRDF authoring standards (REP-103, xacro prefix) | `**/*.xacro`, `**/*.urdf`, `**/*.srdf` | always |
| `description-conventions.md` | 2-Layer description pattern (Description/Integration) | `**/*_description/**`, `**/*_integrations/**` | always |
| `gripper-integration.md` | GripperCommand interface, topic paths, usage examples | `**/*gripper*` | `gripper != none` |

## plem-neuromeka Rules

Installed when `robot_vendor=neuromeka`.

| File | Description | paths |
|------|-------------|-------|
| `driver-conventions.md` | HW Interface implementation patterns (on_init/read/write) | `**/*_driver/**` |
| `neuromeka-description-conventions.md` | neuromeka-specific Description/Integration rules | `**/*_description/**`, `**/*_integrations/**` |
| `launch-conventions.md` | Launch parameter naming, multi-robot rules | `**/launch/**`, `**/*.launch.py` |
| `testing-conventions.md` | use_fake_hardware testing, startup verification | `**/test/**`, `**/*test*` |

## plem-onrobot Rules

Installed when `gripper` is an OnRobot family product.

(No rules — Description rules are now in `plem-msgs/description-conventions.md`)

## plem-stereolabs Rules

Installed when `camera` is a Stereolabs family product.

| File | Description | paths |
|------|-------------|-------|
| `zed-camera.md` | ZED ROS 2 코딩 규칙 — QoS, 토픽명, TF 정합, headless NITROS, param_overrides | `**/*zed*`, `**/*camera*` |

이 규칙은 **항상 활성화되는 코딩 가드레일**이다 (QoS Silent Failure 방지, 토픽명 실수 차단 등).
`/zed-sdk` 스킬은 별도로 **호출 시 활성화되는 상세 레퍼런스**를 제공한다. 두 가지는 역할이 다르다:
- `zed-camera.md` rule → always-on 코딩 규칙 (`.claude/rules/`에 복사)
- `/zed-sdk` skill → on-demand 상세 문서 (API, 튜닝, YOLO 등)

## plem-stereolabs References

ZED 카메라 상세 레퍼런스는 `/zed-sdk` 스킬이 제공한다. plem-init은 references를 복사하지 않는다.
스킬이 ZED 관련 질문 시 자동 트리거되므로 별도 설치 불필요.

## Embedded Rules (generated directly by plem-init)

File creation method, not symlinks. Project-specific rules not found in packages.

| File | Description | paths |
|------|-------------|-------|
| `project-overview.md` | plem platform architecture summary, interface table, launch structure | (none — always active) |

**project-overview.md content:**

```markdown
---
description: "plem platform architecture overview — black-box lower control, user builds upper layer, key interfaces"
---

# Project Overview

## plem Platform

plem is a real-time lower control platform for industrial manipulators.
It receives trajectories via the ROS2 standard interface (FollowJointTrajectory) and executes them in a 1kHz real-time loop.

Users do not call the plem library directly. Only the defined ROS2 interfaces are used.

## Architecture

```
User project (MoveIt, custom planner)
  → FollowJointTrajectory (ros2_control)
    → neuromeka_robot_driver (HW Interface)
      → plem RT engine (1kHz)
        → EtherCAT → robot
```

The upper layer (trajectory generation, vision, gripper sequencing) is implemented in the user project.
The lower layer (real-time control, EtherCAT) is provided by plem.

## MoveIt

MoveIt is the upper-layer trajectory generation tool and belongs to the user project domain.
`neuromeka_moveit_config` is a reference implementation — copy and customize it.
MoveIt launch runs separately from plem_launch.py (allow at least 4 seconds between them).
```

## Copy Command Patterns

규칙 원본은 `.repos`로 버전 고정된 `src/` 저장소에 있다. symlink 대신 copy를 사용하여 상대경로 해석 문제를 방지한다.

```bash
mkdir -p .claude/rules

# plem-msgs (always)
cp src/plem-msgs/.claude/rules/interface-standards.md .claude/rules/
cp src/plem-msgs/.claude/rules/namespace-conventions.md .claude/rules/
cp src/plem-msgs/.claude/rules/urdf-srdf-standards.md .claude/rules/
cp src/plem-msgs/.claude/rules/description-conventions.md .claude/rules/

# plem-neuromeka (robot_vendor=neuromeka)
cp src/plem-neuromeka/.claude/rules/driver-conventions.md .claude/rules/
cp src/plem-neuromeka/.claude/rules/neuromeka-description-conventions.md .claude/rules/
cp src/plem-neuromeka/.claude/rules/launch-conventions.md .claude/rules/
cp src/plem-neuromeka/.claude/rules/testing-conventions.md .claude/rules/

# gripper != none (e.g. rg6 → OnRobot)
cp src/plem-msgs/.claude/rules/gripper-integration.md .claude/rules/

# camera is Stereolabs family (zedxm)
cp src/plem-stereolabs/.claude/rules/zed-camera.md .claude/rules/
# /zed-sdk 스킬이 상세 레퍼런스 자동 제공 (별도 복사 불필요)
```

## Adding New Peripherals

Adding an entry to this mapping table will make it automatically supported by plem-init.
Use the `/plem-extend` skill to add the peripheral itself.
