---
description: >
  ZED ROS 2 detection reference — Object Detection and Tracking, Custom Object Detection,
  and Body Tracking. Extracted from official Stereolabs documentation.
sources:
  - https://www.stereolabs.com/docs/ros2/object-detection/
  - https://www.stereolabs.com/docs/ros2/custom-object-detection/
  - https://www.stereolabs.com/docs/ros2/body-tracking/
fetched: 2026-04-07
---

# ZED ROS 2 Detection Reference

## Table of Contents

- [Object Detection and Tracking](#object-detection-and-tracking)
  - [Available Detection Models](#available-detection-models)
  - [Model Availability](#model-availability)
  - [Enabling Object Detection](#enabling-object-detection)
  - [Initial Model Optimization](#initial-model-optimization)
  - [ROS 2 Message Types](#ros-2-message-types)
  - [Visualization in RViz 2](#visualization-in-rviz-2)
- [Custom Object Detection](#custom-object-detection)
  - [Model Requirements](#model-requirements)
  - [Export the YOLO-like ONNX Model](#export-the-yolo-like-onnx-model)
  - [Setup the Custom Model Usage](#setup-the-custom-model-usage)
  - [Custom Model Configuration File](#custom-model-configuration-file)
  - [Class-Specific Configuration](#class-specific-configuration)
  - [Launch the ZED Node with Custom Object Detection](#launch-the-zed-node-with-custom-object-detection)
  - [Enable the Object Detection Processing](#enable-the-object-detection-processing)
  - [Object Detection and Tracking Results](#object-detection-and-tracking-results)
- [Body Tracking](#body-tracking)
  - [Available Body Tracking Models](#available-body-tracking-models)
  - [Available Body Formats](#available-body-formats)
  - [Enable Body Tracking](#enable-body-tracking)
  - [Body Tracking Results in RViz 2](#body-tracking-results-in-rviz-2)

---

## Object Detection and Tracking

Source: <https://www.stereolabs.com/docs/ros2/object-detection/>

The Object Detection module integrates with ROS 2 to enable real-time detection and tracking capabilities using the ZED SDK.

### Available Detection Models

| Model | Description |
|-------|-------------|
| `MULTI_CLASS_BOX_FAST` | General-purpose object detection with bounding boxes |
| `MULTI_CLASS_BOX_MEDIUM` | Balanced accuracy and speed for multi-class detection |
| `MULTI_CLASS_BOX_ACCURATE` | Higher accuracy multi-class detection (slower) |
| `PERSON_HEAD_BOX_FAST` | Specialized head detection, optimized for crowded scenes |
| `PERSON_HEAD_BOX_ACCURATE` | Specialized head detection with improved accuracy |
| `CUSTOM_YOLOLIKE_BOX_OBJECTS` | Custom YOLO-like model inference using ONNX files |

### Model Availability

Built-in `MULTI_CLASS_BOX` and `PERSON_HEAD_BOX` models are provided and downloaded automatically by the SDK. Custom YOLO models require an ONNX file and are discussed in the [Custom Object Detection](#custom-object-detection) section.

### Enabling Object Detection

**Automatic Startup:**
Set `object_detection.od_enabled` to `true` in the `common_stereo.yaml` configuration file.

**Manual Control:**
Call the `~/enable_obj_det` service with parameter `True` to start processing or `False` to stop.

### Initial Model Optimization

> **Note:** The first time you run the ZED node with the object detection configuration, the SDK will optimize the model for the GPU used on the host device. This process may take a long time, depending on the model size and the power of GPU used. The optimized model will be saved in the `/usr/local/zed/resources` folder and will be reused in subsequent runs which won't require the optimization process anymore.

Sample output during optimization:

```
[ZED][INFO] Please wait while the AI model is being optimized for your graphics card
This operation will be run only once and may take a few minutes
```

### ROS 2 Message Types

Detection results are published using a custom message type: `zed_interfaces/ObjectsStamped`

For detailed message structure documentation, refer to the custom messages section.

### Visualization in RViz 2

#### ZedOdDisplay Plugin

A dedicated RViz 2 display plugin visualizes object detection results. The plugin is available in the [zed-ros2-examples](https://github.com/stereolabs/zed-ros2-examples) repository.

#### Configuration Parameters

| Parameter | Description |
|-----------|-------------|
| `Topic` | Select the object detection topic from available streams |
| `Depth` | Incoming message queue depth |
| `History Policy` | Set the QoS history policy. `Keep Last` is suggested for performance and compatibility |
| `Reliability Policy` | Set the QoS reliability policy. `Best Effort` is suggested for performance and compatibility |
| `Durability Policy` | Set the QoS durability policy. `Volatile` is suggested for compatibility |
| `Transparency` | Adjust detected object structure transparency |
| `Show Skeleton` | Currently unused |
| `Show Labels` | Enable/disable object label visualization |
| `Show Bounding Boxes` | Toggle bounding box display |
| `Link Size` | Adjust corner line thickness |
| `Joint Radius` | Sphere radius at bounding box corners |
| `Label Scale` | Object label text scaling |

> **Note:** The source code of the plugin in the [zed-ros2-examples](https://github.com/stereolabs/zed-ros2-examples) repository is a valid example of how to process the data of topics of type `zed_interfaces/ObjectsStamped`.

---

## Custom Object Detection

Source: <https://www.stereolabs.com/docs/ros2/custom-object-detection/>

This guide explains how to use a custom YOLO-like model for object detection with the ZED ROS 2 Wrapper. This is useful if you have trained your own model and want to integrate it with the ZED SDK.

### Model Requirements

The custom model must:

- Be in **ONNX** format
- Be **compatible** with the ZED SDK
- Be **exported correctly** for integration

### Export the YOLO-like ONNX Model

You can perform object detection inference using a custom YOLO-like ONNX model.

> Refer to the [YOLO ONNX model export documentation](https://www.stereolabs.com/docs/yolo/export/) for detailed instructions.

#### Quick Example Using Ultralytics YOLOv8

```bash
python -m pip install -U ultralytics
yolo export model=yolov8s.pt format=onnx simplify=True dynamic=False imgsz=512
```

### Setup the Custom Model Usage

#### Configuration in `common_stereo.yaml`

To use your model, set the following in your `common_stereo.yaml`:

```yaml
object_detection:
  detection_model: 'CUSTOM_YOLOLIKE_BOX_OBJECTS'
  enable_tracking: true # Enable detected object tracking
```

#### Tracking State Values

When `enable_tracking` is `true`, the ZED SDK advanced algorithms allow tracking of detected objects over time, even if temporarily occluded or moved out of frame.

The field `tracking_state` in the `zed_interfaces/ObjectsStamped` message indicates the tracking state:

- `0` -- **OFF**: object no more valid
- `1` -- **OK**: object is valid and tracked
- `2` -- **SEARCHING**: occlusion occurred, trajectory is estimated
- `3` -- **TERMINATE**: the track will be deleted in the next frame

### Custom Model Configuration File

#### YAML Configuration Header

```yaml
/**:
  ros__parameters:
    object_detection:
      custom_onnx_file: ''              # Path to your ONNX file
      custom_onnx_input_size: 512       # Input resolution (e.g., 512 for 1x3x512x512 tensor)
      custom_class_count: 80            # Number of classes in your model (e.g., 80 for COCO)
```

#### Parameter Descriptions

- **`custom_onnx_file`**: Path to your ONNX file
- **`custom_onnx_input_size`**: Input resolution used during training (e.g., 512)
- **`custom_class_count`**: Number of classes your model was trained on (e.g., 80 for COCO dataset)

### Class-Specific Configuration

For each class, add a `class_XXX` block (where `XXX` is the class index, from `0` to `custom_class_count - 1`):

```yaml
class_XXX:
  label: '' # Label of the object in the custom ONNX file
  model_class_id: 0 # Class ID of the object in the custom ONNX file
  enabled: true # Enable/disable the detection of this class
  confidence_threshold: 50.0 # Minimum detection confidence [0,99]
  is_grounded: true # Hypothesis about object movements (DoF) for tracking
  is_static: false # Hypothesis about object staticity for tracking
  tracking_timeout: -1.0 # Maximum tracking time (seconds) before dropping
  tracking_max_dist: -1.0 # Maximum tracking distance (meters) before dropping
  max_box_width_normalized: -1.0 # Maximum allowed width normalized to image size
  min_box_width_normalized: -1.0 # Minimum allowed width normalized to image size
  max_box_height_normalized: -1.0 # Maximum allowed height normalized to image size
  min_box_height_normalized: -1.0 # Minimum allowed height normalized to image size
  max_box_width_meters: -1.0 # Maximum allowed 3D width
  min_box_width_meters: -1.0 # Minimum allowed 3D width
  max_box_height_meters: -1.0 # Maximum allowed 3D height
  min_box_height_meters: -1.0 # Minimum allowed 3D height
  object_acceleration_preset: 'DEFAULT' # Possible values: 'DEFAULT', 'LOW', 'MEDIUM', 'HIGH'
  max_allowed_acceleration: 100000.0 # Custom maximum acceleration (m/s^2)
```

#### Class Parameter Reference

| Parameter | Description | Range | Dynamic |
|-----------|-------------|-------|---------|
| `label` | Label of the object in custom ONNX file | -- | -- |
| `model_class_id` | Class ID matching training model | -- | -- |
| `enabled` | Enable/disable detection of this class | true/false | Yes |
| `confidence_threshold` | Minimum detection confidence | [0,99] | Yes |
| `is_grounded` | Hypothesis about object movements for tracking | true/false | Yes |
| `is_static` | Hypothesis about object staticity for tracking | true/false | Yes |
| `tracking_timeout` | Maximum tracking time before dropping (sec) | [0,500] / -1.0 | Yes |
| `tracking_max_dist` | Maximum tracking distance before dropping (m) | [0,500] / -1.0 | Yes |
| `max_box_width_normalized` | Maximum width (normalized to image) | [0,1] / -1.0 | Yes |
| `min_box_width_normalized` | Minimum width (normalized to image) | [0,1] / -1.0 | Yes |
| `max_box_height_normalized` | Maximum height (normalized to image) | [0,1] / -1.0 | Yes |
| `min_box_height_normalized` | Minimum height (normalized to image) | [0,1] / -1.0 | Yes |
| `max_box_width_meters` | Maximum 3D width | [0,500] / -1.0 | Yes |
| `min_box_width_meters` | Minimum 3D width | [0,500] / -1.0 | Yes |
| `max_box_height_meters` | Maximum 3D height | [0,500] / -1.0 | Yes |
| `min_box_height_meters` | Minimum 3D height | [0,500] / -1.0 | Yes |
| `object_acceleration_preset` | Acceleration preset | DEFAULT, LOW, MEDIUM, HIGH | -- |
| `max_allowed_acceleration` | Custom max acceleration override | [0,10000] (m/s^2) | Yes |

#### Key Parameter Notes

- **`label`**: Set to the label of the object in your custom ONNX file
- **`model_class_id`**: Must match the ID of the class used during training
- **`enabled`**: Dynamic parameter; can be changed at runtime
- **`confidence_threshold`**: Dynamic parameter; can be changed at runtime
- **`is_grounded`**: Dynamic parameter; can be changed at runtime
- **`is_static`**: Dynamic parameter; can be changed at runtime
- **`tracking_timeout`**: Use -1.0 to disable the timeout
- **`tracking_max_dist`**: Only valid for static objects; use -1.0 to disable
- **Width/Height thresholds**: Use -1.0 to disable any threshold
- **`max_allowed_acceleration`**: When set to a different value from default (100000), takes precedence over preset, allowing custom maximum acceleration

#### Template File

Use the provided `custom_object_detection.yaml` template as a reference example. It is preconfigured for models trained on the 80 classes COCO dataset.

### Launch the ZED Node with Custom Object Detection

#### Launch Command

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=<camera_model> custom_object_detection_config_path:='<path_to_custom_object_detection.yaml>'
```

#### Launch Parameters

- **`camera_model`**: Replace with desired camera model (e.g., `zedx`, `zedxm`, `zed2i`, `zed2`, `zedm`, `zed`, or `virtual`)
- **`custom_object_detection_config_path`**: Path to your custom object detection configuration file

> **Note:** The `custom_object_detection_config_path` launch parameter is optional. If not provided, the ZED node will use the default configuration file `custom_object_detection.yaml` located in the `config` folder of the ZED ROS 2 Wrapper package.

### Enable the Object Detection Processing

**Automatic Enablement:**
You can automatically start the object detection module by setting the `object_detection.od_enabled` parameter to `true` in the `common_stereo.yaml` file. This will enable the object detection when the ZED node starts.

**Manual Control:**
You can also start/stop the object detection manually by calling the service:

- **Start**: Call `~/enable_obj_det` with the parameter `True`
- **Stop**: Call `~/enable_obj_det` with the parameter `False`

See the [services documentation](https://www.stereolabs.com/docs/ros2/zed-node/#services) for more info.

> **Note:** The first time you run the ZED node with the custom object detection configuration, the SDK will optimize the model for the GPU used on the host device. This process may take a long time, depending on the model size and the power of GPU used. The optimized model will be saved in the `/usr/local/zed/resources` folder and will be reused in subsequent runs which won't require the optimization process anymore.
>
> ```
> [ZED][INFO] Please wait while the AI model is being optimized for your graphics card
> This operation will be run only once and may take a few minutes
> ```

### Object Detection and Tracking Results

#### Output Message Type

The results of the Object Detection and Tracking processing are published using a custom message of type `zed_interfaces/ObjectsStamped` defined in the package `zed_interfaces`.

#### Visualization in RViz 2

To visualize the results of the Object Detection processing in RViz 2, the `ZedOdDisplay` plugin is required. The plugin is available in the [zed-ros2-examples](https://github.com/stereolabs/zed-ros2-examples) GitHub repository and can be installed following the online instructions.

> **Note:** The source code of the plugin is a valid example of how to process the data of topics of type `zed_interfaces/ObjectsStamped`.

#### RViz 2 Display Plugin Parameters

| Parameter | Description |
|-----------|-------------|
| `Topic` | Selects the object detection topic to visualize from available images |
| `Depth` | The depth of the incoming message queue |
| `History policy` | Set the QoS history policy (`Keep Last` suggested) |
| `Reliability Policy` | Set the QoS reliability policy (`Best Effort` suggested) |
| `Durability Policy` | Set the QoS durability policy (`Volatile` suggested) |
| `Transparency` | Transparency level of detected object structures |
| `Show skeleton` | Not used |
| `Show Labels` | Enable/disable visualization of object label |
| `Show Bounding Boxes` | Enable/disable visualization of bounding boxes |
| `Link Size` | Size of the bounding boxes' corner lines |
| `Joint Radius` | Radius of spheres placed on bounding box corners |
| `Label Scale` | Scale of the object label |

#### Label Format

The format of the label of the detected objects is:

```
<tracking_id>-<label> [<label_id>]
```

Where:

- **`tracking_id`**: The tracking ID associated by the ZED SDK to the detected object. The tracking ID is unique for each detected object and identifies it in the tracking process.
- **`label`**: The label of the detected object, corresponding to the value of the `label` parameter in the configuration file.
- **`label_id`**: The ID of the label, corresponding to the value of the `model_class_id` parameter in the configuration file.

---

## Body Tracking

Source: <https://www.stereolabs.com/docs/ros2/body-tracking/>

The ROS 2 wrapper offers full support for the Body Tracking module of the ZED SDK.

### Available Body Tracking Models

| Model | Description |
|-------|-------------|
| `HUMAN_BODY_FAST` | Keypoints based, specific to human skeleton, real time performance even on NVIDIA Jetson or low end GPU cards |
| `HUMAN_BODY_MEDIUM` | Keypoints based, specific to human skeleton, compromise between accuracy and speed |
| `HUMAN_BODY_ACCURATE` | Keypoints based, specific to human skeleton, state of the art accuracy, requires powerful GPU |

### Available Body Formats

| Format | Description |
|--------|-------------|
| `BODY_18` | 18 keypoints model. Basic Body model |
| `BODY_34` | 34 keypoints model. Body model, requires body fitting enabled |
| `BODY_38` | 38 keypoints model. Body model, including feet simplified face and hands |

### Enable Body Tracking

**Automatic Startup:**
Body Tracking can be started automatically when the ZED Wrapper node starts by setting the parameter `body_tracking.bt_enabled` to `true` in the file `common.yaml`.

**Manual Control:**
It is also possible to start the Body Tracking processing manually by calling the service `~/enable_obj_det` with the parameter `True`.

In both cases, the Body Tracking processing can be stopped by calling the service `~/enable_obj_det` with the parameter `False`.

See the services documentation for more information.

### Output Format

The result of the detection is published using a custom message type `zed_interfaces/ObjectsStamped` defined in the package `zed_interfaces`.

### Body Tracking Results in RViz 2

To visualize the results of the Body Tracking processing in RViz 2, the `ZedOdDisplay` plugin is required. The plugin is available in the [zed-ros2-examples](https://github.com/stereolabs/zed-ros2-examples) GitHub repository and can be installed following the online instructions.

> **Note:** The source code of the plugin is a valid example about how to process data from topics of type `zed_interfaces/ObjectsStamped`.

#### Visualization Parameters

| Parameter | Description |
|-----------|-------------|
| `Topic` | Selects the body tracking topic to visualize from the list of available images |
| `Depth` | The depth of the incoming message queue |
| `History policy` | Set the QoS history policy. `Keep Last` is suggested for performance and compatibility |
| `Reliability Policy` | Set the QoS reliability policy. `Best Effort` is suggested for performance and compatibility |
| `Durability Policy` | Set the QoS durability policy. `Volatile` is suggested for compatibility |
| `Transparency` | The transparency level of the structures composing the detected bodies |
| `Show skeleton` | Enable/disable the visualization of the skeleton of the detected persons |
| `Show Labels` | Enable/disable the visualization of the label |
| `Show Bounding Boxes` | Enable/disable the visualization of the bounding boxes of the detected bodies |
| `Link Size` | The size of the bounding boxes' corner lines and skeleton link lines |
| `Joint Radius` | The radius of the spheres placed on the corners of the bounding boxes and on the skeleton joint points |
| `Label Scale` | The scale of the label of the bodies |
