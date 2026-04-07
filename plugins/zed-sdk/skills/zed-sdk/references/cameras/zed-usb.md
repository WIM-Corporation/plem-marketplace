---
description: >
  ZED USB 3 cameras (ZED, ZED Mini, ZED 2, ZED 2i) — getting started guide covering
  unboxing, connection, SDK installation, tools, code samples, virtual display, and Docker.
sources:
  - https://www.stereolabs.com/docs/cameras/zed-2/
---

# ZED USB 3 Cameras

## Table of Contents

- [ZED USB 3 Camera Getting Started](#zed-usb-3-camera-getting-started)
  - [Overview](#overview)
  - [What's in the Box](#whats-in-the-box)
  - [Connect Your Camera](#connect-your-camera)
  - [Download and Install the ZED SDK](#download-and-install-the-zed-sdk)
  - [Test with ZED Tools](#test-with-zed-tools)
  - [Play with Code Samples](#play-with-code-samples)
  - [Using ZED with Virtual Display](#using-zed-with-virtual-display)
  - [Using Docker](#using-docker)

---

## ZED USB 3 Camera Getting Started

Source: https://www.stereolabs.com/docs/cameras/zed-2/

### Overview

The ZED USB 3 camera enables applications spanning robotics, drones, virtual reality, and augmented reality. It provides high-definition stereo video and depth perception, enabling you to create immersive experiences and advanced computer vision applications.

> **Note:** This guide covers ZED, ZED Mini, ZED 2, and ZED 2i models. For ZED X or ZED X One cameras, refer to their respective getting started guides.

### What's in the Box

The package includes:

- ZED 2i or ZED Mini stereo camera
- 1.5m USB 3.0 cable
- 4m external USB 3.0 cable

### Connect Your Camera

Simply unpack the device and plug it into any USB 3.0 port. The cameras are UVC (USB Video Class) compliant and automatically recognized by computers.

#### Common Connection Questions

- **Multiple cameras:** See support documentation for using several ZED cameras on a single platform
- **USB extension:** Reference materials cover extending the working distance of your camera
- **Connection issues:** Troubleshooting guides address USB 3.0 bandwidth and frame dropping problems
- **IP camera setup:** Consult the Local Streaming section to transmit video over IP networks

### Download and Install the ZED SDK

The ZED SDK is available for Windows, Linux, and NVIDIA Jetson platforms. It contains libraries powering the camera plus testing tools and feature demonstrations.

Select your platform and follow installation instructions:

- [Windows](https://www.stereolabs.com/docs/development/zed-sdk/windows/)
- [Linux](https://www.stereolabs.com/docs/development/zed-sdk/linux/)
- [Jetson](https://www.stereolabs.com/docs/development/zed-sdk/jetson/)

### Test with ZED Tools

The ZED Tools suite provides user-friendly applications for visualizing and interacting with camera data:

- ZED Explorer
- ZED Studio
- ZED Depth Viewer
- ZED Sensor Viewer
- ZEDfu
- ZED Diagnostic
- ZED Calibration

### Play with Code Samples

The SDK includes tutorials and samples covering:

- Video capture
- Depth perception
- Positional tracking
- Spatial mapping
- Object detection
- Body tracking

Explore the [GitHub repository](https://github.com/stereolabs) for updates and access the [API documentation](https://www.stereolabs.com/docs/api/) for deeper learning.

### Using ZED with Virtual Display

For remote access on NVIDIA Jetson devices, virtual displays enable GUI applications and development tools without physical monitors or HDMI adapters -- ideal for headless robotic setups using VNC, NoMachine, or X11 forwarding.

Reference the "Virtual Display on NVIDIA Jetson" documentation for configuration details.

### Using Docker

For production deployments, Stereolabs recommends packaging applications and the ZED SDK in Docker containers for consistency and simplified distribution.
