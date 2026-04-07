---
description: >
  ZED X One (GMSL2 monocular/stereo cameras) — overview, monocular setup, raw NV12 access,
  dual stereo configuration with calibration, Docker setup, PC development, and troubleshooting.
sources:
  - https://www.stereolabs.com/docs/cameras/zed-x-one/
  - https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-mono/
  - https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-nv12-access/
  - https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-stereo/
  - https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-and-docker/
  - https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-dev-on-pc/
  - https://www.stereolabs.com/docs/cameras/zed-x-one/troubleshooting/
---

# ZED X One — GMSL2 Monocular / Stereo Camera

## Table of Contents

- [ZED X One Overview](#zed-x-one-overview)
- [ZED X One Monocular Setup](#zed-x-one-monocular-setup)
- [Raw NV12 Buffer Access](#raw-nv12-buffer-access)
- [Dual ZED X One Stereo Configuration](#dual-zed-x-one-stereo-configuration)
- [ZED X One with Docker](#zed-x-one-with-docker)
- [Developing with ZED X One Stereo on a PC](#developing-with-zed-x-one-stereo-on-a-pc)
- [Troubleshooting](#troubleshooting)

---

## ZED X One Overview

Source: https://www.stereolabs.com/docs/cameras/zed-x-one/

### About ZED X One

The ZED X One is a professional-grade camera specifically engineered for robotic applications in production environments. These cameras feature multiple configuration options including Global or Rolling Shutter modes, 4K HDR capabilities with exceptional low-light performance, and selectable lens options (wide or narrow field of view). The integrated high-performance IMU enables positional tracking functionality.

The camera's secure GMSL2 connection provides low-latency video transmission without electromagnetic interference, making it ideal for robotics platform integration.

### Usage Modes

#### Monocular Operation

The ZED X One functions as a standalone monocular camera accessible through the ZED SDK using the `sl::CameraOne` object. Users can capture high-resolution images, video, and sensor data.

#### Stereo Configuration

Two ZED X One units can be paired side-by-side at a fixed distance with rigid mounting to create a stereo system featuring modular baseline capabilities. The distance between cameras affects the 3D depth range:

- **Small baseline:** Accurate close-range viewing; shorter maximum distance
- **Large baseline:** Extended range; increased minimum working distance

Lens selection also impacts effective depth range. After mechanical setup, the system requires calibration to compute the relative position between cameras for subsequent depth computation. Once calibrated, the pair functions as a standard ZED SDK input with full feature availability.

### System Requirements

ZED X One cameras require specific hardware due to their GMSL2 connection, which is incompatible with USB. Users must have:

- NVIDIA Jetson device properly configured for GMSL2 cameras
- Appropriate capture card hardware
- Proper power supply meeting GMSL2 requirements

The cameras are not compatible with all host machines.

### Remote Access and Development

- **Virtual Display:** For remote robotic setups requiring GUI access without physical monitors, the Virtual Display feature on NVIDIA Jetson enables running applications through VNC, NoMachine, or X11 forwarding.
- **Desktop Development:** Developers working on projects for embedded platforms can utilize ZED SDK / ZED Media Server Streaming to develop on desktop machines as though the camera were directly connected.

### Advanced Features

**Raw NV12 Buffer Access:** For performance-critical applications like GStreamer pipelines or NVIDIA DeepStream, the ZED SDK provides zero-copy API access to raw NV12 buffers directly from the capture pipeline, enabling low-latency integration with NVIDIA multimedia frameworks while avoiding unnecessary memory copies.

---

## ZED X One Monocular Setup

Source: https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-mono/

### Install the GMSL2 Driver

> **Important:** This procedure applies only to ZED Box Orin, ZED Box Mini, or official NVIDIA Jetson development kits equipped with a ZED Link GMSL2 Capture Card. For different GMSL2 systems, refer to your hardware manufacturer's instructions.

ZED X One cameras require a GMSL2 driver for proper operation. This driver configures the GMSL2 device and is hardware-dependent.

#### Download and Installation

Download the appropriate driver from the [ZED X Driver download page](https://www.stereolabs.com/developers/drivers).

> **Note:** Always verify the latest driver version available. Installing the most recent version is recommended.

Install using:

```bash
sudo dpkg -i stereolabs-<board>_X.X.X-<deserializer>-L4TZZ.Z.Z_arm64.deb
```

Where:
- `X.X.X` = driver version
- `<board>` = board model
- `<deserializer>` = deserializer type
- `L4TZZ.Z.Z` = Jetson Linux version (corresponding to JetPack version)

**Example:** ZED X Driver v1.3.2 on L4T 36.4.0 (JetPack 6.2) with ZED Link Duo:

```bash
sudo dpkg -i stereolabs-zedlink-duo_1.3.2-LI-MAX96712-all-L4T36.4.0_arm64.deb
```

> **Note:** If installation fails due to missing dependencies, install `libqt5core5a`:
>
> ```bash
> sudo apt install libqt5core5a
> ```

After installation, **reboot** your NVIDIA Jetson platform.

For troubleshooting, refer to the [ZED Link troubleshooting guide](https://www.stereolabs.com/docs/embedded/zed-link/troubleshooting/).

### Use the ZED X One with the ZED SDK

The ZED SDK provides built-in support for ZED X One monocular data acquisition using the `sl::CameraOne` class, enabling direct camera management through the SDK without external tools.

#### Install the ZED SDK

The [ZED SDK](https://www.stereolabs.com/docs/development/zed-sdk/) enables image processing from ZED X One cameras in monocular mode. The `sl::CameraOne` class provides core functionality to retrieve raw and rectified images plus inertial data.

To get started, [download and install the ZED SDK on your NVIDIA Jetson platform](https://www.stereolabs.com/docs/development/zed-sdk/jetson/).

#### Sample Code -- C++

```cpp
#include <sl/CameraOne.hpp>

using namespace sl;

// Set the input from stream
InitParametersOne init_parameters;

// Set any InitParametersOne as needed to configure the camera settings

sl::CameraOne zed_one;

// Open the camera
ERROR_CODE err = zed_one.open(init_parameters);
if (err != ERROR_CODE::SUCCESS)
    exit(-1);

Mat bgra;

while (!exit_app) {
    if (zed_one.grab() == ERROR_CODE::SUCCESS) {
        zed_one.retrieveImage(bgra); // Retrieve the BGRA image (default format)

        // Any processing
    }
}
// Close the camera
zed_one.close();
```

#### Sample Code -- Python

```python
import pyzed.sl as sl

zed_one = sl.CameraOne()

# Set the input from stream
init = sl.InitParametersOne()

# Set any InitParametersOne as needed to configure the camera settings

# Open the camera
err = zed_one.open(init)
if err != sl.ERROR_CODE.SUCCESS:
    exit(1)

bgra = sl.Mat()

while not exit_app:
    if zed_one.grab() == sl.ERROR_CODE.SUCCESS:
        zed_one.retrieve_image(bgra)  # Retrieve the BGRA image (default format)
        # Any processing

# Close the camera
zed_one.close()
```

For more details, refer to the [ZED SDK API documentation](https://www.stereolabs.com/docs/api).

### Use the ZED X One with NVIDIA Libargus Camera API

The camera can be opened using the [Libargus Camera API](https://docs.nvidia.com/jetson/l4t-multimedia/group__LibargusAPI.html), NVIDIA's tools for opening GMSL2 and CSI-connected cameras on Jetson.

#### Installation

Ensure the multimedia API is installed:

```bash
sudo apt install nvidia-l4t-jetson-multimedia-api
```

#### Compilation

```bash
cp -r /usr/src/jetson_multimedia_api/* ./
sudo apt install libgtk-3-dev
cd argus
mkdir build && cd build && cmake .. && make
cp apps/camera/ui/camera/argus_camera ./
./argus_camera
```

### Use the ZED X One with GStreamer

#### Using the Stereolabs `zedxonesrc` Source Element

Refer to the [ZED GStreamer plugin documentation](https://www.stereolabs.com/docs/gstreamer/zedxone-camera-source/) to leverage the camera's full capabilities.

#### Using the NVIDIA `nvarguscamerasrc` Source Element

To open the camera using the nvarguscamera GStreamer plugin:

```bash
gst-launch-1.0 nvarguscamerasrc sensor-id=0 ! 'video/x-raw(memory:NVMM), width=(int)1920, height=(int)1200, framerate=30/1' ! nvvidconv flip-method=0 ! 'video/x-raw, format=(string)I420' ! xvimagesink -e
```

Refer to the [NVIDIA documentation](https://docs.nvidia.com/jetson/archives/r35.5.0/DeveloperGuide/SD/Multimedia/AcceleratedGstreamer.html) for more information.

### Use the ZED X One with the Open Source Driver ZED X Open Capture

To use the open source ZED X One capture API, visit [https://github.com/stereolabs/zedx-one-capture](https://github.com/stereolabs/zedx-one-capture).

Compile the library, then modify the sample to fit your application needs. The library is based on NVIDIA's multimedia API.

> **Note:** IMU data retrieval support will be available in a future release.

### Use the ZED X One with ROS 2

The [ZED ROS 2 wrapper](https://www.stereolabs.com/docs/ros2/) supports monocular ZED X One data publishing.

When launching the ZED ROS 2 node, set the `camera_model` parameter to an available model: `zedxonegs` or `zedxone4k`.

**Examples:**

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxonegs
```

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zedxone4k
```

For additional details, refer to the [ZED ROS 2 documentation](https://www.stereolabs.com/docs/ros2/).

---

## Raw NV12 Buffer Access

Source: https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-nv12-access/

The RawBuffer API provides direct access to native **NvBufSurface** buffers from the ZED X One camera capture pipeline. This zero-copy interface allows developers to access image data without copying, enabling integration with NVIDIA multimedia frameworks.

> **Note:** This API is only available in ZED SDK version 5.2 and later, exclusively on NVIDIA Jetson platforms with GMSL2 cameras. It is not supported on x86 platforms, USB cameras, or with SVO/Network streaming sources.

### Use Cases

- **GStreamer pipelines** -- Direct frame delivery without memory duplication
- **NVIDIA DeepStream** -- Low-latency inference for real-time object detection
- **Custom CUDA processing** -- Immediate GPU buffer access
- **Hardware video encoding** -- Direct NVENC integration

### Enabling the API

Define `SL_ENABLE_ADVANCED_CAPTURE_API` **before** including the ZED SDK header:

```cpp
#define SL_ENABLE_ADVANCED_CAPTURE_API
#include <sl/CameraOne.hpp>
```

### Code Example

```cpp
#define SL_ENABLE_ADVANCED_CAPTURE_API
#include <sl/CameraOne.hpp>
#include <nvbufsurface.h>

using namespace sl;

int main() {
    CameraOne zed;
    InitParametersOne init_params;
    init_params.camera_resolution = RESOLUTION::HD1080;
    init_params.camera_fps = 30;

    if (zed.open(init_params) != ERROR_CODE::SUCCESS) {
        return -1;
    }

    while (true) {
        if (zed.grab() == ERROR_CODE::SUCCESS) {
            RawBuffer raw;
            if (zed.retrieveImage(raw) == ERROR_CODE::SUCCESS) {
                if (raw.isValid()) {
                    void* nvbuf = raw.getRawBuffer();
                    NvBufSurface* surf = static_cast<NvBufSurface*>(nvbuf);

                    uint64_t timestamp = raw.getTimestamp();
                    unsigned int width = raw.getWidth();
                    unsigned int height = raw.getHeight();

                    // Process the NV12 buffer...
                }
            }
        }
    }

    zed.close();
    return 0;
}
```

### DeepStream Integration

For NVIDIA DeepStream pipelines, pass the `NvBufSurface` object directly to your inference pipeline:

```cpp
#define SL_ENABLE_ADVANCED_CAPTURE_API
#include <sl/Camera.hpp>
#include <nvbufsurface.h>
#include <nvds_meta.h>

RawBuffer raw;
if (zed.retrieveImage(raw) == ERROR_CODE::SUCCESS && raw.isValid()) {
    NvBufSurface* surface = static_cast<NvBufSurface*>(raw.getRawBuffer());
    
    // Feed surface to DeepStream batch
    // surface->surfaceList[0] contains the NV12 frame data
}
```

### Critical Warnings

**DO NOT manually destroy the NvBufSurface.** Calling functions like `NvBufSurfaceDestroy` or `NvBufSurfaceUnMap` will cause crashes or undefined behavior.

Key constraints:

- The SDK manages all buffer memory -- you have read-only access
- Hold the `RawBuffer` for minimal duration to avoid blocking the capture pipeline
- Currently only `RAW_BUFFER_TYPE::NVBUFSURFACE` is supported
- This API is available exclusively on NVIDIA Jetson platforms with GMSL2 cameras

### Buffer Format

Raw buffers contain **NV12** formatted image data:

- **Y plane** -- Full-resolution luminance information
- **UV plane** -- Half-resolution (2x2 subsampled) chrominance data

This native capture format from the ZED X One sensor provides optimal performance for pipelines processing NV12 directly.

---

## Dual ZED X One Stereo Configuration

Source: https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-stereo/

Two ZED X One cameras can be combined to create a Virtual Stereo Vision system, functioning as a single stereoscopic camera similar to the ZED 2i or ZED X.

When creating a stereo rig, synchronization between the two cameras is essential for accurate depth perception. The ZED X One cameras support hardware synchronization via the GMSL2 interface when used with ZED Link capture cards, ZED Box Orin, or ZED Box Mini, ensuring simultaneous image capture with 15 us accuracy.

This configuration enables you to build a custom stereo rig with a baseline (distance between cameras) tailored to specific application requirements:

- **Short baselines** (down to 25 mm with ZED X One S models) for close-range depth perception
- **Long baselines** (up to several meters) for enhanced long-range accuracy

### Field of View and Baseline Calculations

For a fixed minimum depth value `h`, calculate the required baseline B as:

```
B = (2 * h * tan(a/2))
```

Conversely, if you fix the baseline B, the corresponding minimum depth value h is:

```
h = (B / (2 * tan(a/2)))
```

Where `a` is the horizontal Field of View (FOV) of the camera model.

To obtain a minimum depth value that allows for a usable depth map, apply a 6x factor to h:

```
h' = 6*h ; B' = B/6
```

#### Maximum Depth Calculation

The maximum depth (in meters) can be calculated with:

```
D_max = (f * B) / (s * disparity_min)
```

Where:
- **B** is the baseline in meters
- **f** is the focal length of the optics in meters
- **sens_w** is the size of the CMOS sensor in meters
- **res_W** is the image resolution (use 1280 as approximation)

Retrieve Field of View and focal length information from product datasheets.

For detailed assembly guidance, refer to the support article on setting up your stereo rig with two ZED X One cameras.

### Software Installation

You need two main software components:

1. **GMSL2 driver** -- to configure the system to control GMSL2 cameras and retrieve images and inertial data
2. **ZED SDK** -- to process stereoscopic data

#### Installing the GMSL2 Driver

> **Important:** This procedure is valid only for ZED Box Orin, ZED Box Mini, or official NVIDIA Jetson development kit platforms equipped with a ZED Link GMSL2 Capture Card.

Download the appropriate driver from the [ZED X Driver download page](https://www.stereolabs.com/developers/drivers).

```bash
sudo dpkg -i stereolabs-<board>_X.X.X-<deserializer>-L4TZZ.Z.Z_arm64.deb
```

Where:
- `X.X.X` is the driver version
- `<board>` is the board model
- `<deserializer>` is the deserializer type
- `L4TZZ.Z.Z` is the Jetson Linux version

**Example:** For ZED X Driver v1.3.2 on L4T 36.4.0 (JetPack 6.2) with Stereolabs ZED Link Duo GMSL2 Capture Card:

```bash
sudo dpkg -i stereolabs-zedlink-duo_1.3.2-LI-MAX96712-all-L4T36.4.0_arm64.deb
```

> **Note:** If installation fails due to missing dependencies, install `libqt5core5a`:
>
> ```bash
> sudo apt install libqt5core5a
> ```

**Reboot** your NVIDIA Jetson platform after installation.

For troubleshooting, refer to the [ZED Link troubleshooting guide](https://www.stereolabs.com/docs/embedded/zed-link/troubleshooting/).

#### Installing the ZED SDK

The [ZED SDK](https://www.stereolabs.com/docs/development/zed-sdk/) enables processing of stereoscopic data from dual ZED X One cameras configured as a virtual stereo system. The `sl::Camera` class provides core functionality for depth computation and 3D perception.

[Download and install the ZED SDK on your NVIDIA Jetson platform](https://www.stereolabs.com/docs/development/zed-sdk/jetson/).

### Configuring the Custom Stereo Rig

The two ZED X One cameras should be rigidly mounted parallel to each other at a fixed distance (baseline). It is **critical that the cameras don't move in rotation or translation relative to each other over time**. Any minimum movement will require a new calibration.

Mechanical stability should be adapted depending on usage conditions, especially vibration or shocks that could impact camera alignments and significantly decrease depth processing accuracy.

In the Stereolabs store, find the [Dual Camera Mount for ZED X One](https://www.stereolabs.com/store/products/zed-x-one-dual-mount) to mount two cameras at a fixed distance and test the stereo setup.

### Calibrating the Custom Stereo Rig

The calibration step is **mandatory** to perform depth estimation using the ZED SDK API.

This procedure determines:
- **Intrinsic parameters:** The optical characteristics of each monocular camera (focal length, optical center, distortion)
- **Extrinsic parameters:** The relative position and orientation between the two cameras in the stereo rig

#### When Calibration Must Be Performed

Calibration **must be performed** in these scenarios:

- **Initial setup:** When first assembling your dual ZED X One stereo rig
- **Mechanical changes:** If the relative position or orientation between cameras is altered or modified, even if slightly
- **Physical impact:** After any shock, vibration, or mechanical stress that could affect camera optical axis alignment

> **Warning:** If the mechanical configuration changes and the system is not recalibrated, depth measurements will be compromised and inaccurate.

#### Understanding Calibration Parameters

While monocular ZED X One cameras come with pre-assembled optics that are factory-calibrated for intrinsic parameters, the calibration process for a custom stereo system typically refines the intrinsic parameters and estimates custom extrinsic parameters for optimal depth estimation accuracy.

Only the extrinsic parameters (translations and rotations between cameras) are affected by mechanical changes to the rig. However, refining intrinsic parameters during calibration can improve overall accuracy.

#### User Responsibility

It is the user's responsibility to:
- Perform the calibration procedure when required
- Manage and distribute calibration files to all systems using the custom stereo rig
- Recalibrate when mechanical changes occur

#### Using the ZED OpenCV Stereo Calibration Tool

A calibration tool using the [OpenCV library](https://opencv.org/) is provided to perform stereo calibration of the dual ZED X One system. It simplifies the calibration process and generates calibration files compatible with the ZED SDK.

The tool is open-source and available on [GitHub](https://github.com/stereolabs/zed-opencv-calibration).

##### Building the Tool

```bash
git clone https://github.com/stereolabs/zed-opencv-calibration.git
cd zed-opencv-calibration

# Build the stereo calibration tool and the reprojection viewer
mkdir build && cd build
cmake ..
make -j$(nproc)
```

##### Performing Stereo Calibration

The Stereo Calibration Tool enables precise calibration of ZED stereo cameras and custom stereo rigs using a checkerboard pattern. This process computes intrinsic camera parameters (focal length, principal point, distortion coefficients) and extrinsic parameters (relative position and orientation between cameras).

**Checkerboard Pattern Requirements:**

- **Default configuration:** 9x6 checkerboard with 25.4 mm squares
- **Custom patterns:** Supported via command-line options

> **Important:** Pattern dimensions refer to the number of **inner corners** (where black and white squares meet), not the number of squares.

**Preparing the Calibration Target:**

- Print the checkerboard pattern maximized and attach it to a rigid, flat surface
- Ensure the pattern is perfectly flat and well-lit
- Avoid reflections or glare on the checkerboard surface

##### Running the Calibration

Default command:

```bash
cd build/stereo_calibration/
./zed_stereo_calibration
```

This command tries to open the first connected ZED camera for live calibration using default checkerboard settings.

**Command-line options:**

```
Usage: ./zed_stereo_calibration [options]
  --h_edges <value>      Number of horizontal inner edges of the checkerboard
  --v_edges <value>      Number of vertical inner edges of the checkerboard
  --square_size <value>  Size of a square in the checkerboard (in mm)
  --svo <file>           Path to the SVO file.
  --fisheye              Use fisheye lens model.
  --virtual              Use ZED X One cameras as a virtual stereo pair.
  --left_id <id>         Id of the left camera if using virtual stereo.
  --right_id <id>        Id of the right camera if using virtual stereo.
  --left_sn <sn>         S/N of the left camera if using virtual stereo.
  --right_sn <sn>        S/N of the right camera if using virtual stereo.
  --help, -h             Show this help message.
```

##### Stereo Calibration Example Commands

ZED Stereo Camera using an SVO file:

```bash
./zed_stereo_calibration --svo <full_path_to_svo_file>
```

Virtual Stereo Camera using camera IDs:

```bash
./zed_stereo_calibration --virtual --left_id 0 --right_id 1
```

Virtual Stereo Camera using serial numbers with custom checkerboard (12x9 with 30mm squares):

```bash
./zed_stereo_calibration --virtual --left_sn <serial_number> --right_sn <serial_number> --h_edges 12 --v_edges 9 --square_size 30.0
```

Virtual Stereo Camera with fisheye lenses using serial numbers:

```bash
./zed_stereo_calibration --fisheye --virtual --left_sn <serial_number> --right_sn <serial_number>
```

> **Note:** Obtain serial numbers or IDs of connected ZED cameras by running:
>
> ```bash
> ZED_Explorer --all
> ```

##### The Calibration Process

The calibration process consists of two main phases:

1. **Data Acquisition:** Move the checkerboard in front of the camera(s) to capture diverse views. The tool provides real-time feedback on captured data quality.
2. **Calibration Computation:** Once sufficient data is collected, the tool computes calibration parameters and saves them to two files.

During data acquisition, press the **Spacebar** or **S** key to capture images when the checkerboard is in a desired position.

- If the checkerboard is detected in both images and captured data differs enough from previously captured images, the data is accepted and quality indicators are updated
- If not accepted, a message indicates the reason (e.g., checkerboard not detected, insufficient variation)

Blue dots appearing on the left image indicate the center of each detected and accepted checkerboard. Dot size indicates relative checkerboard size (bigger dots mean closer to camera).

**Good calibration data collection guidelines:**

- The checkerboard must always be fully visible in both left and right images
- Move the checkerboard over a wide area of the image frame (green polygons on the left image indicate covered areas; red areas indicate uncovered zones)
- Move the checkerboard closer and farther from the camera to ensure depth variation (at least one image covering almost the full left frame is required)
- Tilt and rotate the checkerboard to provide different angles

The "X", "Y", "Size", and "Skew" percentages indicate the quality of collected data for each criterion:

- **X and Y:** Coverage of horizontal and vertical area by checkerboard corners
- **Size:** Range of checkerboard sizes (distance variation)
- **Skew:** Range of skew angles (0 degrees = fronto-parallel; practical maximum around 40 degrees)

**Tips to improve each metric:**

- **X and Y:** Move the checkerboard to the edges and corners of the left image while keeping it fully visible in the right frame
- **Size:** Move the checkerboard closer and farther; acquire at least one image where it covers almost the full left image
- **Skew:** Rotate the checkerboard in different angles; easier when closer and rotated around vertical and horizontal axes simultaneously

The calibration process automatically starts when all metrics reach 100% and the minimum number of samples is collected, or the maximum number of samples is reached.

The GUI shows for each metric:
- **MIN_VAL:** Minimum value stored in all collected samples
- **MAX_VAL:** Maximum value stored in all collected samples
- **COVERAGE:** Difference between MIN_VAL and MAX_VAL
- **REQUIRED:** Minimum required value for COVERAGE
- **SCORE:** Percentage score calculated as (COVERAGE / REQUIRED) * 100%

Calibration steps:
1. The left camera is calibrated first, followed by the right camera to obtain intrinsic parameters
2. Stereo calibration is performed to compute extrinsic parameters between the two cameras

Good calibration results typically yield a reprojection error below 0.5 pixels for each calibration step.

If any reprojection error is too high, the calibration is not accurate enough and should be redone. Before recalibrating, verify:
- The checkerboard is perfectly flat and securely mounted
- The checkerboard is well-lit with even, stable lighting
- Camera lenses are clean and free of smudges or dust
- No reflections or glare appear on the checkerboard surface

After good calibration is complete, two files are generated:

- `zed_calibration_<serial_number>.yml` -- Contains intrinsic and extrinsic parameters in OpenCV format
- `SN<serial_number>.conf` -- Contains calibration parameters in ZED SDK format

**Using calibration files in ZED SDK applications:**

- Use the `sl::InitParameters::optional_opencv_calibration_file` parameter to load calibration from the OpenCV file
- Manually copy the `SN<serial_number>.conf` file to the ZED SDK calibration folder:
  - Linux: `/usr/local/zed/settings/`
  - Windows: `C:\ProgramData\Stereolabs\settings`
- Use the `sl::InitParameters::optional_settings_path` to indicate where to find the custom `SN<serial_number>.conf` calibration file

> **Note:** When calibrating a virtual ZED X One stereo rig, the serial number of the Virtual Stereo Camera is generated by the ZED SDK using the serial numbers of the two individual cameras. Use this generated serial number when loading the calibration in your application to have a unique identifier for the virtual stereo setup.

### Using the Custom Stereo Rig with the ZED SDK

#### Using ZED SDK Virtual Stereo API Functions (Recommended -- For ZED SDK >= v5.1)

The ZED SDK version 5.1 and later includes built-in support for data acquisition from dual ZED X One stereo systems, allowing you to open and manage the virtual stereo rig directly through the SDK.

Verify that the two ZED X One cameras are properly connected and recognized by running `ZED_Explorer --all` or `ZED_Studio --list`.

The ZED SDK requires a valid calibration file for accurate depth computation. Follow the calibration procedure to generate this file.

To open the dual ZED X One stereo system, specify the serial numbers or camera IDs of both cameras in the `InitParameters` when initializing the `sl::Camera` object.

##### Using Camera Serial Numbers

**C++:**

```cpp
#include <sl/Camera.hpp>

// Generate a unique virtual stereo serial number from the two ZED X One serial numbers
unsigned int sn_left = 123456789;  // Serial number of the left ZED X One
unsigned int sn_right = 987654321; // Serial number of the right ZED X One
int sn_stereo = sl::generateVirtualStereoSerialNumber(sn_left, sn_right);
init_params.input.setVirtualStereoFromSerialNumbers(sn_left, sn_right, sn_stereo);

// Set any other InitParameters as needed to configure the camera and depth settings

// If an Optional OpenCV calibration file is not provided, the SDK will look for
// the file named SN<sn_stereo>.conf in the settings folder.
// init_params.optional_opencv_calibration_file = "/path/to/opencv_calibration_file.yaml";

// Open the camera
ERROR_CODE err = zed.open(init_parameters);
if (err != ERROR_CODE::SUCCESS)
    exit(-1);

while (!exit_app) {
    if (zed.grab() == ERROR_CODE::SUCCESS) {
        // Any processing
    }
}
// Close the camera
zed.close();
```

**Python:**

```python
# Set the input from stream
init = sl.InitParameters()

# Generate a unique virtual stereo serial number from the two ZED X One serial numbers
sn_left = 123456789  # Serial number of the left ZED X One
sn_right = 987654321 # Serial number of the right ZED X One
sn_stereo = sl.generate_virtual_stereo_serial_number(sn_left, sn_right)
init.set_virtual_stereo_from_serial_numbers(sn_left, sn_right, sn_stereo)

# Set any other InitParameters as needed to configure the camera and depth settings

# If an Optional OpenCV calibration file is not provided, the SDK will look for
# the file named SN<sn_stereo>.conf in the settings folder.
# init.optional_opencv_calibration_file = "/path/to/opencv_calibration_file.yaml"

# Open the camera
err = zed.open(init)
if err != sl.ERROR_CODE.SUCCESS:
  exit(1)

while not exit_app:
    if zed.grab() == sl.ERROR_CODE.SUCCESS:
        # Any processing

# Close the camera
zed.close()
```

##### Using Camera IDs

**C++:**

```cpp
#include <sl/Camera.hpp>
#include <sl/CameraOne.hpp>

// Generate a unique virtual stereo serial number from the two ZED X One serial numbers
int sn_stereo = 11xxxxxxxx; // Custom serial number for the virtual stereo camera
int id_left = 0;  // Camera ID of the left ZED X One
int id_right = 1; // Camera ID of the right ZED X One
init_params.input.setVirtualStereoFromCameraIDs(id_left, id_right, sn_stereo);

// Set any other InitParameters as needed to configure the camera and depth settings

// If an Optional OpenCV calibration file is not provided, the SDK will look for
// the file named SN<sn_stereo>.conf in the settings folder.
// init_params.optional_opencv_calibration_file = "/path/to/opencv_calibration_file.yaml";

// Open the camera
ERROR_CODE err = zed.open(init_parameters);
if (err != ERROR_CODE::SUCCESS)
    exit(-1);

while (!exit_app) {
    if (zed.grab() == ERROR_CODE::SUCCESS) {
        // Any processing
    }
}
// Close the camera
zed.close();
```

**Python:**

```python
# Set the input from stream
init = sl.InitParameters()
id_left = 0  # Camera ID of the left ZED X One
id_right = 1 # Camera ID of the right ZED X One
sn_stereo = 11xxxxxxxx # Custom serial number for the virtual stereo camera
init.set_virtual_stereo_from_camera_id(id_left, id_right, sn_stereo)

# Set any other InitParameters as needed to configure the camera and depth settings

# Open the camera
err = zed.open(init)
if err != sl.ERROR_CODE.SUCCESS:
  exit(1)

while not exit_app:
    if zed.grab() == sl.ERROR_CODE.SUCCESS:
        # Any processing

# Close the camera
zed.close()
```

> **Note:** You can use any custom serial numbers in the range [110000000, 119999999], but using the serial number generated from the two ZED X One cameras using the function `sl::generateVirtualStereoSerialNumber` is recommended to avoid conflicts with existing devices.

#### Using the ZED Media Server Tool (Obsolete -- For ZED SDK < v5.1)

For earlier SDK versions, use the ZED Media Server tool to configure a virtual Stereo camera from 2 ZED X One:

```bash
ZED_Media_Server
```

> **Note:** At the time of writing, some ZED SDK Tools (e.g., ZED Depth Viewer, ZEDfu) do not support the new virtual stereo API. In this case, use the ZED Media Server tool to create a virtual stereo camera from the two ZED X One cameras.

The GUI of ZED Media Server allows setting up which cameras should be the left and the right using the cameras' serial numbers. Ensure the system is correctly set up, especially that the left and right cameras are not swapped.

Set the desired resolution, then click the bottom **SAVE** button once the system is set up. This stores the configuration of the cameras serial numbers and their location in the virtual stereo system. The virtual camera serial number SN on the left will be the one used in the ZED SDK to reference this virtual stereo camera.

Click the **Stream** button to start streaming the images. The GUI can be closed; a service (`zed_media_server_cli`) will automatically start in the background to stream data from the virtual stereo camera.

There is no restriction on the virtual camera setup, which allows for a ZED X One to be used in **multiple virtual stereo cameras** at once.

The ZED X One stereo system can be opened with the ZED SDK by using the streaming input mode, on the same machine or remotely on a local network. The images are encoded and sent by the ZED Media Server tool (either by the GUI or the service).

To open a ZED X One stereo system, use the streaming address of the Jetson (`127.0.0.1` for localhost) and the streaming port, typically `34000`, in `InitParameters`.

**C++:**

```cpp
// Set the input from stream
InitParameters init_parameters;
init_parameters.input.setFromStream("127.0.0.1", 34000); // Specify the IP and port of the sender

// Set any other InitParameters as needed to configure the camera and depth settings

// Open the camera
ERROR_CODE err = zed.open(init_parameters);
if (err != ERROR_CODE::SUCCESS)
    exit(-1);

while (!exit_app) {
    if (zed.grab() == ERROR_CODE::SUCCESS) {
        // Any processing
    }
}
// Close the camera
zed.close();
```

**Python:**

```python
# Set the input from stream
init = sl.InitParameters()
init.set_from_stream("127.0.0.1", 34000) # Specify the IP and port of the sender

# Set any other InitParameters as needed to configure the camera and depth settings

# Open the camera
err = zed.open(init)
if err != sl.ERROR_CODE.SUCCESS:
  exit(1)

while not exit_app:
    if zed.grab() == sl.ERROR_CODE.SUCCESS:
        # Any processing

# Close the camera
zed.close()
```

**C#:**

```csharp
// Set the input from stream
InitParameters initParameters = new InitParameters();
initParameters.inputType = INPUT_TYPE.STREAM; 
initParameters.ipStream = "127.0.0.1"; // Specify the IP of the sender
initParameters.portStream = "34000"; // Specify the port of the sender

RuntimeParameters runtimeParameters = new RuntimeParameters();
// Open the camera
ERROR_CODE err = zed.Open(ref initParameters);
if (err != ERROR_CODE.SUCCESS)
    Environment.Exit(-1);

while (!exit_app) {
    if (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
        // Any processing
    }
}
// Close the camera
zed.Close();
```

### Example Applications

The [ZED SDK GitHub repository](https://github.com/stereolabs/zed-sdk/) includes several example applications demonstrating how to use a dual ZED X One stereo system.

### Using the Custom Stereo Rig with ROS 2

The [ZED ROS 2 wrapper](https://www.stereolabs.com/docs/ros2/) supports dual ZED X One stereo systems.

When launching the ZED ROS 2 node, set `virtual` as the camera model and specify the serial numbers or camera IDs of both ZED X One cameras in the launch file parameters:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=virtual camera_ids:=[0,1]
```

or

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=virtual camera_serial_numbers::=[123456789,987654321]
```

For more details, refer to the [ZED ROS 2 wrapper documentation](https://www.stereolabs.com/docs/ros2/).

---

## ZED X One with Docker

Source: https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-and-docker/

To operate the ZED X One camera within a Docker container, specific configuration options and volume mounts are necessary.

### Docker Run Command

```bash
docker run --runtime nvidia -it --privileged -e DISPLAY \
  --network host \
  -v /dev/:/dev/ \
  -v /tmp/:/tmp/ \
  -v /var/nvidia/nvcam/settings/:/var/nvidia/nvcam/settings/ \
  -v /etc/systemd/system/zed_x_daemon.service:/etc/systemd/system/zed_x_daemon.service \
  <docker_image> sh
```

### Critical Requirements

- **L4T Version Matching:** The L4T (Linux for Tegra) version on your host system must match the L4T version of the container image you're using.
- **Driver Installation:** The ZED GMSL2 driver should be installed exclusively on the host machine, not within the Docker container itself.
- **Dependency Installation:** If you cannot access the ZED X camera in Docker, the ZED Link driver may not be properly installed on the host. You may need to install the `libqt5core5a` dependency:

  ```bash
  sudo apt install libqt5core5a
  ```

  Install this package before reinstalling the driver if necessary.

### Key Flags Explained

| Flag | Purpose |
|------|---------|
| `--runtime nvidia` | Enables GPU access |
| `-it` | Runs in interactive mode with terminal |
| `--privileged` | Grants container extended privileges for hardware access |
| `-e DISPLAY` | Forwards display environment variable |
| `--network host` | Uses host network namespace |
| `-v` | Mounts volumes for device, temporary files, camera settings, and daemon service |

---

## Developing with ZED X One Stereo on a PC

Source: https://www.stereolabs.com/docs/cameras/zed-x-one/zed-x-one-dev-on-pc/

This guide enables developers to work on desktop machines while leveraging ZED X One cameras configured in stereo mode on remote NVIDIA Jetson devices. The approach uses network streaming to access camera data as if it were locally connected.

### Prerequisites

Before beginning, ensure you have:

- Set up an NVIDIA Jetson device for ZED X One using the official setup guide
- Physical or SSH access to the Jetson device
- ZED SDK installed on your local development machine
- ZED X One cameras installed in stereo configuration on the Jetson

### ZED SDK Streaming

#### Device Setup

The ZED X One in stereo configuration uses the ZED Media Server tool to handle data streaming. This tool streams on port 34000 by default. Refer to the ZED X One stereo setup documentation for Jetson device configuration specifics.

#### Connecting on Local Machine

To visualize the live stream using ZED SDK tools, run ZED_Depth_Viewer:

```bash
./ZED_Depth_Viewer
```

Click the connection icon in the top left corner. A connection dialog opens where you enter:
- The NVIDIA Jetson device IP address
- The streaming port (default: **34000**)

After a few moments, you'll receive a live view from the remote ZED One cameras.

#### SDK Integration

To use the stream in your ZED SDK application, modify the initialization parameters. Instead of opening a physically connected camera, configure the input to connect to the remote stream:

```cpp
// Create a ZED camera object
Camera zed;

// Set init parameters as default
InitParameters init_parameters;
init_parameters.input.setFromStream("192.168.X.X", 34000);

// Open the camera
auto err = zed.open(init_parameters);
if (err != ERROR_CODE::SUCCESS) {
    return EXIT_FAILURE;
}
```

This change allows you to develop locally on your PC while processing data from ZED One cameras on a remote embedded device. The remaining application logic operates identically to local camera configurations.

---

## Troubleshooting

Source: https://www.stereolabs.com/docs/cameras/zed-x-one/troubleshooting/

### The Camera Is Not Detected

GMSL2 cameras require more careful hardware management than USB alternatives. When you modify the hardware setup -- such as connecting or disconnecting a camera, or rearranging camera order -- you must either reboot the Jetson device or restart the daemon using:

```bash
sudo systemctl restart zed_x_daemon
```

> **Note:** If you're working with a custom carrier board or a partner's ECU, verify that the custom driver includes the `zed_x_daemon` service. Without it, every hardware change necessitates a full device reboot.

### Blurry Images After System Update

System updates can overwrite a patched library that the ZED Link driver depends on, resulting in image quality degradation.

#### Resolution Steps

1. **Download the driver package** from the [ZED X Drivers download page](https://www.stereolabs.com/developers/drivers), selecting the appropriate version for your device.

2. **Extract and restore the patched library:**

   ```bash
   ar x stereolabs-zed<model>_<version>-<deser>-<l4t_version>_arm64.deb
   tar xvf data.tar.xz
   sudo cp ./tmp/R<l4t_version>/libnvisppg.so /usr/lib/aarch64-linux-gnu/tegra/libnvisppg.so
   ```

   Replace `stereolabs-zed<model>_<version>-<deser>-<l4t_version>_arm64.deb` with your downloaded package filename and `<l4t_version>` with your current L4T version (e.g., `R36.4.3`).

3. **Reboot the device:**

   ```bash
   sudo reboot
   ```

After completing these steps, the GMSL2 camera should deliver clear, properly functioning images.

### Contact Support

If troubleshooting doesn't resolve your issue, reach out to the [community forum](https://community.stereolabs.com/) for additional assistance.
