---
description: >
  ZED SDK Body Tracking documentation — body tracking overview with supported
  body formats, and using the Body Tracking API.
sources:
  - https://www.stereolabs.com/docs/body-tracking/
  - https://www.stereolabs.com/docs/body-tracking/using-body-tracking/
fetched: 2026-04-07
---

# Body Tracking

## Table of Contents

- [Body Tracking Overview](#body-tracking-overview)
- [Using the Body Tracking API](#using-the-body-tracking-api)

---

## Body Tracking Overview

Source: https://www.stereolabs.com/docs/body-tracking/

### How It Works

The body tracking module focuses on detecting and tracking a person's bones. Each detected bone is represented by its two endpoints, called keypoints. The ZED camera provides 2D and 3D information on each keypoint, plus local rotation between neighboring bones.

The process mirrors the Object Detection module, sharing outputs like 3D position and velocity. It uses neural networks for keypoint detection, then applies depth and positional tracking to obtain final 3D keypoint positions.

### Supported Body Formats

The ZED SDK supports three body formats:

#### BODY_18

Contains 18 keypoints following the COCO18 skeleton representation:

| Index | Name | Index | Name |
|-------|------|-------|------|
| 0 | NOSE | 9 | RIGHT_KNEE |
| 1 | NECK | 10 | RIGHT_ANKLE |
| 2 | RIGHT_SHOULDER | 11 | LEFT_HIP |
| 3 | RIGHT_ELBOW | 12 | LEFT_KNEE |
| 4 | RIGHT_WRIST | 13 | LEFT_ANKLE |
| 5 | LEFT_SHOULDER | 14 | RIGHT_EYE |
| 6 | LEFT_ELBOW | 15 | LEFT_EYE |
| 7 | LEFT_WRIST | 16 | RIGHT_EAR |
| 8 | RIGHT_HIP | 17 | LEFT_EAR |

#### BODY_34

Contains 34 keypoints with extended skeletal structure, indexed 0-33.

#### BODY_38

Contains 38 keypoints with the most detailed skeletal representation, indexed 0-37.

### Processing Levels

**2D/3D Body Detection**: The SDK uses neural networks on camera images to infer 2D bones and keypoints, then applies depth and positional tracking for 3D positioning.

**3D Body Tracking**: When enabled, assigns identity to detected bodies over time and outputs more stable 3D body estimation through filtering.

**3D Body Fitting**: Enables deduction of missing keypoints using human kinematic constraints and extracts local rotations between neighboring bones by solving inverse kinematic problems.

### Detection Outputs

Each detected person is stored as an `sl.BodyData` structure with these properties:

| Property | Description | Output |
|----------|-------------|--------|
| **ID** | Fixed identifier for tracking over time | Integer |
| **Unique Object ID** | Helps identify and track AI detections | String |
| **Tracking State** | Current tracking status | Ok, Off, Searching, Terminate |
| **Action State** | Movement status | Idle, Moving |
| **Position** | 3D position relative to camera | [x, y, z] |
| **Velocity** | Movement velocity in space | [vx, vy, vz] |
| **Position Covariance** | Confidence in position estimate | Array of 6 values |
| **2D Bounding Box** | Box in image surrounding object | Four pixel coordinates |
| **Mask** | Pixels belonging to object | Binary mask |
| **Detection Confidence** | Localization and label certainty | 0-100 |
| **3D Bounding Box** | Box in space surrounding object | Eight 3D coordinates |
| **Dimensions** | Width, height, length | [width, height, length] |
| **2D Keypoint** | Body points in 2D | Vector of [x,y] |
| **Keypoint** | Body points in 3D | Vector of [x, y, z] |
| **2D Head Bounding Box** | Head bounds in image | Four pixel coordinates |
| **3D Head Bounding Box** | Head bounds in space | Eight 3D coordinates |
| **Head Position** | 3D head centroid | [x, y, z] |
| **Keypoint Confidence** | Per-keypoint detection confidence | Vector of float |
| **Keypoint Covariance** | Per-keypoint confidence matrix | Vector of 6-value arrays |
| **Local Position Per Joint** | Position of each keypoint locally | Vector of [x,y,z] |
| **Local Orientation Per Joint** | Rotation of each keypoint | Vector of [x,y,z,w] |
| **Global Root Orientation** | Body's root orientation | [x,y,z,w] |

---

## Using the Body Tracking API

Source: https://www.stereolabs.com/docs/body-tracking/using-body-tracking/

### Body Tracking Configuration

To configure the body tracking module, use `BodyTrackingParameters` at initialization and `BodyTrackingRuntimeParameters` to change specific parameters during use.

> **Note**: The initial configuration must be set only once when enabling the module and runtime configuration can be changed at runtime.

#### Detection Models

The `BodyTrackingParameters::detection_model` enables human body detection with these presets:

- `BODY_TRACKING_MODEL::HUMAN_BODY_FAST`: real time performance even on NVIDIA Jetson or low-end GPU cards
- `BODY_TRACKING_MODEL::HUMAN_BODY_MEDIUM`: compromise between accuracy and speed
- `BODY_TRACKING_MODEL::HUMAN_BODY_ACCURATE`: state-of-the-art accuracy, requires powerful GPU

#### Body Fitting and Formats

- `BodyTrackingParameters::enable_body_fitting`: enables the fitting process of each detected person. Must be enabled to retrieve the local rotations of each keypoints.

- `BodyTrackingParameters::body_format` options:
  - `BODY_FORMAT::BODY_18`: 18 keypoints body model (COCO18 format). Not directly compatible with public software like Unreal or Unity. Local keypoints' rotation and translation not available.
  - `BODY_FORMAT::BODY_34`: 34 keypoints body model. Compatible with public software. Requires **body_fitting** enabled.
  - `BODY_FORMAT::BODY_38`: 38 keypoints body model. Includes simplified hands and feet keypoints.

#### Configuration Code Examples

**C++:**
```cpp
// Set initialization parameters
BodyTrackingParameters detection_parameters;
detection_parameters.detection_model = BODY_TRACKING_MODEL::HUMAN_BODY_ACCURATE;
detection_parameters.enable_tracking = true;
detection_parameters.enable_body_fitting = true;
detection_parameters.body_format = BODY_FORMAT::BODY_34;

// Set runtime parameters
BodyTrackingRuntimeParameters detection_parameters_rt;
detection_parameters_rt.detection_confidence_threshold = 40;
```

**Python:**
```python
# Set initialization parameters
detection_parameters = sl.BodyTrackingParameters()
detection_parameters.detection_model = sl.BODY_TRACKING_MODEL.HUMAN_BODY_ACCURATE  
detection_parameters.enable_tracking = true
detection_parameters.enable_body_fitting = True
detection_parameters.body_format = sl.BODY_FORMAT.BODY_34

# Set runtime parameters
detection_parameters_rt = sl.BodyTrackingRuntimeParameters()
detection_parameters_rt.detection_confidence_threshold = 40
```

**C#:**
```csharp
// Set initialization parameters
BodyTrackingParameters detection_parameters = new BodyTrackingParameters();
detection_parameters.enableObjectTracking = true;
detection_parameters.detectionModel = sl.BODY_TRACKING_MODEL.HUMAN_BODY_ACCURATE;
detection_parameters.enableBodyFitting = true;
detection_parameters.bodyFormat = sl.BODY_FORMAT.BODY_34;

// Set runtime parameters
BodyTrackingRuntimeParameters detection_parameters_rt = new BodyTrackingRuntimeParameters();
detection_parameters_rt.detectionConfidenceThreshold = 40;
```

### Positional Tracking Integration

If tracking persons' motion within their environment is needed, activate positional tracking first:

**C++:**
```cpp
if (detection_parameters.enable_tracking) {
    // Set positional tracking parameters
    PositionalTrackingParameters positional_tracking_parameters;
    // Enable positional tracking
    zed.enablePositionalTracking(positional_tracking_parameters);
}
```

**Python:**
```python
if detection_parameters.enable_tracking:
    # Set positional tracking parameters
    positional_tracking_parameters = sl.PositionalTrackingParameters()
    # Enable positional tracking
    zed.enable_positional_tracking(positional_tracking_parameters)
```

**C#:**
```csharp
if (detection_parameters.enableObjectTracking) {
    // Set positional tracking parameters
    PositionalTrackingParameters trackingParams = new PositionalTrackingParameters();
    // Enable positional tracking
    zed.EnablePositionalTracking(ref trackingParams);
}
```

### Enabling the Module

**C++:**
```cpp
// Enable body tracking with initialization parameters
zed_error = zed.enableBodyTracking(detection_parameters);
if (zed_error != ERROR_CODE::SUCCESS) {
    cout << "enableBodyTracking: " << zed_error << "\nExit program.";
    zed.close();
    exit(-1);
}
```

**Python:**
```python
# Enable body tracking with initialization parameters
zed_error = zed.enable_body_tracking(detection_parameters)
if zed_error != sl.ERROR_CODE.SUCCESS:
    print("enable_body_tracking", zed_error, "\nExit program.")
    zed.close()
    exit(-1)
```

**C#:**
```csharp
// Enable body tracking with initialization parameters
zed_error = zedCamera.EnableBodyTracking(ref detection_parameters);
if (zed_error != ERROR_CODE.SUCCESS) {
    Console.WriteLine("enableBodyTracking: " + zed_error + "\nExit program.");
    zed.Close();
    Environment.Exit(-1);
}
```

> **Note**: The Body Tracking module can be used with all ZED Cameras, except the ZED 1 Camera.

### Getting Human Body Data

To get detected persons in a scene, call `grab(...)` and extract data with `retrieveBodies()`.

**C++:**
```cpp
sl::Bodies bodies; // Structure containing all the detected bodies
// grab runtime parameters
RuntimeParameters runtime_parameters;
runtime_parameters.measure3D_reference_frame = sl::REFERENCE_FRAME::WORLD;

if (zed.grab(runtime_parameters) == ERROR_CODE::SUCCESS) {
  zed.retrieveBodies(bodies, detection_parameters_rt);
}
```

**Python:**
```python
bodies = sl.Bodies() # Structure containing all the detected bodies
# grab runtime parameters
runtime_params = sl.RuntimeParameters()
runtime_params.measure3D_reference_frame = sl.REFERENCE_FRAME.WORLD

if zed.grab(runtime_params) == sl.ERROR_CODE.SUCCESS:
  zed.retrieve_bodies(bodies, obj_runtime_param)
```

**C#:**
```csharp
sl.Bodies bodies = new sl.Bodies();
// grab runtime parameters
RuntimeParameters runtimeParameters = new RuntimeParameters();
runtimeParameters.measure3DReferenceFrame = sl.REFERENCE_FRAME.WORLD;

if (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
  zed.RetrieveBodies(ref bodies, ref detection_parameters_rt);
}
```

#### Data Structure

The `sl::Bodies` class stores all person data in its `vector<sl::BodyData> body_list` attribute. Each person is stored as `sl::BodyData`. The `sl::Bodies` structure contains the detection timestamp to connect bodies to images.

All 2D data relate to the left image, while 3D data are in either `CAMERA` or `WORLD` referential depending on `RuntimeParameters.measure3D_reference_frame`. The 2D data are expressed in initial camera resolution. A scaling can be applied if needed in another resolution.

For 3D data, coordinate frame and units can be set via `InitParameters` with `COORDINATE_SYSTEM` and `UNIT` respectively.

### Accessing 2D and 3D Body Keypoints

**C++:**
```cpp
// collect all 2D keypoints
for (auto& kp_2d : body.keypoint_2d) {
  // user code using each kp_2d point
}

// collect all 3D keypoints
for (auto& kp_3d : obj.keypoint)
{
  // user code using each kp_3d point
}
```

**Python:**
```python
# collect all 2D keypoints
for kp_2d in obj.keypoint_2d:
    # user code using each kp_2d point

# collect all 3D keypoints
for kp_3d in obj.keypoint:
    # user code using each kp_3d point
```

**C#:**
```csharp
// collect all 2D keypoints
foreach (var kp_2d in obj.keypoints2D)
{
  // user code using each kp_2d point
}

// collect all 3D keypoints
foreach (var kp_3d in obj.keypoints)
{
  // user code using each kp_3d point
}
```

### Getting More Results (Body Fitting Enabled)

When fitting is enabled at initial configuration, more results are available based on the chosen `BODY_FORMAT`. All local rotation and translation of each keypoint become available with `BODY_FORMAT::BODY_34` or `BODY_FORMAT::BODY_38`.

**C++:**
```cpp
// collect local rotation for each keypoint
for (auto &kp : body.local_orientation_per_joint)
{
   // kp is the local keypoint rotation represented by a quaternion
   // user code
}

// collect local translation for each keypoint
for (auto &kp : body.local_position_per_joint)
{
   // kp is the local keypoint translation
   // user code
}

// get global root orientation
auto global_root_orientation = body.global_root_orientation
```

**Python:**
```python
# collect local rotation for each keypoint
for kp in body.local_orientation_per_joint:
    # kp is the local keypoint rotation represented by a quaternion
    # user code

# collect local translation for each keypoint
for kp in body.local_position_per_joint:
  # kp is the local keypoint translation
  # user code

# get global root orientation
global_root_orientation = body.global_root_orientation
```

**C#:**
```csharp
// collect local rotation for each keypoint
foreach (var kp in body.localOrientationPerJoint)
{
   // kp is the local keypoint rotation represented by a quaternion
   // user code
}

// collect local translation for each keypoint
foreach (var kp in body.localPositionPerJoint)
{
   // kp is the local keypoint translation
   // user code
}

// get global root orientation
Quaternion globalRootOrientation = body.globalRootOrientation;
```

> **Note**: All these data are expressed in the chosen `COORDINATE_SYSTEM` and `UNITS`.

### Code Example

For complete code examples, check out the Tutorial and Sample repositories on GitHub.
