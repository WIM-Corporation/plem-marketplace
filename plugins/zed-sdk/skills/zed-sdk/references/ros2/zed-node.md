---
description: >
  ZED ROS 2 node reference — Getting Started, ZED Stereo Node, ZED Mono Node,
  Custom Stereo Rig, and Custom Messages. Extracted from official Stereolabs documentation.
sources:
  - https://www.stereolabs.com/docs/ros2/
  - https://www.stereolabs.com/docs/ros2/zed-node/
  - https://www.stereolabs.com/docs/ros2/zed-mono-node/
  - https://www.stereolabs.com/docs/ros2/custom-stereo/
  - https://www.stereolabs.com/docs/ros2/custom-msgs/
fetched: 2026-04-07
---

# ZED ROS 2 Node Reference

## Table of Contents

- [Getting Started with ROS 2 and ZED](#getting-started-with-ros-2-and-zed)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
  - [Build Instructions](#build-instructions)
  - [Starting the ZED Node](#starting-the-zed-node)
  - [Displaying ZED Data](#displaying-zed-data)
  - [Available Topics (Quick Reference)](#available-topics-quick-reference)
  - [Launching with SVO Video](#launching-with-svo-video)
  - [Dynamic Reconfiguration](#dynamic-reconfiguration)
  - [Node Diagnostics](#node-diagnostics)
- [ZED Stereo Node](#zed-stereo-node)
  - [Launch](#launch)
  - [Published Topics](#published-topics)
  - [Image Transport](#image-transport)
  - [NVIDIA Isaac ROS Nitros](#nvidia-isaac-ros-nitros)
  - [Point Cloud Transport](#point-cloud-transport)
  - [QoS Profiles](#qos-profiles)
  - [Configuration Parameters (Stereo)](#configuration-parameters-stereo)
  - [Transform Frames](#transform-frames)
  - [Services](#services)
  - [Dynamic Parameters (Stereo)](#dynamic-parameters-stereo)
  - [Assigning GPU to a Camera](#assigning-gpu-to-a-camera)
  - [Node Diagnostic](#node-diagnostic)
- [ZED Mono Node](#zed-mono-node)
  - [Launch (Mono)](#launch-mono)
  - [Published Topics (Mono)](#published-topics-mono)
  - [Image Transport (Mono)](#image-transport-mono)
  - [QoS Profiles (Mono)](#qos-profiles-mono)
  - [Configuration Parameters (Mono)](#configuration-parameters-mono)
  - [Dynamic Parameters (Mono)](#dynamic-parameters-mono)
  - [Transform Frames (Mono)](#transform-frames-mono)
  - [Services (Mono)](#services-mono)
  - [Assigning GPU (Mono)](#assigning-gpu-mono)
- [Custom Stereo Rig](#custom-stereo-rig)
  - [Prerequisites (Custom Stereo)](#prerequisites-custom-stereo)
  - [Calibration Requirements](#calibration-requirements)
  - [Launching with Custom Stereo Rig](#launching-with-custom-stereo-rig)
  - [Technical Details (Custom Stereo)](#technical-details-custom-stereo)
- [Custom Messages](#custom-messages)
  - [Installation (Custom Messages)](#installation-custom-messages)
  - [Heartbeat](#heartbeat)
  - [Health Status](#health-status)
  - [SVO Status](#svo-status)
  - [Plane Detection Result](#plane-detection-result)
  - [Depth Information](#depth-information)
  - [Positional Tracking Status](#positional-tracking-status)
  - [GNSS Fusion Status](#gnss-fusion-status)
  - [Object Detection and Body Tracking](#object-detection-and-body-tracking)

---

## Getting Started with ROS 2 and ZED

Source: <https://www.stereolabs.com/docs/ros2/>

### Overview

The ZED ROS 2 wrapper integrates Stereolabs stereo cameras with ROS 2, providing access to:

- Left and right rectified/unrectified images
- Depth data
- Colored 3D point cloud
- IMU data
- Sensors data
- Visual Inertial Odometry
- Pose tracking with loop closure
- Detected objects
- Human body skeleton

### Prerequisites

- Ubuntu 22.04 (Jammy Jellyfish)
- ZED SDK v4.2 or later
- CUDA dependency
- ROS 2 Humble Hawksbill (LTS)

> **Note:** The ZED ROS 2 Wrapper has limited compatibility with ROS 2 Foxy on Ubuntu 20.04, with certain modules disabled. DDS and network configuration optimization is recommended for maximum performance.

### Build Instructions

```bash
mkdir -p ~/ros2_ws/src/
cd ~/ros2_ws/src/
git clone https://github.com/stereolabs/zed-ros2-wrapper.git
cd ..
sudo apt update
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --cmake-args=-DCMAKE_BUILD_TYPE=Release
echo source $(pwd)/install/local_setup.bash >> ~/.bashrc
source ~/.bashrc
```

The `--symlink-install` option allows modifications without rebuilding. For `zsh`, use `local_setup.zsh` instead.

### Starting the ZED Node

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera model>
```

The launch script uses "manual composition," loads YAML parameters for your camera model, and generates the TF tree from xacro configuration.

### Displaying ZED Data

#### Using RViz 2

```bash
ros2 launch zed_display_rviz2 display_zed_cam.launch.py camera_model:=<camera model>
```

> **Warning:** RViz 2 on NVIDIA Jetson devices is not recommended for heavy tasks like point cloud processing.

### Available Topics (Quick Reference)

**Images:**

| Topic | Description |
|-------|-------------|
| `rgb/color/rect/image` | Color rectified image |
| `rgb/color/raw/image` | Color unrectified image |
| `right/color/rect/image` | Right rectified image |
| `left/color/rect/image` | Left rectified image |
| `confidence/confidence_image` | Confidence map |

**Depth:**

| Topic | Description |
|-------|-------------|
| `depth/depth_registered` | 32-bit depth in meters |

**Point Cloud:**

| Topic | Description |
|-------|-------------|
| `point_cloud/cloud_registered` | 3D colored point cloud (PointCloud2) |

**Position and Path:**

| Topic | Description |
|-------|-------------|
| `odom` | Visual odometry pose |
| `pose` | Camera pose with fusion algorithm |
| `pose_with_covariance` | Camera pose with covariance |
| `path_odom` | Odometry poses sequence |
| `path_map` | Camera poses sequence |

### Launching with SVO Video

Record sequences using the ZED Explorer tool. Launch with recorded video:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera model> svo_path:=<full_path_to_svo_file>
```

With RViz 2:

```bash
ros2 launch zed_display_rviz2 display_zed_cam.launch.py camera_model:=<camera model> svo_path:=<full_path_to_svo_file>
```

The wrapper supports SVO v2 format from ZED SDK v4.1 onward.

### Dynamic Reconfiguration

Parameters marked `[DYNAMIC]` in YAML configuration files can be changed during execution. Modify the files in `zed_wrapper/config` directory for custom configurations.

Set parameters via CLI:

```bash
ros2 param set /zed/zed_node depth.depth_confidence 80
```

Successful parameter changes return: `Set parameter successful`

Invalid parameters generate error messages specifying valid ranges.

Use RQT GUI for dynamic reconfiguration:

```bash
rqt
```

Navigate to `Plugins -> Configuration -> Dynamic Reconfigure`

### Node Diagnostics

The node publishes diagnostic information to the `/diagnostics` topic using the `diagnostic_updater` package. Analyze diagnostics with ROS 2 tools like the RQT Runtime Monitor plugin.

---

## ZED Stereo Node

Source: <https://www.stereolabs.com/docs/ros2/zed-node/>

### Launch

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera model>
```

Supported camera models: `zed`, `zedm`, `zed2`, `zed2i`, `zedx`, `zedxm`, `virtual`.

### Published Topics

> **Note:** Starting from v5.1.0, not all topics are advertised by default. Individual parameters enable/disable each topic's publication.

> **Note:** Topic prefix convention: `~` = `/<namespace>/<node_name>/` where namespace is the `camera_name` parameter value.

#### Status Topics

| Topic | Description |
|-------|-------------|
| `~/status/health` | General node status (custom message) |
| `~/status/heartbeat` | Heartbeat signal for node monitoring (custom message) |

#### Image Streams

Topics follow the convention: `~/<sensor_type>/<color_model>/<rect_type>/image`

**RGB Channel:**

| Topic | Description |
|-------|-------------|
| `~/rgb/color/rect/image` | Rectified color image |
| `~/rgb/color/rect/camera_info` | Color camera calibration data |
| `~/rgb/gray/rect/image` | Rectified grayscale image |
| `~/rgb/gray/rect/camera_info` | Grayscale camera calibration data |
| `~/rgb/color/raw/image` | Unrectified color image |
| `~/rgb/color/raw/camera_info` | Color raw calibration data |
| `~/rgb/gray/raw/image` | Unrectified grayscale image |
| `~/rgb/gray/raw/camera_info` | Grayscale raw calibration data |

**Left Channel:**

| Topic | Description |
|-------|-------------|
| `~/left/color/rect/image` | Left rectified color image |
| `~/left/color/raw/image` | Left unrectified color image |
| `~/left/gray/rect/image` | Left rectified grayscale image |
| `~/left/gray/raw/image` | Left unrectified grayscale image |
| Corresponding `camera_info` topics | Calibration data for each stream |

**Right Channel:**

| Topic | Description |
|-------|-------------|
| `~/right/color/rect/image` | Right rectified color image |
| `~/right/color/raw/image` | Right unrectified color image |
| `~/right/gray/rect/image` | Right rectified grayscale image |
| `~/right/gray/raw/image` | Right unrectified grayscale image |
| Corresponding `camera_info` topics | Calibration data for each stream |

> **Note:** The RGB and left channels are identical; RGB associates with depth, while left/right support stereo processing.

**Stereo Pair:**

| Topic | Description |
|-------|-------------|
| `~/stereo/color/rect/image` | Side-by-side rectified stereo pair |
| `~/stereo/color/raw/image` | Side-by-side unrectified stereo pair |

#### Depth and Point Cloud

| Topic | Description |
|-------|-------------|
| `~/depth/camera_info` | Depth calibration data |
| `~/depth/depth_registered` | Depth map registered to left image |
| `~/depth/depth_info` | Min/max depth information (custom message) |
| `~/point_cloud/cloud_registered` | Registered color point cloud |
| `~/confidence/confidence_map` | Confidence image |
| `~/disparity/disparity_image` | Disparity image |

#### Sensor Data

| Topic | Description |
|-------|-------------|
| `~/left_cam_imu_transform` | Transform from left camera to IMU |
| `~/imu/data` | Fused accelerometer, gyroscope, orientation (Earth frame) |
| `~/imu/data_raw` | Raw accelerometer and gyroscope (Earth frame) |
| `~/imu/mag` | Magnetometer data (ZED 2/2i only) |
| `~/atm_press` | Atmospheric pressure (ZED 2/2i only) |
| `~/temperature/imu` | IMU temperature |
| `~/temperature/left` | Left sensor temperature |
| `~/temperature/right` | Right sensor temperature |

#### Positional Tracking

| Topic | Description |
|-------|-------------|
| `~/pose` | Absolute 3D position/orientation relative to Map frame |
| `~/pose/status` | Tracking module status (custom message) |
| `~/pose_with_covariance` | Camera pose with covariance |
| `~/odom` | Position/orientation relative to Odometry frame |
| `~/odom/status` | Odometry status (custom message) |
| `~/path_map` | Sequence of poses in Map frame |
| `~/path_odom` | Sequence of odometry poses in Map frame |

#### Geo Tracking

| Topic | Description |
|-------|-------------|
| `~/pose/filtered` | GNSS-fused robot pose |
| `~/pose/filtered/status` | GNSS fusion status (custom message) |
| `~/geo_pose/` | Latitude/Longitude pose |
| `~/geo_pose/status` | Geo pose status (custom message) |

#### 3D Mapping

| Topic | Description |
|-------|-------------|
| `~/mapping/fused_cloud` | Fused point cloud (when mapping enabled) |

#### Object Detection

| Topic | Description |
|-------|-------------|
| `~/obj_det/objects` | Detected objects (custom message) |

#### Body Tracking

| Topic | Description |
|-------|-------------|
| `~/body_trk/skeletons` | Detected body skeletons (custom message) |

#### Plane Detection

| Topic | Description |
|-------|-------------|
| `~/plane` | Detected plane (custom message) |
| `~/plane_marker` | Plane visualization for RVIZ 2 |

### Image Transport

The wrapper supports the ROS 2 `image_transport` stack with these standard transports:

- `raw`: Uncompressed image
- `compressed`: JPEG or PNG compressed
- `theora`: Ogg Theora compressed
- `compressedDepth`: Lossless depth compression

Associated `camera_info` topics are published for all compressed streams to maintain proper image-calibration associations.

> **Note:** Image transport topics are unavailable when NVIDIA Isaac ROS Nitros is enabled.

### NVIDIA Isaac ROS Nitros

The wrapper supports NVIDIA Isaac ROS Nitros for zero-copy message transport via NVIDIA GPUDirect RDMA. This optional feature requires manual package installation and is not included as a default dependency.

### Point Cloud Transport

The wrapper supports ROS 2 `pointcloud_transport` (available in Humble Hawksbill and later). Point cloud transport is optional and requires manual installation:

```bash
sudo apt install ros-${ROS_DISTRO}-point-cloud-transport \
  ros-${ROS_DISTRO}-point-cloud-transport-plugins \
  ros-${ROS_DISTRO}-zlib-point-cloud-transport \
  ros-${ROS_DISTRO}-zstd-point-cloud-transport \
  ros-${ROS_DISTRO}-draco-point-cloud-transport
```

Point clouds are published via `point_cloud_transport::Publisher` with both raw and compressed streams available.

### QoS Profiles

All topics use default ROS 2 Quality of Service settings:

| Setting | Value |
|---------|-------|
| Reliability | RELIABLE |
| History (Depth) | KEEP_LAST (10) |
| Durability | VOLATILE |
| Lifespan | Infinite |
| Deadline | Infinite |
| Liveliness | AUTOMATIC |
| Liveliness Lease Duration | Infinite |

#### Durability Compatibility

| Publisher | Subscriber | Connection | Result |
|-----------|------------|------------|--------|
| Volatile | Volatile | Yes | Volatile |
| Volatile | Transient local | No | -- |
| Transient local | Volatile | Yes | Volatile |
| Transient local | Transient local | Yes | Transient local |

#### Reliability Compatibility

| Publisher | Subscriber | Connection | Result |
|-----------|------------|------------|--------|
| Best effort | Best effort | Yes | Best effort |
| Best effort | Reliable | No | -- |
| Reliable | Best effort | Yes | Best effort |
| Reliable | Reliable | Yes | Reliable |

> **Note:** All affected policies must be compatible for a connection to establish.

### Configuration Parameters (Stereo)

#### General Parameters (Namespace: `general`)

| Parameter | Description | Value |
|-----------|-------------|-------|
| `camera_model` | Type of Stereolabs camera | `zed`, `zedm`, `zed2`, `zed2i`, `zedx`, `zedxm`, `virtual` |
| `camera_name` | User name for the camera | string |
| `grab_resolution` | Native camera grab resolution | `HD2K`, `HD1200`, `HD1080`, `HD720`, `SVGA`, `VGA`, `AUTO` |
| `grab_frame_rate` | ZED SDK internal grabbing rate | `15`, `30`, `60`, `90`, `100`, `120` |
| `camera_timeout_sec` | Camera timeout (sec) if communication fails | int |
| `camera_max_reconnect` | Reconnection attempts after timeout | int |
| `camera_flip` | Flip camera data if mounted upside down | `true`, `false` |
| `self_calib` | Enable self-calibration at camera opening | `true`, `false` |
| `serial_number` | Select ZED camera by Serial Number | int |
| `camera_id` | Select ZED camera by ID (0 for first, 1 for second...) | int |
| `pub_resolution` | Resolution for image/depth publishing | `'NATIVE'`, `'CUSTOM'` |
| `pub_downscale_factor` | Rescale factor to reduce bandwidth | double |
| `pub_frame_rate`* | Video/depth publish rate | double |
| `enable_image_validity_check` | Image validity check before processing | int |
| `gpu_id` | GPU device for depth computation | int |
| `optional_opencv_calibration_file` | Path to OpenCV calibration file | string |
| `async_image_retrieval` | Retrieve images at framerate different from grab framerate | `true`, `false` |
| `publish_status` | Enable publishing of node status topics | `true`, `false` |

#### Video Parameters (Namespace: `video`)

| Parameter | Description | Value |
|-----------|-------------|-------|
| `saturation`* | Image saturation | int, [0,8] |
| `sharpness`* | Image sharpness | int, [0,8] |
| `gamma`* | Image gamma | int, [0,8] |
| `auto_exposure_gain`* | Enable auto exposure and auto gain | `true`, `false` |
| `exposure`* | Exposure value if auto-exposure is false | int [0,100] |
| `gain`* | Gain value if auto-exposure is false | int [0,100] |
| `auto_whitebalance`* | Enable auto white balance | `true`, `false` |
| `whitebalance_temperature`* | White balance temperature | int [28,65] |
| `enable_24bit_output` | Enable BGR 24-bit output | `true`, `false` |
| `publish_rgb` | Enable RGB image stream publishing | `true`, `false` |
| `publish_left_right` | Enable Left/Right image streams | `true`, `false` |
| `publish_raw` | Enable raw (unrectified) streams | `true`, `false` |
| `publish_gray` | Enable grayscale streams | `true`, `false` |
| `publish_stereo` | Enable stereo pair streams | `true`, `false` |

**ZED, ZED-M, ZED 2, ZED 2i specific:**

| Parameter | Description | Value |
|-----------|-------------|-------|
| `brightness`* | Image brightness | int, [0,8] |
| `contrast`* | Image contrast | int, [0,8] |
| `hue`* | Image hue | int, [0,11] |

**ZED X, ZED X-M, Virtual specific:**

| Parameter | Description | Value |
|-----------|-------------|-------|
| `exposure_time`* | Real exposure time in microseconds | int, [28,30000] |
| `auto_exposure_time_range_min`* | Min exposure auto control range (us) | int |
| `auto_exposure_time_range_max`* | Max exposure auto control range (us) | int |
| `exposure_compensation`* | Exposure-target compensation | int, [0-100] |
| `analog_gain`* | Real analog gain (sensor) in mDB | int, [1000-16000] |
| `auto_analog_gain_range_min`* | Min sensor gain in automatic control | int |
| `auto_analog_gain_range_max`* | Max sensor gain in automatic control | int |
| `digital_gain`* | Real digital gain (ISP) as factor | int, [1-256] |
| `auto_digital_gain_range_min`* | Min digital ISP gain in automatic control | int |
| `auto_digital_gain_range_max`* | Max digital ISP gain in automatic control | int |
| `denoising`* | Level of denoising on images | int, [0-100] |

#### Depth Parameters (Namespace: `depth`)

| Parameter | Description | Value |
|-----------|-------------|-------|
| `depth_mode` | Depth map quality | `'NEURAL_LIGHT'`, `'NEURAL'`, `'NEURAL_PLUS'` |
| `depth_stabilization` | Enable depth stabilization | int, [0,100] |
| `openni_depth_mode` | OpenNI format (16 bit, millimeters) | int, [0,1] |
| `point_cloud_freq`* | Frequency of pointcloud publishing | double |
| `point_cloud_res` | Resolution for point cloud publishing | `'COMPACT'`, `'REDUCED'` |
| `depth_confidence`* | Depth confidence threshold | int [0,100] |
| `depth_texture_conf`* | Depth texture confidence threshold | int [0,100] |
| `remove_saturated_areas`* | Exclude color saturated areas from depth | `true`, `false` |
| `publish_depth_map` | Enable depth map stream | `true`, `false` |
| `publish_depth_info` | Enable depth info stream | `true`, `false` |
| `publish_point_cloud` | Enable point cloud stream | `true`, `false` |
| `publish_depth_confidence` | Enable depth confidence map stream | `true`, `false` |
| `publish_disparity` | Enable disparity image stream | `true`, `false` |
| `min_depth` | Minimum depth value computed | double |
| `max_depth` | Maximum range for depth | double, ]0.0,20.0] |

#### Positional Tracking Parameters (Namespace: `pos_tracking`)

| Parameter | Description | Value |
|-----------|-------------|-------|
| `pos_tracking_enabled` | Enable positional tracking at start | `true`, `false` |
| `pos_tracking_mode` | Tracking algorithm generation | `'GEN_1'`, `'GEN_2'`, `'GEN_3'` |
| `imu_fusion` | Enable IMU fusion for tracking | `true`, `false` |
| `publish_tf` | Enable odom -> base_link TF | `true`, `false` |
| `publish_map_tf` | Enable map -> odom TF | `true`, `false` |
| `map_frame` | Frame_id of pose message | string |
| `odometry_frame` | Frame_id of odom message | string |
| `area_memory_db_path` | Full path of space memory DB | string |
| `area_memory` | Enable Loop Closing algorithm | `true`, `false` |
| `reset_odom_with_loop_closure` | Auto odometry reset on loop closure | `true`, `false` |
| `depth_min_range` | Remove fixed robot zones from VO evaluation | double |
| `set_as_static` | Camera will be static | `true`, `false` |
| `set_gravity_as_origin` | Align tracking to IMU gravity | `true`, `false` |
| `floor_alignment` | Use floor as height origin | `true`, `false` |
| `initial_base_pose` | Initial reference pose | array |
| `path_pub_rate` | Path messages publishing frequency (Hz) | double |
| `path_max_count` | Max poses in arrays (-1 for infinite) | int |
| `two_d_mode` | Enable planar surface movement mode | `true`, `false` |
| `fixed_z_value` | Fixed Z coordinate if two_d_mode enabled | double |
| `transform_time_offset` | Value added to TF timestamps | double |
| `reset_pose_with_svo_loop` | Reset pose on SVO loop | `true`, `false` |
| `publish_odom_pose` | Enable odometry and pose messages | `true`, `false` |
| `publish_pose_covariance` | Enable pose_with_covariance message | `true`, `false` |
| `publish_cam_path` | Enable path_odom message | `true`, `false` |

#### GNSS Fusion Parameters (Namespace: `gnss_fusion`)

| Parameter | Description | Value |
|-----------|-------------|-------|
| `gnss_fusion_enabled` | Enable NavSatFix fusion into pose data | `true`, `false` |
| `gnss_fix_topic` | Name of GNSS topic (NavSatFix type) | string |
| `gnss_zero_altitude` | Ignore GNSS altitude information | `true`, `false` |
| `h_covariance_mul` | Multiplier for horizontal covariance (X/Y) | double |
| `v_covariance_mul` | Multiplier for vertical covariance (Z) | double |
| `gnss_frame` | TF frame of GNSS sensor | string |
| `publish_utm_tf` | Publish utm -> map TF | `true`, `false` |
| `broadcast_utm_transform_as_parent_frame` | Publish utm -> map or map -> utm TF | `true`, `false` |
| `enable_reinitialization` | Reinitialization during GNSS signal loss | `true`, `false` |
| `enable_rolling_calibration` | Refine VIO/GNSS calibration progressively | `true`, `false` |
| `enable_translation_uncertainty_target` | Account for translation uncertainty | `true`, `false` |
| `gnss_vio_reinit_threshold` | Threshold for GNSS/VIO reinitialization | double |
| `target_translation_uncertainty` | Target translation uncertainty for calibration | double |
| `target_yaw_uncertainty` | Target yaw uncertainty for calibration | double |

#### Mapping Parameters (Namespace: `mapping`)

| Parameter | Description | Value |
|-----------|-------------|-------|
| `mapping_enabled` | Enable/disable mapping module | `true`, `false` |
| `resolution` | Resolution of fused point cloud | double, [0.01, 0.2] |
| `max_mapping_range` | Max depth range while mapping (meters) | double, [-1, 2.0, 20.0] |
| `fused_pointcloud_freq` | Publishing frequency (Hz) of 3D map | double |
| `clicked_point_topic` | Topic from Rviz for plane detection | string |
| `pd_max_distance_threshold` | Plane detection position spread control | double |
| `pd_normal_similarity_threshold` | Plane detection angle spread control | double |
| `publish_det_plane` | Enable detected planes publishing | `true`, `false` |

#### Object Detection Parameters (Namespace: `object_detection`)

| Parameter | Description | Value |
|-----------|-------------|-------|
| `od_enabled` | Auto-enable Object Detection at start | `true`, `false` |
| `enable_tracking` | Track objects across images | `true`, `false` |
| `model` | Detection model | `'MULTI_CLASS_BOX_FAST'`, `'MULTI_CLASS_BOX_MEDIUM'`, `'MULTI_CLASS_BOX_ACCURATE'`, `'PERSON_HEAD_BOX_FAST'`, `'PERSON_HEAD_BOX_ACCURATE'`, `'CUSTOM_YOLOLIKE_BOX_OBJECTS'` |
| `allow_reduced_precision_inference` | Allow lower precision for performance | `true`, `false` |
| `max_range` | Upper depth range for detections [m] | double |
| `prediction_timeout` | Time (sec) for OK state without detection | double |
| `filtering_mode` | Filtering mode for raw detections | `'0'`: NONE, `'1'`: NMS3D, `'2'`: NMS3D_PER_CLASS |

**Object Detection Classes:**

| Parameter | Description | Value |
|-----------|-------------|-------|
| `class.people.enabled`* | Enable detection of people | `true`, `false` |
| `class.people.confidence_threshold`* | Min confidence for people | double, [0,99] |
| `class.vehicles.enabled`* | Enable detection of vehicles | `true`, `false` |
| `class.vehicles.confidence_threshold`* | Min confidence for vehicles | double, [0,99] |
| `class.bags.enabled`* | Enable detection of bags | `true`, `false` |
| `class.bags.confidence_threshold`* | Min confidence for bags | double, [0,99] |
| `class.animal.enabled`* | Enable detection of animals | `true`, `false` |
| `class.animal.confidence_threshold`* | Min confidence for animals | double, [0,99] |
| `class.electronics.enabled`* | Enable detection of electronics | `true`, `false` |
| `class.electronics.confidence_threshold`* | Min confidence for electronics | double, [0,99] |
| `class.fruit_vegetable.enabled`* | Enable detection of fruit/vegetables | `true`, `false` |
| `class.fruit_vegetable.confidence_threshold`* | Min confidence for fruit/vegetables | double, [0,99] |
| `class.sports.enabled`* | Enable detection of sports | `true`, `false` |
| `class.sports.confidence_threshold`* | Min confidence for sports | double, [0,99] |

#### Body Tracking Parameters (Namespace: `body_tracking`)

| Parameter | Description | Value |
|-----------|-------------|-------|
| `bt_enabled` | Enable Body Tracking | `true`, `false` |
| `model` | Detection model | `'HUMAN_BODY_FAST'`, `'HUMAN_BODY_MEDIUM'`, `'HUMAN_BODY_ACCURATE'` |
| `body_format` | Skeleton format | `'BODY_18'`, `'BODY_34'`, `'BODY_38'`, `'BODY_70'` |
| `allow_reduced_precision_inference` | Allow lower precision for performance | `true`, `false` |
| `max_range` | Upper depth range for detections [m] | double |
| `body_kp_selection` | Body selection output | `'FULL'`, `'UPPER_BODY'` |
| `enable_body_fitting` | Apply body fitting | `true`, `false` |
| `enable_tracking` | Track skeletons across images | `true`, `false` |
| `prediction_timeout_s` | Time (sec) for OK state without detection | double |
| `confidence_threshold`* | Min detection confidence for keypoints | double, [0,99] |
| `minimum_keypoints_threshold`* | Min keypoints for valid skeleton | int |

#### Streaming Server Parameters (Namespace: `stream_server`)

| Parameter | Description | Value |
|-----------|-------------|-------|
| `stream_enabled` | Enable streaming server at camera open | `true`, `false` |
| `codec` | Encoding type | `'H264'`, `'H265'` |
| `port` | Streaming port (must be even) | int |
| `bitrate` | Streaming bitrate in Kbits/s | int, [1000-60000] |
| `gop_size` | Max distance between IDR/I-frames | int, [max 256] |
| `adaptative_bitrate` | Adjust bitrate based on packet loss | `true`, `false` |
| `chunk_size` | Stream buffer chunk size in bytes | int, [1024-65000] |
| `target_framerate` | Framerate for streaming output | int |

#### Debug Parameters (Namespace: `debug`)

| Parameter | Description | Value |
|-----------|-------------|-------|
| `sdk_verbose` | ZED SDK verbose level | int, `0` to disable |
| `sdk_verbose_log_file` | Path to SDK log file | string |
| `use_pub_timestamps` | Use ROS time instead of camera time | `true`, `false` |
| `debug_common` | General debug log outputs | `true`, `false` |
| `debug_sim` | Simulation debug log outputs | `true`, `false` |
| `debug_video_depth` | Video/depth debug log outputs | `true`, `false` |
| `debug_camera_controls` | Camera controls debug log outputs | `true`, `false` |
| `debug_point_cloud` | Point cloud debug log outputs | `true`, `false` |
| `debug_positional_tracking` | Positional tracking debug log outputs | `true`, `false` |
| `debug_gnss` | GNSS fusion debug log outputs | `true`, `false` |
| `debug_sensors` | Sensors debug log outputs | `true`, `false` |
| `debug_mapping` | Mapping debug log outputs | `true`, `false` |
| `debug_terrain_mapping` | Terrain mapping debug log outputs | `true`, `false` |
| `debug_object_detection` | Object detection debug log outputs | `true`, `false` |
| `debug_body_tracking` | Body tracking debug log outputs | `true`, `false` |
| `debug_roi` | Region of interest debug log outputs | `true`, `false` |
| `debug_streaming` | Streaming debug log outputs | `true`, `false` |
| `debug_advanced` | Advanced debug log outputs | `true`, `false` |
| `debug_nitros` | Nitros debug log outputs | `true`, `false` |
| `disable_nitros` | Disable NITROS usage for debugging | `true`, `false` |

> **Note:** Parameters marked with `*` are dynamic and can be reconfigured during node execution using `ros2 param set` commands.

### Transform Frames

The ZED ROS 2 wrapper broadcasts multiple coordinate frames. Reference frames can be customized in the launch file.

**Frame Hierarchy:**

| Frame | Description |
|-------|-------------|
| `<camera_name>_camera_link` | ZED base center position |
| `<camera_name>_camera_center` | Middle baseline position (from visual odometry and tracking) |
| `<camera_name>_left_camera` | Left camera position and orientation |
| `<camera_name>_left_camera_optical` | Left camera optical frame |
| `<camera_name>_right_camera` | Right camera position and orientation |
| `<camera_name>_right_camera_optical` | Right camera optical frame |
| `<camera_name>_imu_link` | Inertial data frame origin (not available with ZED) |
| `<camera_name>_mag_link` | Magnetometer frame (ZED2/ZED2i only) |
| `<camera_name>_baro_link` | Barometer frame (ZED2/ZED2i only) |
| `<camera_name>_temp_left_link` | Left temperature frame (ZED2/ZED2i only) |
| `<camera_name>_temp_right_link` | Right temperature frame (ZED2/ZED2i only) |

**TF Tree Structure:**

```
map_frame (map)
  └─ odometry_frame (odom)
       └─ camera_link (<camera_name>_camera_link)
            └─ camera_frame (<camera_name>_camera_center)
                 ├─ left_camera_frame (<camera_name>_left_camera_frame)
                 │    ├─ left_camera_optical (<camera_name>_left_camera_optical)
                 │    └─ imu_frame (<camera_name>_imu_link)
                 └─ right_camera_frame (<camera_name>_right_camera_frame)
                      └─ right_camera_optical (<camera_name>_right_camera_optical)
```

The odometry frame uses visual-inertial odometry only, while the map frame applies positional tracking with sensor fusion and loop closure information per REP105 standards.

### Services

| Service | Description |
|---------|-------------|
| `~/reset_odometry` | Resets odometry values, eliminating Visual Odometry drift |
| `~/reset_pos_tracking` | Restarts tracking algorithm with initial pose from parameter server or latest pose set via `set_pose` |
| `~/set_pose` | Restarts tracking with specified initial camera pose [X, Y, Z, R, P, Y] |
| `~/enable_obj_det` | Enable/disable object detection |
| `~/enable_body_trk` | Enable/disable body tracking |
| `~/enable_mapping` | Enable/disable spatial mapping |
| `~/enable_streaming` | Enable/disable local streaming server |
| `~/start_svo_rec` | Start SVO recording (default: zed.svo in ~/.ros/) |
| `~/stop_svo_rec` | Stop active SVO recording |
| `~/toggle_svo_pause` | Toggle SVO playback pause (requires `general.svo_realtime` false) |
| `~/set_svo_frame` | Set SVO playback to specified frame |
| `~/set_roi` | Set Region of Interest to described polygon |
| `~/reset_roi` | Reset Region of Interest to full image frame |
| `~/toLL` | Convert map coordinates to Latitude/Longitude (GNSS fusion only) |
| `~/fromLL` | Convert Latitude/Longitude to map coordinates (GNSS fusion only) |

**Service Call Example:**

```bash
ros2 service call /zed/zed_node/enable_obj_det std_srvs/srv/SetBool data:\ true\
```

### Dynamic Parameters (Stereo)

Parameters marked with `*` in configuration tables and tagged `[DYNAMIC]` in YAML files support runtime adjustment.

```bash
ros2 param set /zed/zed_node depth.confidence 80
```

Success response: `Set parameter successful`

Error response: `Set parameter failed` with warning explaining the constraint violation.

Dynamic parameters include:
- Video controls (saturation, sharpness, gamma, exposure, gain, white balance, brightness, contrast, hue)
- Depth settings (confidence threshold, texture confidence, stabilization, min/max range)
- Positional tracking (point cloud frequency)
- Object detection (class-specific thresholds, tracking parameters)
- Body tracking (confidence threshold, minimum keypoints)
- Camera exposure and gain (ZED X models)

The `rqt` tool offers graphical configuration via `Configuration` -> `Dynamic Reconfigure` plugin.

### Assigning GPU to a Camera

Specify `gpu_id` in `common_stereo.yaml` for depth computation acceleration. Default value (-1) selects the GPU with the highest CUDA core count. When operating multiple ZED cameras, assign each to a separate GPU.

### Node Diagnostic

The ZED node publishes diagnostic information to `/diagnostics` using the `diagnostic_updater` package. Analysis is available through the Runtime Monitor rqt plugin.

Available diagnostic information:
- Uptime and grab frequency/processing time
- Frame drop rate and input mode
- Video/depth publishing rates and processing times
- Depth mode and point cloud metrics
- GNSS fusion status
- Odometry and localization status
- TF broadcasting rate
- Object detection and body tracking status/rates
- IMU TF broadcasting rate
- Sensor data publishing rate
- Camera internal temperatures
- SVO playback and recording status
- Streaming server status

---

## ZED Mono Node

Source: <https://www.stereolabs.com/docs/ros2/zed-mono-node/>

### Launch (Mono)

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera model>
```

Supported models: `zedxonegs`, `zedxone4k`

### Published Topics (Mono)

Topics follow the naming convention: `~/<sensor_type>/<color_model>/<rect_type>/image`

**RGB Channel:**

| Topic | Description |
|-------|-------------|
| `~/rgb/color/rect/image` | Color rectified image |
| `~/rgb/color/rect/camera_info` | Color camera calibration data |
| `~/rgb/gray/rect/image` | Grayscale rectified image |
| `~/rgb/gray/rect/camera_info` | Grayscale camera calibration data |
| `~/rgb/color/raw/image` | Color unrectified image |
| `~/rgb/color/raw/camera_info` | Color raw calibration data |
| `~/rgb/gray/raw/image` | Grayscale unrectified image |
| `~/rgb/gray/raw/camera_info` | Grayscale raw calibration data |

**Sensors Data:**

| Topic | Description |
|-------|-------------|
| `~/imu/data` | Fused IMU data |
| `~/imu/data_raw` | Raw IMU data |
| `~/temperature` | Temperature data |
| `~/left_cam_imu_transform` | Camera-IMU transform |

### Image Transport (Mono)

The wrapper supports standard ROS 2 image transports:
- `raw` - uncompressed image
- `compressed` - JPEG or PNG compressed image
- `theora` - Ogg Theora compressed image
- `compressedDepth` - depth image with lossless compression

Associated `camera_info` topics are published for all compressed streams.

Supports NVIDIA Isaac ROS Nitros for zero-copy message transport using GPU Direct RDMA (optional, requires manual installation).

### QoS Profiles (Mono)

Default configuration:

| Setting | Value |
|---------|-------|
| Reliability | RELIABLE |
| History (Depth) | KEEP_LAST (10) |
| Durability | VOLATILE |
| Lifespan | Infinite |
| Deadline | Infinite |
| Liveliness | AUTOMATIC |
| Liveliness Lease Duration | Infinite |

**Durability Compatibility:**

| Publisher | Subscriber | Connection | Result |
|-----------|------------|------------|--------|
| Volatile | Volatile | Yes | Compatible |
| Volatile | Transient Local | No | Incompatible |
| Transient Local | Volatile | Yes | Compatible |
| Transient Local | Transient Local | Yes | Compatible |

**Reliability Compatibility:**

| Publisher | Subscriber | Connection | Result |
|-----------|------------|------------|--------|
| Best Effort | Best Effort | Yes | Compatible |
| Best Effort | Reliable | No | Incompatible |
| Reliable | Best Effort | Yes | Compatible |
| Reliable | Reliable | Yes | Compatible |

### Configuration Parameters (Mono)

#### General Parameters (Namespace: `general`)

From `common_mono.yaml`:

| Parameter | Description | Value |
|-----------|-------------|-------|
| `serial_number` | Select ZED camera by serial number | int |
| `pub_resolution` | Output resolution | `'NATIVE'`, `'CUSTOM'` |
| `pub_downscale_factor` | Rescale factor for custom resolution | double |
| `gpu_id` | GPU device for depth computation | int |
| `optional_opencv_calibration_file` | OpenCV calibration file path | string |

From `zedxonegs.yaml` and `zedxone4k.yaml`:

| Parameter | Description | Value |
|-----------|-------------|-------|
| `camera_model` | Camera type | `zedxonegs`, `zedxone4k` |
| `camera_name` | User camera name | string |
| `grab_resolution` | Native grab resolution | `'HD1200'`, `'QHDPLUS'`, `'HD1080'`, `'SVGA'`, `'AUTO'` |
| `grab_frame_rate` | SDK internal grabbing rate | 15, 30, 60, 90, 100, 120 |

#### Streaming Server Parameters (Namespace: `stream_server`)

From `common_mono.yaml`:

| Parameter | Description | Value |
|-----------|-------------|-------|
| `stream_enabled` | Enable streaming server | `true`, `false` |
| `codec` | Encoding type | `'H264'`, `'H265'` |
| `port` | Streaming port (must be even) | int |
| `bitrate` | Streaming bitrate in Kbits/s | int: 1000-60000 |
| `gop_size` | Max distance between IDR/I-frames | int: max 256 |
| `adaptative_bitrate` | Adjust bitrate based on packet loss | `true`, `false` |
| `chunk_size` | Stream buffer chunk size | int: 1024-65000 |
| `target_framerate` | Output framerate | 15, 30, 60, 100 |

#### Video Parameters (Namespace: `video`)

From `common_mono.yaml` (`*` = dynamic parameter):

| Parameter | Description | Value |
|-----------|-------------|-------|
| `saturation`* | Image saturation | int: 0-8 |
| `sharpness`* | Image sharpness | int: 0-8 |
| `gamma`* | Image gamma | int: 0-8 |
| `auto_whitebalance`* | Enable auto white balance | `true`, `false` |
| `whitebalance_temperature`* | White balance temperature | int: 28-65 |
| `exposure_time`* | Real exposure time in microseconds | int: 28-30000 |
| `auto_exposure_time_range_min`* | Min exposure auto control range | int |
| `auto_exposure_time_range_max`* | Max exposure auto control range | int |
| `exposure_compensation`* | Exposure target compensation | int: 0-100 |
| `analog_gain`* | Real analog sensor gain in mDB | int: 1000-16000 |
| `auto_analog_gain_range_min`* | Min sensor gain auto control | int |
| `auto_analog_gain_range_max`* | Max sensor gain auto control | int |
| `digital_gain`* | Real digital ISP gain as factor | int: 1-256 |
| `auto_digital_gain_range_min`* | Min digital gain auto control | int |
| `auto_digital_gain_range_max`* | Max digital gain auto control | int |
| `denoising`* | Denoising level for images | int: 0-100 |
| `enable_24bit_output` | Enable BGR 24-bit output | `true`, `false` |
| `publish_rgb` | Enable RGB image publishing | `true`, `false` |
| `publish_raw` | Enable raw image publishing | `true`, `false` |
| `publish_gray` | Enable grayscale publishing | `true`, `false` |

From `zedxone4k.yaml`:

| Parameter | Description | Value |
|-----------|-------------|-------|
| `enable_hdr` | Enable HDR mode if supported | `true`, `false` |

#### Sensors Parameters (Namespace: `sensors`)

From `common_mono.yaml` (`*` = dynamic parameter):

| Parameter | Description | Value |
|-----------|-------------|-------|
| `publish_imu_tf` | Enable IMU TF broadcasting | `true`, `false` |
| `sensors_pub_rate`* | Sensors data publishing frequency | double |
| `publish_imu` | Advertise IMU topic | `true`, `false` |
| `publish_imu_raw` | Advertise raw IMU topic | `true`, `false` |
| `publish_cam_imu_transf` | Advertise CAMERA-IMU transformation | `true`, `false` |
| `publish_temp` | Advertise temperature topics | `true`, `false` |

#### Debug Parameters (Namespace: `debug`)

From `common_mono.yaml`:

| Parameter | Description | Value |
|-----------|-------------|-------|
| `sdk_verbose` | ZED SDK verbose level | int: 0 = disable |
| `sdk_verbose_log_file` | SDK log file path | string |
| `use_pub_timestamps` | Use ROS time instead of camera time | `true`, `false` |
| `debug_common` | General debug logs | `true`, `false` |
| `debug_video_depth` | Video/depth debug logs | `true`, `false` |
| `debug_camera_controls` | Camera controls debug | `true`, `false` |
| `debug_sensors` | Sensors debug logs | `true`, `false` |
| `debug_streaming` | Streaming debug logs | `true`, `false` |
| `debug_advanced` | Advanced debug logs | `true`, `false` |
| `debug_nitros` | Nitros debug logs | `true`, `false` |
| `disable_nitros` | Disable NITROS if available | `true`, `false` |

### Dynamic Parameters (Mono)

Parameters marked with `[DYNAMIC]` can be reconfigured during node execution:

```bash
ros2 param set /zed/zed_node video.exposure_time 5000
```

Success response: `Set parameter successful`

Error response includes parameter name and constraint violation details.

Use `rqt` tool plugin `Configuration` -> `Dynamic Reconfigure` for graphical interface.

### Transform Frames (Mono)

The wrapper broadcasts multiple coordinate frames:

| Frame | Description |
|-------|-------------|
| `<camera_name>_camera_link` | ZED base center position/orientation (bottom central fixing hole) |
| `<camera_name>_camera_center` | ZED middle baseline from visual odometry and tracking |
| `<camera_name>_camera_frame` | ZED CMOS sensor position/orientation |
| `<camera_name>_camera_optical` | ZED camera optical frame position/orientation |
| `<camera_name>_imu_link` | Inertial data frame origin (not available with ZED) |

Reference frames can be changed in launch files.

### Services (Mono)

| Service | Description |
|---------|-------------|
| `~/enable_streaming` | Enable/disable local streaming server |

**Service Call Example:**

```bash
ros2 service call /zed/zed_node/enable_streaming std_srvs/srv/SetBool "{data: True}"
```

Response example:

```
requester: making request: std_srvs.srv.SetBool_Request(data=True)

response:
std_srvs.srv.SetBool_Response(success=True, message='Streaming Server started')
```

### Assigning GPU (Mono)

Specify `gpu_id` in `common_mono.yaml` to select GPU for depth computation. Default value (-1) selects GPU with highest CUDA core count. For multiple ZEDs, assign each to a different GPU to optimize performance.

> **Note:** Starting from ROS 2 Wrapper version 5.1.0, image topic naming convention changed from `~/<sensor_type>/image_<rect_type>_<color_model>` format. Update launch files and scripts to use new topic names.

---

## Custom Stereo Rig

Source: <https://www.stereolabs.com/docs/ros2/custom-stereo/>

The ROS 2 Wrapper supports custom stereo rigs created with a dual ZED X One camera setup.

### Prerequisites (Custom Stereo)

You must follow the Dual ZED X One - Stereo guide to properly connect and configure the cameras for stereo operations.

### Calibration Requirements

Before using the Custom Stereo Rig with ROS 2, you must calibrate the system to ensure accurate depth perception and 3D reconstruction.

You can use the OpenCV ZED Calibration Tool to perform the calibration with a guided procedure.

Once the custom stereo rig is calibrated, ensure that the ZED ROS 2 Wrapper can access the calibration parameters by:
- Copying the `SNxxxxxxx.conf` file to the `/usr/local/zed/settings/` folder, OR
- Setting the `general.optional_opencv_calibration_file` parameter to the path of your OpenCV calibration file

### Launching with Custom Stereo Rig

Set `virtual` as the camera model and specify the serial numbers or camera IDs of both ZED X One cameras.

Using camera IDs:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=virtual camera_ids:=[0,1]
```

Using serial numbers:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=virtual camera_serial_numbers:=[123456789,987654321]
```

### Technical Details (Custom Stereo)

The ZED ROS 2 Wrapper internally uses the `sl::generateVirtualStereoSerialNumber` ZED SDK API function to create a unique serial number identifier for the custom stereo rig based on the serial numbers of the two connected cameras. This allows the node to correctly identify and utilize the stereo configuration.

> **Note:** It is not required to pass information about the baseline distance between the two cameras to the launch file or to the node, as this information is automatically retrieved from the calibration file and used by the ZED ROS 2 Wrapper node to set up the TF frames accordingly.

---

## Custom Messages

Source: <https://www.stereolabs.com/docs/ros2/custom-msgs/>

### Installation (Custom Messages)

Custom messages are defined in the [zed-ros2-interfaces](https://github.com/stereolabs/zed-ros2-interfaces) repository and installed via:

```bash
sudo apt install ros-<ros2-distro>-zed-msgs
```

### Heartbeat

`zed_interfaces/Heartbeat` -- published on `~/status/heartbeat`:

```
uint64 beat_count
string node_ns
string node_name
string full_name
uint32 camera_sn
bool svo_mode
bool simul_mode
```

### Health Status

`zed_interfaces/HealthStatusStamped` -- published on `~/status/health`:

```
std_msgs/Header header
uint32 serial_number
string camera_name
bool low_image_quality
bool low_lighting
bool low_depth_reliability
bool low_motion_sensors_reliability
```

### SVO Status

`zed_interfaces/SVOStatus` -- published on `~/status/svo`:

```
string file_name
uint8 status
uint8 STATUS_PLAYING=0
uint8 STATUS_PAUSED=1
uint8 STATUS_END=2
uint64 frame_ts
uint32 frame_id
uint32 total_frames
bool loop_active
uint32 loop_count
bool real_time_mode
```

### Plane Detection Result

`zed_interfaces/PlaneStamped`:

```
std_msgs/Header header
shape_msgs/Mesh mesh
shape_msgs/Plane coefficients
geometry_msgs/Point32 normal
geometry_msgs/Point32 center
geometry_msgs/Transform pose
float32[2] extents
geometry_msgs/Polygon bounds
```

### Depth Information

`zed_interfaces/DepthInfoStamped`:

```
std_msgs/Header header
float32 min_depth
float32 max_depth
```

### Positional Tracking Status

`zed_interfaces/PosTrackStatus`:

```
uint8 SEARCHING=0
uint8 OK=1
uint8 OFF=2
uint8 FPS_TOO_LOW=3
uint8 SEARCHING_FLOOR_PLANE=3
uint8 status
```

### GNSS Fusion Status

`zed_interfaces/GNSSFusionStatus` -- published on `~/pose/filtered/status`:

```
uint8 OK=0
uint8 OFF=1
uint8 CALIBRATION_IN_PROGRESS=2
uint8 RECALIBRATION_IN_PROGRESS=3
uint8 gnss_fusion_status
```

### Object Detection and Body Tracking

`zed_interfaces/ObjectsStamped`:

```
std_msgs/Header header
zed_interfaces/Object[] objects
```

#### Object Message Structure

```
string label
int16 label_id
string sublabel
float32 confidence
float32[3] position
float32[6] position_covariance
float32[3] velocity
bool tracking_available
int8 tracking_state
int8 action_state
zed_msgs/BoundingBox2Di bounding_box_2d
zed_msgs/BoundingBox3D bounding_box_3d
float32[3] dimensions_3d
zed_msgs/BoundingBox2Df head_bounding_box_2d
zed_msgs/BoundingBox3D head_bounding_box_3d
float32[3] head_position
bool skeleton_available
int8 body_format
zed_msgs/Skeleton2D skeleton_2d
zed_msgs/Skeleton3D skeleton_3d
```

#### Bounding Box Types

**BoundingBox2Df:**

```
zed_interfaces/Keypoint2Df[4] corners
```

**BoundingBox2Di:**

```
zed_interfaces/Keypoint2Di[4] corners
```

**BoundingBox3D:**

```
zed_interfaces/Keypoint3D[8] corners
```

#### Keypoint Types

| Type | Definition |
|------|------------|
| `Keypoint2Df` | `float32[2] kp` |
| `Keypoint2Di` | `uint32[2] kp` |
| `Keypoint3D` | `float32[3] kp` |

#### Skeleton Types

| Type | Definition |
|------|------------|
| `Skeleton2D` | `zed_interfaces/Keypoint2Df[70] keypoints` |
| `Skeleton3D` | `zed_interfaces/Keypoint3D[70] keypoints` |
