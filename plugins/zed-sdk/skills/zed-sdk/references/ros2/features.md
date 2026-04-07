---
description: "ZED ROS 2 features — RViz2, Video, Depth, Positional Tracking, Geo Tracking, Plane Detection, ROI, Recording & Replay"
source_urls:
  - https://www.stereolabs.com/docs/ros2/rviz2/
  - https://www.stereolabs.com/docs/ros2/video/
  - https://www.stereolabs.com/docs/ros2/depth-sensing/
  - https://www.stereolabs.com/docs/ros2/positional-tracking/
  - https://www.stereolabs.com/docs/ros2/geo-tracking/
  - https://www.stereolabs.com/docs/ros2/plane-detection/
  - https://www.stereolabs.com/docs/ros2/region-of-interest/
  - https://www.stereolabs.com/docs/ros2/record-and-replay-data-with-ros-wrapper/
fetched: 2026-04-07
---

# ZED ROS 2 Features

## Table of Contents

- [Data Display with RViz2](#data-display-with-rviz2)
  - [Global Options](#global-options)
  - [Grid](#grid)
  - [Robot Model](#robot-model)
  - [TF (Transform)](#tf-transform)
  - [Video](#video)
  - [Depth Sensing](#depth-sensing)
  - [Positional Tracking](#positional-tracking)
  - [Object Detection](#object-detection)
  - [Body Tracking](#body-tracking)
  - [Plane Detection](#plane-detection)
- [Using Video Capture with ROS 2](#using-video-capture-with-ros-2)
  - [Video with RViz 2](#video-with-rviz-2)
    - [Camera Plugin](#camera-plugin)
    - [Image Plugin](#image-plugin)
  - [Video Subscribing in C++](#video-subscribing-in-c)
    - [Introduction](#introduction)
    - [Running the Tutorial](#running-the-tutorial)
    - [Sample Output](#sample-output)
    - [The Code](#the-code)
    - [Code Explanation](#code-explanation)
- [Using Depth Perception with ROS 2](#using-depth-perception-with-ros-2)
  - [Depth with RViz 2](#depth-with-rviz-2)
    - [Depth Image](#depth-image)
    - [Pointcloud](#pointcloud)
    - [Confidence](#confidence)
  - [Depth Subscribing in C++](#depth-subscribing-in-c)
    - [Introduction](#introduction-1)
    - [Running the Tutorial](#running-the-tutorial-1)
    - [The Code](#the-code-1)
    - [Code Explanation](#code-explanation-1)
- [Using Positional Tracking with ROS 2](#using-positional-tracking-with-ros-2)
  - [Position with RViz 2](#position-with-rviz-2)
    - [Camera Pose](#camera-pose)
    - [Camera Path](#camera-path)
  - [Position Info Subscribing in C++](#position-info-subscribing-in-c)
    - [Introduction](#introduction-2)
    - [Running the Tutorial](#running-the-tutorial-2)
    - [Code Example](#code-example)
    - [Code Explanation](#code-explanation-2)
- [Geo Tracking](#geo-tracking)
- [Plane Detection](#plane-detection-1)
- [Region of Interest](#region-of-interest)
- [Record and Replay](#record-and-replay-camera-data-with-ros-2)

---

## Data Display with RViz2

RViz is a graphical visualization tool for ROS that displays various data types through plugins. RViz 2 is the ROS 2-compatible version. The `zed_display_rviz2` package provides a pre-configured launch script called `display_zed_cam.launch.py` for ZED camera visualization.

> **Note:** RViz 2 is resource-intensive and shares GPU resources with the ZED SDK. Running it on NVIDIA Jetson devices is not recommended, as it may degrade active node performance. For optimal results, run RViz 2 on a separate computer connected to the same ROS 2 network.

### Global Options

Configure these parameters for proper ZED camera data visualization:

- **Fixed frame**: Set to the reference frame (typically `map` or `odom`)
- **Frame rate**: Controls 3D view update frequency; lower values reduce GPU load

GPU resource competition with the ZED SDK may cause performance issues. If needed, reduce the Frame Rate setting or run RViz 2 on a separate networked computer.

### Grid

This plugin displays a spatial reference grid, typically representing the floor plane. It helps orient objects and frames in the 3D scene.

**Key parameters:**

- `Reference frame`: Frame used for grid coordinates (normally the fixed frame)
- `Plane cell count`: Grid size in cells
- `Normal cell count`: Cells perpendicular to grid plane (normally: 0)
- `Cell size`: Dimensions in meters per cell
- `Plane`: Two axes defining the grid plane

### Robot Model

Visualizes the robot's 3D structure as defined in its URDF (Unified Robot Description Format) file, displaying links and joints.

**Key parameters:**

- `Visual enabled`: Toggle 3D visualization
- `Description Source`: Choose `File` (Topic option not fully functional)
- `Description File`: URDF file path (e.g., `zed.urdf` or `zedm.urdf`)

Expanding the Links section reveals the complete model tree with joints and spatial positioning relative to the fixed frame.

### TF (Transform)

Provides visual representation of the transform tree, displaying coordinate frame positions and orientations throughout the system.

**Key parameters:**

- `Show names`: Toggle link name visualization
- `Show axes`: Toggle frame axes visualization
- `Show arrows`: Toggle frame connection arrows
- `Marker Scale`: Rescale TF objects for visibility
- `Update interval`: Update frequency in seconds (0 for each update)

A key feature enables selective visualization of individual frames, reducing clutter and focusing analysis on relevant transform relationships.

### Video

Refer to the Video with RViz 2 tutorial for configuring plugins and topics to display real-time camera images within RViz 2.

### Depth Sensing

Consult the Depth with RViz 2 tutorial for configuring visualization of real-time depth maps from your ZED camera.

### Positional Tracking

See the Positional Tracking with RViz 2 tutorial for displaying camera pose and trajectory data in real time to monitor localization and movement.

### Object Detection

Follow the Object Detection with RViz 2 tutorial to visualize detection results using the custom Stereolabs plugin, displaying detected objects and attributes.

### Body Tracking

Refer to the Body Tracking with RViz 2 tutorial for setting up visualization of detected bodies and their attributes using custom plugins.

### Plane Detection

Consult the Plane Detection with RViz 2 tutorial for displaying detected planes and their attributes in real time within RViz 2.

---

## Using Video Capture with ROS 2

### Video with RViz 2

This section explains how to configure RViz 2 to visualize video data from the ZED node using two different visualization plugins.

#### Camera Plugin

The Camera plugin displays image data from `sensor_msgs/Image` topics and renders virtual objects in front of the camera feed.

**Key Parameters:**

- **Topic**: Selects which image topic to visualize
- **Depth**: Queue depth for incoming messages
- **History policy**: "Keep Last" recommended for performance
- **Reliability Policy**: "Best Effort" for performance; "Reliable" for compatibility
- **Durability Policy**: "Volatile" suggested for compatibility

The Visibility section allows selective display of active plugins in the camera view.

#### Image Plugin

The Image plugin visualizes `sensor_msgs/Image` topics in a dedicated display panel.

**Key Parameters:**

- **Topic**: Selects the image topic from available options
- **Depth**: Incoming message queue depth
- **History policy**: "Keep Last" recommended
- **Reliability Policy**: "Best Effort" preferred; "Reliable" for compatibility
- **Durability Policy**: "Volatile" recommended

### Video Subscribing in C++

This section demonstrates how to create a C++ node that subscribes to image messages from the ZED node.

#### Introduction

Launch the ZED node with:

```bash
ros2 launch zed_display_rviz2 display_zed_cam.launch.py camera_model:=<camera model>
```

The node only publishes when subscribers are connected.

#### Running the Tutorial

Execute the subscriber node:

```bash
ros2 run stereolabs_zed_tutorial_video stereolabs_zed_tutorial_video
```

With topic remapping for ZED:

```bash
ros2 run zed_tutorial_video zed_tutorial_video --ros-args \
  -r left_image:=/zed/zed_node/left/color/rect/image \
  -r right_image:=/zed/zed_node/right/color/rect/image
```

#### Sample Output

```
[INFO] [zed_video_tutorial]: Left  Rectified image received from ZED
       Size: 1280x720 - Timestamp: 1602576933.791896880 sec 
[INFO] [zed_video_tutorial]: Right Rectified image received from ZED
       Size: 1280x720 - Timestamp: 1602576933.891931106 sec
```

#### The Code

```cpp
#include <rclcpp/rclcpp.hpp>
#include <rclcpp/qos.hpp>
#include <sensor_msgs/msg/image.hpp>

rclcpp::Node::SharedPtr g_node = nullptr;

void imageRightRectifiedCallback(const sensor_msgs::msg::Image::SharedPtr msg) {
    RCLCPP_INFO(g_node->get_logger(),
                "Right Rectified image received from ZED\tSize: %dx%d - Timestamp: %u.%u sec ",
                msg->width, msg->height,
                msg->header.stamp.sec,msg->header.stamp.nanosec);
}

void imageLeftRectifiedCallback(const sensor_msgs::msg::Image::SharedPtr msg) {
    RCLCPP_INFO(g_node->get_logger(),
                "Left  Rectified image received from ZED\tSize: %dx%d - Timestamp: %u.%u sec ",
                msg->width, msg->height,
                msg->header.stamp.sec,msg->header.stamp.nanosec);
}

int main(int argc, char* argv[]) {
    rclcpp::init(argc, argv);
    
    g_node = rclcpp::Node::make_shared("zed_video_tutorial");
    
    rclcpp::QoS video_qos(10);
    video_qos.keep_last(10);
    video_qos.best_effort();
    video_qos.durability_volatile();
    
    auto right_sub = g_node->create_subscription<sensor_msgs::msg::Image>(
                "right_image", video_qos, imageRightRectifiedCallback );
    
    auto left_sub = g_node->create_subscription<sensor_msgs::msg::Image>(
                "left_image", video_qos, imageLeftRectifiedCallback );
    
    rclcpp::spin(g_node);
    rclcpp::shutdown();
    
    return 0;
}
```

#### Code Explanation

**Callbacks:** The image callbacks receive `std::shared_ptr` to messages, accessing properties like width, height, and timestamp without manual memory management.

**QoS Configuration:** The ZED component node uses a default QoS profile with reliability set as RELIABLE and durability set as VOLATILE.

**Node Creation:** Uses `rclcpp::Node::make_shared()` to instantiate the node, followed by creating subscriptions to left and right image topics with compatible QoS settings.

> **Note:** The tutorial uses non-subclassed node instantiation, which differs from ROS 2 best practices for node composition. More contemporary examples use subclassed approaches for composability.

### Conclusion

Complete source code is available on [GitHub in the zed_video_tutorial package](https://github.com/stereolabs/zed-ros2-examples/tree/master/tutorials/zed_video_tutorial), including `package.xml` and `CMakeLists.txt` configuration files.

---

## Using Depth Perception with ROS 2

### Depth with RViz 2

This section explains how to configure RViz 2 sessions to visualize depth data in various formats.

#### Depth Image

The `Image` plugin displays depth data published as `sensor_msgs/Image` topics. Since depth data uses 32-bit floating-point encoding rather than 8-bit standard format, special parameters apply:

- **Normalize range**: Automatically calculates conversion range from floating-point to 8-bit grayscale
- **Min value**: Manual minimum depth range in meters (when normalize is unchecked)
- **Max value**: Manual maximum depth range in meters (when normalize is unchecked)

Manual normalization proves useful when you know maximum measured depth and want to maintain consistent image scaling.

#### Pointcloud

The `Pointcloud2` plugin visualizes `sensor_msgs/Pointcloud2` topics. Key parameters include:

- **Topic**: Selects which point cloud message to display
- **Depth**: Queue depth for incoming messages
- **History policy**: "Keep Last" recommended for performance
- **Reliability Policy**: "Best Effort" for performance, "Reliable" for compatibility
- **Durability Policy**: "Volatile" suggested
- **Style**: "Points" with "Size=1" maximizes frame rate
- **Color transformer**: "RGB8" matches color to depth pixels; "Axis color" creates color proportional to axis value

When mapping is enabled, the plugin also visualizes the fused point cloud from mapping operations via the `/zed/zed_node/point_cloud/fused_cloud_registered` topic.

#### Confidence

Visualize the `Confidence Map` using the `Image` plugin on the `~/confidence/confidence_image` topic. Lighter pixels indicate more reliable depth measurements.

### Depth Subscribing in C++

This tutorial demonstrates writing a C++ node that subscribes to `sensor_msgs/Image` messages to retrieve depth data and calculate distance at image center.

#### Introduction

Launch the ZED node with:

```bash
ros2 launch zed_display_rviz2 display_zed_cam.launch.py camera_model:=<camera model>
```

The ZED node only publishes when other nodes subscribe to its topics.

#### Running the Tutorial

Execute the compiled tutorial:

```bash
ros2 run zed_tutorial_depth zed_tutorial_depth
```

Remap to the correct topic:

```bash
ros2 run zed_tutorial_depth zed_tutorial_depth --ros-args -r depth:=/zed/zed_node/depth/depth_registered
```

Expected output shows center distance measurements in meters, with "nan" values where no valid depth exists.

#### The Code

```cpp
#include "rclcpp/rclcpp.hpp"
#include "sensor_msgs/msg/image.hpp"

using namespace std::placeholders;

class MinimalDepthSubscriber : public rclcpp::Node {
  public:
    MinimalDepthSubscriber()
        : Node("zed_depth_tutorial") {

        rclcpp::QoS depth_qos(10);
        depth_qos.keep_last(10);
        depth_qos.best_effort();
        depth_qos.durability_volatile();

        mDepthSub = create_subscription<sensor_msgs::msg::Image>(
                   "depth", depth_qos,
                   std::bind(&MinimalDepthSubscriber::depthCallback, this, _1) );
    }

  protected:
    void depthCallback(const sensor_msgs::msg::Image::SharedPtr msg) {
        float* depths = (float*)(&msg->data[0]);

        int u = msg->width / 2;
        int v = msg->height / 2;

        int centerIdx = u + msg->width * v;

        RCLCPP_INFO(get_logger(), "Center distance : %g m", depths[centerIdx]);
    }

  private:
    rclcpp::Subscription<sensor_msgs::msg::Image>::SharedPtr mDepthSub;
};

int main(int argc, char* argv[]) {
    rclcpp::init(argc, argv);

    auto depth_node = std::make_shared<MinimalDepthSubscriber>();

    rclcpp::spin(depth_node);
    rclcpp::shutdown();
    return 0;
}
```

#### Code Explanation

The tutorial uses ROS 2's Component architecture. A `MinimalDepthSubscriber` class extends `rclcpp::Node`.

The constructor initializes QoS settings compatible with the ZED node publisher:

- Keep last 10 messages
- Best effort reliability
- Volatile durability

The callback function receives `sensor_msgs/Image` messages. It:

1. Casts the data pointer to `float*`
2. Calculates center pixel image coordinates [u,v]
3. Converts 2D coordinates to linear index
4. Prints the depth value

The main function initializes ROS 2, creates the component as a shared pointer, spins the node, and handles shutdown.

### Conclusion

Complete source code and supporting files (`package.xml`, `CMakeLists.txt`) are available in the [zed_depth_tutorial](https://github.com/stereolabs/zed-ros2-examples/tree/master/tutorials/zed_depth_tutorial) GitHub repository.

---

## Using Positional Tracking with ROS 2

### Position with RViz 2

#### Camera Pose

The `Pose` plugin visualizes the camera's position and orientation in the Map frame using `geometry_msgs/PoseStamped` messages.

**Topic**: `~/pose`

**Key Parameters:**

- **Topic**: Subscribe to `/zed/zed_node/odom`
- **Unreliable**: Check to reduce message latency
- **Position tolerance** and **Angle tolerance**: Set to `0` for all positional data
- **Keep**: Number of messages to visualize simultaneously
- **Shape**: Arrow or three-axis frame representation

#### Camera Path

Two path types are provided:

- `~/path_map`: Camera pose history in Map frame
- `~/path_odom`: Camera odometry history in Map frame

The odometry path (red) shows "pure visual odometry" and is affected by drift. The camera pose path (green) is continuously corrected using Stereolabs' tracking algorithm combining visual information, space memory, and IMU data (for ZED-M or ZED2).

### Position Info Subscribing in C++

#### Introduction

Launch the camera node:

```bash
ros2 launch zed_display_rviz2 display_zed_cam.launch.py camera_model:=<camera model>
```

#### Running the Tutorial

Execute the subscriber node:

```bash
ros2 run zed_tutorial_pos_tracking zed_tutorial_pos_tracking
```

With topic remapping:

```bash
ros2 run zed_tutorial_pos_tracking zed_tutorial_pos_tracking --ros-args \
  -r odom:=/zed/zed_node/odom -r pose:=/zed/zed_node/pose
```

#### Code Example

```cpp
#include <rclcpp/rclcpp.hpp>
#include <rclcpp/qos.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>
#include <tf2/LinearMath/Quaternion.h>
#include <tf2/LinearMath/Matrix3x3.h>

using namespace std::placeholders;

#define RAD2DEG 57.295779513

class MinimalPoseOdomSubscriber : public rclcpp::Node {
public:
    MinimalPoseOdomSubscriber()
        : Node("zed_odom_pose_tutorial") {

        rclcpp::QoS qos(10);
        qos.keep_last(10);
        qos.best_effort();
        qos.durability_volatile();

        mPoseSub = create_subscription<geometry_msgs::msg::PoseStamped>(
                    "pose", qos,
                    std::bind(&MinimalPoseOdomSubscriber::poseCallback, this, _1));

        mOdomSub = create_subscription<nav_msgs::msg::Odometry>(
                    "odom", qos,
                    std::bind(&MinimalPoseOdomSubscriber::odomCallback, this, _1));
    }

protected:
    void poseCallback(const geometry_msgs::msg::PoseStamped::SharedPtr msg) {
        double tx = msg->pose.position.x;
        double ty = msg->pose.position.y;
        double tz = msg->pose.position.z;

        tf2::Quaternion q(msg->pose.orientation.x, msg->pose.orientation.y,
                         msg->pose.orientation.z, msg->pose.orientation.w);
        tf2::Matrix3x3 m(q);

        double roll, pitch, yaw;
        m.getRPY(roll, pitch, yaw);

        RCLCPP_INFO(get_logger(), 
            "Received pose in '%s' frame : X: %.2f Y: %.2f Z: %.2f - "
            "R: %.2f P: %.2f Y: %.2f - Timestamp: %u.%u sec",
            msg->header.frame_id.c_str(), tx, ty, tz,
            roll * RAD2DEG, pitch * RAD2DEG, yaw * RAD2DEG,
            msg->header.stamp.sec, msg->header.stamp.nanosec);
    }

    void odomCallback(const nav_msgs::msg::Odometry::SharedPtr msg) {
        double tx = msg->pose.pose.position.x;
        double ty = msg->pose.pose.position.y;
        double tz = msg->pose.pose.position.z;

        tf2::Quaternion q(msg->pose.pose.orientation.x,
                         msg->pose.pose.orientation.y,
                         msg->pose.pose.orientation.z,
                         msg->pose.pose.orientation.w);
        tf2::Matrix3x3 m(q);

        double roll, pitch, yaw;
        m.getRPY(roll, pitch, yaw);

        RCLCPP_INFO(get_logger(),
            "Received odometry in '%s' frame : X: %.2f Y: %.2f Z: %.2f - "
            "R: %.2f P: %.2f Y: %.2f - Timestamp: %u.%u sec",
            msg->header.frame_id.c_str(), tx, ty, tz,
            roll * RAD2DEG, pitch * RAD2DEG, yaw * RAD2DEG,
            msg->header.stamp.sec, msg->header.stamp.nanosec);
    }

private:
    rclcpp::Subscription<geometry_msgs::msg::PoseStamped>::SharedPtr mPoseSub;
    rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr mOdomSub;
};

int main(int argc, char* argv[]) {
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<MinimalPoseOdomSubscriber>());
    rclcpp::shutdown();
    return 0;
}
```

#### Code Explanation

The node is structured as a `rclcpp::Node` component. Position data is extracted directly from messages, while orientation is converted from quaternions to roll-pitch-yaw values. QoS settings ensure compatibility with the ZED node's publisher configuration.
<!-- Part B: Geo Tracking, Plane Detection, Region of Interest, Record & Replay -->
  - [Recording and replaying rosbag files](#recording-and-replaying-rosbag-files)

---

## Geo Tracking

> Source: https://www.stereolabs.com/docs/ros2/geo-tracking/

### Using Geo Tracking with ROS 2

In this tutorial you will learn how to leverage Georeferential information from a GNSS sensor to improve the overall outdoor performance of the Positional Tracking module.

The ZED ROS 2 Wrapper is compatible with each type of GNSS sensor provided with a ROS 2 driver that publishes Latitude and Longitude datum with a message of type `sensor_msgs::msg::NavSatFix` on the topic defined by the parameter `gnss_fusion.gnss_fix_topic` (by default `/gps/fix`).

### Enable GNSS Fusion

GNSS Fusion can be started automatically when the ZED Wrapper node starts by setting the parameter `gnss_fusion.gnss_fusion_enabled` to `true` in the file `common.yaml`.

When the Geo Tracking module is active, the ZED ROS 2 Wrapper nodes wait for the first valid GNSS Datum on the subscribed topic before starting the processing:

```
[INFO] [1681308875.997297634] [zed2i.zed_node]: *** Positional Tracking with GNSS fusion ***
[INFO] [1681308875.997340244] [zed2i.zed_node]:  * Waiting for the first valid GNSS fix...
```

### GNSS Fusion results

When the Geo Tracking module is enabled the GNSS datum is automatically fused with the Positional Tracking information to provide a precise camera pose in `map` frame on the topics `~/pose`. The messages on the topic `~/pose/filtered` contain the GNSS fused odometry information to be used with external Kalman Filters.

The ZED ROS 2 Wrapper publishes also the pose of the robot in Earth coordinates on the topic `~/geo_pose/` of type `geographic_msgs::msg::GeoPoseStamped`.

---

## Plane Detection

> Source: https://www.stereolabs.com/docs/ros2/plane-detection/

### Using Plane Detection with ROS 2

In this tutorial, you will learn how to exploit the Plane Detection capabilities of the ZED SDK to detect the planes in the environment where a ZED camera is operating.

### Start a plane detection task

The ZED ROS 2 nodelet subscribes to the topic `/clicked_point` of type geometry_msgs/PointStamped, usually published by Rviz2.

When a message on the topic `/clicked_point` is received, the node searches for the first plane hitten by a virtual ray starting from the camera optical center and virtually passing through the received 3D point.

If a plane is found, its position and orientation are calculated, the 3D mesh is extracted and all the useful plane information is published as a custom zed_interfaces/PlaneStamped message on the topic `/<camera_model>/<node_name>/plane`.

A second message of type `visualization_msgs/Marker` with information useful for visualization is published on the topic `/<camera_model>/<node_name>/plane_marker` in order to display the plane using a Marker display plugin in Rviz.

#### Logging

When a plane detection is started, the log of the ROS wrapper will show the following information:

```
[zed_wrapper-2] 1651505097.533702002 [zed2i.zed_node] [INFO] Clicked 3D point [X FW, Y LF, Z UP]: [2.04603,-0.016467,0.32191]
[zed_wrapper-2] 1651505097.533748287 [zed2i.zed_node] [INFO] 'map' -> 'zed2i_left_camera_optical': {0.061,0.010,0.011} {0.495,-0.534,0.466,0.503}
[zed_wrapper-2] 1651505097.533775284 [zed2i.zed_node] [INFO] Point in camera coordinates [Z FW, X RG, Y DW]: {0.044,-0.436,2.034}
[zed_wrapper-2] 1651505097.533812591 [zed2i.zed_node] [INFO] Clicked point image coordinates: [655.536,231.765]
[zed_wrapper-2] 1651505097.592107647 [zed2i.zed_node] [INFO] Found plane at point [2.046,-0.016,0.322] -> Center: [1.909,-0.760,-0.007], Dims: 1.681x2.519
```

### Rviz2

The Rviz2 GUI allows one to easily start a plane detection task and displays the results of the detection.

#### Start a plane detection

To publish a `/clicked_point` point message and start a plane detection the `Publish Point` button must be enabled and a point of the 3D view or the camera view must be clicked.

#### Configure Rviz to display the results

The Marker plugin allows you to visualize the information of the detected planes.

Key parameters:

- **Topic**: The topic that contains the information relative to the detected planes: e.g. `/zed/zed_node/plane_marker`
- **Depth**: The size of the message queue. Use at least a value of `2` to not lose messages.
- **History policy**: Set the QoS history policy. `Keep Last` is suggested for performance and compatibility.
- **Reliability Policy**: Set the QoS reliability policy. `Best Effort` is suggested for performance and compatibility.
- **Durability Policy**: Set the QoS durability policy. `Volatile` is suggested for compatibility.
- **Namespaces**: The list of available information:
  - `plane_hit_points`: Select to display a sphere where the click has been received.
  - `plane_meshes`: Select to display all the meshes of the detected planes.

### Detected Plane message

The custom `zed_interfaces/PlaneStamped` message is defined in the zed-ros2-interfaces repository.

---

## Region of Interest

> Source: https://www.stereolabs.com/docs/ros2/region-of-interest/

### Setting the Region of Interest in ROS 2

With ZED SDK v3.8.x we have introduced an interesting feature for robotics applications: the "Region of Interest" to focus on for all SDK processing, discarding other parts.

When mounting a ZED on a robot it happens very often that parts of the robot itself are statically visible in the camera's field of view. This fact affects the depth extraction and performance of the positional tracking algorithms because part of the image will be stable even if the camera is moving.

The region of interest can be used to ignore these non-useful parts of the frame in the ZED SDK pipeline thus improving the overall performance of the ZED SDK algorithms run by the ZED ROS 2 Wrapper.

### How to use it

To set the region of interest of the ZED SDK processing it is necessary to call the API function `sl::Camera::setRegionOfInterest` which requires as an input parameter an image mask of type `sl::Mat` which sets the valid pixel zones of the frames captured, all the pixels with 0 (zero) as value are ignored.

The ZED ROS 2 Wrapper automatically creates the required `sl::Mat` starting from a parameter describing a polygon that contains the region of the image to be used during the data processing.

The Region of Interest can be set when the node starts through a node parameter, or at runtime by calling a ROS 2 service.

#### Node parameter

The node parameter used to set the region of interest is `general.region_of_interest`, the parameter is a string containing the list of the normalized coordinates of the polygon.

We use normalized coordinates so it is possible to change the resolution of the images without necessarily changing the definition of the parameter of the Region of Interest.

For example, to define a rhomboid-shaped Region of Interest, with the vertices in the central quarter of the frame, it is necessary to set the parameter `region_of_interest` in `common.yaml` like

```yaml
region_of_interest: "[[0.5,0.25],[0.75,0.5],[0.5,0.75],[0.25,0.5]]"
```

To keep the Region of Interest equal to the full image the polygon must be empty:

```yaml
region_of_interest: ""
```

or

```yaml
region_of_interest: "[]"
```

#### ROS 2 service

The custom service to set a new Region of Interest at runtime is defined in the `zed-ros2-interfaces` repository. The service name is `setROI` and the type is `zed_interfaces::srv::SetROI`.

The service has a parameter of type string defining the shape of the polygon of the Region of Interest defined in the same way as the node parameter `general.region_of_interest`.

To reset the Region of Interest to the full image you can call the service `resetROI` of type `std_srvs::srv::Trigger`.

---

## Record and Replay camera data with ROS 2

> Source: https://www.stereolabs.com/docs/ros2/record-and-replay-data-with-ros-wrapper/

This guide provides step-by-step instructions for recording and replaying data with the ZED ROS 2 wrapper. You'll learn how to capture camera sensor data into SVO or ROS 2 bag files, and how to replay these recordings for debugging, analysis, or development.

The guide also highlights best practices for data synchronization, playback configuration, and optimizing your workflow for efficient data handling.

> **Warning:** In order to use the recording and replay tools efficiently, ensure to tune your DDS settings properly by following the dedicated tutorial.

### Recording and replaying SVO files

#### Record SVO files with the ZED ROS Wrapper

An SVO file is a proprietary video format used by the ZED stereo camera to record:
- Synchronized stereo video (left and right images)
- Inertial Measurement Unit (IMU) and other sensor data (temperature, magnetometer, barometer if available)

**Main advantages of the SVO:**
- **Low system load** during recording: Only essential sensor data is saved, resulting in smaller file sizes and minimal CPU usage. Heavy data types such as point clouds and stereo images can be generated later from the SVO during replay, reducing the need for high-performance hardware during data capture.
- **Flexible SDK parameter tuning** during replay: SVO files allow you to replay the same recorded sequence multiple times while adjusting ZED SDK parameters (e.g., depth mode, resolution, tracking settings). This enables efficient experimentation and optimization without the need to re-record data, streamlining the development and debugging process.

**SVO Limitations:**
- **Records and replays only ZED SDK sensor data**: SVO files capture data directly from the camera (images, IMU, etc.) but do not include topics from other ROS nodes or external navigation modules. If you need to record and replay the full ROS ecosystem -- including additional sensors or navigation data -- use ROS bag files instead.

#### Single camera recording

**1. Launch the ZED ROS 2 Wrapper:**

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera_model>
```

**2. Start recording an SVO file:** *(in a new terminal)*

```bash
ros2 service call /zed/zed_node/start_svo_rec zed_msgs/srv/StartSvoRec "{svo_filename: '/path/to/svo/file/file.svo2', compression_mode: <choose between 0 and 5>}"
```

SVO videos can be recorded using various compression modes. We provide both lossless and compressed modes to preserve image quality or reduce file size. Choose your preferred compression mode when recording an SVO with the ZED wrapper:

| Compression Type | Average Size (% of RAW) | Mode |
|---|---|---|
| H.264 (AVCHD) | 1% | 1 |
| H.264 LOSSLESS | 25% | 3 |
| H.265 LOSSLESS | 25% | 4 |
| H.265 (HEVC) | 1% | 0 / 2 (default) |
| LOSSLESS (PNG/ZSTD) | 42% | 5 |

> **Note:** By default, the SVO file is saved as `zed.svo2` in the current directory. To change this, use the `svo_filename` parameter.

Compression mode by default will be 0 if not assigned, which is the H265 LOSSY compression mode, similar to the default SVO recording tool in *ZED_Explorer*.

**3. Stop the SVO recording:**

```bash
ros2 service call /zed/zed_node/stop_svo_rec std_srvs/srv/Trigger
```

#### Recording Instructions (multi camera setup)

For optimal multi-camera setups, refer to our multi-camera tutorial, which demonstrates how to configure up to four cameras using IPC (Intra-Process Communication) for zero-copy data transfer and maximum efficiency. With this approach, each camera node provides its own SVO recording service, allowing you to start and stop recordings independently. To record SVO files from multiple cameras at once, invoke the following command for each camera in separate terminals:

```bash
ros2 service call /zed_multi/<camera_name>/start_svo_rec zed_msgs/srv/StartSvoRec "{svo_filename: '/path/to/svo/file/file.svo2', compression_mode: <choose between 0 and 5>}"
```

Stopping the SVO recording then can be done with the following command for each camera:

```bash
ros2 service call /zed_multi/<camera_name>/stop_svo_rec std_srvs/srv/Trigger
```

#### Recording Performances

To evaluate recording performance, the following metrics are based on tests performed with all optional SDK modules disabled (depth, positional tracking, and object detection) when launching the ZED wrapper. Up to four ZED X cameras were connected to a single Jetson board. For each camera configuration, the results represent the maximum achievable performance using the latest ZED SDK. All values are reported per camera for consistency and easy comparison.

**Orin AGX:**

| Cameras | Resolution | Compression Mode | Max. SVO FPS | SVO Size |
|---|---|---|---|---|
| 1 | HD1200 | H265 | 60 | 400 MB |
| 2 | HD1200 | H265 | 60 | 400 MB |
| 4 | HD1200 | H265 | 30 | 200 MB |

**Orin NX 16:**

| Cameras | Resolution | Compression Mode | Max. SVO FPS | SVO Size |
|---|---|---|---|---|
| 1 | HD1200 | H265 | 60 | 400 MB |
| 2 | HD1200 | H265 | 30 | 200 MB |
| 4 | HD1200 | H265 | 30 | 200 MB |

**Test Metrics:**
- The Maximum SVO FPS metric indicates the mean recording frame rate achieved for each individual SVO file.
- The SVO file size metric indicates the mean file size of an SVO recorded over a recording period of 1 minute.

#### Replaying SVO files with the ZED ROS Wrapper

Once you have recorded an SVO file, you can use the ZED ROS 2 wrapper to replay it, simulating a live camera stream. During SVO playback, you can enable or disable SDK modules -- such as depth sensing, point cloud generation, and tracking -- to extract additional data or test different processing pipelines. This flexibility allows you to experiment with various parameter settings and replay the same sequence multiple times, making it easier to debug, optimize, and validate your robotics applications without needing to re-record data.

To replay an SVO file, first set your desired parameters in the ZED wrapper's configuration YAML file. Then, launch the wrapper with the following command:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera_model> svo_path:=</path/to/your/svo/file.svo2>
```

> **Warning:** At the moment, this feature is limited to single SVO replay.

To support debugging workflows involving SVO files within a robotics architecture, we provide several tools and tutorials:

- `svo_control_node` -- A utility for precise control over SVO playback using the ZED ROS 2 wrapper. Features include pause/resume, step forward/backward, and playback speed adjustment.
- `sync_node` -- Enables synchronized playback of SVO files alongside external navigation data from a ROS 2 bag. Supports pause/resume and step-wise playback, while maintaining time alignment.
- `SVO to ROS Bag Conversion Workflow` -- A tutorial-based method to convert .svo files into standard ROS 2 bag files and merge them with navigation data from another bag, allowing unified playback and analysis.

Follow the dedicated tutorial to learn how to use these tools effectively in your workflow.

### Recording and replaying rosbag files

#### Record rosbag files with the ZED ROS Wrapper

Rosbag files provide a standard way to record and replay data within the ROS ecosystem. With the ZED ROS 2 Wrapper, you can capture not only camera sensor data but also any additional topics published by other nodes in your robotics stack. This makes rosbags ideal for debugging, analysis, and sharing complete system datasets. Recorded topics can be replayed and visualized using tools like *RVIZ* or *Foxglove*, enabling thorough inspection and troubleshooting of complex robotics applications.

**Main advantages of the Rosbag:**
- Record and replay the entire robotics stack, including all ROS topics published by any node in your system.
- Capture data from navigation modules, additional sensors, and both standard and custom (proprietary) ROS messages for complete dataset coverage.
- Easily share, analyze, and visualize recorded data using standard ROS tools and third-party applications.

**Rosbag Limitations:**
- Recording large or high-frequency topics, such as images and point clouds, can quickly consume significant storage and system resources, potentially impacting performance.
- ZED parameters and processing options are set at recording time and cannot be changed during playback, limiting flexibility for post-recording optimization or experimentation.

#### Recording Best Practices

##### Use `mcap` storage

The `mcap` format allows rosbags optimization and the capability to be immediately replayed through visualization tools like *Foxglove*.

```bash
$ sudo apt install ros-"$ROS_DISTRO"-rosbag2-storage-mcap
```

##### Use `image_transport` compression and `ffmpeg` codecs

If you plan to record image topics, using FFmpeg with the NVENC (for desktop GPUs) or NvMpi (for Jetson boards) codecs in ROS 2 enables hardware-accelerated video encoding on NVIDIA GPUs. This offloads the computationally intensive encoding process from the CPU to the GPU, resulting in lower CPU usage and more stable system performance during recording. Leveraging GPU-based encoding helps maintain higher frame rates, reduces the risk of dropped frames, and allows for reliable rosbag recording even with multiple high-resolution video streams.

Follow the instructions here to build a version of ffmpeg that supports NVMPI:

```bash
git clone https://github.com/berndpfrommer/jetson-ffmpeg.git
cd jetson-ffmpeg && mkdir build && cd build && cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr/local ..  && sudo make install
sudo ldconfig && cd ../.. && git clone git://source.ffmpeg.org/ffmpeg.git -b release/7.1 --depth=1
sudo apt install libx264-dev
cd jetson-ffmpeg && ./ffpatch.sh ../ffmpeg && cd ../ffmpeg && ./configure --enable-nonfree --enable-shared --enable-nvmpi --enable-gpl --enable-libx264  --prefix=/usr/local && sudo make install
echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc && source ~/.bashrc
```

Once installed, ensure the codecs `h264_nvmpi`/`hevc_nvmpi` (for Jetson boards) or `hevc_nvenc` (for desktop GPU) are properly listed within the available ffmpeg codecs:

```bash
ffmpeg -codecs
```

We recommend installing the `image_transport` plugins from source in your ROS workspace (remove any previously installed binary versions to avoid conflicts):

```bash
cd your_ros_ws/src/
# clone the image_transport_plugins package (use git commands to put it in the correct branch associated to your ros distro version)
git clone https://github.com/ros-perception/image_transport_plugins.git
# clone ffmpeg packages to support the codecs within ROS
git clone https://github.com/ros-misc-utilities/ffmpeg_image_transport.git
git clone https://github.com/ros-misc-utilities/ffmpeg_encoder_decoder.git
# [optional] clone the foxglove_compressed_video_transport to ensure proper Foxglove streaming
git clone https://github.com/ros-misc-utilities/foxglove_compressed_video_transport.git
#export ffmpeg library
cd ..
rosdep install --from-paths src --ignore-src -r -y
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release
source install/local_setup.bash
```

You should now be able to use the `ffmpeg` installed codecs with the ROS wrapper with the `foxglove_compressed_video_transport` package. To do so, modify slightly the zed camera launcher to add the chosen codec parameters for the desired type of images. For example, if you want to enable *Foxglove* image transport with the ffmpeg `h264_nvmpi` compression codec on the cameras rectified images topics, add these lines to the ZED wrapper node parameters:

```python
node_parameters.append(
{
 #Add any desired parameters for the zed camera node, then add the images image compression codecs parameters
'.' + camera_name_val + '.left.color.rect.image.foxglove.encoding': 'h264_nvmpi',
'.' + camera_name_val + '.left.color.rect.image.foxglove.profile': 'main',
'.' + camera_name_val + '.left.color.rect.image.foxglove.preset': 'medium',
'.' + camera_name_val + '.left.color.rect.image.foxglove.gop': 10,
'.' + camera_name_val +'.left.color.rect.image.foxglove.bitrate': 4194304,
'.' + camera_name_val + '.right.color.rect.image.foxglove.encoding': 'h264_nvmpi',
'.' + camera_name_val + '.right.color.rect.image.foxglove.profile': 'main',
'.' + camera_name_val + '.right.color.rect.image.foxglove.preset': 'medium',
'.' + camera_name_val + '.right.color.rect.image.foxglove.gop': 10,
'.' + camera_name_val +'.right.color.rect.image.foxglove.bitrate': 4194304
}
)
```

Use the following command to explore available codec parameters and options:

```bash
ffmpeg -h encoder=<encoder_codec_name>
```

You can then adjust the launcher configuration to match your desired recording setup. The parameters will be used at the next launch of the cameras, after recompiling your ROS workspace containing the ZED wrapper.

##### Use rosbag recording as a component node available with IPC (Optional)

Starting with ROS 2 Jazzy, the [ros2 bag](https://github.com/ros2/rosbag2?tab=readme-ov-file#using-recorder-and-player-as-composable-nodes-) tool natively supports node composition. This allows you to launch the rosbag recorder as a composable node within a container, enabling efficient intra-process communication (IPC) and reducing data copying overhead.

For earlier ROS 2 distributions, you can achieve similar functionality using the rosbag2_composable_recorder community package. This package provides a component node for rosbag recording with IPC support, improving performance when recording high-bandwidth topics such as images or point clouds.

> **Tip:** Using rosbag as a composable node with IPC is especially beneficial in multi-camera or high-throughput scenarios, as it minimizes CPU and memory usage during recording.

#### Recording Instructions

##### 1. Launch the ZED ROS 2 Wrapper

Single camera setup:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera_model>
```

Multi camera setup (up to 4 cameras):

```bash
ros2 launch zed_multi_camera zed_multi_camera.launch.py cam_names:='[zed1,...,zed4]' cam_models:='[zedx,...,zedxm]' cam_serials:='[<serial_camera_1>,...,<serial_camera_4>]'
```

##### 2. Record node topics as a Rosbag `mcap` file

```bash
ros2 bag record -s mcap /topic1 /topic2 ...
```

In the example described above (recording each of the stereo camera images topics with `foxglove_compressed_video_transport`), the command would be:

```bash
ros2 bag record -s mcap /zed_multi/zed1/left/color/rect/image/foxglove /zed_multi/zed1/right/color/rect/image/foxglove /zed_multi/zed2/left/color/rect/image/foxglove /zed_multi/zed2/right/color/rect/image/foxglove ...
```

#### Recording Performances of the ZED Cameras images with the ZED Wrapper

To evaluate recording performance, the metrics below are based on tests conducted with no additional SDK modules enabled (depth, positional tracking, object detection modules disabled), using up to four ZED X cameras connected to a single Jetson board. For each camera configuration, the results reflect the maximum achievable performance using the latest version of the ZED SDK. One Rosbag file is recorded with all the cameras left and right images topics. The test is launched with the `h264_nvmpi` codec added on each stereo camera rectified images topics with a `bit_rate` of 4194304 and medium `preset`.

**Orin AGX:**

| Cameras | Resolution | Compression Mode | Max. Rosbag FPS | File Size |
|---|---|---|---|---|
| 1 | HD1200 | h264_nvmpi | 23 | 50 MB |
| 1 | HD1080 | h264_nvmpi | 25 | 55 MB |
| 1 | SVGA | h264_nvmpi | 30 | 65 MB |
| 2 | HD1200 | h264_nvmpi | 19 | 85 MB |
| 2 | HD1080 | h264_nvmpi | 22 | 95 MB |
| 2 | SVGA | h264_nvmpi | 30 | 127 MB |
| 4 | HD1200 | h264_nvmpi | 16 | 140 MB |
| 4 | HD1080 | h264_nvmpi | 17 | 160 MB |
| 4 | SVGA | h264_nvmpi | 30 | 250 MB |

**Orin NX 16:**

| Cameras | Resolution | Compression Mode | Max. Rosbag FPS | File Size |
|---|---|---|---|---|
| 1 | HD1200 | h264_nvmpi | 15 | 62 MB |
| 1 | HD1080 | h264_nvmpi | 20 | 88 MB |
| 1 | SVGA | h264_nvmpi | 30 | 124 MB |
| 2 | HD1200 | h264_nvmpi | 15 | 124.5 MB |
| 2 | HD1080 | h264_nvmpi | 18 | 155 MB |
| 2 | SVGA | h264_nvmpi | 30 | 250 MB |
| 4 | HD1200 | h264_nvmpi | 7.5 | 124.5 MB |
| 4 | HD1080 | h264_nvmpi | 9 | 158 MB |
| 4 | SVGA | h264_nvmpi | 28 | 450 MB |

**Test Metrics:**
- The Maximum Rosbag FPS metric indicates the mean recording frame rate achieved for the rosbag file.
- The rosbag file size metric indicates the mean file size of a rosbag recorded over a period of 1 minute.

#### Tips for recording rosbags efficiently and reduce overall recording load

- Record only the topics you need.
- On Jetson, use the `jetson_clocks.sh` script.
- On Jetson, get the highest power mode possible (**MAXN** recommended).
- Split large bags with the `--max-bag-size` or `--max-bag-duration` parameters.
- Reduce the frame rate for the images and point clouds (e.g from 30 fps to 10 fps) to reduce rosbag loads.
- Reduce publishing rates of other topics when a fast publishing rate (>10 Hz) is not necessary.
- Images and point cloud sizes can be further reduced from the chosen resolution using the `pub_downscale_factor` parameter (e.g setting the parameter to 2.0 on a HD1200 resolution publishing images with a resolution of 960x608 pixels).
- The `pub_frame_rate` parameter clamps the publishing rate to the chosen limit.

#### Replaying the recorded rosbag

You can replay your recorded `mcap` rosbag file using standard ROS 2 tools or visualize it directly in *Foxglove*. *Foxglove* natively supports the `mcap` format and compressed image topics via the `foxglove-compressed-image-transport` plugin, enabling efficient playback and inspection of high-bandwidth data. With *Foxglove*, you can pause, seek, and resume playback at any point, making it easy to analyze specific events or time ranges within your dataset.

To replay a rosbag in ROS 2, use:

```bash
ros2 bag play <your_bag_file>
```

For advanced playback options (such as rate control or topic remapping), refer to the `ros2 bag play` documentation.
