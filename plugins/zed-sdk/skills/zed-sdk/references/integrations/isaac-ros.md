---
description: >
  NVIDIA Isaac ROS integration with ZED cameras -- overview, setup guide,
  NITROS subscriber tutorial, AprilTag detection tutorial, and troubleshooting.
source_urls:
  - https://www.stereolabs.com/docs/isaac-ros/
  - https://www.stereolabs.com/docs/isaac-ros/setting_up_isaac_ros/
  - https://www.stereolabs.com/docs/isaac-ros/tutorial_subscriber/
  - https://www.stereolabs.com/docs/isaac-ros/tutorial_apriltag/
  - https://www.stereolabs.com/docs/isaac-ros/troubleshooting/
fetched: 2026-04-07
---

# ZED Isaac ROS Integration

## Table of Contents

- [Isaac ROS Overview](#isaac-ros-overview)
- [Setting up Isaac ROS](#setting-up-isaac-ros)
- [Subscribe to ZED Topics with NITROS](#subscribe-to-zed-topics-with-nitros)
- [AprilTag Detection](#apriltag-detection)
- [Troubleshooting](#troubleshooting)

---

## Isaac ROS Overview

NVIDIA Isaac ROS is a collection of CUDA-accelerated computing packages and AI models designed to streamline and expedite the development of advanced AI robotics applications.

### ZED ROS 2 Integration

The ZED ROS 2 Wrapper automatically integrates ZED stereo cameras with the NVIDIA Isaac ROS framework, leveraging GPU capabilities for real-time perception tasks.

> **Compatibility Notice**: The ZED ROS2 Wrapper is only compatible with NVIDIA Isaac ROS versions 3.2.x. Version 4.x support for Jetpack 7 and Jetson Thor will arrive in future updates.

### NITROS Support

The build system automatically checks for the presence of NVIDIA Isaac ROS packages, specifically the `isaac_ros_nitros` package. When detected, ZED Camera ROS 2 components build with NITROS support enabled.

**What is NITROS?** NITROS (NVIDIA Isaac Transport for ROS) accelerates ROS data streaming by leveraging GPU memory, enabling high-performance data transfer while bypassing CPU bottlenecks.

**Key Implementation Details:**
- The wrapper uses Managed NITROS publishers to publish images and depth maps directly from GPU memory.
- This eliminates unnecessary data copies and CPU overhead.
- Applications like real-time object detection, mapping, and navigation benefit from improved throughput and reduced latency.

**Fallback Capability:** If the `isaac_ros_nitros` package remains undetected during build, the ZED ROS 2 Wrapper still compiles and functions normally -- NITROS acceleration simply won't be enabled.

**ROS 2 Type Adaptation:** Managed NITROS publishers and subscribers maintain compatibility with standard (non-Isaac) ROS 2 nodes by automatically converting data to standard ROS 2 message types when necessary (for example, rviz2 visualization).

---

## Setting up Isaac ROS

### Key Prerequisites

A solid connection to the internet is required to download the NVIDIA Isaac ROS packages and the Stereolabs software. For Jetson devices, wired connections are recommended for optimal stability and speed.

### NVIDIA Jetson Setup

Before installing Isaac ROS on Jetson devices:

1. Install Python3 and nvidia-jetpack.
2. Configure the VPI library for compute acceleration on Jetson's PVA accelerator.
3. Install an NVMe SSD for Docker image storage (critical for performance).

Docker images are large, and slower storage devices create performance bottlenecks.

### Docker Configuration Path

#### ZED SDK Installation in Docker

The setup requires creating a custom Dockerfile layer to install the ZED SDK within the Isaac ROS Docker environment. Key steps:

- Creating an entrypoint script (`zed-entrypoint.sh`) to manage ZED folder permissions.
- Building a `Dockerfile.zed` that installs the ZED SDK on top of the Isaac ROS base image.
- Modifying installation scripts for either Jetson (aarch64) or x86_64 architectures.

**For Jetson systems**, the script downloads ZED SDK 5.0 from: `https://download.stereolabs.com/zedsdk/5.0/l4t36.4/jetsons`

**For x86_64 systems**, it uses: `https://download.stereolabs.com/zedsdk/5.0/cu12/ubuntu24`

The installation includes dependencies for the ZED ROS 2 Wrapper, such as ros-humble-zed-msgs, robot-localization, and geographic-msgs packages.

#### ZED ROS 2 Wrapper Installation

After Docker setup:

```bash
cd ${ISAAC_ROS_WS}/src
git clone https://github.com/stereolabs/zed-ros2-wrapper.git
cd ..
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --cmake-args=-DCMAKE_BUILD_TYPE=Release
```

### Apt Repository Configuration

For desktop systems (not recommended for Jetson), install Isaac ROS packages directly via Ubuntu's package manager:

1. Set system locale to UTF-8.
2. Install dependencies (gnupg, wget, software-properties-common).
3. Register NVIDIA's GPG key and add the Isaac ROS repository.
4. Install specific packages like `ros-humble-isaac-ros-managed-nitros`.

The guide provides separate repository URLs for US and China CDNs.

### Validation

Test the installation by launching:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<model> enable_ipc:=false
```

> **Important**: Set `enable_ipc` to `false` to avoid conflicts with NITROS transport.

### Persistent Volume Mounts

For Docker deployments, mounting volumes is recommended:
- `/usr/local/zed/settings` for offline calibration files
- `/usr/local/zed/resources` for AI model caching to avoid repeated downloads

### Important Notes

- Different JetPack versions require URL adjustments in installation scripts.
- ZED SDK versions can be changed (e.g., 5.0 to 5.1) by modifying URLs.
- CUDA versions require corresponding URL updates for x86_64 systems.
- Ubuntu version differences need URL path adjustments.

---

## Subscribe to ZED Topics with NITROS

This tutorial demonstrates subscribing to ZED camera topics using NITROS in Isaac ROS nodes. It compares performance between NITROS and standard ROS 2 subscriptions through benchmarking.

### Setup Requirements

**Prerequisites:**
- ZED camera configured and publishing data via `zed-ros2-wrapper`
- Isaac ROS development environment installed
- Docker support available (optional but recommended)

**Installation steps:**

1. Clone the ZED ROS2 examples repository into your workspace.
2. If using Docker, start the Isaac ROS environment:

```bash
./scripts/run_dev.sh -i ros2_humble.zed
```

3. Build the subscriber example:

```bash
colcon build --symlink-install --packages-above zed_isaac_ros_nitros_sub
```

### NITROS Subscription Implementation

#### Component Structure

The implementation uses a C++ ROS 2 component class `ZedNitrosSubComponent` that inherits from `rclcpp::Node`.

Key member variable:

```cpp
std::shared_ptr<nvidia::isaac_ros::nitros::ManagedNitrosSubscriber<
  nvidia::isaac_ros::nitros::NitrosImageView>> _nitrosSub;
```

The subscriber initialization requires topic name specification, Nitros type declaration (e.g., `nitros_image_rgba8_t` or `nitros_image_32FC1_t`), and callback function binding.

The example employs a runtime detection strategy: first receives messages via standard ROS 2 subscription to determine the encoding (image vs. depth), then creates the appropriately-typed NITROS subscriber.

#### Callback structure

```cpp
void nitros_sub_callback(const nvidia::isaac_ros::nitros::NitrosImageView & img)
{
  // Access GPU data and metadata
  img.GetGpuData();
  img.GetEncoding();
  img.GetWidth();
  img.GetHeight();
}
```

### Benchmarking

The example measures and compares:

- **Latency:** Average, minimum, maximum, and standard deviation of message delivery times
- **Frame Rate:** Frequency statistics for received messages
- **CPU Usage:** Processing load during subscription
- **GPU Usage:** Graphics processor utilization

Results are printed to console and optionally saved to CSV format.

### Configuration Parameters

**General section:**
- `grab_resolution`: Native camera resolution (HD1200, HD2K, HD1080, HD720, SVGA, VGA, AUTO)
- `pub_resolution`: Publishing resolution (NATIVE or CUSTOM with downscaling)
- `pub_frame_rate`: Publishing frequency

**Benchmark section:**
- `tot_samples`: Number of samples to process
- `cpu_gpu_load_period`: Measurement interval in milliseconds
- `csv_log_file`: Output filename for results

**Debug section:**
- `debug_nitros`: Enable detailed Nitros information
- `use_pub_timestamps`: Measure latency from publication time

### Launch and Execution

```bash
ros2 launch zed_isaac_ros_nitros_sub zed_nitros_sub_example.launch.py \
  camera_model:=<camera_model> \
  topic_name:=<topic_name>
```

Example for ZED X One GS:

```bash
ros2 launch zed_isaac_ros_nitros_sub zed_nitros_sub_example.launch.py \
  camera_model:=zedxonegs \
  topic_name:=/zed_isaac/zed/rgb/rect/image
```

### Launch File Configuration

The launch file performs:

1. **Container setup:** Uses `component_container_mt` for multi-threaded execution.
2. **ZED wrapper integration:** Launches the camera publisher with IPC disabled.
3. **Component loading:** Registers the NITROS subscriber component.

**Critical settings:**
- `enable_ipc: false` -- NITROS requires this disabled
- `use_intra_process_comms: False` -- Mandatory for NITROS compatibility

### Performance Results Example

Testing on NVIDIA Jetson AGX Orin with ZED X One GS at HD1200 @ 60 FPS:

**DDS (Standard ROS 2):**

| Metric | Value |
|---|---|
| Average Latency | 0.00477946 sec |
| Average Frequency | 60.1756 Hz |
| Average CPU Load | 27.4333% |
| Average GPU Load | 38.6972% |

**NITROS:**

| Metric | Value | Improvement |
|---|---|---|
| Average Latency | 0.000404906 sec | 1080.39% improvement |
| Average Frequency | 59.7909 Hz | -- |
| Average CPU Load | 24.5845% | 11.588% improvement |
| Average GPU Load | 37.1849% | 4.067% improvement |

The NITROS subscriber demonstrated significantly lower latency with comparable frame rates and reduced resource consumption.

---

## AprilTag Detection

This tutorial demonstrates creating an Isaac ROS application using AprilTag detection with ZED cameras.

The application subscribes to ZED camera image streams, converts images to a supported format, detects AprilTags, and publishes detection information. It leverages the NITROS communication framework for efficient GPU memory-based data exchange without unnecessary CPU copies.

> **Note**: Image rectification is not required for AprilTag detection since the ZED Wrapper component handles necessary preprocessing in GPU memory.

### Install Required Packages

Clone the ZED ROS2 Examples repository:

```bash
cd ${ISAAC_ROS_WS}/src && \
git clone https://github.com/stereolabs/zed-ros2-examples.git
```

For Docker environments, start the Isaac ROS environment with ZED support:

```bash
cd ${ISAAC_ROS_WS}/src/isaac_ros_common && \
./scripts/run_dev.sh -i ros2_humble.zed \
-a "-v /usr/local/zed/settings:/usr/local/zed/settings \
    -v /usr/local/zed/resources:/usr/local/zed/resources"
```

Install Isaac ROS AprilTag and Image Processing packages:

```bash
sudo apt-get update && \
sudo apt-get install -y ros-humble-isaac-ros-apriltag ros-humble-isaac-ros-image-proc
```

Build the application:

```bash
cd ${ISAAC_ROS_WS} && \
colcon build --symlink-install --packages-above zed_isaac_ros_april_tag
```

### Configuration

#### AprilTag Parameters (`zed_isaac_ros_april_tag.yaml`)

```yaml
/**:
    ros__parameters:
        size: 0.155
        max_tags: 64
        tile_size: 4
        tag_family: 'tag36h11'
        backends: 'CUDA'
```

**Configuration options:**
- `size`: AprilTag size in meters (e.g., 0.155)
- `max_tags`: Maximum detectable tags (e.g., 64)
- `tile_size`: Adaptive thresholding window size in pixels (e.g., 4)
- `tag_family`: Detection family (CUDA supports only `tag36h11`; CPU/PVA support additional families)
- `backends`: Processing backend (`CPU`, `CUDA`, or `PVA`)

Generate AprilTags using the tool at https://chaitanyantr.github.io/apriltag.html.

#### Camera Parameters (`zed_params.yaml`)

```yaml
/**:
    ros__parameters:
        general:
          grab_resolution: 'HD1080'
          grab_frame_rate: 30
          pub_resolution: 'CUSTOM'
          pub_downscale_factor: 2.0
          pub_frame_rate: 30.0
```

**Configuration options:**
- `grab_resolution`: Native resolution (`HD2K`, `HD1200`, `HD1080`, `HD720`, `SVGA`, `AUTO`)
- `grab_frame_rate`: Internal grabbing rate
- `pub_resolution`: Publishing resolution (`NATIVE` or `CUSTOM`)
- `pub_downscale_factor`: Rescale factor for custom resolution
- `pub_frame_rate`: Data publishing rate

### Running the Application

```bash
ros2 launch zed_isaac_ros_april_tag zed_isaac_ros_april_tag.launch.py camera_model:=<camera_model>
```

Replace `<camera_model>` with your camera (e.g., `zedx`, `zed2i`).

### Visualizing Results

Monitor AprilTag detections:

```bash
ros2 topic echo /tag_detections
```

View the ROS2 topic graph:

```bash
ros2 run rqt_graph rqt_graph
```

> **Note**: AprilTag detection doesn't require ZED depth information, so this works with stereo or monocular cameras.

### Launch File Explanation

The launch file `launch/zed_isaac_ros_april_tag.launch.py` orchestrates node startup:

1. Retrieves camera and AprilTag parameters from YAML configuration files.
2. Creates a ROS 2 component container with `component_container_mt`.
3. Launches the ZED Wrapper as a composable node.
4. Reads resolution from camera configuration.
5. Creates an Image Format Converter (ZED BGRA8 to BGR8).
6. Creates an AprilTag detection node with proper topic remappings.
7. Loads both nodes into the container.

**Launch arguments:**
- `camera_model`: Your ZED camera model
- `disable_tf`: Disable TF broadcasting if set to `True`

### Fixing TF Issues (Optional)

If AprilTag transform frames don't propagate correctly, apply a patch:

```bash
cd ${ISAAC_ROS_WS}/src
git clone https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_apriltag.git
cd isaac_ros_apriltag
git fetch origin pull/64/head:fix_tf
git checkout fix_tf
cd ${ISAAC_ROS_WS}
colcon build --symlink-install --packages-up-to isaac_ros_apriltag
```

Re-run the launch file after building the patched version.

---

## Troubleshooting

### Cannot Start ZED ROS 2 Node

**Problem:**

When attempting to launch the ZED ROS 2 node, users may encounter:

```
[component_container_isolated-3] terminate called after throwing an instance of 'std::invalid_argument'
[component_container_isolated-3]   what():  intraprocess communication allowed only with volatile durability
[ERROR] [component_container_isolated-3]: process has died [pid 1339364, exit code -6, cmd '/opt/ros/humble/lib/rclcpp_components/component_container_isolated --use_multi_threaded_executor --ros-args --log-level info --ros-args -r __node:=zed_container -r __ns:=/zed'].
```

**Root Cause:**

This error occurs when Intra Process Communication (IPC) has not been disabled in the ZED ROS 2 node configuration. The error message explicitly references "intraprocess communication allowed only with volatile durability," indicating a conflict in the middleware settings.

**Solution:**

Launch the ZED ROS 2 node with IPC disabled:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<your_camera_model> enable_ipc:=false
```

Replace `<your_camera_model>` with your specific camera model designation. This parameter disables the intraprocess communication feature, allowing the node to start successfully.
