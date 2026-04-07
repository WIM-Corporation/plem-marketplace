---
description: >
  ZED ROS 2 network and performance tuning reference — DDS and Network tuning,
  Node Frequency Tuning, Hardware Encoding Bridge, and Composition/IPC.
  Extracted from official Stereolabs documentation.
sources:
  - https://www.stereolabs.com/docs/ros2/dds-and-network-tuning/
  - https://www.stereolabs.com/docs/ros2/frequency-tuning/
  - https://www.stereolabs.com/docs/ros2/ros2-sdk-bridge/
  - https://www.stereolabs.com/docs/ros2/ros2-composition/
fetched: 2026-04-07
---

# ZED ROS 2 Network Tuning Reference

## Table of Contents

- [DDS Middleware and Network Tuning](#dds-middleware-and-network-tuning)
  - [Change DDS Middleware](#change-dds-middleware)
  - [Tuning for Large Messages](#tuning-for-large-messages)
  - [Make the Tuning Permanent](#make-the-tuning-permanent)
  - [ROS Domain](#ros-domain)
  - [Change MTU Size](#change-mtu-size)
  - [Use Compressed Topics](#use-compressed-topics)
  - [Use Smaller and Less Frequent Information for Data Preview](#use-smaller-and-less-frequent-information-for-data-preview)
- [Node Frequency Tuning](#node-frequency-tuning)
  - [Key Parameters](#key-parameters)
  - [Minimize End-to-End Latency](#minimize-end-to-end-latency)
  - [Optimize CPU Usage](#optimize-cpu-usage)
  - [Tune Output Frequency of Topics](#tune-output-frequency-of-topics)
- [Hardware Encoding Bridge](#hardware-encoding-bridge)
  - [Architecture](#architecture)
  - [Starting the Server](#starting-the-server)
  - [Starting the Clients](#starting-the-clients)
- [Composition and IPC](#composition-and-ipc)
  - [Single ZED Component in a Single Process](#single-zed-component-in-a-single-process)
  - [Multiple Node Components with IPC](#multiple-node-components-with-ipc)

---

## DDS Middleware and Network Tuning

Source: <https://www.stereolabs.com/docs/ros2/dds-and-network-tuning/>

> **Warning:** If these settings are not applied, ROS 2 nodes will fail to receive and send large data like point clouds or images published by the ZED ROS 2 nodes.

> **Note:** Configuration must be applied to all machines involved in the ROS 2 infrastructure that need to send or receive ZED ROS 2 messages.

### Change DDS Middleware

#### Install Cyclone DDS

Cyclone DDS is the recommended DDS implementation for the ZED ROS 2 Wrapper. It ensures reliable communication with the Nav2 framework, supporting autonomous navigation tasks.

The default DDS middleware in ROS 2 Humble Hawksbill is eProsima's Fast DDS. To use Cyclone DDS:

```bash
sudo apt install ros-$ROS_DISTRO-rmw-cyclonedds-cpp
```

Set the `RMW_IMPLEMENTATION` environment variable in each terminal:

```bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
```

To set automatically, add to `~/.bashrc`:

```bash
echo export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp >> ~/.bashrc
```

### Tuning for Large Messages

All DDS implementations require tuning to handle large messages such as images or point clouds, preventing data loss and system overloading.

#### Reduce Fragment Timeout Time

If any part of a UDP packet's IP fragment is missing, remaining fragments occupy kernel buffer space. On unreliable connections like WiFi, this can fill the kernel buffer.

- **Default value:** 30 seconds
- **New value:** 3 seconds

```bash
sudo sysctl -w net.ipv4.ipfrag_time=3
```

#### Increase Maximum Memory for IP Fragment Reassembly

Prevents buffer overflow. Values may need to be very high to accommodate all data received during the ipfrag_time window.

- **Default value:** 4194304 B (4 MB)
- **New value:** 134217728 (128 MB)

```bash
sudo sysctl -w net.ipv4.ipfrag_high_thresh=134217728
```

#### Increase Maximum Linux Kernel Receive Buffer Size

Cyclone DDS may not deliver large messages reliably despite using reliable settings over wired networks.

- **Default value:** 4194304 (4 MB)
- **New value:** 2147483647 (2 GiB)

```bash
sudo sysctl -w net.core.rmem_max=2147483647
```

#### Increase Minimum Socket Receive Buffer and Maximum Message Size for Cyclone DDS

Create a Cyclone DDS configuration file:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<CycloneDDS xmlns="https://cdds.io/config"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="https://cdds.io/config
            https://raw.githubusercontent.com/eclipse-cyclonedds/cyclonedds/master/etc/cyclonedds.xsd">
  <Domain Id="any">
    <General>
      <Interfaces>
        <NetworkInterface autodetermine="true" priority="default" multicast="default" />
      </Interfaces>
      <AllowMulticast>default</AllowMulticast>
      <MaxMessageSize>65500B</MaxMessageSize>
    </General>
    <Internal>
      <SocketReceiveBufferSize min="10MB"/>
      <Watermarks>
        <WhcHigh>500kB</WhcHigh>
      </Watermarks>
    </Internal>
  </Domain>
</CycloneDDS>
```

Set the `CYCLONEDDS_URI` environment variable:

```bash
export CYCLONEDDS_URI=file:///absolute/path/to/the/configuration/file
```

For more details, refer to the [Eclipse Cyclone DDS Run-time Configuration documentation](https://github.com/eclipse-cyclonedds/cyclonedds).

### Make the Tuning Permanent

#### Network Settings

Create or modify the sysctl configuration file:

```bash
sudo nano /etc/sysctl.d/60-zed-buffers.conf
```

Contents:

```
# IP fragmentation settings
net.ipv4.ipfrag_time=3  # in seconds, default is 30 s
net.ipv4.ipfrag_high_thresh=134217728  # 128 MiB, default is 256 KiB

# Increase the maximum receive buffer size for network packets
net.core.rmem_max=2147483647  # 2 GiB, default is 208 KiB
```

Apply the changes:

```bash
sudo sysctl -p /etc/sysctl.d/60-zed-buffers.conf
```

Validate:

```bash
sysctl net.core.rmem_max net.ipv4.ipfrag_time net.ipv4.ipfrag_high_thresh
```

Expected output:

```
net.core.rmem_max = 2147483647
net.ipv4.ipfrag_time = 3
net.ipv4.ipfrag_high_thresh = 134217728
```

#### Cyclone DDS Settings

Save the configuration file as `~/cyclonedds.xml` and add to `~/.bashrc`:

```bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export CYCLONEDDS_URI=file:///home/user/cyclonedds.xml
```

Replace the path with the actual path to the file.

### ROS Domain

In DDS, the Domain ID is the key mechanism allowing different logical networks to share the same physical network.

ROS 2 nodes within the same domain automatically discover and communicate with each other, while nodes on different domains remain isolated. By default, all ROS 2 nodes use Domain ID 0.

To prevent interference between multiple groups of computers, assign each group a unique Domain ID between 0 and 101 (inclusive).

```bash
export ROS_DOMAIN_ID=<DOMAIN_ID>
```

To set permanently, add to `~/.bashrc`:

```bash
export ROS_DOMAIN_ID=<DOMAIN_ID>
```

> **Note:** All nodes that must communicate in the same ROS 2 infrastructure, including nodes running in Docker images, must use the same ROS Domain setting.

### Change MTU Size

The optimal Maximum Transmission Unit (MTU) value depends on your network environment and message size.

#### Common MTU Values for ROS 2

| MTU Size | Use Case |
|----------|----------|
| 1500 bytes (Default) | Safe choice for mixed networks or devices that may not support jumbo frames. Suitable for smaller messages and standard LAN setups. |
| 9000 bytes (Jumbo Frames) | Recommended for transmitting large data (high-res images, point clouds, video streams). Entire network must support jumbo frames. Ideal for low-latency, high-throughput robotics labs. |
| 4000-6000 bytes (Intermediate) | Middle-ground option if your network supports it but doesn't require full 9000 bytes. |

> **Note:** Not all network interface cards support Jumbo Frames (9000 B). Test configurations with temporary commands to use the largest available MTU.

#### Temporary MTU Setup

Changes for current session only, reverts after reboot:

```bash
sudo ip link set dev INTERFACE_NAME mtu 9000
```

Verify:

```bash
ip link show INTERFACE_NAME
```

#### Permanent MTU Setup

Open Netplan configuration:

```bash
sudo nano /etc/netplan/<config_file_name>
```

Add or modify the MTU value:

```yaml
network:
  version: 2
  ethernets:
    INTERFACE_NAME:
      dhcp4: yes
      mtu: 9000
```

Apply:

```bash
sudo netplan apply
```

Verify:

```bash
ip link show <INTERFACE_NAME>
```

> **Note:** If the `netplan` command is missing (e.g., on NVIDIA Jetson), install it:
> ```bash
> sudo apt install netplan.io
> ```

### Use Compressed Topics

To reduce bandwidth for transmitting image and point cloud messages, subscribe to available compressed topics.

#### Image Topics

The ZED ROS 2 Wrapper uses the `image_transport` package with compression options:

| Transport | Example Topic | Description |
|-----------|---------------|-------------|
| `compressed` | `/zed/zed_node/left/color/rect/image/compressed` | JPEG compression of color images. Recommended if hardware compression is unavailable. |
| `compressedDepth` | `/zed/zed_node/depth/depth_registered/compressedDepth` | Floating point compression of depth maps using PNG. |
| `theora` | `/zed/zed_node/left_gray/color/rect/image/theora` | Frame compression using Theora codec if available. |

#### Point Cloud Topics

The ZED ROS 2 Wrapper uses the `point_cloud_transport` package with compression options:

| Transport | Example Topic | Description |
|-----------|---------------|-------------|
| `draco` | `/zed/zed_node/point_cloud/cloud_registered/draco` | Google Draco lossy compression. |
| `zlib` | `/zed/zed_node/point_cloud/cloud_registered/zlib` | zlib lossless compression. |
| `zstd` | `/zed/zed_node/point_cloud/cloud_registered/zstd` | Facebook Zstandard lossless compression. |

### Use Smaller and Less Frequent Information for Data Preview

When subscribing to image and point cloud data solely for preview purposes, maximum resolution and frame rate are unnecessary.

#### Reduce Data Size

Data size publishing is controlled by two parameters in `config/common.yaml`:

| Parameter | Description |
|-----------|-------------|
| `general.pub_resolution` | Use `'NATIVE'` to publish at grab resolution. Use `'CUSTOM'` to retrieve and publish resized image and depth data. |
| `general.pub_downscale_factor` | Rescale factor applied when `general.pub_resolution` is `'CUSTOM'`. |

Example: If `general.grab_resolution` is `HD720` (1280x720), setting resolution to `'CUSTOM'` with a `2.0` rescale factor publishes at 640x360, optimizing bandwidth for preview without affecting internal processing quality.

#### Reduce Data Publishing Rate

| Parameter | Description |
|-----------|-------------|
| `general.pub_frame_rate` | Controls frequency of color image and depth map publishing. |
| `depth.point_cloud_freq` | Controls frequency of point cloud publishing. |

---

## Node Frequency Tuning

Source: <https://www.stereolabs.com/docs/ros2/frequency-tuning/>

> **Note:** This guide applies only to the `stereolabs::ZedCamera` component for stereo cameras. The `stereolabs::ZedCameraOne` component for monocular cameras does not provide the behaviors described in this section.

The ZED Camera component of the `zed_components` package provides parameters to configure the working frequency of different modules. This allows optimization of node performance according to specific needs.

### Key Parameters

| Parameter | Description |
|-----------|-------------|
| `general.grab_frame_rate` | Maximum frequency at which the node attempts to grab frames. This global parameter affects all modules relying on camera frames. Reflects the ZED SDK's `InitParameters::camera_fps` parameter. |
| `general.grab_compute_capping_fps` | Upper computation limit for grab frequency. Reflects the ZED SDK's `InitParameters::grab_compute_capping_fps` parameter. |
| `general.pub_frame_rate` | Frequency of publishing visual images and depth data messages (excluding point clouds). |
| `depth.point_cloud_freq` | Frequency of publishing point cloud messages. |
| `sensors.sensors_pub_rate` | Maximum frequency of publishing sensor data messages. |

### Minimize End-to-End Latency

The end-to-end latency of the ZED Cameras depends on the grab frequency. The latency is fixed and equal to 2-3 frames for GMSL2 cameras and 3-4 frames for USB3 cameras.

To minimize latency, set `general.grab_frame_rate` to the highest value your camera supports for the selected resolution:

| Camera Model | Resolution | Max Grab Frequency | Expected End-to-End Latency |
|---|---|---|---|
| ZED 2i / ZED Mini | VGA | 100 FPS | ~30/40 msec |
| ZED 2i / ZED Mini | HD720 | 60 FPS | ~50/67 msec |
| ZED 2i / ZED Mini | HD1080 | 30 FPS | ~100/133 msec |
| ZED 2i / ZED Mini | HD2K | 15 FPS | ~200/267 msec |
| ZED X / ZED X Mini | SVGA | 120 FPS | ~17/25 msec |
| ZED X / ZED X Mini | HD1080 / HD1200 | 60 FPS | ~33/50 msec |

### Optimize CPU Usage

To reduce CPU usage while maintaining low latency, set `general.grab_compute_capping_fps` to a value lower than `general.grab_frame_rate`. This limits internal ZED SDK processing frequency without affecting low-level grab behaviors.

The `general.grab_compute_capping_fps` parameter accepts any value from 0.1 FPS up to the `general.grab_frame_rate` value (not restricted to fixed camera values like 15, 30, 60, 100, 120). Setting it to 0.0 disables capping and lets the ZED SDK run at maximum frequency.

This parameter affects the maximum output frequency of:
- Image retrieval
- Depth retrieval (depth maps and point clouds)
- Positional Tracking (odometry, pose, TF publishing)
- Object Detection
- Body Tracking modules

The recommended approach: start with a value equal to `general.grab_frame_rate`, then decrease at runtime while monitoring diagnostic feedback. Optimal values are obtained when the "Data Capture - Mean Frequency" average value is higher than 99.5% of the `general.grab_frame_rate` parameter.

### Tune Output Frequency of Topics

Most robotics applications do not require maximum output frequency for all published topics. Higher output frequencies increase CPU usage through middleware processing and consume greater bandwidth, potentially causing network congestion on wireless connections.

#### Use Case Examples

| Application | Recommendation |
|-------------|----------------|
| Obstacle avoidance | Tune point cloud output frequency to meet safety requirements based on robot maximum speed. |
| Visualization only | Set image topic frequency to provide smooth visualization without CPU or network overload. |
| SLAM applications | Adjust image and depth topic frequency to ensure good SLAM performance without resource constraints. |
| State estimation | Set IMU topic frequency to support the estimation algorithm without overloading the system. |

The `general.pub_frame_rate`, `depth.point_cloud_freq`, and `sensors.sensors_pub_rate` parameters are dynamic, allowing runtime tuning according to application requirements.

Monitor diagnostic feedback to find optimal values balancing performance and resource usage. If you monitor the frequency of a topic using external subscribing tools (e.g., `ros2 topic hz` or `rqt Topic Monitor`) and the obtained frequency is lower than expected, you are probably overloading the middleware processing or the network.

---

## Hardware Encoding Bridge

Source: <https://www.stereolabs.com/docs/ros2/ros2-sdk-bridge/>

The Hardware Encoding Bridge leverages the ZED SDK's Local Streaming module to optimize bandwidth when transmitting data across multiple machines in a ROS 2 network. Rather than using multiple ROS 2 topics, this approach compresses ZED data into a single network stream, especially valuable for high-resolution video streams, point clouds, or bandwidth-constrained networks.

> **Important:** The receiving machine must have a compatible NVIDIA GPU supporting hardware decoding. Both encoding and decoding are GPU-accelerated.

### Architecture

The configuration uses:
- **Streaming Server**: A ZED Wrapper node that encodes and broadcasts data
- **Streaming Clients**: One or more ZED Wrapper nodes that connect to the server instead of directly accessing a camera

Each client node operates independently with selective feature activation. For example, a remote monitoring station might:
- Generate rectified images and point clouds locally
- Disable unnecessary features like Positional Tracking or Object Detection
- Transmit only the compressed stream across the network

Server optimization options include disabling depth processing if not required locally.

### Starting the Server

#### Enable streaming at startup

Set `stream_server.stream_enabled` to `true` in either:
- `config/common_stereo.yaml` (stereo cameras)
- `config/common_mono.yaml` (monocular cameras)

Then launch:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera_model>
```

#### Enable streaming at runtime

```bash
ros2 service call /zed/zed_node/enable_streaming std_srvs/srv/SetBool "{data: true}"
```

Confirmation in logs:

```
[component_container_isolated-2] [INFO] [1767798605.865784805] [zed.zed_node]: Streaming server started
```

#### Server Configuration Parameters

Located in `config/common_stereo.yaml` or `config/common_mono.yaml`:

| Parameter | Description | Values |
|-----------|-------------|--------|
| `stream_server.codec` | Hardware encoding codec | `H264`, `H265` |
| `stream_server.port` | Streaming port (must be even) | Any even number |
| `stream_server.gop_size` | Distance between IDR/I-frames | Higher values = better compression on static scenes but increased latency |
| `stream_server.adaptative_bitrate` | Adjust bitrate based on packet loss | Boolean; varies bitrate between [bitrate/4, bitrate] |
| `stream_server.chunk_size` | Size of each data chunk in bytes | Range: [1024 - 65000] |
| `stream_server.target_framerate` | Output framerate for streaming | 15, 30, 60, or 120 (if supported) |

#### Stopping the server

```bash
ros2 service call /zed/zed_node/enable_streaming std_srvs/srv/SetBool "{data: False}"
```

Logs confirm:

```
[component_container_isolated-2] [INFO] [1767799177.061194120] [zed.zed_node]: Stopping the Streaming Server
[component_container_isolated-2] [INFO] [1767799177.344780234] [zed.zed_node]: Streaming server stopped
```

### Starting the Clients

Once the server runs, configure client nodes with these launch parameters:

| Parameter | Required | Description |
|-----------|----------|-------------|
| `stream_address` | Yes | IP address of the streaming server |
| `stream_port` | No | Port number (default: 30000) |

#### Launch command

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera_model> stream_address:=<server_ip_address> stream_port:=<server_port>
```

#### Obtain server IP address

```bash
hostname -I
```

Or for detailed output:

```bash
ip addr show
```

#### Visualization with RViz2

```bash
ros2 launch zed_display_rviz2 display_zed_cam.launch.py camera_model:=<camera_model> stream_address:=<server_ip_address> stream_port:=<server_port>
```

#### Connection confirmation

**Server-side logs:**

```
[component_container_isolated-2] [ZED][Streaming] Adding Receiver with IP: 192.168.xxx.yyy
```

**Client-side logs:**

```
[component_container_isolated-2] [INFO] [1767802880.393214664] [zeds.zed_node]: === LOCAL STREAMING OPENING ===
[component_container_isolated-2] [2026-01-07 17:21:20 UTC][ZED][INFO] Logging level INFO
[component_container_isolated-2] [2026-01-07 17:21:21 UTC][ZED][INFO] [Init]  Serial Number: S/N xxxxxxxx
[component_container_isolated-2] [2026-01-07 17:21:21 UTC][ZED][INFO] [Init]  Depth mode: NEURAL LIGHT
[component_container_isolated-2] [INFO] [1767802881.944188474] [zeds.zed_node]:  * ZED SDK running on GPU #0
```

#### Key Advantages

- **Reduced bandwidth**: Replaces multiple ROS 2 topics with a single compressed stream
- **GPU acceleration**: Hardware encoding/decoding minimizes CPU overhead
- **Flexible deployment**: Each client independently configures required features
- **Scalability**: Multiple clients connect to a single streaming server

---

## Composition and IPC

Source: <https://www.stereolabs.com/docs/ros2/ros2-composition/>

ROS 2 expanded the concept of nodelet from ROS 1 replacing nodelets with components and introducing the new concept of "Composition."

### Single ZED Component in a Single Process

Run a ZED Node in a single process using the default launch command:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera_model>
```

The launch file creates a ROS 2 Container process called `zed_container`:

```python
container_name_val='zed_container'
distro = os.environ['ROS_DISTRO']
if distro == 'foxy':
    # Foxy does not support the isolated mode
    container_exec='component_container'
else:
    container_exec='component_container_isolated'

zed_container = ComposableNodeContainer(
    name=container_name_val,
    namespace=namespace_val,
    package='rclcpp_components',
    executable=container_exec,
    arguments=['--ros-args', '--log-level', 'info'],
    output='screen',
)
```

Then it loads a `stereolabs::ZedCamera` or `stereolabs::ZedCameraOne` into it:

```python
# ZED Wrapper component
if( camera_model_val=='zed' or
    camera_model_val=='zedm' or
    camera_model_val=='zed2' or
    camera_model_val=='zed2i' or
    camera_model_val=='zedx' or
    camera_model_val=='zedxm' or
    camera_model_val=='virtual'):
    zed_wrapper_component = ComposableNode(
        package='zed_components',
        namespace=namespace_val,
        plugin='stereolabs::ZedCamera',
        name=node_name_val,
        parameters=node_parameters,
        extra_arguments=[{'use_intra_process_comms': True}]
    )
else: # 'zedxonegs' or 'zedxone4k')
    zed_wrapper_component = ComposableNode(
        package='zed_components',
        namespace=namespace_val,
        plugin='stereolabs::ZedCameraOne',
        name=node_name_val,
        parameters=node_parameters,
        extra_arguments=[{'use_intra_process_comms': True}]
    )

full_container_name = '/' + namespace_val + '/' + container_name_val
info = '* Loading ZED node: ' + node_name_val + ' in container: ' + full_container_name
return_array.append(LogInfo(msg=TextSubstitution(text=info)))

load_composable_node = LoadComposableNodes(
    target_container=full_container_name,
    composable_node_descriptions=[zed_wrapper_component]
)
```

### Multiple Node Components with IPC

**Intra Process Communication (IPC)** is an advanced concept in ROS 2 that optimizes performance of nodes running on the same machine.

#### The ZED IPC Tutorial

The ZED IPC tutorial demonstrates how to leverage ROS 2 Composition and Intra-Process Communication to create a new node component that subscribes to point cloud topics published by all ZED Camera node components running within the same process.

Key features:
- **Multiple ZED Nodes**: Initializes and manages multiple ZED Camera nodes within the same process
- **Custom Subscriber Node**: Loads a custom node component subscribing to point cloud topics
- **Zero-Copy Data Transfer**: Utilizes ROS 2 intra-process communication for zero-copy data transfer

#### Usage

```bash
ros2 launch zed_ipc zed_ipc.launch.py cam_names:=[<camera_name_array>] cam_models:=[<camera_model_array>] cam_serials:=[<camera_serial_array>]
```

#### The Code Explained

**Step 1**: Create a ROS 2 Container and load ZED camera components using the multi-camera launch file:

```python
# Call the multi-camera launch file
multi_camera_launch_file = os.path.join(
    get_package_share_directory('zed_multi_camera'),
    'launch',
    'zed_multi_camera.launch.py'
)
zed_multi_camera = IncludeLaunchDescription(
    launch_description_source=PythonLaunchDescriptionSource(multi_camera_launch_file),
    launch_arguments={
        'cam_names': names,
        'cam_models': models,
        'cam_serials': serials,
        'disable_tf': disable_tf
    }.items()
)
actions.append(zed_multi_camera)
```

**Step 2**: Remap topic names. The demo node subscribes to generic `pointcloud_X` topic names, so the launch file must create correct remappings:

```python
# Create topic remappings for the point cloud node
remappings = []
name_array = parse_array_param(names.perform(context))
for i in range(cam_count):
    base_topic = 'pointcloud_' + str(i)
    remap = '/zed_multi/' + name_array[i] + '/point_cloud/cloud_registered'
    remapping = (base_topic, remap)
    remappings.append(remapping)
```

**Step 3**: Create the demo component node that subscribes to Point Cloud topics:

```python
pc_node = ComposableNode(
    package='zed_ipc',
    plugin='stereolabs::PointCloudComponent',
    name='ipc_point_cloud',
    namespace='zed_multi',
    parameters=[{
        'cam_count': cam_count
    }],
    remappings=remappings,
    extra_arguments=[{'use_intra_process_comms': True}]
)
```

**Step 4**: Load the Point Cloud component into the existing ZED Container to leverage IPC:

```python
load_pc_node = LoadComposableNodes(
    composable_node_descriptions=[pc_node],
    target_container='/zed_multi/zed_multi_container'
)
actions.append(load_pc_node)
```

Verify all nodes are running in the same container:

```bash
ros2 component list
```

#### Example

Two ZED X cameras named `zedx_front` and `zedx_rear`:

```bash
ros2 launch zed_ipc zed_ipc.launch.py cam_names:=[zedx_front,zedx_rear] cam_models:=[zedx,zedx] cam_serials:=[xxxxxxxxx,yyyyyyyy]
```

Verification:

```bash
ros2 component list
/zed_multi/zed_multi_container
  1  /zed_multi/zedx_front
  2  /zed_multi/zedx_rear
  3  /zed_multi/ipc_point_cloud
```
