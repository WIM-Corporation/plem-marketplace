---
description: >
  Consolidated ZED SDK Depth Sensing documentation. Covers overview, depth modes
  (NEURAL / NEURAL_LIGHT / NEURAL_PLUS), depth settings (InitParameters and
  RuntimeParameters), and the depth-sensing API (retrieving depth maps, point
  clouds, normals, confidence filtering).
sources:
  - https://www.stereolabs.com/docs/depth-sensing/
  - https://www.stereolabs.com/docs/depth-sensing/depth-modes/
  - https://www.stereolabs.com/docs/depth-sensing/depth-settings/
  - https://www.stereolabs.com/docs/depth-sensing/using-depth/
fetched: 2026-04-07
---

# ZED SDK -- Depth Sensing

## Table of Contents

- [Depth Sensing Overview](#depth-sensing-overview)
  - [Introduction](#introduction)
  - [Depth Perception](#depth-perception)
  - [Depth Map](#depth-map)
  - [3D Point Cloud](#3d-point-cloud)
  - [Depth Accuracy](#depth-accuracy)
- [Depth Modes](#depth-modes)
  - [NEURAL](#neural)
  - [NEURAL LIGHT](#neural-light)
  - [NEURAL PLUS](#neural-plus)
  - [Depth Modes Comparison](#depth-modes-comparison)
- [Depth Settings](#depth-settings)
  - [sl::InitParameters Depth Parameters](#slinitparameters-depth-parameters)
  - [sl::RuntimeParameters Depth Parameters](#slruntimeparameters-depth-parameters)
- [Using the Depth Sensing API](#using-the-depth-sensing-api)
  - [Depth Sensing Configuration](#depth-sensing-configuration)
  - [Retrieving Depth Data](#retrieving-depth-data)
  - [Displaying Depth Image](#displaying-depth-image)
  - [Getting Point Cloud Data](#getting-point-cloud-data)
  - [Getting Normal Map](#getting-normal-map)
  - [Adjusting Depth Resolution](#adjusting-depth-resolution)
  - [Code Example](#code-example)

---

## Depth Sensing Overview

Source: <https://www.stereolabs.com/docs/depth-sensing/>

### Introduction

The ZED stereo camera mimics human binocular vision. Human eyes are separated by approximately 65 mm, giving each eye a slightly different perspective. The brain compares these views to infer depth and 3D motion.

Similarly, Stereolabs' stereo cameras have two separated optical sensors that capture high-resolution 3D video. They estimate depth and motion by comparing the displacement of pixels between the left and right images.

### Depth Perception

Depth perception is the capability to determine distances between objects and perceive the world in three dimensions. Traditional depth sensors have been limited to short-range, indoor applications for gesture control and body tracking. Using stereo vision, the ZED provides universal depth sensing capabilities:

- Depth capture extends to 35 meters
- Field of view reaches up to 110 deg (H) x 95 deg (V)
- The camera functions both indoors and outdoors, unlike active sensors such as structured-light or time-of-flight systems

### Depth Map

Depth maps from the ZED store a distance value (Z) for each pixel coordinate (X, Y). The distance is expressed in metric units (such as meters) and calculated from the back of the left camera sensor to scene objects.

Since depth maps use 32-bit encoding, they cannot be displayed directly. A color image representation maps depth values to a color scale, providing intuitive visualization of depth variations across the scene.

### 3D Point Cloud

Point clouds represent another common depth visualization approach. A point cloud functions as a three-dimensional depth map. While depth maps contain only Z information per pixel, point clouds consist of 3D points (X, Y, Z) representing the scene's external surface and can include color data.

### Depth Accuracy

Stereo vision uses triangulation to determine depth from disparity images. Depth resolution changes according to this relationship:

```
Dr = Z^2 * alpha
```

Where `Dr` is depth resolution, `Z` is distance, and `alpha` represents a constant.

Depth accuracy decreases with distance, following a quadratic relationship. For ZED stereo cameras, depth accuracy typically reaches around 1% of measured distance at close range, increasing to approximately 9% at maximum range.

Depth accuracy may also be reduced by outliers on homogeneous or textureless surfaces -- such as white walls, green screens, or reflective areas. These surfaces often lack sufficient visual features, resulting in temporal instability and less reliable measurements.

---

## Depth Modes

Source: <https://www.stereolabs.com/docs/depth-sensing/depth-modes/>

Stereolabs AI Depth leverages advanced neural networks to generate high-quality depth maps from stereo images, delivering reliable results even in challenging scenarios. Compared to traditional approaches, AI Depth provides superior accuracy in low-texture and low-light environments. This makes it especially well-suited for applications such as robotics, augmented reality (AR), and 3D mapping, where dependable depth perception is critical.

The ZED SDK provides multiple AI-powered depth modes, allowing you to tailor depth sensing to your application's requirements. Each mode offers a different balance of accuracy, range, and computational speed, so you can optimize for precision, performance, or a mix of both depending on your use case.

### NEURAL

The `NEURAL` depth mode uses AI-powered disparity estimation to deliver a strong balance of depth accuracy and processing speed. It is ideal for applications that require reliable depth perception without sacrificing real-time performance.

#### Neural Depth Computational Performances on Embedded Devices

Performance data obtained with ZED SDK v5.0.1 RC, ZED X Driver v1.3.0, and ZED X camera.

**Orin AGX**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 30  | 5       | 26      |
| 2       | 30  | 6       | 50      |
| 4       | 30  | 26      | 53      |

**Orin NX 16**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 30  | 9       | 59      |
| 2       | 23  | 20      | 94      |
| 4       | 10  | 39      | 96      |

**Orin NX 8**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 12  | 22      | 90      |
| 2       | 5   | 25      | 93      |
| 4       | OOM | OOM     | OOM     |

**Nano 8 Gb**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 30  | 14      | 88      |
| 2       | 18  | 20      | 98      |
| 4       | 9   | 38      | 98      |

**Nano 4 Gb**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 30  | 12      | 70      |
| 2       | 17  | 18      | 96      |
| 4       | 6   | 35      | 98      |

#### Neural Depth Accuracy (ZED X)

| Distance Range (m) | Mean Error | Standard Deviation |
|---------------------|------------|--------------------|
| [0.3 - 4]           | < 1%       | Low                |
| [4 - 6]             | < 2.5%     | Low                |
| [6 - 9]             | < 4%       | Medium             |
| [10 - 12]           | < 6%       | High               |

> A lower standard deviation indicates more stable and accurate depth estimation, resulting in smoother and more reliable 3D point clouds. Higher deviation can lead to noise and distortion.

#### Enabling NEURAL Depth Mode

**C++**

```cpp
// Set depth mode in NEURAL
InitParameters init_parameters;
init_parameters.depth_mode = DEPTH_MODE::NEURAL;
```

**Python**

```python
# Set depth mode in NEURAL
init_parameters = sl.InitParameters()
init_parameters.depth_mode = sl.DEPTH_MODE.NEURAL
```

**C#**

```csharp
// Set depth mode in NEURAL
InitParameters init_parameters = new InitParameters();
init_parameters.depthMode = DEPTH_MODE.NEURAL;
```

### NEURAL LIGHT

The `NEURAL_LIGHT` depth mode provides AI-powered disparity estimation optimized for speed and efficiency. It enables real-time depth sensing with lower computational load, making it ideal for multi-camera setups and applications where fast processing is prioritized over maximum depth accuracy.

#### Neural Light Depth Computational Performances on Embedded Devices

**Orin AGX**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 30  | 5       | 11      |
| 2       | 30  | 6       | 23      |
| 4       | 30  | 22      | 46      |

**Orin NX 16**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 30  | 2       | 23      |
| 2       | 30  | 5       | 47      |
| 4       | 30  | 14      | 81      |

**Orin NX 8**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 30  | 24      | 80      |
| 2       | 13  | 27      | 80      |
| 4       | OOM | OOM     | OOM     |

**Nano 8 Gb**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 30  | 14      | 36      |
| 2       | 30  | 25      | 64      |
| 4       | 21  | 45      | 84      |

**Nano 4 Gb**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 30  | 15      | 28      |
| 2       | 30  | 25      | 55      |
| 4       | 19  | 40      | 90      |

#### Neural Light Depth Accuracy (ZED X)

| Distance Range (m) | Mean Error | Standard Deviation |
|---------------------|------------|--------------------|
| [0.3 - 3]           | < 1%       | Low                |
| [3 - 5]             | < 3%       | Medium             |
| [5 - 12]            | < 8%       | High               |

#### Enabling NEURAL LIGHT Depth Mode

**C++**

```cpp
// Set depth mode in NEURAL_LIGHT
InitParameters init_parameters;
init_parameters.depth_mode = DEPTH_MODE::NEURAL_LIGHT;
```

**Python**

```python
# Set depth mode in NEURAL_LIGHT
init_parameters = sl.InitParameters()
init_parameters.depth_mode = sl.DEPTH_MODE.NEURAL_LIGHT
```

**C#**

```csharp
// Set depth mode in NEURAL_LIGHT
InitParameters init_parameters = new InitParameters();
init_parameters.depthMode = DEPTH_MODE.NEURAL_LIGHT;
```

### NEURAL PLUS

The `NEURAL_PLUS` depth mode provides the highest depth accuracy and detail among all AI-powered modes. It is designed for applications that demand maximum precision and robustness, such as advanced robotics, inspection, and 3D reconstruction. While it requires more computational resources and delivers lower frame rates compared to other modes, `NEURAL_PLUS` excels in challenging environments and when capturing fine object details is critical.

#### Neural Plus Depth Computational Performances on Embedded Devices

**Orin AGX**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 29  | 7       | 90      |
| 2       | 17  | 11      | 90      |
| 4       | 8   | 21      | 97      |

**Orin NX 16**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 12  | 2       | 92      |
| 2       | 5   | 4       | 98      |
| 4       | 2   | 14      | 98      |

**Orin NX 8**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 3   | 20      | 97      |
| 2       | 1.3 | 25      | 98      |
| 4       | OOM | OOM     | OOM     |

**Nano 8 Gb**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 8   | 12      | 95      |
| 2       | 4   | 18      | 97      |
| 4       | 2   | 35      | 98      |

**Nano 4 Gb**

| Cameras | FPS | CPU (%) | GPU (%) |
|---------|-----|---------|---------|
| 1       | 8   | 10      | 94      |
| 2       | 3   | 19      | 98      |
| 4       | 1   | 34      | 98      |

#### Neural Plus Depth Accuracy (ZED X)

| Distance Range (m) | Mean Error | Standard Deviation |
|---------------------|------------|--------------------|
| [0.3 - 9]           | < 1%       | Low                |
| [9 - 12]            | < 2%       | Medium             |

#### Enabling NEURAL PLUS Depth Mode

**C++**

```cpp
// Set depth mode in NEURAL_PLUS
InitParameters init_parameters;
init_parameters.depth_mode = DEPTH_MODE::NEURAL_PLUS;
```

**Python**

```python
# Set depth mode in NEURAL_PLUS
init_parameters = sl.InitParameters()
init_parameters.depth_mode = sl.DEPTH_MODE.NEURAL_PLUS
```

**C#**

```csharp
// Set depth mode in NEURAL_PLUS
InitParameters init_parameters = new InitParameters();
init_parameters.depthMode = DEPTH_MODE.NEURAL_PLUS;
```

### Depth Modes Comparison

| Depth Mode    | Ideal Range | Benefits | Limitations |
|---------------|-------------|----------|-------------|
| NEURAL_LIGHT  | [0.3-5]     | Fastest depth mode available; Best for multi camera setup; Suited for mid-range obstacle avoidance | Smallest ideal depth range; May miss small objects or object details; Slightly less robust to environmental light changes than NEURAL |
| NEURAL        | [0.3-9]     | Balanced depth and performance; Better object detail than NEURAL_LIGHT; Suitable for most multi-camera applications; Same robustness to environmental changes as NEURAL_PLUS | Slower than NEURAL_LIGHT; Less detail than NEURAL_PLUS |
| NEURAL_PLUS   | [0.3-12]    | Highest object details available; Highest ideal depth range and stability; Best for detecting near, far, and small objects; Most robust to environmental changes (rain, sun) and light reflections | Slowest depth mode; May not be suited for multi camera setup |

> **Notes:**
> - The depth range is highly dependent on the camera baseline and optics. A bigger baseline produces increased depth range. Tests were conducted with a ZED X GS (lens of 2 mm) whose stereo baseline is 120 mm.
> - Jetson Power Profile: Tests were conducted using MAXN without Super mode.

---

## Depth Settings

Source: <https://www.stereolabs.com/docs/depth-sensing/depth-settings/>

### sl::InitParameters Depth Parameters

#### Depth Mode

Refer to the [Depth Modes](#depth-modes) section above for details about available depth modes for ZED cameras.

#### Depth Range

The depth range specifies minimum and maximum distances at which object depth can be estimated.

**ZED Mini**

- Focal Length: 3 mm
- Max Depth Range: 0.1 m to 15 m
- Ideal Depth Range: 0.1 m to 9 m

**ZED 2i**

- Wide: 2.1 mm focal length, 0.3 m - 20 m max, 0.3 m - 12 m ideal
- Narrow: 4 mm focal length, 1.5 m - 35 m max, 1.5 m - 20 m ideal

**ZED X**

- Wide: 2.2 mm focal length, 0.3 m - 20 m max, 0.3 m - 12 m ideal
- Narrow: 4 mm focal length, 1.0 m - 35 m max, 1.0 m - 20 m ideal

**ZED X Mini**

- Wide: 2.2 mm focal length, 0.1 m - 8 m max, 0.1 m - 4 m ideal
- Narrow: 4 mm focal length, 0.15 m - 12 m max, 0.15 m - 6 m ideal

#### Minimum Range

Adjust the minimum detectable depth using `depth_minimum_distance` in `InitParameters` to enable depth estimation for closer objects within hardware limits.

**C++**

```cpp
InitParameters init_parameters;
init_parameters.coordinate_units = UNIT::METERS;
init_parameters.depth_minimum_distance = 0.15; // Set the minimum depth perception distance to 15cm
```

**Python**

```python
init_params = sl.InitParameters()
init_parameters.coordinate_units = sl.UNIT.METER
init_parameters.depth_minimum_distance = 0.15 # Set the minimum depth perception distance to 15cm
```

**C#**

```csharp
InitParameters init_parameters = new InitParameters();
init_parameters.coordinateUnits = UNIT.METER;
init_parameters.depthMinimumDistance = 0.15f; // Set the minimum depth perception distance to 15cm
```

#### Maximum Range

Increase maximum detectable depth using `depth_maximum_distance` in `InitParameters` to detect farther objects, up to hardware limits. This proves useful for applications requiring extended-range depth data.

> **Note:** Depth accuracy decreases with distance. Consider the trade-off between range and accuracy. See the [Depth Accuracy](#depth-accuracy) section for details.

**C++**

```cpp
InitParameters init_parameters;
init_parameters.depth_mode = DEPTH_MODE::NEURAL;   // Set the depth mode to NEURAL
init_parameters.coordinate_units = UNIT::METER;
init_parameters.depth_maximum_distance = 40;        // Set the maximum depth perception distance to 40m
```

**Python**

```python
init_params = sl.InitParameters()
init_parameters.depth_mode = sl.DEPTH_MODE.NEURAL   # Set the depth mode to NEURAL
init_parameters.coordinate_units = UNIT.METER
init_parameters.depth_maximum_distance = 40          # Set the maximum depth perception distance to 40m
```

**C#**

```csharp
InitParameters init_parameters = new InitParameters();
init_parameters.depthMode = DEPTH_MODE.NEURAL;      // Set the depth mode to NEURAL
init_parameters.coordinateUnits = UNIT.METER;
init_parameters.depthMaximumDistance = 40;            // Set the maximum depth perception distance to 40m
```

**Tips:**

- Maximum depth range can be reduced to clamp values above a certain distance, useful for reducing depth jitter at extended distances.
- Increasing maximum range has no impact on memory or FPS.

#### Depth Stabilization

Depth stabilization reduces map jitter and enhances accuracy by temporally filtering depth data across frames. It leverages positional tracking to maintain stable estimates during camera motion, while intelligently distinguishing between static and dynamic regions to preserve moving object integrity.

Enabled by default. For improved computational performance, disable with `init_parameters.depth_stabilization = false`.

**Tips:**

- For fixed cameras, enable `PositionalTrackingParameters::set_as_static` with depth stabilization to allow the module to disable visual tracking.
- Applications requiring disabled Positional Tracking must set depth stabilization to 0, otherwise tracking activates automatically.
- High stabilization strength combined with quick motion may cause "ghosting" around fast objects; default setting is 30.

### sl::RuntimeParameters Depth Parameters

For additional information, see the [API documentation](https://www.stereolabs.com/docs/api/structsl_1_1RuntimeParameters.html).

#### Depth Confidence Filtering

Depth estimation introduces uncertainty, resulting in points with varying reliability. Filtering unreliable data improves precision for demanding applications.

The ZED SDK provides a confidence map where each pixel receives a value from 0 (high confidence) to 100 (low confidence), enabling exclusion of less trustworthy depth data.

**C++**

```cpp
sl::Mat confidence_map;
zed.retrieveMeasure(confidence_map, sl::MEASURE::CONFIDENCE);
```

**Python**

```python
confidence_map = sl.Mat()
zed.retrieve_measure(confidence_map, sl.MEASURE.CONFIDENCE)
```

**C#**

```csharp
Mat confidence_map = new Mat();
zed.RetrieveMeasure(confidence_map, MEASURE.CONFIDENCE);
```

Filter unreliable points by implementing custom filtering or setting the `sl::RuntimeParameters::confidence_threshold` parameter, which automatically removes points exceeding the specified confidence limit.

**Two confidence threshold types:**

1. **`confidence_threshold`** -- Filters depth points with low confidence, primarily removing unreliable measurements around object edges to prevent closely-spaced objects from appearing "linked."

2. **`texture_confidence_threshold`** -- Filters depth points in low-texture regions (uniform/featureless areas) where insufficient visual information makes reliable depth estimation difficult.

---

## Using the Depth Sensing API

Source: <https://www.stereolabs.com/docs/depth-sensing/using-depth/>

### Depth Sensing Configuration

To enable depth sensing, configure options in `InitParameters` during camera initialization. For runtime adjustments like toggling depth computation or changing sensing modes, use `RuntimeParameters` while the camera is running.

**C++**

```cpp
// Set configuration parameters
InitParameters init_params;
init_params.depth_mode = DEPTH_MODE::ULTRA; // Use ULTRA depth mode
init_params.coordinate_units = UNIT::MILLIMETER; // Use millimeter units (for depth measurements)
```

**Python**

```python
# Set configuration parameters
init_params = sl.InitParameters()
init_params.depth_mode = sl.DEPTH_MODE.ULTRA # Use ULTRA depth mode
init_params.coordinate_units = sl.UNIT.MILLIMETER # Use millimeter units (for depth measurements)
```

**C#**

```csharp
// Set depth mode in ULTRA
InitParameters init_parameters = new InitParameters();
init_parameters.depthMode = DEPTH_MODE.ULTRA; // Use ULTRA depth mode
init_parameters.coordinateUnits = UNIT.MILLIMETER; // Use millimeter units (for depth measurements)
```

For additional information on depth configuration parameters, refer to the [Depth Settings](#depth-settings) section above.

### Retrieving Depth Data

To obtain the depth map of a scene, call `grab()` to capture a new frame, then use `retrieveMeasure()` to access depth data aligned with the left image. The `retrieveMeasure()` function retrieves various data types including depth maps, confidence maps, normal maps, or point clouds based on the specified measure type.

**C++**

```cpp
sl::Mat image;
sl::Mat depth_map;
if (zed.grab() == ERROR_CODE::SUCCESS) {
  // A new image and depth is available if grab() returns SUCCESS
  zed.retrieveImage(image, VIEW::LEFT); // Retrieve left image
  zed.retrieveMeasure(depth_map, MEASURE::DEPTH); // Retrieve depth
}
```

**Python**

```python
image = sl.Mat()
depth_map = sl.Mat()
runtime_parameters = sl.RuntimeParameters()
if zed.grab(runtime_parameters) == sl.ERROR_CODE.SUCCESS:
  # A new image and depth is available if grab() returns SUCCESS
  zed.retrieve_image(image, sl.VIEW.LEFT) # Retrieve left image
  zed.retrieve_measure(depth_map, sl.MEASURE.DEPTH) # Retrieve depth
```

**C#**

```csharp
sl.Mat image = new sl.Mat();
sl.Mat depth_map = new sl.Mat();
uint mWidth = (uint)zed.ImageWidth;
uint mHeight = (uint)zed.ImageHeight;
image.Create(mWidth, mHeight, MAT_TYPE.MAT_8U_C4, MEM.CPU);
depth.Create(mWidth, mHeight, MAT_TYPE.MAT_32F_C1, MEM.CPU);

sl.RuntimeParameters runtimeParameters = new sl.RuntimeParameters();
if (zed.Grab(ref runtimeParameters) == sl.ERROR_CODE.SUCCESS) {
  // A new image and depth is available if Grab() returns SUCCESS
  zed.RetrieveImage(image, VIEW.LEFT); // Retrieve left image
  zed.RetrieveMeasure(depth_map, MEASURE.DEPTH); // Retrieve depth
}
```

#### Accessing Depth Values

The depth map is stored in a `sl::Mat` object functioning as a 2D matrix where each element represents the distance from the camera to a specific point in the scene. Each pixel at coordinates (X, Y) contains a 32-bit floating-point value indicating depth (Z) at that location, typically in millimeters unless otherwise configured.

To retrieve the depth value at a particular pixel, use the `getValue()` method provided by the SDK.

**C++**

```cpp
float depth_value = 0;
depth_map.getValue(x, y, &depth_value);
```

**Python**

```python
depth_value = depth_map.get_value(x, y)
```

**C#**

```csharp
depth_value.GetValue(1, 2, out float depth_value);
```

By default, depth values are expressed in millimeters. Units can be changed using `InitParameters::coordinate_units`. Advanced users can retrieve images, depth and point clouds in CPU memory (default) or GPU memory using `retrieveMeasure(*, *, MEM_GPU)`.

### Displaying Depth Image

The 32-bit depth map can be displayed as a grayscale 8-bit image. The ZED SDK scales real depth values to 8-bit values [0, 255], where 255 (white) represents the closest possible depth value and 0 (black) represents the most distant possible depth value. This process is called depth normalization.

To retrieve a depth image, use `retrieveImage(depth, VIEW::DEPTH)`.

> **Note:** Do not use the 8-bit depth image in your application for purposes other than displaying depth.

**C++**

```cpp
sl::Mat depth_for_display;
zed.retrieveImage(depth_for_display, VIEW::DEPTH);
```

**Python**

```python
depth_for_display = sl.Mat()
zed.retrieve_image(depth_for_display, sl.VIEW.DEPTH)
```

**C#**

```csharp
sl.Mat depth_for_display = new sl.Mat();
uint mWidth = (uint)zed.ImageWidth;
uint mHeight = (uint)zed.ImageHeight;
depth_for_display.Create(mWidth, mHeight, MAT_TYPE.MAT_32F_C1, MEM.CPU);
zed.RetrieveImage(depth_for_display, VIEW.DEPTH);
```

### Getting Point Cloud Data

The ZED camera provides a 3D point cloud, which is a collection of points in 3D space representing the scene. Each point in the point cloud corresponds to a pixel in the depth map and contains (X, Y, Z) coordinates along with color information (RGBA).

A 3D point cloud with (X, Y, Z) coordinates and RGBA color can be retrieved using `retrieveMeasure()`.

**C++**

```cpp
sl::Mat point_cloud;
zed.retrieveMeasure(point_cloud, MEASURE::XYZRGBA);
```

**Python**

```python
point_cloud = sl.Mat()
zed.retrieve_measure(point_cloud, sl.MEASURE.XYZRGBA)
```

**C#**

```csharp
sl.Mat point_cloud = new sl.Mat();
uint mWidth = (uint)zed.ImageWidth;
uint mHeight = (uint)zed.ImageHeight;
point_cloud.Create(mWidth, mHeight, MAT_TYPE.MAT_32F_C4, MEM.CPU);
zed.RetrieveMeasure(point_cloud, MEASURE.XYZRGBA);
```

To access a specific pixel value, use `getValue()`.

**C++**

```cpp
float4 point3D;
// Get the 3D point cloud values for pixel (i, j)
point_cloud.getValue(i, j, &point3D);
float x = point3D.x;
float y = point3D.y;
float z = point3D.z;
float color = point3D.w;
```

**Python**

```python
# Get the 3D point cloud values for pixel (i, j)
point3D = point_cloud.get_value(i, j)
x = point3D[0]
y = point3D[1]
z = point3D[2]
color = point3D[3]
```

**C#**

```csharp
float4 point3D = new float4();
// Get the 3D point cloud values for pixel (i, j)
point_cloud.GetValue(i, j, out point3D);
float x = point3D.x;
float y = point3D.y;
float z = point3D.z;
float color = point3D.w;
```

The point cloud stores its data on 4 channels using a 32-bit float for each channel. The last float stores color information, where R, G, B, and alpha channels (4 x 8-bit) are concatenated into a single 32-bit float.

You can choose between different color formats using `XYZ<COLOR>`. For example, BGRA color is available using `retrieveMeasure(point_cloud, MEASURE::XYZBGRA)`.

#### Measuring Distance in Point Cloud

When measuring distances, use the 3D point cloud instead of the depth map. The Euclidean distance formula calculates the distance of an object relative to the left eye of the camera.

**C++**

```cpp
float4 point3D;
// Measure the distance of a point in the scene represented by pixel (i, j)
point_cloud.getValue(i, j, &point3D);
float distance = sqrt(point3D.x * point3D.x + point3D.y * point3D.y + point3D.z * point3D.z);
```

**Python**

```python
# Measure the distance of a point in the scene represented by pixel (i, j)
point3D = point_cloud.get_value(i, j)
distance = math.sqrt(point3D[0] * point3D[0] + point3D[1] * point3D[1] + point3D[2] * point3D[2])
```

**C#**

```csharp
float4 point3D = new float4();
// Measure the distance of a point in the scene represented by pixel (i, j)
point_cloud.GetValue(i, j, out point3D);
float distance = (float)Math.Sqrt(point3D.x * point3D.x + point3D.y * point3D.y + point3D.z * point3D.z);
```

### Getting Normal Map

You can obtain a normal map by calling `retrieveMeasure()` with the `NORMALS` measure type. Surface normals are useful for applications such as traversability analysis and real-time lighting, as they describe the orientation of surfaces in the scene.

The normal map is stored as a 4-channel, 32-bit floating-point matrix, where the X, Y, and Z components represent the direction of the normal vector at each pixel. The fourth channel is unused.

**C++**

```cpp
sl::Mat normal_map;
zed.retrieveMeasure(normal_map, MEASURE::NORMALS);
```

**Python**

```python
normal_map = sl.Mat()
zed.retrieve_measure(normal_map, sl.MEASURE.NORMALS)
```

**C#**

```csharp
sl.Mat normal_map = new sl.Mat();
uint mWidth = (uint)zed.ImageWidth;
uint mHeight = (uint)zed.ImageHeight;
normal_map.Create(mWidth, mHeight, MAT_TYPE.MAT_32F_C4, MEM.CPU);
zed.RetrieveMeasure(normal_map, MEASURE.NORMALS);
```

To access the normal vector at a specific pixel, use the `getValue()` method, which returns the (X, Y, Z) components of the normal.

### Adjusting Depth Resolution

To optimize performance and reduce data acquisition time, you can retrieve depth or point cloud data at a lower resolution by specifying the desired width and height in the `retrieveMeasure()` function. Additionally, you can choose whether the data is stored in CPU (RAM) or GPU memory by setting the appropriate memory type parameter. This flexibility allows you to balance processing speed and resource usage according to your application's needs.

**C++**

```cpp
sl::Mat point_cloud;
// Retrieve a resized point cloud
// width and height specify the total number of columns and rows for the point cloud dataset
width = zed.getResolution().width / 2;
height = zed.getResolution().height / 2;
zed.retrieveMeasure(point_cloud, MEASURE::XYZRGBA, MEM::GPU, width, height);
```

**Python**

```python
point_cloud = sl.Mat()
# Retrieve a resized point cloud
# width and height specify the total number of columns and rows for the point cloud dataset
width = zed.get_resolution().width / 2
height = zed.get_resolution().height / 2
zed.retrieve_measure(point_cloud, sl.MEASURE.XYZRGBA, sl.MEM.GPU, width, height)
```

**C#**

```csharp
sl.Mat point_cloud = new sl.Mat();
// Retrieve a resized point cloud
// width and height specify the total number of columns and rows for the point cloud dataset
width = zed.ImageWidth / 2;
height = zed.ImageHeight / 2;
point_cloud.Create(width, height, MAT_TYPE.MAT_32F_C4, MEM.CPU);
zed.RetrieveMeasure(point_cloud, MEASURE.XYZRGBA, MEM.GPU, new Resolution(width, height));
```

### Code Example

For code examples, check out the [Tutorial](https://github.com/stereolabs/zed-examples/tree/master/tutorials/tutorial%203%20-%20depth%20sensing) and [Sample](https://github.com/stereolabs/zed-examples/tree/master/depth%20sensing) on GitHub.
