---
description: >
  ZED ROS 2 advanced reference — Multi-camera setup and Robot Integration.
  Extracted from official Stereolabs documentation.
sources:
  - https://www.stereolabs.com/docs/ros2/multi-camera/
  - https://www.stereolabs.com/docs/ros2/ros2-robot-integration/
fetched: 2026-04-07
---

# ZED ROS 2 Advanced Reference

## Table of Contents

- [Multi-Camera Setup](#multi-camera-setup)
  - [Key Requirements](#key-requirements)
  - [Launch File Configuration](#launch-file-configuration)
  - [Running the Example](#running-the-example)
  - [Multi-Camera URDF Configuration](#multi-camera-urdf-configuration)
  - [Component Verification](#component-verification)
  - [Transform Frame Tree](#transform-frame-tree)
- [Robot Integration](#robot-integration)
  - [Installation Dependencies](#installation-dependencies)
  - [URDF Creation with Xacro](#urdf-creation-with-xacro)
  - [Mono-Camera Configuration](#mono-camera-configuration)
  - [Multi-Camera Configuration](#multi-camera-configuration)
  - [Visualization](#visualization)

---

## Multi-Camera Setup

Source: <https://www.stereolabs.com/docs/ros2/multi-camera/>

This tutorial demonstrates how to create a multi-camera configuration with ZED devices. Proper identification of each camera using serial numbers and precise positioning relative to a reference point are essential for successful multi-camera setups.

### Key Requirements

- Each camera must have a unique identifier (serial number)
- Position and orientation of each camera must be defined relative to a reference point
- Working example available in the `zed-ros2-examples` GitHub repository under `tutorials/zed_multi_camera`

### Launch File Configuration

The example launch file `zed_multi_camera.launch.py` dynamically configures robotics systems with multiple ZED cameras of different models.

#### System Architecture

The launch file initiates:

- One Robot State Publisher node defining position/orientation of each camera
- Individual Robot State Publisher nodes for each camera broadcasting static frames
- One ZED node per camera in the system

The number of ZED nodes is inferred from launch file parameters. All ZED nodes load in the same ROS 2 container as components using ROS 2 Composition.

> **Note:** Additional ROS 2 components can be loaded in the same container for zero-copy Intra-Process Communication (IPC).

#### Launch Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cam_names` | Array | Yes | Camera names, e.g., `'[zed_front,zed_back]'` |
| `cam_models` | Array | Yes | Camera models, e.g., `'[zed2i,zed2]'` |
| `cam_serials` | Array | Yes | Serial numbers, e.g., `[3001234,2001234]` |
| `disable_tf` | Boolean | No | Disable TF broadcasting; only first camera broadcasts map->odom->camera_link |

> **Important:** All arrays must have identical size.

### Running the Example

Launch a dual camera configuration:

```bash
ros2 launch zed_multi_camera zed_multi_camera.launch.py cam_names:='[zed_front,zed_rear]' cam_models:='[zedx,zedxm]' cam_serials:='[<serial_camera_front>,<serial_camera_rear>]'
```

To retrieve serial numbers of connected cameras:

```bash
ZED_Explorer --all
```

### Multi-Camera URDF Configuration

Create a URDF file defining camera positions relative to a reference link. The example uses `urdf/zed_multi.urdf.xacro`.

#### Reference Links

```xml
<link name="$(arg multi_link)" />
<link name="$(arg camera_name_0)_camera_link" />
<link name="$(arg camera_name_1)_camera_link" />
```

The `multi_link` xacro argument defaults to `zed_multi_link`. A virtual `camera_link` for each camera correctly connects individual camera URDFs to the reference link.

#### Joint Configuration

```xml
<joint name="$(arg camera_name_0)_camera_joint" type="fixed">
    <parent link="$(arg camera_name_0)_camera_link"/>
    <child link="$(arg multi_link)"/>
    <origin xyz="0.06 0.0 0.0" rpy="0 0 0" />
</joint>

<joint name="$(arg camera_name_1)_camera_joint" type="fixed">
    <parent link="$(arg multi_link)"/>
    <child link="$(arg camera_name_1)_camera_link"/>
    <origin xyz="-0.06 0.0 0.0" rpy="0 0 ${M_PI}" />
</joint>
```

Each joint requires:

- **Position:** `<origin xyz="x y z" rpy="r p y" />` (meters and radians)
- **Orientation:** Roll, pitch, yaw in radians

> **Important:** The first joint has `parent link` and `child link` inverted with respect to all the other joints. This is required because the first camera is the reference for visual odometry processing and in ROS a joint cannot have two parents.

### Component Verification

Check running components:

```bash
ros2 component list
```

Example output:

```
/zed_multi/zed_multi_container
  1  /zed_multi/zed_front
  2  /zed_multi/zed_rear
```

All nodes run in the `zed_multi` namespace.

### Transform Frame Tree

The system generates a TF tree with the reference link (`zed_multi_link`) as the central hub connecting individual camera frames.

---

## Robot Integration

Source: <https://www.stereolabs.com/docs/ros2/ros2-robot-integration/>

This tutorial explains how to use the xacro tool to add ZED cameras to a robot's URDF. There are two primary configurations depending on localization strategy:

1. Using ZED Positional Tracking exclusively for robot localization
2. Using ROS 2 tools (e.g., Robot Localization package) to fuse multiple odometry sources

Tutorial files are available in `tutorials/zed_robot_integration` of the [zed-ros2-examples GitHub repository](https://github.com/stereolabs/zed-ros2-examples).

### Installation Dependencies

For the AgileX Scout Mini 4WD robot reference:

```bash
cd <ros2_workspace>/src
git clone https://github.com/stereolabs/scout_ros2.git
git clone https://github.com/westonrobot/ugv_sdk.git
git clone https://github.com/westonrobot/async_port.git
cd ..
sudo apt update
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --cmake-args=-DCMAKE_BUILD_TYPE=Release --parallel-workers $(nproc)
source ~/.bashrc
```

### URDF Creation with Xacro

Xacro is an XML macro language enabling shorter, more readable XML files through macro expansion with parameters, variables, constants, and math formulas.

### Mono-Camera Configuration

#### Set Parameters

```xml
<xacro:arg name="camera_name"   default="zed" />
<xacro:arg name="camera_model"  default="zed" />
<xacro:arg name="use_zed_localization" default="true" />
```

- **`camera_name`**: Prefix for camera link and joint names
- **`camera_model`**: Determines visual mesh, dimensions, mounting bias values
- **`use_zed_localization`**: Controls TF tree structure (ZED vs. external localization)

#### Add Robot Model

```xml
<xacro:include filename="$(find scout_description)/urdf/scout_mini.xacro" />
```

The `scout_mini.xacro` file defines a `base_link` reference for camera placement.

#### Add ZED Camera

```xml
<xacro:include filename="$(find zed_wrapper)/urdf/zed_macro.urdf.xacro" />
<xacro:zed_camera name="$(arg camera_name)" model="$(arg camera_model)" />
```

#### Connect Camera to Robot

The ZED URDF defines reference link `<camera_name>_camera_link`. This must connect to the robot URDF.

> **Critical TF Requirement:** If you plan to use the ZED Positional Tracking module, and you set the parameter `pos_tracking.publish_tf` of the ZED node to `true`, then the `<camera_name>_camera_link` must be the root frame of the robot to correctly localize it on the map.

**With ZED Localization Enabled (`use_zed_localization:=true`):**

```xml
<xacro:if value="$(arg use_zed_localization)">
  <joint name="$(arg camera_name)_joint" type="fixed">
    <parent link="$(arg camera_name)_camera_link"/>
    <child link="base_link"/>
    <origin
      xyz="-0.12 0.0 -0.25"
      rpy="0 0 0"
    />
  </joint>
</xacro:if>
```

Frame `<camera_name>_camera_link` becomes parent; `base_link` is child. Camera positioned 12 cm ahead and 25 cm above robot center.

**Without ZED Localization (`use_zed_localization:=false`):**

```xml
<xacro:unless value="$(arg use_zed_localization)">
  <joint name="$(arg camera_name)_joint" type="fixed">
    <parent link="base_link"/>
    <child link="$(arg camera_name)_camera_link"/>
    <origin
      xyz="0.12 0.0 0.25"
      rpy="0 0 0"
    />
  </joint>
</xacro:unless>
```

Frame `base_link` becomes parent; `<camera_name>_camera_link` is child with inverse transform.

### Multi-Camera Configuration

#### Set Parameters

```xml
<xacro:arg name="camera_name_1"   default="zed_front" />
<xacro:arg name="camera_name_2"   default="zed_back" />
<xacro:arg name="camera_model_1"  default="zedx" />
<xacro:arg name="camera_model_2"  default="zedx" />
<xacro:arg name="use_zed_localization" default="true" />
```

Each camera requires a **unique** name; models can match.

#### Add All Cameras

```xml
<xacro:include filename="$(find zed_wrapper)/urdf/zed_macro.urdf.xacro" />
<xacro:zed_camera name="$(arg camera_name_1)" model="$(arg camera_model_1)" />
<xacro:zed_camera name="$(arg camera_name_2)" model="$(arg camera_model_2)" />
```

#### Connect Cameras to Robot

Camera #1 handles main localization:

```xml
<xacro:if value="$(arg use_zed_localization)">
  <joint name="$(arg camera_name_1)_joint" type="fixed">
    <parent link="$(arg camera_name_1)_camera_link"/>
    <child link="base_link"/>
    <origin
      xyz="-0.12 0.0 -0.25"
      rpy="0 0 0"
    />
  </joint>    
</xacro:if>
<xacro:unless value="$(arg use_zed_localization)">
  <joint name="$(arg camera_name_1)_joint" type="fixed">
    <parent link="base_link"/>
    <child link="$(arg camera_name_1)_camera_link"/>
    <origin
      xyz="0.12 0.0 0.25"
      rpy="0 0 0"
    />
  </joint>
</xacro:unless>
```

All secondary cameras attach to `base_link`:

```xml
<joint name="$(arg camera_name_2)_joint" type="fixed">
  <parent link="base_link"/>
  <child link="$(arg camera_name_2)_camera_link"/>
  <origin
    xyz="-0.12 0.0 0.25"
    rpy="0 0 ${M_PI}"
  />
</joint>
```

> **Important:** If `use_zed_localization` is `true`, **only** the node of camera #1 must broadcast the TF and it must set the parameter `pos_tracking.publish_tf:=true`. The other ZED nodes must disable the TF broadcasting: `pos_tracking.publish_tf:=false` to avoid conflicts.

### Visualization

Mono-camera with ZED localization:

```bash
ros2 launch zed_robot_integration view_mono_zed.launch.py use_zed_localization:=true
```

Dual-camera with ZED localization:

```bash
ros2 launch zed_robot_integration view_dual_zed.launch.py use_zed_localization:=true
```
