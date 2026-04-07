---
description: >
  ZED SDK Positional Tracking consolidated reference.
  Covers overview, quickstart, tracking modes (GEN_1/GEN_3), settings,
  status enums, VSLAM area memory/mapping, coordinate frames, and API usage.
  Source: https://www.stereolabs.com/docs/positional-tracking/
---

# ZED SDK -- Positional Tracking

## Table of Contents

- [Positional Tracking Overview](#positional-tracking-overview)
- [Quickstart](#quickstart)
- [Positional Tracking Modes](#positional-tracking-modes)
- [Positional Tracking Settings](#positional-tracking-settings)
- [Positional Tracking Status](#positional-tracking-status)
- [VSLAM - Mapping Tutorial](#vslam---mapping-tutorial)
- [Coordinate Frames](#coordinate-frames)
- [Using the API](#using-the-api)

---

## Positional Tracking Overview

Source: https://www.stereolabs.com/docs/positional-tracking/

Positional tracking enables devices to estimate their position and orientation in 3D space, providing six degrees of freedom (6DoF): translation along X, Y, Z axes and rotation via roll, pitch, and yaw. The ZED SDK's stereo SLAM algorithms power this capability across diverse applications from robotics to augmented reality.

### How It Works

The system employs visual tracking to continuously estimate camera motion by analyzing and matching visual features across consecutive frames. An integrated inertial sensor provides high-frequency measurements of accelerations and angular velocities, which can be fused with visual data for more reliable motion estimation.

### Visual-Inertial SLAM (VSLAM) Architecture

The module integrates three key components:

1. **Stereo Visual Odometry** -- tracks 3D visual features across frames to estimate motion
2. **IMU Data** -- delivers high-frequency accelerations and angular velocities for robust estimation during rapid movement or low-texture environments
3. **SLAM** -- maintains a sparse 3D landmark map to reduce drift and enable loop closure, facilitating scalable localization in indoor, outdoor, and dynamic settings

Loop closure corrects accumulated drift when the camera revisits previously mapped locations.

### Pose Information Output

The SDK outputs real-time camera pose for the left stereo eye relative to a reference coordinate frame, including:

- **Position [X, Y, Z]** -- 3D location in the reference frame
- **Orientation [X, Y, Z, W]** -- quaternion representation convertible to Euler angles or rotation matrix
- **Linear and Angular velocity**
- **Metadata** -- timestamp, tracking confidence, transformation matrices

### Primary Use Cases

#### Robotics

Autonomous mobile robots, drones, UAVs, humanoids, and manipulators leverage positional tracking for autonomous navigation, real-time SLAM-based mapping, velocity estimation, and trajectory planning. Native ROS 2 integration enables deployment with frameworks like Nav2 and MoveIt.

#### Virtual and Augmented Reality

Inside-out tracking supports full 6DoF user motion estimation, real-time spatial understanding for occlusion and interaction, and seamless integration with Unity 3D or Unreal Engine for immersive mixed reality experiences.

#### Visual Effects and Match Moving

Filmmakers capture precise camera motion on set to drive virtual cameras in real-time for previsualization and compositing, achieving perfect perspective alignment between CG elements and live-action footage.

---

## Quickstart

Source: https://www.stereolabs.com/docs/positional-tracking/quickstart/

The Positional Tracking sample enables rapid deployment of the positional tracking module. Available implementations include C++, Python, and C# languages.

Key capabilities:

- Stream live video with 3D point cloud visualization via OpenGL
- Real-time API status monitoring for module health verification
- Customizable Positional Tracking parameters to adjust tracking behavior
- SVO recording playback for offline parameter testing
- SLAM map recording and extraction during sessions
- Existing map loading for relocalization in known environments

### Installation and Setup

Download the latest ZED SDK from the [official release page](https://www.stereolabs.com/en-fr/developers/release).

### Running the Sample (Linux)

#### C++ Version

```bash
cd /usr/local/zed/samples/positional\ tracking/positional\ tracking/cpp
mkdir build && cd build
cmake .. && make
./ZED_Positional_Tracking
```

Modify parameters by editing `src/main.cpp`, then recompile with `make` in the build folder.

#### Python Version

```bash
cd /usr/local/zed/samples/positional\ tracking/positional\ tracking/python
python3 positional_tracking.py
```

Edit `positional_tracking.py` to adjust parameters before running.

### Command-Line Options

```
--help                      Shows usage information
--resolution <mode>         Resolution: HD2K | HD1200 | HD1080 | HD720 | SVGA | VGA
--svo <filename.svo>        Use SVO file input (exclusive with --stream)
--stream <ip[:port]>        Network streaming input (exclusive with --svo)
-i <input_area_file>        Input area file for explore or map mode
--map -o <output_area_file> Map mode creates/updates .area file
--roi <roi_filepath>        Region of interest mask for static areas
--custom-initial-pose       Enable custom initial pose
--2d-ground-mode            Enable 2D ground mode
```

### Examples

```bash
./build/ZED_Positional_Tracking --svo recording.svo2 --map -o new_map.area
./build/ZED_Positional_Tracking -i map.area
```

The sample displays video feed, tracking status, and 3D camera position rendering. Using `--map` exports a `.area` file containing mapped area data after the session completes.

### Keyboard Controls

| Key | Action |
|-----|--------|
| `space` | Toggle camera view visibility |
| `d` | Switch background color (dark/light) |
| `p` | Enable/disable live point cloud display |
| `l` | Enable/disable landmark display |
| `f` | Follow camera |
| `z` | Reset view |
| `ctrl` + drag | Rotate |
| `esc` | Exit |

---

## Positional Tracking Modes

Source: https://www.stereolabs.com/docs/positional-tracking/positional-tracking-modes/

The Positional Tracking module employs visual-inertial SLAM (VSLAM) technology to deliver real-time 3D position and orientation estimates. The system fuses stereo vision with IMU data to build and refine environmental 3D maps while tracking motion simultaneously.

### GEN_1 Mode

GEN_1 implements a dense VSLAM approach that leverages depth data from stereo cameras. Rather than using sparse keypoints, it generates dense representations directly from depth information, enabling stable tracking in low-texture environments. The stereo vision and IMU fusion improves robustness against motion blur and rapid movements, making it ideal for AR/VR applications.

> GEN_1 is optimized primarily for VIO (Visual-Inertial Odometry) mode. The dense VSLAM architecture was not designed with loop closure or area map relocalization in mind.

**Load Performance (Jetson Orin NX 16):**

- Neural Light: 13 FPS max, 77% CPU, 44% GPU
- Neural: 8 FPS max, 80% CPU, 44% GPU
- Neural Plus: 4 FPS max, 94% CPU, 44% GPU

**Accuracy Performance (VIO):**

- Indoor warehouse: 0.8m mean APE, 1.8m max APE
- Outdoor structured: 3.38m mean APE, 7.76m max APE

### GEN_3 Mode

GEN_3 introduces a scalable, feature-based VSLAM pipeline designed for robustness and precision. By extracting and tracking high-quality visual features rather than relying on dense mapping, it maintains lightweight maps with strong loop closure and global optimization capabilities, minimizing drift and improving long-term consistency.

> GEN_3 is recommended for both the VIO and relocalization localization strategies.

**Load Performance:**

- Up to 80 FPS, 13% CPU, 44% GPU

**Accuracy Performance (VIO):**

- Indoor warehouse: 0.56m mean APE, 1.2m max APE
- Outdoor structured: 0.29m mean APE, 0.58m max APE

### Localization Strategies

1. **VIO (Visual-Inertial Odometry)** -- pure localization without prior maps
2. **Relocalization** -- localization within area maps for multi-session tracking

### Comparison Table

| Feature | GEN_1 | GEN_3 |
|---------|-------|-------|
| Best for low-texture environments | Yes | -- |
| Feature-rich indoor/outdoor | -- | Yes |
| Loop closure capability | Limited | Advanced |
| Computational load | Higher | Lighter |
| Relocalization support | Not recommended | Recommended |
| Depth dependency | Heavy | None required |
| Severe visual degradation handling | Robust | Limited |

---

## Positional Tracking Settings

Source: https://www.stereolabs.com/docs/positional-tracking/positional-tracking-settings/

The `sl::PositionalTrackingParameters` structure enables customization of the ZED SDK's Positional Tracking module.

### Minimum Depth Range

> **Note:** Only for `GEN_1` mode positional tracking.

Sets the minimum depth distance for positional tracking. This helps improve stability by ignoring very close static objects that may introduce noise into pose estimation.

**Default:** -1 (no minimum depth)

```cpp
sl::PositionalTrackingParameters tracking_parameters;
tracking_parameters.mode = sl::POSITIONAL_TRACKING_MODE::GEN_3;
tracking_parameters.depth_min_range = 3.0;
```

```python
tracking_parameters = sl.PositionalTrackingParameters()
tracking_parameters.mode = sl.POSITIONAL_TRACKING_MODE.GEN_3
tracking_parameters.depth_min_range = 3.0
```

### Initial World Transform

Defines the camera's initial pose in the world frame when positional tracking begins. Uses a `sl::Transform` parameter to position the camera relative to the world coordinate system.

**Default:** Identity matrix

Recommendations:
- Use when camera position relative to world coordinates is known in advance
- Useful for multi-camera or multi-sensor setups requiring common reference alignment

```cpp
sl::PositionalTrackingParameters params;
params.initial_world_transform = sl::Transform::identity();
```

### Enable Area Memory

Allows the camera to remember surroundings and reuse saved area maps for localization. Enables loop-closure, drift correction, and re-localization.

**Default:** true

Recommendations:
- Enable for applications revisiting the same environment (warehouse robots, AR/VR)
- Disable for short missions where map building is unnecessary

```cpp
sl::PositionalTrackingParameters params;
params.enable_area_memory = true;
```

### Enable Pose Smoothing

Applies smoothing to pose output to reduce jitter and fluctuations, potentially introducing slight latency.

**Default:** false

Recommendations:
- Enable for AR/VR or visualization prioritizing smooth motion
- Disable for high-speed robotics requiring minimal latency

```cpp
sl::PositionalTrackingParameters params;
params.enable_pose_smoothing = false;
```

### Set Floor As Origin

Aligns the tracking coordinate system with the detected floor plane, setting z=0 at floor level. Requires IMU-equipped cameras and remains in `SEARCHING_FLOOR_PLANE` state until floor detection completes.

**Default:** false

Recommendations:
- Useful for indoor robotics or AR applications assuming floor as reference
- Not suitable for 3D movement scenarios (drones) or cameras not initially seeing floor

```cpp
sl::PositionalTrackingParameters params;
params.set_floor_as_origin = true;
```

### Area File Path

Specifies path to a previously saved area map (.area file) for relocalization. The system loads the map at startup and localizes within that pre-mapped environment.

**Default:** empty string ("")

Recommendations:
- Use when revisiting known environments for fast relocalization without rebuilding maps
- Ensure .area files use same positional tracking mode and depth mode as current configuration
- Create area maps using `GEN_3` mode for optimal compatibility

```cpp
sl::PositionalTrackingParameters params;
params.area_file_path = "myEnvironment.area";
```

### Enable IMU Fusion

Combines IMU measurements (accelerometer and gyroscope) with visual odometry for enhanced tracking robustness, improving performance during rapid movements and visual occlusions.

**Default:** true

Recommendations:
- Disable only for cameras without IMU (EOL ZED Model)
- Keep enabled on platforms with IMU support (ZED 2i, ZED X, ZED X Mini)

```cpp
sl::PositionalTrackingParameters params;
params.enable_imu_fusion = true;
```

### Set As Static

Treats the camera as stationary, fixing pose to the initial transform and skipping tracking computations. Useful for fixed-mount scenarios while maintaining world frame reference for other modules.

**Default:** false

Recommendations:
- Use for fixed-location mounted cameras (ceiling rigs)
- Not recommended for mobile or robot-mounted cameras

```cpp
sl::PositionalTrackingParameters params;
params.set_as_static = true;
```

### Set Gravity As Origin

Uses IMU's gravity vector to override roll and pitch components of `initial_world_transform`, ensuring vertical axis alignment regardless of camera mounting angle. Preserves yaw from initial transform. Has no effect on cameras without IMU.

**Default:** true

Recommendations:
- Keep enabled for consistent orientation regardless of mounting angle
- Particularly useful for mobile robots and AR/VR applications
- Disable only when full control over initial orientation via `initial_world_transform` is required

```cpp
sl::PositionalTrackingParameters params;
params.set_gravity_as_origin = true;
```

### Enable Localization Only

Enables localization-only mode with area memory workflows. The system localizes within a previously saved area map without updating or expanding it. Requires `enable_area_memory` to be true and valid `area_file_path`.

**Default:** false

Recommendations:
- Enable for deployment scenarios with pre-mapped environments requiring consistent relocalization without modifying stored map data (production robots in fixed warehouse layouts)
- Disable during initial mapping sessions to allow map creation or updating

```cpp
sl::PositionalTrackingParameters params;
params.enable_localization_only = true;
```

### Enable 2D Ground Mode

Constrains positional tracking to 2D ground plane, removing vertical degree of freedom for ground-based platforms. Prevents height drift and improves tracking stability for platforms not requiring full 3D motion tracking.

**Default:** false

Recommendations:
- Enable for wheeled robots, AGVs, or AMRs operating on flat surfaces
- Disable for aerial vehicles or multi-floor navigation scenarios requiring full 3D pose estimation

```cpp
sl::PositionalTrackingParameters params;
params.enable_2d_ground_mode = true;
```

---

## Positional Tracking Status

Source: https://www.stereolabs.com/docs/positional-tracking/positional-tracking-status/

The Positional Tracking module provides real-time status information through two primary functions:

1. **`getPosition()`** -- Returns `sl::POSITIONAL_TRACKING_STATE`
2. **`getPositionalTrackingStatus()`** -- Returns `sl::PositionalTrackingStatus` structure containing:
   - `sl::ODOMETRY_STATUS odometry_status`
   - `sl::SPATIAL_MEMORY_STATUS spatial_memory_status`
   - `sl::AREA_EXPORTING_STATE area_exporting_state`

### POSITIONAL_TRACKING_STATE

Indicates the current status of the positional tracking module:

| State | Description |
|-------|-------------|
| `SEARCHING` | Deprecated state |
| `OK` | Tracking functioning normally |
| `OFF` | Tracking currently disabled |
| `FPS_TOO_LOW` | Effective FPS is too low to provide accurate motion tracking results |
| `SEARCHING_FLOOR_PLANE` | Camera searching for floor plane; world reference frame will be set afterward |
| `UNAVAILABLE` | Module unable to track from previous to current frame |

### ODOMETRY_STATUS

Describes Visual Odometry (VO) tracking state:

| Status | Description |
|--------|-------------|
| `OK` | Successfully tracked from previous to current frame |
| `UNAVAILABLE` | Cannot track current frame |
| `INSUFFICIENT_FEATURES` | Failed due to insufficient feature detection |

### SPATIAL_MEMORY_STATUS (VSLAM)

Indicates Visual SLAM tracking process state:

| Status | Description |
|--------|-------------|
| `OK` | Deprecated for GEN_3 |
| `LOOP_CLOSED` | System found loop closure or relocated within area map |
| `SEARCHING` | Deprecated for GEN_3 |
| `OFF` | Spatial memory turned off |
| `INITIALIZING` | Acquiring initial memory or locating first loop closure |
| `KNOWN_MAP` | Camera localized within loaded area map |
| `MAP_UPDATE` | Robot mapping or exiting area bounds |
| `LOST` | Localization cannot operate anymore (obstruction or sudden jumps) |

### AREA_EXPORTING_STATE

Reflects spatial memory exportation process status:

| State | Description |
|-------|-------------|
| `SUCCESS` | File successfully created |
| `RUNNING` | Currently writing spatial memory |
| `NOT_STARTED` | Exportation not called |
| `FILE_EMPTY` | No data in spatial memory |
| `FILE_ERROR` | Not written due to invalid filename |
| `SPATIAL_MEMORY_DISABLED` | Learning disabled; no file creation possible |

---

## VSLAM - Mapping Tutorial

Source: https://www.stereolabs.com/docs/positional-tracking/area-memory/

The Visual SLAM (Visual Simultaneous Localization and Mapping) system in the ZED SDK builds spatial representations through positional tracking. When `enable_area_memory` is activated, the system stores this information in an "Area map" -- a compact structure encoding visual features, keyframes, and landmarks detected during mapping sessions.

### Key Capabilities

Area maps enable two critical functions:

1. **Loop Closure**: When the camera revisits previously mapped regions, the system recognizes them and corrects accumulated positional drift
2. **Stable Tracking**: Maintains repeatable performance in known environments

Mapping can occur in real-time during camera operation or offline through recorded video files (SVO format).

### Mapping Procedure

#### Initial Setup

Select a strategic starting point with:
- Open space containing rich, static visual features
- Daily accessibility for consistent camera repositioning
- Potential floor markings or fiducial markers for reference

The mapping camera should be:
- Rigidly mounted with vibration resistance
- Maintained with clean lenses
- Positioned for wide, unobstructed field of view (avoid downward angles)

#### Two Mapping Options

**Option 1 -- Offline Mapping**: Record an SVO file using ZED Explorer or ZED Studio, then process it through the sample application afterward.

**Option 2 -- Online Mapping**: Direct live recording using:

```bash
./build/ZED_Positional_Tracking --map -o map_name.area
```

#### Best Practices for Exploration

The Spatial Memory status progresses through states:

- `INITIALIZING` -- insufficient motion/keyframes
- `MAP_UPDATE` -- active mapping in progress
- `LOOP_CLOSED` -- system detected previously visited location
- `LOST` -- temporary tracking loss (auto-corrects)

For environment exploration:

1. **Clockwise loop**: Examine section perimeter in one direction
2. **Counter-clockwise loop**: Same starting point, opposite direction
3. **Multi-angle exploration**: Capture static environmental features from varied perspectives

Large environments should be divided into several mapping sections, with single loops not exceeding roughly 20 meters. Feature-rich areas benefit from standard coverage; featureless environments require doubled loop iterations.

### Lifelong Mapping

The SDK supports continuous map expansion. Launch with:

```bash
./build/ZED_Positional_Tracking -i map.area --map -o extended_map.area
```

Position the camera at the original map's starting point. The system:

- Loads the existing map (`KNOWN_MAP` status)
- Transitions to `MAP_UPDATE` when entering unexplored regions
- Returns to `KNOWN_MAP` upon reconnecting with previously mapped areas

### Relocalization

Once an Area map is created, enable relocalization:

```bash
./build/ZED_Positional_Tracking -i map.area
```

The camera maintains `KNOWN_MAP` status within previously mapped regions. When entering unfamiliar areas, status may briefly shift to `LOST`, requiring guidance back to known areas to re-establish tracking.

---

## Coordinate Frames

Source: https://www.stereolabs.com/docs/positional-tracking/coordinate-frames/

The ZED camera system uses coordinate frames to express motion relative to reference points. Two primary frames exist: the Camera Frame (relative positioning) and the World Frame (absolute positioning).

### Camera Frame

The Camera Frame is attached to the camera, located at the back of the left eye. It enables expression of relative pose between sequential positions. To retrieve movement between the current and previous camera position:

```cpp
getPosition(zed_pose, REFERENCE_FRAME::CAMERA)
```

### World Frame

The World Frame provides an absolute reference point in real-world space. By default, it originates where the ZED begins motion tracking, oriented toward the initial viewing direction.

To obtain camera position in world space:

```cpp
getPosition(zed_pose, REFERENCE_FRAME::WORLD)
```

#### World Frame Transformation

You can modify the initial Camera Frame location relative to the World Frame through:

1. Setting initial world transform parameters in `PositionalTrackingParameters`
2. Loading a saved Area file with Spatial Memory enabled

```cpp
sl::Transform initial_position;
initial_position.setTranslation(sl::Translation(0, 180, 0));
tracking_parameters.initial_world_transform = initial_position;
```

### Frame Transforms

When the ZED moves, the left eye and camera center don't move identically. Frame transforms express rotational and translational offsets between coordinate systems.

The `getPosition()` function returns the pose of the left eye. To get center-of-camera movement, apply a rigid transform using the baseline distance:

```cpp
void transformPose(sl::Transform &pose, float tx) {
    Transform transform_;
    transform_.tx = tx;
    pose = pose * transform_;
}

float translation_left_to_center =
    zed.getCameraInformation().camera_configuration.
    calibration_parameters.T.x * 0.5f;
```

### Coordinate System Selection

The ZED supports multiple coordinate systems via `sl::InitParameters`:

| System | Description |
|--------|-------------|
| `IMAGE` | Right-handed, Y-down (default) |
| `LEFT_HANDED_Y_UP` | Unity 3D format |
| `RIGHT_HANDED_Y_UP` | OpenGL format |
| `LEFT_HANDED_Z_UP` | Unreal Engine format |
| `RIGHT_HANDED_Z_UP` | CAD applications (3DSMax) |
| `RIGHT_HANDED_Z_UP_X_FORWARD` | ROS compliant (REP 103) |

```cpp
init_params.coordinate_system = COORDINATE_SYSTEM::RIGHT_HANDED_Y_UP;
```

### Coordinate Units

Default measurements use millimeters. Alternative units (meters, centimeters, feet, inches) can be set:

```cpp
init_params.coordinate_units = UNIT::METER;
```

Both Camera Frame and World Frame share the same coordinate system.

---

## Using the API

Source: https://www.stereolabs.com/docs/positional-tracking/using-tracking/

### Positional Tracking Configuration

To set up positional tracking, use `InitParameters` during initialization and `RuntimeParameters` for runtime adjustments.

```cpp
// C++
InitParameters init_params;
init_params.camera_resolution = RESOLUTION::HD720;
init_params.coordinate_system = COORDINATE_SYSTEM::RIGHT_HANDED_Y_UP;
init_params.coordinate_units = UNIT::METER;
```

```python
# Python
init_params = sl.InitParameters()
init_params.camera_resolution = sl.RESOLUTION.HD720
init_params.coordinate_system = sl.COORDINATE_SYSTEM.RIGHT_HANDED_Y_UP
init_params.coordinate_units = sl.UNIT.METER
```

```csharp
// C#
InitParameters init_params = new InitParameters();
init_params.resolution = RESOLUTION.HD720;
init_params.coordinateSystem = COORDINATE_SYSTEM.RIGHT_HANDED_Y_UP;
init_params.coordinateUnits = UNIT.METER;
```

### Enabling Positional Tracking

After opening the camera, activate tracking using `enablePositionalTracking()` with `PositionalTrackingParameters`.

```cpp
// C++
sl::PositionalTrackingParameters tracking_parameters;
err = zed.enablePositionalTracking(tracking_parameters);
```

```python
# Python
tracking_parameters = sl.PositionalTrackingParameters()
err = zed.enable_positional_tracking(tracking_parameters)
```

```csharp
// C#
PositionalTrackingParameters trackingParams = new PositionalTrackingParameters();
zed.EnablePositionalTracking(ref trackingParams);
```

Use `disablePositionalTracking()` to stop tracking at any time.

### Getting Pose

Camera position updates with each new frame. Retrieve pose data using `getPosition()` after frame acquisition.

The `Pose` class stores camera position, timestamp, and confidence information. Position is always relative to a reference frame -- use `REFERENCE_FRAME::WORLD` for real-world space or `REFERENCE_FRAME::CAMERA` for odometry relative to the last position. By default, the left eye pose is returned.

```cpp
// C++
sl::Pose zed_pose;
if (zed.grab() == ERROR_CODE::SUCCESS) {
    POSITIONAL_TRACKING_STATE state = zed.getPosition(zed_pose, REFERENCE_FRAME::WORLD);
    printf("Translation: tx: %.3f, ty:  %.3f, tz:  %.3f, timestamp: %llu\r",
    zed_pose.getTranslation().tx, zed_pose.getTranslation().ty, zed_pose.getTranslation().tz, zed_pose.timestamp);
    printf("Orientation: ox: %.3f, oy:  %.3f, oz:  %.3f, ow: %.3f\r",
    zed_pose.getOrientation().ox, zed_pose.getOrientation().oy, zed_pose.getOrientation().oz, zed_pose.getOrientation().ow);
}
```

```python
# Python
zed_pose = sl.Pose()
if zed.grab(runtime_parameters) == sl.ERROR_CODE.SUCCESS:
    state = zed.get_position(zed_pose, sl.REFERENCE_FRAME.FRAME_WORLD)
    py_translation = sl.Translation()
    tx = round(zed_pose.get_translation(py_translation).get()[0], 3)
    ty = round(zed_pose.get_translation(py_translation).get()[1], 3)
    tz = round(zed_pose.get_translation(py_translation).get()[2], 3)
    print("Translation: tx: {0}, ty:  {1}, tz:  {2}, timestamp: {3}\n".format(tx, ty, tz, zed_pose.timestamp))
    py_orientation = sl.Orientation()
    ox = round(zed_pose.get_orientation(py_orientation).get()[0], 3)
    oy = round(zed_pose.get_orientation(py_orientation).get()[1], 3)
    oz = round(zed_pose.get_orientation(py_orientation).get()[2], 3)
    ow = round(zed_pose.get_orientation(py_orientation).get()[3], 3)
    print("Orientation: ox: {0}, oy:  {1}, oz: {2}, ow: {3}\n".format(ox, oy, oz, ow))
```

```csharp
// C#
Pose zed_pose = new Pose();
RuntimeParameters runtimeParameters = new RuntimeParameters();
if (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
    POSITIONAL_TRACKING_STATE state = zed.GetPosition(ref zed_pose, REFERENCE_FRAME.WORLD);
    Console.WriteLine("Translation: tx: " + zed_pose.translation.X + "ty: " + zed_pose.translation.Y + "tz: " + zed_pose.translation.Z + "Timestamp: " + zed_pose.timestamp);
    Console.WriteLine("Rotation: ox: " + zed_pose.rotation.X + "oy: " + zed_pose.rotation.Y + "oz: " + zed_pose.rotation.Z + "ow: " + zed_pose.rotation.w);
}
```

Retrieve translation, orientation, or rotation matrices using `getTranslation()`, `getOrientation()`, and `getRotation()`.

### Getting Velocity

Velocity updates with each new frame. Use `getPosition()` after frame acquisition to access velocity data. The example extracts velocity relative to the Camera Frame with linear and angular velocities along the [x,y,z] axes.

```cpp
// C++
sl::Pose zed_pose;
if (zed.grab() == ERROR_CODE::SUCCESS) {
    POSITIONAL_TRACKING_STATE state = zed.getPosition(zed_pose, REFERENCE_FRAME::CAMERA);
    printf("Linear Twist: vx: %.3f, vy:  %.3f, vz:  %.3f, timestamp: %llu\r",
    zed_pose.twist[0], zed_pose.twist[1], zed_pose.twist[2], zed_pose.timestamp);
    printf("Angular Twist: x: %.3f, y:  %.3f, z:  %.3f, timestamp: %llu\r",
    zed_pose.twist[3], zed_pose.twist[4], zed_pose.twist[5], zed_pose.timestamp);
}
```

```python
# Python
zed_pose = sl.Pose()
if zed.grab(runtime_parameters) == sl.ERROR_CODE.SUCCESS:
    state = zed.get_position(zed_pose, sl.REFERENCE_FRAME.FRAME_CAMERA)
    vx = zed_pose.twist[0]
    vy = zed_pose.twist[1]
    vz = zed_pose.twist[2]
    print("Translation: vx: {0}, vy:  {1}, vz:  {2}, timestamp: {3}\n".format(vx, vy, vz, zed_pose.timestamp))
    x = zed_pose.twist[3]
    y = zed_pose.twist[4]
    z = zed_pose.twist[5]
    print("Orientation: x: {0}, y:  {1}, z: {2}\n".format(x, y, z))
```

```csharp
// C#
Pose zed_pose = new Pose();
RuntimeParameters runtimeParameters = new RuntimeParameters();
if (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
    POSITIONAL_TRACKING_STATE state = zed.GetPosition(ref zed_pose, REFERENCE_FRAME.CAMEERA);
    Console.WriteLine("Linear velocity: vx: " + zed_pose.twist[0] + "vy: " + zed_pose.twist[1] + "z: " + zed_pose.twist[2] + "Timestamp: " + zed_pose.timestamp);
    Console.WriteLine("Angular velocity: x: " + zed_pose.twist[3] + "y: " + zed_pose.twist[4] + "z: " + zed_pose.twist[5]);
}
```

### Saving an Area Map

Area maps can be saved asynchronously during tracking with GEN3 mode enabled.

```cpp
// C++ - Full example
#include <sl/Camera.hpp>
#include <iostream>
#include <thread>

int main(int argc, char **argv) {
    sl::Camera zed;

    sl::InitParameters init_params;
    init_params.depth_mode = sl::DEPTH_MODE::NONE;
    init_params.coordinate_units = sl::UNIT::METER;

    auto status = zed.open(init_params);
    if (status != sl::ERROR_CODE::SUCCESS) {
        std::cout << "Failed to open ZED: " << status << std::endl;
        return -1;
    }

    sl::PositionalTrackingParameters track_params;
    track_params.enable_area_memory = true;
    track_params.mode = sl::POSITIONAL_TRACKING_MODE::GEN3;

    status = zed.enablePositionalTracking(track_params);
    if (status != sl::ERROR_CODE::SUCCESS) {
        std::cout << "Failed to enable tracking: " << status << std::endl;
        return -1;
    }

    std::cout << "Move the camera following the mapping procedure..." << std::endl;

    while (true) {
        if (zed.grab() == sl::ERROR_CODE::SUCCESS) {
            sl::Pose pose;
            zed.getPosition(pose);

            if (/* exit condition */ false)
                break;
        }
    }

    std::string area_file = "environment.area";
    status = zed.saveAreaMap(area_file.c_str());

    if (status == sl::ERROR_CODE::SUCCESS) {
        sl::AREA_EXPORTING_STATE export_state = zed.getAreaExportState();

        while (export_state == sl::AREA_EXPORTING_STATE::RUNNING) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            export_state = zed.getAreaExportState();
        }

        if (export_state == sl::AREA_EXPORTING_STATE::SUCCESS) {
            std::cout << "Successfully saved area map to " << area_file << std::endl;
        } else {
            std::cout << "Failed to save area map: "
                      << sl::toString(export_state).c_str() << std::endl;
        }
    } else {
        std::cout << "Failed to start area save: " << status << std::endl;
    }

    zed.disablePositionalTracking();
    zed.close();
}
```

```python
# Python - Full example
import pyzed.sl as sl
import time

zed = sl.Camera()

init_params = sl.InitParameters()
init_params.depth_mode = sl.DEPTH_MODE.NONE
init_params.coordinate_units = sl.UNIT.METER

status = zed.open(init_params)
if status != sl.ERROR_CODE.SUCCESS:
    print("Failed to open ZED:", status)
    exit(1)

track_params = sl.PositionalTrackingParameters()
track_params.enable_area_memory = True
track_params.mode = sl.POSITIONAL_TRACKING_MODE.GEN3

status = zed.enable_positional_tracking(track_params)
if status != sl.ERROR_CODE.SUCCESS:
    print("Failed to enable tracking:", status)
    exit(1)

print("Move the camera around to record the area...")

while True:
    if zed.grab(runtime) == sl.ERROR_CODE.SUCCESS:
        pass

output_file = "environment.area"
status = zed.save_area_map(output_file)

if status == sl.ERROR_CODE.SUCCESS:
    print("Saving AREA asynchronously...")

    export_state = zed.get_area_export_state()
    while export_state == sl.AREA_EXPORTING_STATE.RUNNING:
        time.sleep(0.01)
        export_state = zed.get_area_export_state()

    if export_state == sl.AREA_EXPORTING_STATE.SUCCESS:
        print("Successfully saved AREA to", output_file)
    else:
        print("Failed to save AREA:", export_state)
else:
    print("Failed to start AREA save:", status)

zed.disable_positional_tracking()
zed.close()
```

```csharp
// C# - Full example
using System;
using System.Threading;
using sl;

class Program {
    static void Main(string[] args) {
        Camera zed = new Camera();

        InitParameters init = new InitParameters();
        init.depthMode = DEPTH_MODE.NONE;
        init.coordinateUnits = UNIT.METER;

        ERROR_CODE status = zed.Open(ref init);
        if (status != ERROR_CODE.SUCCESS) {
            Console.WriteLine("Failed to open ZED: " + status);
            return;
        }

        PositionalTrackingParameters trackParams = new PositionalTrackingParameters();
        trackParams.enableAreaMemory = true;
        trackParams.mode = POSITIONAL_TRACKING_MODE.GEN3;

        status = zed.EnablePositionalTracking(ref trackParams);
        if (status != ERROR_CODE.SUCCESS) {
            Console.WriteLine("Failed to enable tracking: " + status);
            return;
        }

        Console.WriteLine("Move the camera around to record the area...");

        while ( /*insert condition here*/) {
            if (zed.Grab(ref runtime) == ERROR_CODE.SUCCESS) {
                // Just collecting tracking data
            }
        }

        string file = "environment.area";
        status = zed.SaveAreaMap(file);

        if (status == ERROR_CODE.SUCCESS) {
            Console.WriteLine("Saving AREA asynchronously...");

            AREA_EXPORTING_STATE state = zed.GetAreaExportState();
            while (state == AREA_EXPORTING_STATE.RUNNING) {
                Thread.Sleep(10);
                state = zed.GetAreaExportState();
            }

            if (state == AREA_EXPORTING_STATE.SUCCESS) {
                Console.WriteLine("Successfully saved AREA to " + file);
            } else {
                Console.WriteLine("Failed to save AREA: " + state);
            }
        } else {
            Console.WriteLine("Failed to start saving AREA: " + status);
        }

        zed.DisablePositionalTracking();
        zed.Close();
    }
}
```

### Relocalizing within an Area Map

Load a previously saved area file to relocalize the camera within a known environment.

```cpp
// C++
sl::PositionalTrackingParameters tracking_parameters;
tracking_parameters.area_file_path = "example.area";
err = zed.enablePositionalTracking(tracking_parameters);
```

```python
# Python
tracking_parameters = sl.PositionalTrackingParameters()
tracking_parameters.area_file_path = "example.area"
err = zed.enable_positional_tracking(tracking_parameters)
```

```csharp
// C#
PositionalTrackingParameters trackingParams = new PositionalTrackingParameters();
trackingParams.areaFilePath = "example.area";
zed.EnablePositionalTracking(ref trackingParams);
```
