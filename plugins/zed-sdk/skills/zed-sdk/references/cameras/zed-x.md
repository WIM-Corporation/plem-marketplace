---
description: >
  ZED X and ZED X Mini (GMSL2 stereo cameras) — overview, PC development via streaming,
  Docker setup, NVIDIA ISP tuning, raw NV12 buffer access, and troubleshooting.
sources:
  - https://www.stereolabs.com/docs/cameras/zed-x/
  - https://www.stereolabs.com/docs/cameras/zed-x/zed-x-dev-on-pc/
  - https://www.stereolabs.com/docs/cameras/zed-x/zed-x-and-docker/
  - https://www.stereolabs.com/docs/cameras/zed-x/zed-x-isp-guide/
  - https://www.stereolabs.com/docs/cameras/zed-x/zed-x-nv12-access/
  - https://www.stereolabs.com/docs/cameras/zed-x/troubleshooting/
---

# ZED X — GMSL2 Stereo Camera

## Table of Contents

- [ZED X Overview](#zed-x-overview)
- [Developing with ZED X on a PC](#developing-with-zed-x-on-a-pc)
- [ZED X with Docker](#zed-x-with-docker)
- [NVIDIA ISP Guide](#nvidia-isp-guide)
- [Raw NV12 Buffer Access](#raw-nv12-buffer-access)
- [Troubleshooting](#troubleshooting)

---

## ZED X Overview

Source: https://www.stereolabs.com/docs/cameras/zed-x/

### About ZED X and ZED X Mini

The ZED X camera is a professional-grade camera designed specifically for robotic applications in production environments. It features an IP66-rated Global Shutter and high-performance IMU built to handle harsh operational conditions. The camera employs Neural Depth Engine 2 technology to generate accurate depth maps even in challenging lighting and untextured settings. Its secure GMSL2 connection enables low-latency video transmission without EMI interference, making it suitable for robotics platforms.

### System Setup Requirements

> **Critical:** The ZED X and ZED X Mini use GMSL2 connectivity, which is **not compatible with USB**. This connection type requires specific hardware and cannot work with all host machines. Users must complete the "Get Started with ZED Link" guide to properly configure their NVIDIA Jetson device for GMSL2 camera support before proceeding.

### PC Development Workflow

Developers working on embedded projects can use ZED SDK LocalStreaming to process ZED X data on desktop computers as if the camera connected directly. This capability allows development tasks on PC while targeting Jetson deployment. Detailed setup instructions are available in the dedicated ZED X on PC development guide.

### Virtual Display Setup

For remote system access on NVIDIA Jetson devices, virtual display technology enables GUI application execution without physical monitors. This approach suits headless robotic setups where you need to use the ZED SDK remotely through VNC, NoMachine, or X11 forwarding.

### Advanced Features

- **Raw NV12 Buffer Access:** Performance-critical applications like GStreamer and NVIDIA DeepStream can access raw NV12 buffers directly from the capture pipeline, avoiding unnecessary memory copies and reducing latency for NVIDIA multimedia frameworks.
- **Docker Support:** Comprehensive Docker integration guidance is available for containerized ZED X and ZED X Mini deployments.
- **Troubleshooting Resources:** Complete troubleshooting documentation covers common setup and operational issues.

---

## Developing with ZED X on a PC

Source: https://www.stereolabs.com/docs/cameras/zed-x/zed-x-dev-on-pc/

This guide enables developers to perform development tasks on desktop machines while working with ZED X cameras on embedded platforms like NVIDIA Jetson devices.

By streaming the data over the local network, any ZED SDK application can access a low-latency stream, allowing developers to work with the data as if it were a camera directly connected to their machine.

### Prerequisites

Before beginning, ensure you have:

- Set up your NVIDIA Jetson device for ZED X following the official setup guide
- Physical or remote SSH access to the NVIDIA Jetson device
- ZED SDK installed on both your local machine and the Jetson device

### Setting Up the Jetson Device for Streaming

Run a streaming application on the remote device to enable data transmission. Two implementation options are available:

**C++ Implementation:**

```bash
cd /usr/local/zed/samples/camera\ streaming/sender/cpp
mkdir build && cd build
cmake .. && make
./ZED_Streaming_Sender
```

**Python Implementation:**

```bash
cd /usr/local/zed/samples/camera\ streaming/sender/python
python3 streaming_sender.py
```

The application will display:

```
[Sample] Streaming on port 30000
[Streaming] Streaming is now running....
```

> **Note:** Examine the sample source code to implement streaming functionality in your own applications.

### Connecting to the Stream Locally

Launch the ZED Depth Viewer on your desktop machine:

```bash
./ZED_Depth_Viewer
```

Click the connection icon in the top-left corner, then enter the Jetson device's IP address and port number (default: 30000).

After a brief moment, you'll see a live stream from the remote ZED camera.

### Using Streams in ZED SDK Applications

Modify the initialization parameters to accept network streams instead of direct camera connections. For example, change this standard configuration:

```cpp
InitParameters init_parameters;
// Open the camera
auto err = zed.open(init_parameters);
```

To this network-enabled version:

```cpp
InitParameters init_parameters;
init_parameters.input.setFromStream("192.168.X.X", 30000);
auto err = zed.open(init_parameters);
```

This single modification allows your existing ZED SDK applications to process remote camera streams seamlessly.

---

## ZED X with Docker

Source: https://www.stereolabs.com/docs/cameras/zed-x/zed-x-and-docker/

To use the ZED X and ZED X Mini cameras within a Docker container, specific options and volume mounts are required when running the container.

### Docker Run Command

```bash
docker run --runtime nvidia -it --privileged -e DISPLAY \
  --network host \
  -v /dev/:/dev/ \
  -v /tmp/:/tmp/ \
  -v /var/nvidia/nvcam/settings/:/var/nvidia/nvcam/settings/ \
  -v /etc/systemd/system/zed_x_daemon.service:/etc/systemd/system/zed_x_daemon.service \
  -v ${HOME}/zed_docker_ai/:/usr/local/zed/resources/ \
  <docker_image> sh
```

### Important Prerequisites

- **L4T Version Matching:** Ensure that the L4T (Linux for Tegra) version of your host system matches the L4T version of the container.
- **Driver Installation:** The ZED GMSL2 driver must be only installed on the host machine, and not in the Docker container.

### Troubleshooting

If the ZED X camera cannot be opened in Docker, the ZED Link driver may not be properly installed on the host system. You may need to install the `libqt5core5a` dependency before reinstalling the driver:

```bash
sudo apt install libqt5core5a
```

---

## NVIDIA ISP Guide

Source: https://www.stereolabs.com/docs/cameras/zed-x/zed-x-isp-guide/

This guide provides instructions on utilizing the NVIDIA ISP (Image Signal Processor) for camera configuration and settings. The ISP handles image data processing captured by the camera and applies various enhancements and corrections.

### Modifying and Reloading the ISP

1. **Locate the ISP file:** `/var/nvidia/nvcam/settings/zedx_ar02340.isp`

2. **Edit the file:** Open in a text editor with sudo privileges and make necessary changes. Refer to camera model documentation for available parameters.

3. **Save changes:** Store the modified ISP file.

4. **Reload the ISP:** Execute the following script to apply new settings:

```bash
#!/bin/bash
sudo systemctl restart nvargus-daemon.service
sudo rmmod sl_zedx
sudo rmmod max96712
sleep 1
if [[ ! $(lsmod | grep max96712) ]]; then
    sudo insmod /usr/lib/modules/5.10.104-tegra/kernel/drivers/stereolabs/max96712/max96712.ko
    if [[ ! $? ]]; then
        echo "Error while inserting the module"
        exit
    fi
fi
if [[ $(lsmod | grep sl_zedx) ]]; then
    sudo rmmod sl_zedx
fi

sudo insmod /usr/lib/modules/5.10.104-tegra/kernel/drivers/stereolabs/zedx/sl_zedx.ko
```

### Exposure/Gain Settings

The NVIDIA ISP allows adjustment of exposure and gain settings for optimal image capture.

#### Locating Settings

Exposure/gain settings appear as:

```
ae.ExposureTuningTable.Preview[0] = {2.4, 0.01666, 3.0, 1.0};
ae.ExposureTuningTable.Preview[1] = {2.4, 0.03333, 3.0, 1.0};
ae.ExposureTuningTable.Preview[2] = {2.4, 0.03333, 3.0, 1.0};
ae.ExposureTuningTable.Preview[3] = {2.4, 0.03333, 3.0, 1.0};
ae.ExposureTuningTable.Preview[4] = {2.4, 0.03333, 3.0, 1.0};
ae.ExposureTuningTable.Preview[5] = {2.4, 0.06666, 3.0, 1.0};
ae.ExposureTuningTable.Preview[6] = {2.4, 0.06666, 3.0, 1.0};
ae.ExposureTuningTable.Preview[7] = {2.4, 0.06666, 3.0, 1.0};
```

#### Parameter Meanings

- **First value (2.4):** Camera aperture. ZED X has fixed aperture, requiring no changes.
- **Second value (0.01666):** Exposure time indicating the exposure interval:
  - `0.01666` = exposure interval of 0-16ms
  - `0.03333` = exposure interval of 16-33ms
- **Third and fourth values (1.0, 1.0):** Analog Gain (AG) and Digital Gain (DG) respectively. Adjust AG to control gain relative to exposure.

> **Important:** Do not modify the DG because it makes the auto-exposure unstable.

#### Example AG Values

For specific illumination scenarios:

| AG  | Exposure (ms) | Gain |
|-----|---------------|------|
| 1.0 | 16,000        | 900  |
| 3.0 | 13,113        | 1300 |
| 5.0 | 8,397         | 2200 |
| 7.0 | 6,751         | 2900 |
| 9.0 | 5,676         | 3500 |

Save the ISP file with updated exposure/gain values.

### Enabling Lens Shading Correction

The NVIDIA ISP supports lens shading correction to compensate for lens imperfections.

#### Steps

1. **Open the ISP file** in a text editor.

2. **Locate resolution settings:**

   ```
   lensShading.imageHeight        = 1200;
   lensShading.imageWidth         = 1920;
   ```

3. **Adjust resolution values** to match your desired resolution for lens shading correction. You can only use one resolution if you enable the lens shading correction and it is the one set with `imageHeight` and `imageWidth`.

4. **Enable lens shading correction** by changing:

   ```
   ap15Function.lensShading = FALSE; -->  TRUE;
   ```

5. **Save the ISP file** with updated settings.

> **Warning:** If you try to open the camera with another resolution it will crash and you will have to restart the daemon.

> **Note:** Ensure that the resolution set for lens shading correction matches the resolution you intend to use; otherwise, it may cause issues.

---

## Raw NV12 Buffer Access

Source: https://www.stereolabs.com/docs/cameras/zed-x/zed-x-nv12-access/

The RawBuffer API provides direct access to native **NvBufSurface** buffers from the ZED X camera capture pipeline, enabling zero-copy integration with NVIDIA multimedia frameworks instead of copying image data.

### Use Cases

- **GStreamer pipelines** -- Feed camera frames directly into GStreamer without memory copies
- **NVIDIA DeepStream** -- Low-latency inference pipelines for real-time object detection
- **Custom CUDA processing** -- Direct GPU access to camera buffers
- **Hardware video encoding** -- Direct integration with NVENC

### Important Limitations

> **Warning:** This is an advanced low-level API. Improper use can crash the Argus stack responsible for camera operations or destabilize the system.

**Availability:** Only in ZED SDK version 5.2+, supported on NVIDIA Jetson platforms with GMSL2 cameras. Not available on x86 platforms, USB cameras, or with SVO/Network streaming.

### Enabling the API

Define `SL_ENABLE_ADVANCED_CAPTURE_API` **before** including the ZED SDK header:

```cpp
#define SL_ENABLE_ADVANCED_CAPTURE_API
#include <sl/Camera.hpp>
```

### Code Example

```cpp
#define SL_ENABLE_ADVANCED_CAPTURE_API
#include <sl/Camera.hpp>
#include <nvbufsurface.h>  // NVIDIA buffer surface API

using namespace sl;

int main() {
    Camera zed;
    InitParameters init_params;
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
                    // Get NvBufSurface pointers (zero-copy)
                    void* nvbufLeft = raw.getRawBuffer();
                    void* nvbufRight = raw.getRawBufferRight();

                    // Cast to NvBufSurface* for use with NVIDIA APIs
                    NvBufSurface* surfLeft = static_cast<NvBufSurface*>(nvbufLeft);
                    NvBufSurface* surfRight = static_cast<NvBufSurface*>(nvbufRight);

                    // Access buffer properties
                    uint64_t timestamp = raw.getTimestamp();
                    unsigned int width = raw.getWidth();
                    unsigned int height = raw.getHeight();

                    // Process the NV12 buffer with your pipeline...
                    // Buffer is automatically released when 'raw' goes out of scope
                }
            }
        }
    }

    zed.close();
    return 0;
}
```

### DeepStream Integration

For NVIDIA DeepStream integration, pass the `NvBufSurface` object directly to your inference pipeline:

```cpp
#define SL_ENABLE_ADVANCED_CAPTURE_API
#include <sl/Camera.hpp>
#include <nvbufsurface.h>
#include <nvds_meta.h>

// In your DeepStream pipeline loop:
RawBuffer raw;
if (zed.retrieveImage(raw) == ERROR_CODE::SUCCESS && raw.isValid()) {
    NvBufSurface* surface = static_cast<NvBufSurface*>(raw.getRawBuffer());
    
    // Feed surface to DeepStream batch
    // surface->surfaceList[0] contains the NV12 frame data
    
    // Process with nvinfer, nvtracker, etc.
}
```

### Critical Warnings

**DO NOT manually destroy the NvBufSurface** (e.g., do not call `NvBufSurfaceDestroy`, `NvBufSurfaceUnMap`, etc.). The buffers are owned and managed by the SDK -- manual destruction causes crashes or undefined behavior.

Additional constraints:

- The SDK manages buffer memory; you have **read access only**
- Hold the `RawBuffer` for minimal duration to avoid blocking the capture pipeline
- Currently only `RAW_BUFFER_TYPE::NVBUFSURFACE` is supported
- API available exclusively on **NVIDIA Jetson platforms** with GMSL2 cameras

### Buffer Format

Raw buffers contain **NV12** formatted image data:

- **Y plane:** Full-resolution luminance data
- **UV plane:** Half-resolution (2x2 subsampled) chrominance data

This is the native sensor format from ZED X, providing maximum performance for pipelines working directly with NV12 data.

---

## Troubleshooting

Source: https://www.stereolabs.com/docs/cameras/zed-x/troubleshooting/

### The Camera is Not Detected

GMSL2 cameras have limited flexibility compared to USB cameras. Hardware configuration changes require special handling.

**Required Actions After Hardware Changes:**

Any modification to hardware configuration -- such as connecting/disconnecting cameras or changing camera order -- necessitates one of the following:

1. **Reboot the Jetson device**, OR
2. **Restart the ZED daemon** using:

   ```bash
   sudo systemctl restart zed_x_daemon
   ```

> **Note:** When using a custom carrier board or partner ECU, verify that the custom driver provides the `zed_x_daemon` service. If unavailable, hardware modifications will require a full device reboot.

### Blurry Images After System Update

Following system updates, users may experience blurry images from GMSL2 cameras due to library overwrites affecting the ZED Link driver.

#### Resolution Steps

**Step 1: Download the Driver Package**

Visit the [ZED X Drivers download page](https://www.stereolabs.com/developers/drivers) and select the appropriate driver package for your device.

**Step 2: Extract and Restore the Patched Library**

```bash
ar x stereolabs-zed<model>_<version>-<deser>-<l4t_version>_arm64.deb
tar xvf data.tar.xz
sudo cp ./tmp/R<l4t_version>/libnvisppg.so /usr/lib/aarch64-linux-gnu/tegra/libnvisppg.so
```

**Parameters to Replace:**

- `stereolabs-zed<model>_<version>-<deser>-<l4t_version>_arm64.deb`: Your actual downloaded filename
- `<l4t_version>`: Your current L4T version (example: R36.4.3)

**Step 3: Reboot the System**

```bash
sudo reboot
```

### Contact Support

If troubleshooting steps don't resolve your issue, reach out to the community for additional assistance at [Stereolabs Community Forum](https://community.stereolabs.com/).
