# MoveIt Setup Guide

plem handles lower control (receiving JointTrajectory → 1kHz real-time execution).
MoveIt (upper-layer trajectory generation, motion planning) is the **user project's responsibility**.

## Reference Implementation

`neuromeka_moveit_config` is a reference implementation. Do not modify it directly — copy it and customize.

### Using the default configuration (no customization needed)

Run in separate terminals:

```bash
# Terminal 1: lower control process
./launch.sh

# Terminal 2: MoveIt move_group (after 4+ seconds)
ros2 launch neuromeka_moveit_config move_group.launch.py

# Terminal 3: RViz (optional)
ros2 launch neuromeka_moveit_config rviz_moveit.launch.py
```

MoveIt runs as a **separate process** from plem_launch.py. Since ros2_control must start first, allow at least a 4-second delay.

### When customization is needed (adding collision geometry, changing planner, etc.)

1. Copy the reference implementation into your workspace:

```bash
cp -r src/plem-neuromeka/neuromeka_moveit_config src/my_moveit_config
```

2. Rename the package in `package.xml` and `CMakeLists.txt`:

```xml
<!-- package.xml -->
<name>my_moveit_config</name>
```

3. Modify the required configuration:
   - `config/kinematics.yaml` — IK solver configuration
   - `config/ompl_planning.yaml` — OMPL planner pipeline
   - `srdf/indy.srdf.xacro` — custom planning groups, disable_collisions
   - `config/pilz_cartesian_limits.yaml` — Cartesian limit configuration

4. Build and launch:

```bash
colcon build --packages-select my_moveit_config
ros2 launch my_moveit_config move_group.launch.py
```

## Key Configuration Files

| File | Purpose |
|------|---------|
| `config/kinematics.yaml` | IK solver (KDL, ikfast, etc.) configuration |
| `config/ompl_planning.yaml` | OMPL planner pipeline |
| `config/pilz_cartesian_limits.yaml` | PTP/LIN/CIRC Cartesian limits |
| `config/servo.yaml` | MoveIt Servo (real-time servoing) configuration |
| `srdf/indy.srdf.xacro` | SRDF (planning groups, collision disabling) |
| `launch/move_group.launch.py` | MoveIt move_group node launch |

## Relationship with plem_launch.py

`plem_launch.py` does not include MoveIt — this is an intentional separation.

- `plem_launch.py`: ros2_control_node, robot_state_publisher, controller spawners, gripper driver
- `move_group.launch.py`: MoveIt planning, subscribes to `/joint_states` and `/tf` for integration
