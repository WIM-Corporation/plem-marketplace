---
description: >
  ZED SDK installation guide covering overview, recommended specifications,
  platform-specific installation (Windows, Linux, NVIDIA Jetson), virtual display
  setup on Jetson, and Docker container usage.
---

# ZED SDK Installation

## Table of Contents

- [ZED SDK Overview](#zed-sdk-overview)
- [Recommended Specifications](#recommended-specifications)
- [Install on Windows](#install-on-windows)
- [Install on Linux](#install-on-linux)
- [Install on NVIDIA Jetson](#install-on-nvidia-jetson)
- [Virtual Display on Jetson](#virtual-display-on-jetson)
- [Docker](#docker)

---

## ZED SDK Overview

> Source: https://www.stereolabs.com/docs/development/zed-sdk/

The ZED SDK is the core software for developing applications with ZED stereo cameras. It provides tools, libraries, and APIs to access camera features comprehensively.

### Key Features

- **High Resolution Image Capture**: Access high-res, high frame rate images with ISP for clear, detailed results
- **Inertial Data Integration**: Incorporate IMUs for improved motion tracking and stability
- **Real-Time 3D Perception**: Enable depth perception for 3D-aware applications
- **Localization**: Tools for camera positioning within environments
- **Global Positioning**: GPS integration for location-aware applications
- **Spatial Mapping**: Create detailed 3D maps for robotics, navigation, and AR
- **Robust Object Detection**: Built-in AI for real-time object detection and tracking
- **Body Tracking**: Track human bodies for gesture recognition and interactive experiences
- **Multi-Camera Fusion**: Use multiple ZED cameras for enhanced spatial understanding
- **Multi-Language Support**: C++, Python, C#, and C
- **Seamless Integration**: Works with popular development environments and frameworks

### Getting Started

1. **Install the SDK**: Download and install from the official website
2. **Set Up Development Environment**: Configure your preferred IDE
3. **Explore Examples and Tutorials**: Review code samples and step-by-step guides
4. **Refer to Documentation**: Learn features and APIs through comprehensive docs
5. **Start Building**: Develop applications using the ZED SDK

### Language Support

- C++
- Python
- C#
- C

### Integration Ecosystem

**Game Engines & Development Environments:**
- Unity
- Unreal Engine 5

**Computer Vision & Libraries:**
- OpenCV
- PyTorch

**Robotics Frameworks:**
- ROS
- ROS 2
- Isaac ROS
- Isaac Sim

**Specialized Tools:**
- YOLO (object detection)
- MATLAB
- GStreamer
- Foxglove
- Live Link (for UE5 and Unity)
- Touch Designer

---

## Recommended Specifications

> Source: https://www.stereolabs.com/docs/development/zed-sdk/specifications/

### PC Specifications

**Minimum Configuration:**

| Component | Requirement |
|-----------|-------------|
| Processor | Dual-core 2.3GHz |
| RAM | 8GB |
| Graphics | NVIDIA RTX GPU* |
| Connectivity | USB 2.0*** |
| OS | Windows 10/11, Ubuntu 22.04, 24.04 |

**Recommended Configuration:**

| Component | Requirement |
|-----------|-------------|
| Processor | Quad-core 2.7GHz or faster |
| RAM | 16GB |
| Graphics | NVIDIA RTX with >6GB VRAM |
| Connectivity | USB 3.0 |
| OS | Windows 10/11, Ubuntu 22.04, 24.04 |

### Embedded Systems

| Component | Requirement |
|-----------|-------------|
| Processor | NVIDIA Jetson Xavier, Orin, Thor** |
| RAM | minimum 4GB models |
| Graphics | NVIDIA Jetson Xavier, Orin |
| Connectivity | USB 2.0/3.0/GMSL2 |
| OS | Jetson Linux v35.3/v35.4/v36.x (JP5/JP6/JP7)**** |

### Important Notes

- \* GPU must have Compute Capabilities >= 7.5 based on Turing or newer architecture
- \*\* NVIDIA Jetson Thor support is under development with potential limitations
- \*\*\* USB 2.0 maximum resolution: VGA at 30 FPS
- \*\*\*\* Jetson Linux v35.5 and v35.6 are not supported

### NVIDIA Driver Requirements

Use the latest available NVIDIA drivers for your hardware.

**Windows:** Follow the official NVIDIA Driver Download page instructions for your specific GPU model.

**Ubuntu:**

> **Warning:** Not required for NVIDIA Jetson systems, as drivers are included in Jetson Linux.

Open kernel module:

```bash
sudo apt-get install -y nvidia-open
```

Proprietary kernel module:

```bash
sudo apt-get install -y cuda-drivers
```

Consult the official NVIDIA Driver Installation Guide for Ubuntu for additional details.

---

## Install on Windows

> Source: https://www.stereolabs.com/docs/development/zed-sdk/windows/

### Download the ZED SDK

The ZED SDK for Windows contains all the drivers and libraries needed to power your camera along with tools for testing its features and settings. Download the ZED SDK from the [releases page](https://www.stereolabs.com/developers/release/) for Windows. Multiple CUDA versions are available; if you have no preference, select the latest one.

### Install the ZED SDK

Run the installer. The installation wizard will guide you through the setup process.

### Setup CUDA

CUDA is an NVIDIA library that the ZED SDK uses to run fast AI and computer vision tasks on your graphics card. During the ZED SDK installation, if CUDA is not detected on your computer, the installer will prompt you to download and install it.

You can skip this step and install CUDA manually from the NVIDIA [CUDA Toolkit archive](https://developer.nvidia.com/cuda-toolkit-archive).

### Restart Your Computer

At the end of the installation, a system restart is required to update the Windows environment variables.

> **Note**: Skipping this step could lead to library not found errors. Make sure to restart your computer, especially if this is the first time the SDK is installed on your machine.

---

## Install on Linux

> Source: https://www.stereolabs.com/docs/development/zed-sdk/linux/

### Download and Install the ZED SDK

The ZED SDK for Linux includes all drivers, libraries, and tools needed to operate your camera and test its capabilities.

1. Download the [ZED SDK](https://www.stereolabs.com/developers/release/) for Linux

2. Navigate to your download folder:

   ```bash
   cd path/to/download/folder
   ```

3. Install `zstd` if not already present (required for the installer):

   ```bash
   sudo apt install zstd
   ```

4. Make the installer executable:

   ```bash
   chmod +x ZED_SDK_UbuntuXX_cudaYY.Y_vZ.Z.Z.zstd.run
   ```

5. Run the installer:

   ```bash
   ./ZED_SDK_UbuntuXX_cudaYY.Y_vZ.Z.Z.zstd.run
   ```

6. Review the Software License and press `q` to continue

7. Answer prompts about dependencies, tools, and samples installation (type `y` for yes, `n` for no, or press `Enter` for defaults)

### Installing in Silent Mode

Basic silent installation:

```bash
./ZED_SDK_UbuntuXX_cudaYY.Y_vZ.Z.Z.zstd.run -- silent
```

**Silent Mode Options:**

Runtime only (excludes libraries, headers, tools, samples):

```bash
./ZED_SDK_UbuntuXX_cudaYY.Y_vZ.Z.Z.zstd.run -- silent runtime_only
```

Skip CUDA check:

```bash
./ZED_SDK_UbuntuXX_cudaYY.Y_vZ.Z.Z.zstd.run -- silent skip_cuda
```

Without Object Detection (excludes AI module for Object Detection, Body Tracking, Neural Depth):

```bash
./ZED_SDK_UbuntuXX_cudaYY.Y_vZ.Z.Z.zstd.run -- silent skip_od_module
```

Without Python Wrapper:

```bash
./ZED_SDK_UbuntuXX_cudaYY.Y_vZ.Z.Z.zstd.run -- silent skip_python
```

Without sl_hub:

```bash
./ZED_SDK_UbuntuXX_cudaYY.Y_vZ.Z.Z.zstd.run -- silent skip_hub
```

Without Tools and Samples:

```bash
./ZED_SDK_UbuntuXX_cudaYY.Y_vZ.Z.Z.zstd.run -- silent skip_tools
```

### Setup CUDA

CUDA is an NVIDIA library that enables fast AI and computer vision processing on your graphics card. The ZED SDK installer automatically downloads and installs CUDA if not detected.

**For manual CUDA installation:**

1. Download CUDA from the [CUDA Toolkit archive](https://developer.nvidia.com/cuda-toolkit-archive)

2. Select these options on the download page: Linux, x86_64, Ubuntu, 22.04 or 20.04, deb (network)

3. Determine your Ubuntu version:

   ```bash
   source /etc/lsb-release
   UBUNTU_VERSION=ubuntu${DISTRIB_RELEASE/./}
   ```

4. Add the CUDA apt repository:

   ```bash
   wget https://developer.download.nvidia.com/compute/cuda/repos/${UBUNTU_VERSION}/x86_64/cuda-keyring_1.0-1_all.deb
   sudo dpkg -i cuda-keyring_1.0-1_all.deb
   ```

5. Update apt cache:

   ```bash
   sudo apt-get update
   ```

6. Install CUDA (specifying exact version recommended):

   ```bash
   sudo apt-get -y install cuda-11-8
   ```

### Restart Your Computer

After installation completes, restart your system to ensure all paths are properly updated.

---

## Install on NVIDIA Jetson

> Source: https://www.stereolabs.com/docs/development/zed-sdk/jetson/

### Overview

To use Stereolabs cameras on NVIDIA Jetson platforms, you need to:

- Setup JetPack
- Install the ZED SDK for NVIDIA Jetson

### Download and Install JetPack

> **Note**: If you are working with a Stereolabs ZED Box, refer to the relative documentation for the ZED Box, ZED Box Orin, or ZED Box Mini instead.

NVIDIA Jetson boards need to be flashed first with JetPack (their operating system). NVIDIA recommends using the SDK Manager to flash your NVIDIA Jetson with the latest OS image and developer tools.

Go to the [JetPack section](https://developer.nvidia.com/embedded/jetpack) of NVIDIA's website and click on **Download SDK Manager**. More installation instructions are available on the official NVIDIA documentation for [Install Jetson Software with SDK Manager](https://docs.nvidia.com/sdk-manager/install-with-sdkm-jetson/index.html).

### Download and Install the ZED SDK

1. **Download** the ZED SDK for NVIDIA Jetson from the [Stereolabs releases page](https://www.stereolabs.com/developers/release/). Select the version matching your JetPack installation.

2. **Navigate** to your download folder:

   ```bash
   cd path/to/download/folder
   ```

3. **Add execution permissions** to the installer:

   ```bash
   chmod +x ZED_SDK_Tegra_L4TXX.X_vY.Y.Y.zstd.run
   ```

4. **Run** the ZED SDK installer:

   ```bash
   ./ZED_SDK_Tegra_L4TXX.X_vY.Y.Y.zstd.run
   ```

5. **Read and accept** the Software License displayed at the beginning (press `q` to continue)

6. **Answer installation prompts** regarding dependencies, tools, and samples using `y` for yes, `n` for no, or `Enter` for default options

> **Note**: CUDA is automatically installed with JetPack on Jetson boards, so you're ready to use the ZED SDK after installation completes.

### Installing in Silent Mode

Basic silent installation:

```bash
./ZED_SDK_Tegra_L4TXX.X_vY.Y.Y.zstd.run -- silent
```

**Silent Mode Options:**

Runtime only (excludes static libraries, headers, tools, and samples):

```bash
./ZED_SDK_Tegra_L4TXX.X_vY.Y.Y.zstd.run -- silent runtime_only
```

Skip CUDA check:

```bash
./ZED_SDK_Tegra_L4TXX.X_vY.Y.Y.zstd.run -- silent skip_cuda
```

Without AI Module (excludes Object Detection, Body Tracking, Neural Depth):

```bash
./ZED_SDK_Tegra_L4TXX.X_vY.Y.Y.zstd.run -- silent skip_od_module
```

Without Python Wrapper:

```bash
./ZED_SDK_Tegra_L4TXX.X_vY.Y.Y.zstd.run -- silent skip_python
```

Without sl_hub:

```bash
./ZED_SDK_Tegra_L4TXX.X_vY.Y.Y.zstd.run -- silent skip_hub
```

Without Tools and Samples:

```bash
./ZED_SDK_Tegra_L4TXX.X_vY.Y.Y.zstd.run -- silent skip_tools
```

---

## Virtual Display on Jetson

> Source: https://www.stereolabs.com/docs/development/zed-sdk/virtual-display/

This guide explains how to set up a virtual display on NVIDIA Jetson devices running ZED SDK applications in headless mode, eliminating the need for physical HDMI dongles or monitors.

### Prerequisites

- A configured remote NVIDIA Jetson device with ZED SDK installed
- Physical or SSH access to the device
- Optional: Remote desktop software like VNC, NoMachine, or X11 forwarding

### Virtual Display Setup

Download a pre-made script from the provided link or manually create `setup-virtual-display.sh`.

The script performs these key functions:

- Detects JetPack version (5.x or 6.x) and L4T release
- Identifies DisplayPort connectors on your hardware
- Generates a 1920x1080@60Hz virtual display using EDID binary data
- Configures nvidia DDX Xorg driver with ConnectedMonitor and CustomEDID options
- Removes incompatible boot parameters on JetPack 6 systems

### Implementation Steps

1. Make the script executable:

   ```bash
   chmod +x setup-virtual-display.sh
   ```

2. Run with sudo privileges:

   ```bash
   sudo ./setup-virtual-display.sh && sudo systemctl restart gdm
   ```

3. Reboot the system to apply changes:

   ```bash
   sudo reboot
   ```

### Verification

After reboot, confirm the setup with:

```bash
DISPLAY=:0 xrandr                    # Should show 1920x1080 screen
DISPLAY=:0 eglinfo 2>&1 | head -15   # Should show NVIDIA EGL vendor
```

### How It Works

- Creates a virtual 1920x1080 display without physical monitor connection
- Enables GPU acceleration for graphics applications
- Supports remote desktop protocol connections (VNC, NoMachine)
- Maintains full EGL/CUDA/Argus compatibility
- Allows real monitors to be hot-plugged later

### Reverting to Physical Display

```bash
sudo cp /etc/X11/xorg.conf.bak.original /etc/X11/xorg.conf && sudo systemctl restart gdm
```

### Troubleshooting

- **Remote desktop connection issues**: Verify your remote desktop server is properly configured and running.
- **Display resolution problems**: Modify the script to adjust the virtual resolution from the default 1920x1080@60Hz.
- **Switch back to physical display**: Use the revert command above, then reboot.

---

## Docker

> Source: https://www.stereolabs.com/docs/development/zed-sdk/docker/

Docker provides a streamlined approach to deploying the ZED SDK on Linux and NVIDIA Jetson systems. This containerization technology enables developers to package all necessary dependencies in isolated environments, preventing conflicts with the host system.

### Available Docker Images

Stereolabs offers two distinct Docker image types for each SDK release, available on Docker Hub:

**Runtime Images:**
- Contain minimal dependencies required for executing ZED SDK applications
- Recommended for production deployments
- Optimized for smaller image size and faster deployment

**Development Images:**
- Include comprehensive development tools for application compilation
- Feature CUDA toolkit, static libraries, and ZED SDK headers
- Ideal for active development and testing

### Getting Started with ZED SDK Containers

```bash
docker pull stereolabs/zed:[tag]  # Download image with specified tag
docker run --gpus all -it --privileged stereolabs/zed:[tag]  # Start container
```

**Command Flags Explained:**

- `--gpus all`: Grants the container access to all available GPU resources on the host system
- `--privileged`: Enables container permissions to access USB-connected camera hardware

### Next Steps

For comprehensive guidance on container customization, volume management, performance optimization, and advanced configurations, consult the dedicated Docker section of the official documentation.
