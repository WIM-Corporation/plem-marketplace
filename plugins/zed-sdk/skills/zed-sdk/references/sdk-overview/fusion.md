---
description: >
  ZED SDK Fusion documentation — Fusion API overview with local/network
  workflows, configuration files, and ZED360 calibration tool.
sources:
  - https://www.stereolabs.com/docs/fusion/overview/
  - https://www.stereolabs.com/docs/fusion/zed360/
fetched: 2026-04-07
---

# Fusion

## Table of Contents

- [Fusion Overview](#fusion-overview)
- [ZED360](#zed360)

---

## Fusion Overview

Source: https://www.stereolabs.com/docs/fusion/overview/

### Overview

The Fusion API enables developers to create applications using data from multiple cameras. It handles time synchronization and geometric calibration issues, along with 360-degree data fusion.

The module extends ZED camera functionality without changing how developers use it, operating on a publish/subscribe pattern where cameras publish data and the Fusion API subscribes to it.

### Workflow

The Fusion API supports two operational approaches:

#### Local Workflow

All ZED cameras connect to the same host computer. Publishers and subscriber run together.

- **Advantages**: low latency, efficient shared memory protocol, high FPS capability, simple setup
- **Disadvantages**: requires powerful GPU with large memory, high USB bandwidth needs, cable length limitations

#### Network Workflow

Publishers and subscriber run on different machines (edge computing model). Based on ZED Boxes architecture.

- **Advantages**: high availability, no single point of failure, scalability, remote system monitoring via ZED Hub
- **Disadvantages**: introduces small latency (<5ms depending on network configuration)

### Available Modules

The Fusion API currently integrates:
- Object detection
- Body tracking
- Spatial mapping
- Positional tracking with external GNSS

### Getting Started

Calibration is critical for optimal performance. The calibration process is critical, as accurate calibration is necessary to obtain reliable and precise results.

Developers should use **ZED360**, a calibration tool designed to accurately calibrate camera arrays. Various calibration methods exist depending on the setup.

### Setting Up Network Workflow

Each camera must run a streaming application that computes required data and transmits it over the local network. The key step involves calling the `startPublishing()` method, which designates the SDK instance as a "Fusion data provider."

By default, data streams on port 30000, configurable via `CommunicationParameters`. Multiple cameras connected to the same PC require different ports.

#### Example Code Structure

```cpp
CommunicationParameters configuration;
zed.startPublishing(configuration);

Bodies bodies;
while (true) {
    auto err = zed.grab();
    if (err == ERROR_CODE::SUCCESS) {
        zed.retrieveBodies(bodies, body_tracker_parameters_rt);
    }
}
```

### Configuration Files

Configuration files contain workflow and camera calibration data in JSON format, organized by camera serial number.

#### File Structure Components

- **input.zed**: Publisher camera opening configuration (type and configuration parameters)
- **input.fusion**: Subscriber connection method (INTRA_PROCESS for local, LOCAL_NETWORK for distributed)
- **world.rotation**: Camera orientation in radians
- **world.translation**: Camera position in meters

Configuration types supported:
- USB_SERIAL, USB_ID, GMSL_SERIAL, GMSL_ID
- SVO_FILE (recorded video files)
- STREAM (network streams)

For network workflows, configuration includes IP address and port for edge device communication.

---

## ZED360

Source: https://www.stereolabs.com/docs/fusion/zed360/

### Overview

ZED360 is a tool that simplifies multi-camera data fusion for users using the ZED SDK's Fusion API with ZED stereo cameras. It enables seamless camera calibration and data fusion, with current focus on body-tracking functionality.

> **Important Note:** ZED360 works exclusively with stereo cameras and cannot be used for ZED X One monocular-to-stereo calibration tasks.

### Getting Started

#### Launch ZED360

- **Windows**: `C:\Program Files (x86)\ZED SDK\tools\ZED360.exe`
- **Linux**: `/usr/local/zed/tools/ZED360`

### Calibration Process

The calibration uses body tracking data from connected cameras. An optimization algorithm aligns incoming data in common WORLD coordinates to minimize keypoint distance discrepancies across cameras.

#### Workflow Options

##### Local Workflow

All cameras connect to a single machine acting as both publisher and subscriber.

**Connection methods:**
- Click "Auto Discover" to locate connected ZED cameras
- Load a configuration file describing your setup

##### Network Workflow

Used when each publisher camera connects to its own host machine, with ZED360 as the dedicated subscriber performing fusion operations.

**Setup steps:**
1. Enter ZED Hub credentials
2. Select workspace
3. Choose devices for calibration
4. Click "Retrieve the selected devices"

### Calibration Rules

- Each camera requires minimal overlap to capture shared subjects
- Only one person should be visible to any single camera at a time

### Step-by-Step Calibration

1. Have a person move throughout the entire desired coverage area
2. Walk slowly to allow iterative optimization (runs approximately every 10 seconds)
3. Continue moving across space for better calibration results
4. Stop when bodies align properly by clicking "Finish calibration"

### Post-Calibration

After completion, save the generated JSON configuration file for use with applications utilizing the Fusion API.

### Key Technical Details

- Camera rotations (pitch and roll) derive from IMU data; only yaw is calibrated
- Floor plane estimation occurs when ankles are visible
- The first loaded camera becomes the world origin at position (0, H, 0), where H represents its height
