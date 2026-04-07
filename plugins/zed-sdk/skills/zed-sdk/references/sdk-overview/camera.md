---
description: >
  Consolidated reference for ZED SDK Camera/Video documentation.
  Covers camera overview, controls, calibration, recording, streaming,
  multi-camera setup, and the Video API usage.
sources:
  - https://www.stereolabs.com/docs/video/
  - https://www.stereolabs.com/docs/video/camera-controls/
  - https://www.stereolabs.com/docs/video/camera-calibration/
  - https://www.stereolabs.com/docs/video/recording/
  - https://www.stereolabs.com/docs/video/streaming/
  - https://www.stereolabs.com/docs/video/multi-camera/
  - https://www.stereolabs.com/docs/video/using-video/
fetched: 2026-04-07
---

# ZED SDK -- Camera & Video Reference

## Table of Contents

- [Camera Overview](#camera-overview)
- [Camera Controls](#camera-controls)
  - [Selecting a Resolution](#selecting-a-resolution)
  - [Selecting an Output View](#selecting-an-output-view)
  - [Adjusting Camera Settings](#adjusting-camera-settings)
  - [Manual/Auto Mode](#manualauto-mode)
  - [Camera Controls API](#camera-controls-api)
- [Camera Calibration](#camera-calibration)
  - [Calibration Parameters](#calibration-parameters)
  - [Calibration API](#calibration-api)
- [Video Recording](#video-recording)
  - [Compression Modes](#compression-modes)
  - [SVO2 Format](#svo2-format)
  - [Recording with Multiple Cameras](#recording-with-multiple-cameras)
  - [Recording API](#recording-api)
  - [Playback API](#playback-api)
- [Local Video Streaming](#local-video-streaming)
  - [Hardware Requirements](#hardware-requirements)
  - [Streaming Modes](#streaming-modes)
  - [Streaming Protocol](#streaming-protocol)
  - [Multi-Camera Stream from One Host](#multi-camera-stream-from-one-host)
  - [Multi-Camera Stream from Different Hosts](#multi-camera-stream-from-different-hosts)
  - [Streaming API](#streaming-api)
  - [Using a Stream as SDK Input](#using-a-stream-as-sdk-input)
- [Multi-Camera Setup](#multi-camera-setup)
  - [Multiple Cameras on One Host](#multiple-cameras-on-one-host)
  - [Multiple Cameras on a Local Network (PTP)](#multiple-cameras-on-a-local-network-ptp)
- [Using the Video API](#using-the-video-api)
  - [Camera Configuration](#camera-configuration)
  - [Image Capture](#image-capture)
  - [Video Recording (API)](#video-recording-api)
  - [Video Playback (API)](#video-playback-api)
  - [Code Examples](#code-examples)

---

## Camera Overview

Stereolabs provides a range of multi-sensor cameras, including stereo and monocular models, designed for high-definition video capture with wide field of view. These cameras include motion, position, and environmental sensors, with connectivity options including USB 3.0 and GMSL2, depending on the model.

The ZED API offers low-level access to camera and sensor data, enabling high-quality video recording, streaming, and real-time processing for various applications.

### Getting Started

- **[How to Control](https://www.stereolabs.com/docs/video/camera-controls/)** your stereo camera.
- **[How to Record](https://www.stereolabs.com/docs/video/recording/)** video in lossless or compressed formats.
- **[How to Stream](https://www.stereolabs.com/docs/video/streaming/)** video and turn a ZED into an IP camera.
- Learn how to get data from the different **[Sensors](https://www.stereolabs.com/docs/sensors/)**.

---

## Camera Controls

The ZED camera provides several configurable settings for tuning video capture using ZED Explorer or the API.

### Selecting a Resolution

The left and right video frames are synchronized and streamed as a single uncompressed side-by-side format.

#### ZED 2/2i/Mini Video Modes

| Video Mode | Output Resolution | Frame Rate (fps) | Field of View |
|------------|-------------------|------------------|---------------|
| HD2K | 4416x1242 | 15 | Wide |
| HD1080 | 3840x1080 | 30, 15 | Wide |
| HD720 | 2560x720 | 60, 30, 15 | Extra Wide |
| VGA | 1344x376 | 100, 60, 30, 15 | Extra Wide |

#### ZED X, ZED X Mini Video Modes

| Video Mode | Output Resolution | Frame Rate (fps) |
|------------|-------------------|------------------|
| HD1200 | 3840x1200 | 60, 30, 15 |
| HD1080 | 3840x1080 | 60, 30, 15 |
| SVGA | 1920x600 | 120, 60, 30, 15 |

Resolution and framerate can be adjusted through ZED Explorer or the API.

### Selecting an Output View

The ZED outputs images in multiple formats:

- Left view
- Right view
- Side-by-side view
- Left or Right Unrectified
- Left or Right Grayscale

### Adjusting Camera Settings

The onboard ISP (Image Signal Processor) performs various algorithms on raw sensor images. Multiple parameters are adjustable via ZED Explorer or the SDK using `sl::VIDEO_SETTINGS`.

#### ZED, ZED 2/2i/Mini Settings

| Setting | Description | Values |
|---------|-------------|--------|
| BRIGHTNESS | Controls image brightness | [0 - 8] |
| CONTRAST | Controls image contrast | [0 - 8] |
| HUE | Controls image color | [0 - 11] |
| SATURATION | Controls image color intensity | [0 - 8] |
| SHARPNESS | Controls image sharpness | [0 - 8] |
| GAMMA | Controls gamma correction | [1 - 9] |
| GAIN | Controls digital amplification | [0 - 100] |
| EXPOSURE | Controls shutter speed | [0 - 100] (% of frame rate) |
| AEC_AGC | Auto gain/exposure control mode | [0 - 1] |
| AEC_AGC_ROI | Region of interest for auto exposure | sl::Rect |
| WHITEBALANCE_TEMPERATURE | Controls white balance | [2800 - 6500] |
| WHITEBALANCE_AUTO | Auto white balance mode | [0 - 1] |
| LED_STATUS | Controls front LED | [0 - 1] |

#### ZED X, ZED X Mini Settings

| Setting | Description | Values |
|---------|-------------|--------|
| SATURATION | Controls image color intensity | [0 - 8] |
| SHARPNESS | Controls image sharpness | [0 - 8] |
| GAMMA | Controls gamma correction | [1 - 9] |
| GAIN | Controls digital amplification | [0 - 100] |
| AEC_AGC | Auto gain/exposure control mode | [0 - 1] |
| AEC_AGC_ROI | Region of interest for auto exposure | sl::Rect |
| WHITEBALANCE_TEMPERATURE | Controls white balance | [2800 - 6500] |
| WHITEBALANCE_AUTO | Auto white balance mode | [0 - 1] |
| LED_STATUS | Controls front LED | [0 - 1] |
| EXPOSURE_TIME | Controls exposure time | Value in us |
| ANALOG_GAIN | Controls real analog gain (sensor) | [1000-16000] mDB |
| DIGITAL_GAIN | Controls real digital gain (ISP) | [1-256] |
| AUTO_EXPOSURE_TIME_RANGE | Range of exposure auto control | [66000-19000] us |
| AUTO_ANALOG_GAIN_RANGE | Range of sensor gain in auto | [1000-16000] mdB |
| AUTO_DIGITAL_GAIN_RANGE | Range of digital ISP gain in auto | [1-256] |
| EXPOSURE_COMPENSATION | Exposure-target compensation | [0-100] (50 = no compensation) |
| DENOISING | Level of denoising applied | [0-100] (50 = no denoising) |

> **Note:** Camera controls adjust both left and right sensor parameters synchronously, not individually.

### Manual/Auto Mode

When White Balance, Exposure, and Gain operate in Auto mode, they adjust automatically based on scene luminance.

In AUTO mode, exposure increases first, then gain, to minimize noise. When exposure reaches maximum, motion blur increases. For reduced blur, switch to MANUAL mode and increase gain before exposure.

Increasing Gamma in low-light environments provides significant light enhancement while reducing saturated areas.

### Camera Controls API

Configure the camera by creating a Camera object and specifying `InitParameters`. These parameters configure resolution, FPS, and depth sensing -- set before opening the camera.

**C++:**

```cpp
Camera zed;
InitParameters init_params;
init_params.camera_resolution = RESOLUTION::HD1080;
init_params.camera_fps = 30;
err = zed.open(init_params);
if (err != ERROR_CODE::SUCCESS)
    exit(-1);
```

**Python:**

```python
zed = sl.Camera()
init_params = sl.InitParameters()
init_params.camera_resolution = sl.RESOLUTION.HD1080
init_params.camera_fps = 30
err = zed.open(init_params)
if err != sl.ERROR_CODE.SUCCESS:
    exit(-1)
```

**C#:**

```csharp
sl.Camera zed = new sl.Camera(0);
sl.InitParameters init_parameters = new sl.InitParameters();
init_parameters.resolution = sl.RESOLUTION.HD1080;
init_parameters.cameraFPS = 30;
sl.ERROR_CODE err = zed.Open(ref init_params);
if (err != sl.ERROR_CODE.SUCCESS)
    Environment.Exit(-1);
```

#### Image Capture

Capture frames by specifying `RuntimeParameters`, calling `grab()` to acquire frames, and `retrieveImage()` to access captured frames. This function supports selecting different views including left, right, unrectified, and grayscale images.

**C++:**

```cpp
sl::Mat image;
if (zed.grab() == ERROR_CODE::SUCCESS) {
  zed.retrieveImage(image, VIEW::LEFT);
}
```

**Python:**

```python
image = sl.Mat()
if zed.grab() == sl.ERROR_CODE.SUCCESS:
  zed.retrieve_image(image, sl.VIEW.LEFT)
```

**C#:**

```csharp
sl.Mat image = new sl.Mat();
RuntimeParameters runtimeParameters = new RuntimeParameters();
if (zed.Grab(ref runtimeParameters) == sl.ERROR_CODE.SUCCESS) {
  zed.retrieveImage(image, sl.VIEW.LEFT);
}
```

#### Adjusting Camera Controls at Runtime

Modify settings like exposure and white balance at runtime using `setCameraSettings()`. Change resolution and frame rate via `InitParameters`.

**C++:**

```cpp
zed.setCameraSettings(VIDEO_SETTINGS::EXPOSURE, 50);
zed.setCameraSettings(VIDEO_SETTINGS::WHITE_BALANCE, 4600);
zed.setCameraSettings(VIDEO_SETTINGS::EXPOSURE, VIDEO_SETTINGS_VALUE_AUTO);
```

**Python:**

```python
zed.set_camera_settings(sl.VIDEO_SETTINGS.EXPOSURE, 50)
zed.set_camera_settings(sl.VIDEO_SETTINGS.WHITE_BALANCE, 4600)
zed.set_camera_settings(sl.VIDEO_SETTINGS.EXPOSURE, -1)
```

**C#:**

```csharp
zed.SetCameraSettings(sl.VIDEO_SETTINGS.EXPOSURE, 50);
zed.SetCameraSettings(sl.VIDEO_SETTINGS.WHITEBALANCE, 4600);
zed.SetCameraSettings(sl.VIDEO_SETTINGS.EXPOSURE, -1);
```

Retrieve settings using `getCameraSettings()`. See API documentation for available settings.

---

## Camera Calibration

### Calibration Parameters

ZED cameras undergo extensive factory calibration to ensure accurate camera parameter estimation. This calibration process defines key characteristics essential for computer vision and imaging applications.

The following parameters are available for each eye and resolution:

- **Focal length:** `fx`, `fy`
- **Principal points:** `cx`, `cy`
- **Lens distortion:** `k1`, `k2`, `k3`, `p1`, `p2`
- **Field of view:** Horizontal, vertical, and diagonal measurements
- **Stereo calibration:** Rotation and translation between left and right eye

### Calibration API

Camera parameters are accessible through the `CalibrationParameters` class, which can be retrieved using `getCameraInformation()`.

**C++:**

```cpp
CalibrationParameters calibration_params = zed.getCameraInformation().camera_configuration.calibration_parameters;
// Focal length of the left eye in pixels
float focal_left_x = calibration_params.left_cam.fx;
// First radial distortion coefficient
float k1 = calibration_params.left_cam.disto[0];
// Translation between left and right eye on x-axis
float tx = calibration_params.stereo_transform.getTranslation()[0];
// Horizontal field of view of the left eye in degrees
float h_fov = calibration_params.left_cam.h_fov;
```

**Python:**

```python
calibration_params = zed.get_camera_information().camera_configuration.calibration_parameters
# Focal length of the left eye in pixels
focal_left_x = calibration_params.left_cam.fx
# First radial distortion coefficient
k1 = calibration_params.left_cam.disto[0]
# Translation between left and right eye on x-axis
tx = calibration_params.stereo_transform.get_translation().get()[0]
# Horizontal field of view of the left eye in degrees
h_fov = calibration_params.left_cam.h_fov
```

**C#:**

```csharp
CalibrationParameters calibration_params = zed.getCameraInformation().cameraConfiguration.calibrationParameters;
// Focal length of the left eye in pixels
float focal_left_x = calibration_params.leftCam.fx;
// First radial distortion coefficient
float k1 = calibration_params.leftCam.disto[0];
// Translation between left and right eye on x-axis
float tz = calibration_params.Trans.x;
// Horizontal field of view of the left eye in degrees
float h_fov = calibration_params.leftCam.hFOV;
```

> **Note:** If self-calibration is enabled, calibration parameters can be re-estimated and refined by the ZED SDK at startup. Updated parameters will be available in `CalibrationParameters`.

---

## Video Recording

The ZED SDK enables recording of large video datasets using H.264, H.265, or lossless compression formats. Videos are stored in Stereolabs' SVO format, which preserves timestamps and sensor metadata. When loading SVO files, the ZED API functions as if a live camera feed is available, supporting all modules including depth sensing, tracking, and spatial mapping.

### Compression Modes

| Compression Mode | Average Size (% of RAW) |
|---|---|
| LOSSLESS (PNG/ZSTD) | 42% |
| H.264 (AVCHD) | 1% |
| H.265 (HEVC) | 1% |
| H.264 LOSSLESS | 25% |
| H.265 LOSSLESS | 25% |

#### Benefits of Hardware Encoding

Hardware-based encoder (referred to as NVENC) built into NVIDIA graphics cards offloads encoding, freeing GPU and CPU resources for other operations. This enables full frame rate recording with minimal performance impact in compute-intensive scenarios.

#### Encoding Quality

Quality varies by GPU generation. Newer Turing-based GPUs (RTX 20-Series, Jetson Xavier) typically produce superior output compared to older generations (GTX 10-Series, Jetson Nano).

### SVO2 Format

Introduced in ZED SDK 4.1, SVO2 stores high-frequency camera data and supports recording custom external sensor data. Key features:

- **High-frequency data**: Sensors record at their native frequency rather than camera frame rate, enabling advanced algorithms like Positional Tracking Gen 2.
- **Custom Data**: User-defined data can be timestamped and recorded alongside ZED data.

### Recording with Multiple Cameras

Multiple cameras can be recorded simultaneously on a single PC. When using hardware encoding, consult the NVENC support matrix to verify maximum concurrent encoding sessions. Adding multiple GPUs increases available recording capacity.

### Recording API

Enable recording using `enableRecording()` with an output filename and `SVO_COMPRESSION_MODE` parameter. Each frame is added to the SVO file automatically.

**C++:**

```cpp
Camera zed;
String output_path(argv[1]);
RecordingParameters recordingParameters;
recordingParameters.compression_mode = SVO_COMPRESSION_MODE::H264;
recordingParameters.video_filename = output_path;
err = zed.enableRecording(recordingParameters);

while (!exit_app) {
    zed.grab();
}
zed.disableRecording();
```

**Python:**

```python
zed = sl.Camera()
output_path = sys.argv[0]
recordingParameters = sl.RecordingParameters()
recordingParameters.compression_mode = sl.SVO_COMPRESSION_MODE.H264
recordingParameters.video_filename = output_path
err = zed.enable_recording(recordingParameters)

while not exit_app:
    zed.grab()

zed.disable_recording()
```

**C#:**

```csharp
sl.Camera zed = new sl.Camera(0);
sl.RuntimeParameters runtimeParameters = new sl.RuntimeParameters();
string output_path = args[0];
sl.RecordingParameters recordingParameters = new sl.RecordingParameters();
recordingParameters.compression_mode = sl.SVO_COMPRESSION_MODE.H264;
recordingParameters.video_filename = output_path;
err = zed.EnableRecording(recordingParameters);

while (!exit_app) {
    zed.Grab(ref runtimeParameters);
}
zed.DisableRecording();
```

### Playback API

Load SVO files using `setFromSVOFile()`. The API behaves as if a live camera is connected, providing access to all modules. When the file ends, `END_OF_SVOFILE_REACHED` error code is returned.

**C++:**

```cpp
Camera zed;
String input_path(argv[1]);
InitParameters init_parameters;
init_parameters.input.setFromSVOFile(input_path);
err = zed.open(init_parameters);

sl::Mat svo_image;
while (!exit_app) {
    if (zed.grab() == ERROR_CODE::SUCCESS) {
        zed.retrieveImage(svo_image, VIEW::SIDE_BY_SIDE);
        int svo_position = zed.getSVOPosition();
    }
    else if (zed.grab() == END_OF_SVOFILE_REACHED) {
        std::cout << "SVO end has been reached. Looping back to first frame" << std::endl;
        zed.setSVOPosition(0);
    }
}
```

**Python:**

```python
zed = sl.Camera()
input_path = sys.argv[1]
init_parameters = sl.InitParameters()
init_parameters.set_from_svo_file(input_path)

zed = sl.Camera()
err = zed.open(init_parameters)

svo_image = sl.Mat()
while not exit_app:
    if zed.grab() == sl.ERROR_CODE.SUCCESS:
        zed.retrieve_image(svo_image, sl.VIEW.SIDE_BY_SIDE)
        svo_position = zed.get_svo_position()
    elif zed.grab() == sl.ERROR_CODE.END_OF_SVOFILE_REACHED:
        print("SVO end has been reached. Looping back to first frame")
        zed.set_svo_position(0)
```

**C#:**

```csharp
sl.Camera zed = new sl.Camera(0);
sl.RuntimeParameters runtimeParameters = new sl.RuntimeParameters();

string input_path = argv[0];
sl.InitParameters init_parameters = new sl.InitParameters();
init_parameters.inputType = sl.INPUT_TYPE.SVO;
init_parameters.pathSVO = input_path;

err = zed.Open(ref init_parameters);

sl.Mat svo_image = new sl.Mat();
while (!exit_app) {
    if (zed.Grab(ref runtimeParameters) == sl.ERROR_CODE.SUCCESS) {
        zed.RetrieveImage(svoImage, sl.VIEW.SIDE_BY_SIDE, sl.MEM.CPU);
        int svo_position = zed.GetSVOPosition();
    }
    if (zed.GetSVOPosition() >= zed.GetSVONumberOfFrames() - 1) {
        Console.WriteLine("SVO end has been reached. Looping back to first frame");
        zed.SetSVOPosition(0);
    }
}
```

---

## Local Video Streaming

Using the ZED SDK, you can stream the side-by-side video of a ZED camera over a local IP network (Ethernet or Wifi).

Devices with proper permissions can access the live feed from anywhere using the ZED SDK on the receiving end. When taking a stream as input, the ZED API will behave as if a camera is directly connected to the PC. Every module of the ZED API will be available: depth, tracking, spatial mapping and more.

### Hardware Requirements

When streaming live video, hardware acceleration is used to perform real-time encoding and decoding with minimal overhead. It is available on NVIDIA GeForce, Quadro, Tesla and embedded NVIDIA Jetson boards (Nano, TX2, Xavier). There are some limitations regarding the number of concurrent encoding sessions, so make sure to check the Desktop GPU Support Matrix or NVIDIA Jetson Support Matrix to determine the appropriate hardware for your use case.

### Streaming Modes

The ZED SDK can stream video using either `H264` or `H265` encoding modes.

#### Recommended Bit Rates

When streaming video content over the network, the user can define a specific bitrate. A low bitrate will degrade the quality of the images but requires less bandwidth to transmit over the network. On the other hand, a high bitrate will provide high-quality images with low compression artifacts but the required bandwidth will go up and might create freeze or drop frames.

| Encoder | Video Mode | Resolution (side by side) | FPS | Bitrate (kbits/s) | Platform Required |
|---------|------------|--------------------------|-----|-------------------|-------------------|
| H.264 (AVCHD) | 2K | 4416x1242 | 15 | 8500 | NVIDIA GPU with hardware encoder, NVIDIA Jetson |
| | HD1080 | 3840x1080 | 30 | 12500 | |
| | HD720 | 2560x720 | 60 | 7000 | |
| H.265 (HEVC) | 2K | 4416x1242 | 15 | 7000 | NVIDIA GPU (Pascal or above) with hardware encoder, NVIDIA Jetson |
| | HD1080 | 3840x1080 | 30 | 11000 | |
| | HD720 | 2560x720 | 60 | 6000 | |

#### Benefits of Hardware Encoding

Both `H264` and `H265` encoding modes have been designed to use the hardware encoder built into NVIDIA GPUs (known as NVENC). With encoding offloaded to NVENC, the GPU and CPU are free for other operations. For example, in a compute-heavy scenario, it is possible to stream a video at a full frame rate with minimal impact on the main application.

#### Encoding Quality

At a given bitrate, hardware encoding quality can vary depending on your GPU generation. The updated NVENC encoder on Turing-based NVIDIA GPUs (RTX 20-Series, Jetson Xavier) will typically produce superior quality than encoders on older generation GPUs (GTX 10-Series, Jetson Nano).

### Streaming Protocol

The streaming module uses the **RTP** protocol to send and receive the video feed. If not specified, the sender will use the port 30000 and 30001 while the receiver will use ports that are determined as below:

- Try opening the same PORT as the sender.
- If not available, try opening PORT + 2.
- Continue testing new ports until one is available.

Example where multiple ZED cameras are streaming video to one single host machine:

| Sender Port | Receiver Port |
|-------------|---------------|
| Camera #1: 30000 (default) | 30000 |
| Camera #2: 30000 (default) | 30002 |
| Camera #3: 30000 (default) | 30004 |
| Camera #4: 40000 | 40000 |

To get the ports opened by the receiver, use the following command on Linux:

```bash
sudo lsof -i -P -n
```

### Multi-Camera Stream from One Host

You can encode and stream videos from multiple cameras connected to a single PC. There is a maximum number of concurrent hardware encoding sessions that can be started on a single NVIDIA GPU. Make sure to check the NVENC support matrix or Jetson support matrix to determine the appropriate hardware requirements.

### Multi-Camera Stream from Different Hosts

It is also possible to stream video from several cameras connected to edge computers or gateways. In this configuration, the Senders are responsible for encoding and streaming an attached ZED's video via the local network. On the other side, the Receivers read the stream and process the images using the ZED SDK. Therefore, the Receivers also require an NVIDIA GPU for NVENC decoding and SDK use.

Both the Senders and the Receivers must be connected to the same local network. For improved bandwidth, connect the Senders and Receivers via Gigabit Ethernet instead of Wi-Fi. All ZED 2, ZED and ZED Mini cameras support Streaming with the ZED SDK.

### Streaming API

To stream the video content of a ZED camera, you need to enable the streaming module with `enableStreaming()`. The standard `grab()` function will grab a frame and send it over to the local network.

Use `StreamingParameters` to specify settings like bitrate, port, etc. Then pass those parameters when you call `enableStreaming()`.

**C++:**

```cpp
// Set the streaming parameters
sl::StreamingParameters stream_params;
stream_params.codec = sl::STREAMING_CODEC::H264; // Can be H264 or H265
stream_params.bitrate = 8000;
stream_params.port = 30000; // Port used for sending the stream
// Enable streaming with the streaming parameters
sl::ERROR_CODE err = zed.enableStreaming(stream_params);

while (!exit_app) {
    zed.grab();
}
// Disable streaming
zed.disableStreaming();
```

**Python:**

```python
# Set the streaming parameters
stream = sl.StreamingParameters()
stream.codec = sl.STREAMING_CODEC.H264 # Can be H264 or H265
stream.bitrate = 8000
stream.port = 30000 # Port used for sending the stream
# Enable streaming with the streaming parameters
err = zed.enable_streaming(stream)

while not exit_app :
    zed.grab()

# Disable streaming
zed.disable_streaming()
```

**C#:**

```csharp
// Enable streaming with the streaming parameters
err =  zed.EnableStreaming(STREAMING_CODEC.H264_BASED, 8000, 30000);

RuntimeParameters runtimeParameters = new RuntimeParameters();
while (!exit_app) {
    zed.Grab(ref runtimeParameters);
}
// Disable streaming
zed.DisableStreaming();
```

### Using a Stream as SDK Input

Video content streamed from a ZED camera is accessible remotely and can be used as standard input for the ZED API. Therefore, every ZED API module will work as if the camera was directly connected to the device. To use a remote stream as input, specify the IP address and the port of the sender in `InitParameters`. Then call `open()` to open the camera from the stream and `grab()` to grab a new frame and do the processing you want.

**C++:**

```cpp
// Set the input from stream
InitParameters init_parameters;
init_parameters.input.setFromStream("127.0.0.1", 30000); // Specify the IP and port of the sender
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
init.set_from_stream("127.0.0.1", 30000) # Specify the IP and port of the sender
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
initParameters.portStream = "30000"; // Specify the port of the sender

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

---

## Multi-Camera Setup

There are two primary approaches for establishing multi-camera configurations:

1. Connecting multiple cameras to a single machine (desktop PC, server, or NVIDIA Jetson board)
2. Converting ZED cameras into IP cameras that synchronize data across a local network

### Multiple Cameras on One Host

It is possible to connect multiple ZED cameras on a single Windows or Linux computer.

#### Hardware Recommendations

**Use PCIe expansion cards**: The ZED operating at 1080p30 generates approximately 250MB/s of image data. USB 3.0 bandwidth maxes out around 620MB/s, limiting the number of cameras, resolutions, and frame rates possible on a single machine. Exceeding this bandwidth causes corrupted frames (green or purple frames, tearing). To use multiple ZED at full speed on a single computer, adding USB 3.0 expansion cards such as Inateck 3.0 PCI-E Expansion Cards is recommended.

**Increase GPU memory**: The ZED SDK requires up to 500MB of GPU memory when using 2K resolution with ULTRA depth mode. For multiple cameras, GeForce 900 series or above with 6GB of memory is recommended.

#### How to List Connected Cameras

The ZED SDK can list connected cameras using `getDeviceList()` and provide their serial numbers for identification. Once you identify which ZED to open, request a specific serial number with `InitParameters.input.setFromSerialNumber(1010)`.

### Multiple Cameras on a Local Network (PTP)

#### Configure the PTP Service to Synchronize the Devices

Precision Time Protocol (PTP or IEEE1588) is a method to synchronize the clock of multiple devices on an Ethernet network by designating one device as the master clock while others synchronize and periodically adjust to it. This ensures all cameras publish frames with timestamps referencing the same time source.

One device must serve as the master (maintaining NTP service if internet-connected) to keep the system clock synchronized with world time.

#### Advantages of PTP

A significant advantage is hardware support in Network Interface Controllers (NICs) and network switches. This specialized hardware accounts for message transfer delays and greatly improves synchronization accuracy. Hardware PTP support provides greater accuracy as the NIC can stamp PTP packets as they are sent and received, while software PTP support requires additional processing of PTP packets by the operating system.

#### Install PTP and Tools

Install required packages on each device:

```bash
sudo apt install linuxptp ethtool
```

The `linuxptp` package includes `ptp4l` and `phc2sys` programs for clock synchronization. The `ethtool` package verifies NIC clock capabilities.

#### Check PTP Hardware Support

Verify NIC capabilities:

```bash
ethtool -T <interface_name>
```

Retrieve network interface names:

```bash
nmcli device status
```

For software timestamping support, parameters should include:

- `SOF_TIMESTAMPING_SOFTWARE`
- `SOF_TIMESTAMPING_TX_SOFTWARE`
- `SOF_TIMESTAMPING_RX_SOFTWARE`

For hardware timestamping support, parameters should include:

- `SOF_TIMESTAMPING_RAW_HARDWARE`
- `SOF_TIMESTAMPING_TX_HARDWARE`
- `SOF_TIMESTAMPING_RX_HARDWARE`

#### Setup the Master Device

Enable NTP sync if connected to the internet:

```bash
timedatectl set-ntp on
```

Start the PTP service in hardware mode:

```bash
sudo ptp4l -i <interface_name> -m
```

If errors indicate lack of hardware timestamping support, use software mode:

```bash
sudo ptp4l -i <interface_name> -S -m
```

#### Setup All the Slave Devices

Start the PTP service in slave mode on each slave device:

```bash
sudo ptp4l -i <interface_name> -s -m
```

For software mode:

```bash
sudo ptp4l -i <interface_name> -S -s -m
```

For hardware-mode slaves, synchronize the system clock with the PTP hardware clock:

```bash
sudo phc2sys -m -s /dev/ptp0 -c CLOCK_REALTIME -O 0
```

The `-s` option specifies the clock source, `-c` sets the destination clock, and `-O 0` explicitly sets clock offset to zero.

#### Test the Configuration

Disable NTP on the master to manually change system time:

```bash
sudo timedatectl set-ntp off
```

Compile a test application comparing timestamps between `CURRENT` and `IMAGE` references. The printed latency value should remain constant in normal conditions. When PTP sync occurs, the `CURRENT` timestamp changes while the `IMAGE` timestamp adapts smoothly.

Generate a visible PTP sync by manually modifying the master's system time:

```bash
sudo date --set="2021-01-20 15:30:00.000"
```

A larger time difference produces greater time jump and longer stabilization period.

> **Note:** Re-enable NTP service after testing to synchronize system clocks with world time:

```bash
sudo timedatectl set-ntp on
```

---

## Using the Video API

The ZED API provides low-level access to the camera hardware and video features, facilitating camera control and high-quality video recording and streaming.

### Camera Configuration

To configure the camera, create a `Camera` object and specify your `InitParameters`. Initial parameters let you adjust camera resolution, FPS, depth sensing parameters and more. These parameters can only be set before opening the camera and cannot be changed while the camera is in use.

> **Note:** `InitParameters` contains a default configuration.

**C++:**

```cpp
// Create a ZED camera object
Camera zed;

// Set configuration parameters
InitParameters init_params;
init_params.camera_resolution = RESOLUTION::HD1080;
init_params.camera_fps = 30;

// Open the camera
ERROR_CODE err = zed.open(init_params);
if (err != SUCCESS)
    exit(-1);
```

**Python:**

```python
# Create a ZED camera object
zed = sl.Camera()

# Set configuration parameters
init_params = sl.InitParameters()
init_params.camera_resolution = sl.RESOLUTION.HD1080
init_params.camera_fps = 30

# Open the camera
err = zed.open(init_params)
if err != sl.ERROR_CODE.SUCCESS:
    exit(-1)
```

**C#:**

```csharp
// Create a ZED camera object
sl.Camera zed = new sl.Camera(0);

// Set configuration parameters
sl.InitParameters init_parameters = new sl.InitParameters();
init_parameters.resolution = sl.RESOLUTION.HD1080;
init_parameters.cameraFPS = 30;

// Open the camera
sl.ERROR_CODE err = zed.Open(ref init_params);
if (err != sl.ERROR_CODE.SUCCESS)
    Environment.Exit(-1);
```

Camera settings such as exposure, white balance and others can be manually set at runtime using `setCameraSettings()`.

**C++:**

```cpp
// Set exposure in manual mode at 50% of camera framerate
zed.setCameraSettings(VIDEO_SETTINGS::EXPOSURE, 50);
// Set white balance to 4600K
zed.setCameraSettings(VIDEO_SETTINGS::WHITE_BALANCE, 4600);
// Reset to auto exposure
zed.setCameraSettings(VIDEO_SETTINGS::EXPOSURE, -1);
```

**Python:**

```python
# Set exposure to 50% of camera framerate
zed.set_camera_settings(sl.VIDEO_SETTINGS.EXPOSURE, 50)
# Set white balance to 4600K
zed.set_camera_settings(sl.VIDEO_SETTINGS.WHITE_BALANCE, 4600)
# Reset to auto exposure
zed.set_camera_settings(sl.VIDEO_SETTINGS.EXPOSURE, -1)
```

**C#:**

```csharp
// Set exposure in manual mode at 50% of camera framerate
zed.SetCameraSettings(sl.VIDEO_SETTINGS.EXPOSURE, 50);
// Set white balance to 4600K
zed.SetCameraSettings(sl.VIDEO_SETTINGS.WHITEBALANCE, 4600);
//Reset to auto exposure
zed.SetCameraSettings(sl.VIDEO_SETTINGS.EXPOSURE, -1);
```

### Image Capture

To capture images from the ZED, specify your `RuntimeParameters` and call `grab()` to grab a new frame and `retrieveImage()` to retrieve the grabbed frame. `retrieveImage()` lets you select between different views such as left, right, unrectified and grayscale images.

**C++:**

```cpp
sl::Mat image;
if (zed.grab() == ERROR_CODE::SUCCESS) {
    // A new image is available if grab() returns SUCCESS
    zed.retrieveImage(image, VIEW::LEFT); // Retrieve the left image
}
```

**Python:**

```python
image = sl.Mat()
runtime_parameters = sl.RuntimeParameters()
if zed.grab(runtime_parameters) == sl.ERROR_CODE.SUCCESS:
    # A new image is available if grab() returns SUCCESS
    zed.retrieve_image(image, sl.VIEW.LEFT) # Retrieve the left image
```

**C#:**

```csharp
sl.Mat image = new sl.Mat();
uint mWidth = (uint)zed.ImageWidth;
uint mHeight = (uint)zed.ImageHeight;
image.Create(mWidth, mHeight, MAT_TYPE.MAT_8U_C4, MEM.CPU); // Mat needs to be created before use.

RuntimeParameters runtimeParameters = new RuntimeParameters();
if (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
    // A new image is available if grab() returns SUCCESS
    zed.RetrieveImage(image, sl.VIEW.LEFT); // Retrieve the left image
}
```

### Video Recording (API)

The ZED SDK uses Stereolabs' SVO format to store videos along with additional metadata such as timestamps and sensor data.

To record SVO files, you need to enable the Recording module with `enableRecording()`. Specify an output file name (eg: _output.svo_) and `SVO_COMPRESSION_MODE`, then save each grabbed frame using `record()`. SVO lets you record video and associated metadata (timestamp, IMU data and more if available).

**C++:**

```cpp
// Create a ZED camera object
Camera zed;

// Enable recording with the filename specified in argument
String output_path(argv[1]);
RecordingParameters recordingParameters;
recordingParameters.compression_mode = SVO_COMPRESSION_MODE::H264;
recordingParameters.video_filename = output_path;
err = zed.enableRecording(recordingParameters);

while (!exit_app) {
    // Each new frame is added to the SVO file
    zed.grab();
}
// Disable recording
zed.disableRecording();
```

**Python:**

```python
# Create a ZED camera object
zed = sl.Camera()

# Enable recording with the filename specified in argument
output_path = sys.argv[0]
recordingParameters = sl.RecordingParameters()
recordingParameters.compression_mode = sl.SVO_COMPRESSION_MODE.H264
recordingParameters.video_filename = output_path
err = zed.enable_recording(recordingParameters)

while not exit_app:
    # Each new frame is added to the SVO file
    zed.grab()

# Disable recording
zed.disable_recording()
```

**C#:**

```csharp
// Create a ZED camera object
sl.Camera zed = new sl.Camera(0);
sl.RuntimeParameters runtimeParameters = new sl.RuntimeParameters();
// Enable recording with the filename specified in argument
string output_path = args[0];
sl.RecordingParameters recordingParameters = new sl.RecordingParameters();
recordingParameters.compression_mode = sl.SVO_COMPRESSION_MODE.H264;
recordingParameters.video_filename = output_path;
err = zed.EnableRecording(recordingParameters);

while (!exit_app) {
    // Each new frame is added to the SVO file
    zed.Grab(ref runtimeParameters);
}
// Disable recording
zed.DisableRecording();
```

### Video Playback (API)

To play SVO files, simply add the file path as an argument in `setFromSVOFile()`. When loading SVO files, the ZED API will behave as if a ZED was connected and a live feed was available. Every module of the ZED API will be available: depth, tracking, spatial mapping and more. When an SVO file is read entirely, `END_OF_SVOFILE_REACHED` error code is returned.

**C++:**

```cpp
// Create a ZED camera object
Camera zed;

// Set SVO path for playback
String input_path(argv[1]);
InitParameters init_parameters;
init_parameters.input.setFromSVOFile(input_path);

// Open the ZED
ERROR_CODE err = zed.open(init_parameters);

sl::Mat svo_image;
while (!exit_app) {
    if (zed.grab(ref runtimeParameters) == ERROR_CODE::SUCCESS) {
        // Read side by side frames stored in the SVO
        zed.retrieveImage(svo_image, VIEW::SIDE_BY_SIDE);
        // Get frame count
        int svo_position = zed.getSVOPosition();
    }
    else if (zed.grab() == ERROR_CODE::END_OF_SVOFILE_REACHED) {
        std::cout << "SVO end has been reached. Looping back to first frame" << std::endl;
        zed.setSVOPosition(0);
    }
}
```

**Python:**

```python
# Create a ZED camera object
zed = sl.Camera()

# Set SVO path for playback
input_path = sys.argv[1]
init_parameters = sl.InitParameters()
init_parameters.set_from_svo_file(input_path)

# Open the ZED
zed = sl.Camera()
err = zed.open(init_parameters)

svo_image = sl.Mat()
while not exit_app:
    if zed.grab() == sl.ERROR_CODE.SUCCESS:
        # Read side by side frames stored in the SVO
        zed.retrieve_image(svo_image, sl.VIEW.SIDE_BY_SIDE)
        # Get frame count
        svo_position = zed.get_svo_position()
    elif zed.grab() == sl.ERROR_CODE.END_OF_SVOFILE_REACHED:
        print("SVO end has been reached. Looping back to first frame")
        zed.set_svo_position(0)
```

**C#:**

```csharp
// Create a ZED camera object
sl.Camera zed = new sl.Camera(0);

sl.RuntimeParameters runtimeParameters = new sl.RuntimeParameters();

// Set SVO path for playback
string input_path = argv[0];
sl.InitParameters init_parameters = new sl.InitParameters();
init_parameters.inputType = sl.INPUT_TYPE.SVO;
init_parameters.pathSVO = input_path;

// Open the ZED
sl.ERROR_CODE err = zed.Open(ref init_parameters);

sl.Mat svo_image = new sl.Mat();
uint mWidth = (uint)zed.ImageWidth;
uint mHeight = (uint)zed.ImageHeight;
svoImage.Create(mWidth * 2, mHeight, MAT_TYPE.MAT_8U_C4, MEM.CPU); // Mat needs to be created before use.
while (!exit_app) {
    if (zed.Grab(ref runtimeParameters) == sl.ERROR_CODE.SUCCESS) {
        // Read side by side frames stored in the SVO
        zed.RetrieveImage(svoImage, sl.VIEW.SIDE_BY_SIDE, sl.MEM.CPU);
        // Get frame count
        int svo_position = zed.GetSVOPosition();
    }
    if (zed.GetSVOPosition() >= zed.GetSVONumberOfFrames() - 1) {
        Console.WriteLine("SVO end has been reached. Looping back to first frame");
        zed.SetSVOPosition(0);
    }
}
```

### Code Examples

Get started with stereo video capture, recording and streaming using the following code samples on GitHub:

- [Camera Control](https://github.com/stereolabs/zed-examples/tree/master/camera%20control)
- [SVO Recording](https://github.com/stereolabs/zed-examples/tree/master/recording/recording), [SVO Playback](https://github.com/stereolabs/zed-examples/tree/master/recording/playback) and [SVO Export](https://github.com/stereolabs/zed-examples/tree/master/recording/export)
- [Camera Streaming](https://github.com/stereolabs/zed-examples/tree/master/camera%20streaming)
