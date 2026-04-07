---
description: >
  ZED SDK Global Localization documentation — overview, GNSS/RTK setup on Linux,
  data synchronization, VIO GNSS calibration, coordinate systems, and troubleshooting.
sources:
  - https://www.stereolabs.com/docs/global-localization/
  - https://www.stereolabs.com/docs/global-localization/using-gnss-linux/
  - https://www.stereolabs.com/docs/global-localization/data-synchronization/
  - https://www.stereolabs.com/docs/global-localization/vio-gnss-calibration/
  - https://www.stereolabs.com/docs/global-localization/global-localization-coordinate-frames/
  - https://www.stereolabs.com/docs/global-localization/troubleshooting/
fetched: 2026-04-07
---

# Global Localization

## Table of Contents

- [Global Localization Overview](#global-localization-overview)
- [Setting up GNSS / RTK on Linux](#setting-up-gnss--rtk-on-linux)
- [Data Synchronization](#data-synchronization)
- [VIO GNSS Calibration](#vio-gnss-calibration)
- [Coordinate Systems](#coordinate-systems)
- [Troubleshooting](#troubleshooting)

---

## Global Localization Overview

Source: https://www.stereolabs.com/docs/global-localization/

### Overview

The ZED SDK's Global Localization module enables real-time camera tracking and localization using a global coordinate system. It combines stereo vision, IMU, and GNSS data to determine the camera's precise position and orientation relative to a global reference frame.

A key capability is operation in GNSS-denied environments where satellite data is unavailable, allowing the system to maintain centimeter-precision positioning through visual and inertial data.

### How It Works

Global localization integrates three complementary data sources:

- **Stereo Vision**: Visual odometry from the ZED camera
- **IMU**: Inertial measurement data
- **GNSS**: Satellite positioning signals

The fusion algorithm dynamically adjusts weighting based on real-time sensor reliability. Each sensor compensates for others' weaknesses -- GNSS corrects visual odometry drift while vision maintains positioning during GNSS outages.

#### Key Components

**Data Synchronization**: ZED cameras operate at 15-120 fps, GNSS at ~1 Hz, and IMU at 400 Hz. Synchronization aligns these disparate rates for effective fusion.

**VIO/GNSS Calibration**: Initial alignment occurs during startup once GNSS fix is obtained. The system provides preliminary calibration quickly, then refines it continuously.

**Sensor Fusion**: Once aligned, visual-inertial data fuses with GNSS. During GNSS outages, visual-inertial odometry maintains positioning.

**Global Output**: Fused position and orientation data converts to various coordinate system formats.

### Getting Started

#### Setting Up Visual-Inertial Tracking

Initialize the ZED camera with appropriate parameters:

**C++:**
```cpp
sl::Camera zed;
sl::InitParameters init_params;
init_params.depth_mode = sl::DEPTH_MODE::ULTRA;
init_params.coordinate_system = sl::COORDINATE_SYSTEM::RIGHT_HANDED_Y_UP;
init_params.coordinate_units = sl::UNIT::METER;
sl::ERROR_CODE camera_open_error = zed.open(init_params);
```

**Python:**
```python
init_params = sl.InitParameters(depth_mode=sl.DEPTH_MODE.ULTRA,
                                coordinate_units=sl.UNIT.METER,
                                coordinate_system=sl.COORDINATE_SYSTEM.RIGHT_HANDED_Y_UP)
zed = sl.Camera()
status = zed.open(init_params)
```

Enable positional tracking:

**C++:**
```cpp
sl::PositionalTrackingParameters pose_tracking_params;
pose_tracking_params.mode = sl::POSITIONAL_TRACKING_MODE::GEN_3;
pose_tracking_params.enable_area_memory = false;
auto positional_init = zed.enablePositionalTracking(pose_tracking_params);
```

**Python:**
```python
pose_tracking_params = sl.PositionalTrackingParameters()
pose_tracking_params.mode = sl.POSITIONAL_TRACKING_MODE.GEN_3()
pose_tracking_params.enable_area_memory = False
positional_init = zed.enable_positional_tracking(pose_tracking_params)
```

Optionally set a Region of Interest (ROI) for static camera elements:

**C++:**
```cpp
std::string roi_file_path = "";
sl::Mat mask_roi;
auto err = mask_roi.read(roi_file_path.c_str());
if (err == sl::ERROR_CODE::SUCCESS)
    zed.setRegionOfInterest(mask_roi, {sl::MODULE::ALL});
```

**Python:**
```python
mask_roi = sl.Mat()
err = mask_roi.read(opt.roi_mask_file)
if err == sl.ERROR_CODE.SUCCESS:
    zed.set_region_of_interest(mask_roi, [sl.MODULE.ALL])
```

Publish VIO data to the Sensor Fusion module:

**C++:**
```cpp
zed.startPublishing();
```

**Python:**
```python
configuration = sl.CommunicationParameters()
zed.start_publishing(configuration)
```

#### Setting Up Global Positional Tracking

Initialize the Fusion object:

**C++:**
```cpp
sl::Fusion fusion;
sl::InitFusionParameters init_fusion_param;
init_fusion_param.coordinate_system = sl::COORDINATE_SYSTEM::RIGHT_HANDED_Z_UP;
init_fusion_param.coordinate_units = sl::UNIT::METER;
init_fusion_param.verbose = true;
sl::FUSION_ERROR_CODE fusion_init_code = fusion.init(init_fusion_param);
```

**Python:**
```python
fusion = sl.Fusion()
init_fusion_param = sl.InitFusionParameters()
init_fusion_param.coordinate_units = sl.UNIT.METER
init_fusion_param.coordinate_system = sl.COORDINATE_SYSTEM.RIGHT_HANDED_Y_UP
init_fusion_param.verbose = True
fusion_init_code = fusion.init(init_fusion_param)
```

Subscribe to camera data:

**C++:**
```cpp
sl::CameraIdentifier uuid(zed.getCameraInformation().serial_number);
fusion.subscribe(uuid);
```

**Python:**
```python
uuid = sl.CameraIdentifier(zed.get_camera_information().serial_number)
fusion.subscribe(uuid, configuration, sl.Transform(0, 0, 0))
```

Configure GNSS/VIO calibration parameters:

**C++:**
```cpp
sl::GNSSCalibrationParameters gnss_calibration_parameter;
gnss_calibration_parameter.enable_reinitialization = false;
gnss_calibration_parameter.enable_translation_uncertainty_target = false;
gnss_calibration_parameter.gnss_vio_reinit_threshold = 5;
gnss_calibration_parameter.target_yaw_uncertainty = 1e-2;
gnss_calibration_parameter.gnss_antenna_position = sl::float3(0,0,0);
```

**Python:**
```python
gnss_calibration_parameters = sl.GNSSCalibrationParameters()
gnss_calibration_parameters.target_yaw_uncertainty = 7e-3
gnss_calibration_parameters.enable_translation_uncertainty_target = False
gnss_calibration_parameters.target_translation_uncertainty = 15e-2
gnss_calibration_parameters.enable_reinitialization = False
gnss_calibration_parameters.gnss_vio_reinit_threshold = 5
```

Enable Fusion positional tracking:

**C++:**
```cpp
sl::PositionalTrackingFusionParameters positional_tracking_fusion_parameters;
positional_tracking_fusion_parameters.enable_GNSS_fusion = true;
positional_tracking_fusion_parameters.gnss_calibration_parameters = gnss_calibration_parameter;
sl::FUSION_ERROR_CODE tracking_error_code = fusion.enablePositionalTracking(
    positional_tracking_fusion_parameters);
```

**Python:**
```python
positional_tracking_fusion_parameters = sl.PositionalTrackingFusionParameters()
positional_tracking_fusion_parameters.enable_GNSS_fusion = True
positional_tracking_fusion_parameters.gnss_calibration_parameters = gnss_calibration_parameters
tracking_error_code = fusion.enable_positionnal_tracking(
    positional_tracking_fusion_parameters)
```

#### Retrieving Fused Data

Process data in a continuous loop:

**C++:**
```cpp
while (true) {
    sl::ERROR_CODE zed_status = zed.grab();
    
    sl::GNSSData input_gnss;
    sl::FUSION_ERROR_CODE ingest_error = fusion.ingestGNSSData(input_gnss);
    if (ingest_error != sl::FUSION_ERROR_CODE::SUCCESS) {
        std::cout << "Ingest error occurred when ingesting GNSSData: " 
                  << ingest_error << std::endl;
    }
    
    if (fusion.process() == sl::FUSION_ERROR_CODE::SUCCESS) {
        sl::Pose fused_position;
        sl::POSITIONAL_TRACKING_STATE current_state = fusion.getPosition(fused_position);
        
        float yaw_std;
        sl::float3 position_std;
        fusion.getCurrentGNSSCalibrationSTD(yaw_std, position_std);
        
        if (yaw_std != -1.f)
            std::cout << "GNSS State: calibration uncertainty yaw_std " 
                      << yaw_std << " rad position_std " << position_std[0] 
                      << " m, " << position_std[1] << " m, " 
                      << position_std[2] << " m\t\t\t\r";
        
        sl::GeoPose current_geopose;
        fusion.getGeoPose(current_geopose);
    }
}
```

**Python:**
```python
while(True):
    status = zed.grab()
    
    input_gnss = sl.GNSSData()
    ingest_error = fusion.ingest_gnss_data(input_gnss)
    if ingest_error != sl.FUSION_ERROR_CODE.SUCCESS and \
       ingest_error != sl.FUSION_ERROR_CODE.NO_NEW_DATA_AVAILABLE:
        print("Ingest error occurred when ingesting GNSSData: ", ingest_error)
    
    if fusion.process() == sl.FUSION_ERROR_CODE.SUCCESS:
        fused_position = sl.Pose()
        current_state = fusion.get_position(fused_position)
        
        print(calibration_std)
        
        current_geopose = sl.GeoPose()
        current_geopose_status = fusion.get_geo_pose(current_geopose)
```

### Complete Samples

Global localization samples are available in the GitHub repository allowing users to view live fused GNSS data, record sequences, and replay them for testing.

---

## Setting up GNSS / RTK on Linux

Source: https://www.stereolabs.com/docs/global-localization/using-gnss-linux/

### Overview

This guide covers configuring a GNSS/RTK module on Linux for use with the ZED SDK's Global Localization module. While focused on the ublox ZED F9P GNSS module, instructions apply to other GNSS modules as well.

### Installation

#### Using GPSD

The recommended approach uses `gpsd`, a service daemon that retrieves and parses GNSS data from multiple formats and provides APIs for easy access.

**Installation steps:**

```bash
# Install dependencies
sudo apt update && sudo apt install scons libgtk-3-dev

# Compile latest gpsd from source
git clone https://gitlab.com/gpsd/gpsd.git
cd gpsd && git checkout 8910c2b60759490ed98970dcdab8323b957edf48
sudo ./gpsinit vcan
scons && scons check && sudo scons udev-install

# Add Python path to .bashrc
echo 'export PYTHONPATH="$PYTHONPATH:/usr/local/lib/python3/dist-packages"' >> ~/.bashrc
```

**User permissions:**

```bash
sudo adduser $USER dialout
sudo adduser $USER tty
```

Log out or reboot for changes to take effect.

**Verify GNSS detection:**

```bash
ls /dev/tty*
```

You should see `/dev/ttyACM0` or `/dev/ttyUSB0` containing GNSS raw data.

**Test data retrieval:**

```bash
cat /dev/ttyACM0
```

#### Running GPSD

**Manual startup:**

```bash
gpsd -nG -s 115200 /dev/ttyACM0
```

**Automatic startup via cron:**

Add this line with `crontab -e`:

```
@reboot sleep 10 && /usr/local/sbin/gpsd -nG -s 115200 /dev/ttyACM0
```

**Test with graphical interface:**

```bash
xgps
```

### Enabling RTK on Your GNSS Module

RTK (Real-Time Kinematic) provides centimeter-level accuracy by using a network of reference stations and a rover receiver. This overcomes standard GNSS limitations like atmospheric disturbances and signal multipath.

#### Using NTRIP

GPSD can function as an NTRIP client to retrieve RTK corrections from a base station. Required information includes:

- **url**: NTRIP base station address
- **port**: NTRIP port
- **mountpoint**: Chosen mountpoint (base station should be within 25km of rover)
- **username**: Optional
- **password**: Optional

**Connect to NTRIP:**

```bash
pkill gpsd # Kill existing instance if running
gpsd -nG ntrip://<username>:<password>@<url>:<port>/<mountpoint> -s 115200 /dev/ttyACM0
```

Run `xgps` and wait for RTK fix. The ECEF pAcc value should show centimeter-level accuracy.

#### Persistent RTK Configuration

Update your cron job with:

```bash
crontab -e
```

Replace the gpsd line with:

```
@reboot sleep 10 && /usr/local/sbin/gpsd -nG ntrip://<username>:<password>@<url>:<port>/<mountpoint> -s 115200 /dev/ttyACM0
```

### Using GNSS in Applications

The ZED SDK provides Geotracking samples on GitHub for viewing live fused GNSS global data, recording sequences, and replaying them.

#### Python Implementation

Install the `gpsdclient` library:

```bash
pip install gpsdclient
```

**Basic usage example:**

```python
from gpsdclient import GPSDClient

# Get data as JSON strings
with GPSDClient(host="127.0.0.1") as client:
    for result in client.json_stream():
        print(result)

# Get data as Python dicts with optional datetime conversion
with GPSDClient() as client:
    for result in client.dict_stream(convert_datetime=True, filter=["TPV"]):
        print("Latitude: %s" % result.get("lat", "n/a"))
        print("Longitude: %s" % result.get("lon", "n/a"))

# Filter by report class
with GPSDClient() as client:
    for result in client.dict_stream(filter=["TPV", "SKY"]):
        print(result)
```

#### C++ Implementation

Install `libgpsmm`:

```bash
sudo apt install libgps-dev
```

**Basic usage example:**

```cpp
#include <libgpsmm.h>
#include <iostream>

int main() {
    gpsmm gps_data("localhost", DEFAULT_GPSD_PORT);

    if (gps_data.stream(WATCH_ENABLE | WATCH_JSON) == nullptr) {
        std::cerr << "Failed to open GPS connection." << std::endl;
        return 1;
    }

    while (true) {
        if (gps_data.waiting(500)) {
            if (gps_data.read() == nullptr) {
                std::cerr << "Error while reading GPS data." << std::endl;
            } else {
                std::cout << "Latitude: " << gps_data.fix->latitude 
                          << ", Longitude: " << gps_data.fix->longitude 
                          << std::endl;
            }
        }
    }

    gps_data.stream(WATCH_DISABLE);
    gps_data.close();

    return 0;
}
```

Full code examples are available in the Stereolabs GitHub repositories for both Global Localization and Geotracking samples.

---

## Data Synchronization

Source: https://www.stereolabs.com/docs/global-localization/data-synchronization/

### General Concept

Global localization requires fusing data from two sources: the ZED Camera and an external GNSS. Precise timing alignment between these data sources is crucial for successful fusion, a process called "data synchronization."

Two primary synchronization methods exist: hardware synchronization (where external signals trigger all sensors) and timestamp-based synchronization. Since not all sensors support hardware triggering, Stereolabs implements timestamp-based synchronization, which also works with hardware-synchronized sensors. The key requirement is that data acquired in close proximity should have similar timestamps.

#### Remote Data Acquisition Note

When acquiring data from remote computers, ensure proper clock synchronization. Ubuntu users can use tools like Chrony or PTP to achieve this. Without proper time synchronization, data from the same moment may have different timestamps, preventing effective data synchronization.

### How It Works

The synchronization process involves matching data with closely related timestamps within a "synchronization window." Small timestamp differences create small windows; larger differences create larger windows.

The synchronization window size is determined by the camera's declared FPS setting. For example:
- 30 FPS = 33 millisecond window
- 60 FPS = 16 millisecond window

Adjust the camera's desired FPS using the `camera_fps` attribute within `InitParameters`.

Data considered synchronized fall within the same synchronization window. Once synchronized, they're removed from the pipeline and returned to fusion. The synchronization cursor then advances to synchronize the next data set.

#### Data Drop Issue

In networked setups, data drops can occur from network problems. A timeout mechanism excludes camera sources that don't receive data within a defined timeframe (in milliseconds). Subsequently, timed-out sources are re-included once accessible again.

The synchronization timeout can be customized using the `timeout_period_number` attribute within the `InitFusionParameters` class.

---

## VIO GNSS Calibration

Source: https://www.stereolabs.com/docs/global-localization/vio-gnss-calibration/

### Overview

GNSS positions are globally referenced and always aligned to the North, while VIO reference and orientation depend on the camera's starting point.

### Key Calibration Parameters

Aligning VIO and GNSS systems requires determining four parameters:

- **Yaw rotation** (1 parameter) between coordinate systems
- **Translation** (3 parameters: X-Y-Z) between acquisition start points

### Coordinate System Model

The documentation describes transformation matrices using coordinate basis notation. Key relationships include:

- `Tab = inverse(A) x B` for coordinate system changes
- `Tb = inverse(Tab) x Ta x Tab` for transformation conversions

The calibration transformation `Tcalib` is retrieved via the `getGeoTrackingCalibration` method. Practical coordinate projections use:

- `T_VIO_projected_in_GNSS = T_calib x T_VIO x T_antenna`
- `T_GNSS_projected_in_VIO = inverse(T_calib) x T_GNSS x inverse(T_antenna)`

### Calibration Stop Criteria

The calibration process halts when a significant level of confidence in the `T_calib` transformation is obtained. Users can set:

- **Target yaw uncertainty** via `target_yaw_uncertainty` attribute
- **Target translation uncertainty** via `target_translation_uncertainty` attribute

By default, only yaw uncertainty is used unless `enable_translation_uncertainty_target` is set to true.

### Rolling Calibration Option

Applications requiring quick GeoPose estimation can enable `enable_rolling_calibration` to utilize initial calibration estimates before optimal accuracy is achieved.

### SDK Configuration Example

```cpp
sl::PositionalTrackingFusionParameters positional_tracking_fusion_parameters;
sl::GNSSCalibrationParameters gnss_calibration_parameter;
gnss_calibration_parameter.enable_reinitialization = false;
gnss_calibration_parameter.enable_translation_uncertainty_target = false;
gnss_calibration_parameter.gnss_vio_reinit_threshold = 5;
gnss_calibration_parameter.target_yaw_uncertainty = 1e-2;
gnss_calibration_parameter.gnss_antenna_position = sl::float3(0, 0, 0);
positional_tracking_fusion_parameters.gnss_calibration_parameters = gnss_calibration_parameter;
positional_tracking_fusion_parameters.enable_GNSS_fusion = true;
sl::FUSION_ERROR_CODE tracking_error_code = fusion.enablePositionalTracking(positional_tracking_fusion_parameters);
```

---

## Coordinate Systems

Source: https://www.stereolabs.com/docs/global-localization/global-localization-coordinate-frames/

### Three Coordinate System Formats

**Latitude/Longitude**: This geographic system specifies locations using angular positions relative to the equator and Greenwich. This is the default coordinate format used for GeoPose and is represented as the `LatLng` object in the SDK.

**ECEF (Earth-Centered Earth-Fixed)**: A three-dimensional Cartesian system with origin at Earth's center of mass. It allows for precise and accurate positioning calculations and is useful for satellite navigation and aerospace applications.

**UTM (Universal Transverse Mercator)**: Divides Earth into 60 zones spanning 6 degrees of longitude each. The system uses a metric grid, which presents coordinates as eastings and northings, and is popular in topographic mapping and surveying.

### Coordinate Conversion

The ZED SDK provides several ways to convert coordinates from one format to another using the functions available through the `GeoConverter` class. Refer to the API documentation for specific implementation details.

---

## Troubleshooting

Source: https://www.stereolabs.com/docs/global-localization/troubleshooting/

### Fusion Error Codes and Solutions

#### Fusion error code: `MODULE_NOT_ENABLED`

**Associated message:** "Positional tracking not enabled for the GeoTracking module. Did you call the `enablePositionalTracking` method on the `sl::Fusion` object?"

**What is happening?** VPS functions cannot be used without enabling the module. Please enable the module before attempting to call these functions.

**Solution:** Ensure that you call the `enablePositionalTracking` function on the `sl::Fusion` object, providing the necessary parameters, before proceeding with Global Localization functions.

#### Fusion error code: `INVALID_COVARIANCE`

**Associated message:** "You have ingested GNSS data with a very low covariance value (less than 1 millimeter)."

**What is happening?** The covariance value for `sl::GNSSData` ingested in the `ingestGNSSData` function is below the acceptable threshold of `1e-6`. The fusion automatically clamps the covariance to `1e-6`.

**Solution:** This is a warning message. Verify the covariance values of your GNSS data before ingestion to prevent this warning.

#### Fusion error code: `INVALID_TIMESTAMP`

**Associated message:** Could be one of:
- "You ingested GNSS data without timestamp (timestamp field set to 0)"
- "You ingested GNSS data with a timestamp far from the current timestamp"

**What is happening?** The fusion process synchronizes data from multiple ZED cameras and GNSS based on timestamps. This error occurs when:
- The ingested data timestamp equals zero (field not set)
- The ingested data timestamp is in the past
- The ingested data timestamp is far from the current synchronization cursor

**Solution:** Check your `sl::GNSSData` timestamp before ingesting it. The current synchronization cursor timestamp can be retrieved using the `getCurrentTimeStamp` method of `sl::Fusion`.

#### Fusion error code: `NO_NEW_DATA_AVAILABLE`

**What is happening?** The fusion data synchronization consumed all data from the camera and is waiting for new data. This usually happens when the fusion `process` method runs at a higher FPS than the `grab` method of the camera.

**Solution:** This is a warning message. Most of the time nothing is wrong. Once new data becomes available, the fusion `.process()` should return a `SUCCESS` error code. If no `SUCCESS` appears after several seconds, refer to synchronization documentation.

#### Fusion error code: `GNSS_DATA_NEED_FIX`

**Associated message:** "It seems that you did not fill the `gnss_status` attribute of your `GNSSData`."

**What is happening?** The field `gnss_status` attribute of your `GNSSData` is set to `sl::GNSS_STATUS::UNKNOWN`.

**Solution:** Set the `gnss_status` attribute for more accurate geo-tracking fusion, or set `gnss_status` to `SINGLE`. Fusion will still process data in degraded mode if not set.

#### Fusion error code: `GNSS_DATA_COVARIANCE_MUST_VARY`

**Associated message:** "You ingested GNSS data with the same covariance multiple times."

**What is happening?** More than fifteen `sl::GNSSData` entries with identical covariance values were ingested, suggesting possibly fixed "hand-crafted" covariance values.

**Solution:** This is a warning message. Fusion will still process data. To deactivate this message, set the environment variable:

```bash
export FUSION_SDK_DISABLE_GNSS_COVARIANCE_CHECK=1
```

#### Error code: `SENSORS_DATA_REQUIRED`

**Associated message:** "Positional Tracking GEN2 with IMU fusion enabled requires high frequency sensors data (available with Streaming version 2, with ZED SDK >=4.1)."

**What is happening?** Positional tracking GEN 2 needs high-frequency IMU data when `enable_imu_fusion` is activated. The provided input does not provide such information, possibly due to SVO gen 1 or streaming gen 1 format.

**Solution:** This is a fatal error. To resolve it, either upgrade to SVO/Streaming version 2, or deactivate IMU fusion by setting `enable_imu_fusion` to `false`.
