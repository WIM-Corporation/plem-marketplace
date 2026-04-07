---
description: >
  Consolidated reference for ZED SDK Sensors documentation.
  Covers sensors overview, IMU, magnetometer, barometer, temperature sensors,
  time synchronization, and the Sensors API usage.
  Source: https://www.stereolabs.com/docs/sensors/
---

# ZED SDK Sensors Reference

## Table of Contents

- [Sensors Overview](#sensors-overview)
  - [Sensor Availability](#sensor-availability)
  - [Getting Sensor Data](#getting-sensor-data)
  - [Sensor Capabilities](#sensor-capabilities)
- [IMU](#imu)
  - [Accelerometer](#accelerometer)
  - [Gyroscope](#gyroscope)
  - [IMU Output Data](#imu-output-data)
  - [IMU API Usage](#imu-api-usage)
  - [Pose](#pose)
- [Magnetometer](#magnetometer)
  - [Magnetometer Output Data](#magnetometer-output-data)
  - [Magnetometer API Usage](#magnetometer-api-usage)
  - [Magnetometer Calibration](#magnetometer-calibration)
- [Barometer](#barometer)
  - [Barometer Output Data](#barometer-output-data)
  - [Barometer API Usage](#barometer-api-usage)
- [Temperature Sensors](#temperature-sensors)
  - [Temperature Output Data](#temperature-output-data)
  - [Temperature API Usage](#temperature-api-usage)
  - [Temperature Drift Compensation](#use-the-sensor-to-compensate-for-temperature-drift)
- [Time Synchronization](#time-synchronization)
  - [Getting Time Synced Sensors Data](#getting-time-synced-sensors-data)
  - [Time Sync Reference](#time-sync-reference)
- [Using the Sensors API](#using-the-sensors-api)
  - [Getting Sensors Data](#getting-sensors-data-1)
  - [Retrieve New Sensor Data](#retrieve-new-sensor-data)
  - [Accessing Raw Sensor Data](#accessing-raw-sensor-data)
  - [Identifying Sensors Capabilities](#identifying-sensors-capabilities)

---

## Sensors Overview

> Source: https://www.stereolabs.com/docs/sensors/

The ZED family of depth cameras is a multi-sensor platform. The cameras have built-in sensors to add position and motion-assisted capabilities to your app, from accelerometer and gyroscope sensors to magnetometer, barometer, and temperature sensors.

### Sensor Availability

| Sensor | ZED X / ZED X Mini / ZED X One | ZED 2 / ZED 2i | ZED Mini | ZED |
|--------|--------------------------------|----------------|----------|-----|
| Accelerometer | Yes | Yes | Yes | No |
| Gyroscope | Yes | Yes | Yes | No |
| Magnetometer | No | Yes | No | No |
| Barometer | No | Yes | No | No |
| Temperature sensors | Yes | Yes | No | No |

> **Note**: ZED and earlier models are out of production.

### Getting Sensor Data

Access sensor information through the Sensors API. The following output data is available:

#### IMU (Accelerometer & Gyroscope)

| Output Data | Description | Units |
|---|---|---|
| linear_acceleration | Acceleration on x, y, z axes including gravity; bias, scale, and misalignment corrected | m/s2 |
| linear_acceleration_uncalibrated | Uncalibrated acceleration on all axes | m/s2 |
| linear_acceleration_covariance | Measurement noise of uncalibrated linear acceleration (3x3 matrix) | -- |
| angular_velocity | Rotation rate around x, y, z axes; corrected values | deg/s |
| angular_velocity_uncalibrated | Uncalibrated rotation rate | deg/s |
| angular_velocity_covariance | Measurement noise of uncalibrated angular velocity (3x3 matrix) | -- |
| pose | IMU position and orientation from sensor fusion (Transform) | -- |
| pose_covariance | Measurement noise of pose orientation (3x3 matrix) | -- |
| camera_imu_transform | Transform between IMU and left camera frames | -- |

#### Barometer

| Output Data | Description | Units |
|---|---|---|
| pressure | Ambient air pressure | hPa |
| relative_altitude | Altitude variation from initial camera position | meters |

#### Magnetometer

| Output Data | Description | Units |
|---|---|---|
| magnetic_field_uncalibrated | Uncalibrated geomagnetic field (x, y, z axes) | uT |

#### Temperature Sensors

| Output Data | Description | Units |
|---|---|---|
| temperature_map[ONBOARD_LEFT] | Temperature near left image sensor | degC |
| temperature_map[ONBOARD_RIGHT] | Temperature near right image sensor | degC |
| temperature_map[IMU] | IMU temperature | degC |
| temperature_map[BAROMETER] | Barometer temperature | degC |

### Sensor Capabilities

The Sensors API enables developers to perform various sensor-related tasks:

- Determine which sensors are present on specific devices
- Access individual sensor specifications (measurement range, resolution, noise characteristics)
- Retrieve calibrated or raw sensor data
- Obtain sensor hardware location, noise density, and bias parameters for visual-inertial fusion applications

For detailed implementation guidance, consult the [Using the API](#using-the-sensors-api) section.

---

## IMU

> Source: https://www.stereolabs.com/docs/sensors/imu/

### Accelerometer

The accelerometer detects the instantaneous acceleration of the camera. The data provided by the accelerometer determines whether the camera is getting faster or slower, in any direction, with a precise value in meters per second squared (m/s2).

When an accelerometer is static, it is still measuring an acceleration of 9.8m/s2 which corresponds to the force applied by the Earth's gravity. This force has always the same direction, from the camera to the center of the earth. The gravity allows us to compute the camera's absolute inclination and detect events like free falls.

### Gyroscope

A gyroscope measures the angular velocity of the camera in degrees per second (deg/s). When combined with the accelerometer, both sensors can estimate the orientation of the camera at a high frequency.

### IMU Output Data

| Output Data | Description | Units |
|---|---|---|
| **linear_acceleration** | Acceleration force applied on all three physical axes (x, y, and z), including the force of gravity. Values are corrected from bias, scale and misalignment. | m/s2 |
| **linear_acceleration_uncalibrated** | Acceleration force applied on all three physical axes (x, y, and z), including the force of gravity. Values are uncalibrated. | m/s2 |
| **linear_acceleration_covariance** | Measurement noise of the uncalibrated linear acceleration of the accelerometer. Provided as a 3x3 covariance matrix. | -- |
| **angular_velocity** | Rate of rotation around each of the three physical axes (x, y, and z). Values are corrected from bias, scale and misalignment. | deg/s |
| **angular_velocity_uncalibrated** | Rate of rotation around each of the three physical axes (x, y, and z). Values are uncalibrated. | deg/s |
| **angular_velocity_covariance** | Measurement noise of the uncalibrated angular velocity of the gyroscope. Provided as a 3x3 covariance matrix. | -- |
| **pose_covariance** | Measurement noise of the pose orientation. Provided as a 3x3 covariance matrix. | -- |
| **camera_imu_transform** | Transform between IMU and Left Camera frames. | -- |

### IMU API Usage

Accessing the IMU data can be done through the `SensorsData` class. Data is stored in the class `SensorsData::IMUData` which amongst others contains the accelerometer and gyroscope values.

#### C++

```cpp
SensorsData sensors_data;
SensorsData::IMUData imu_data;

// Grab new frames and retrieve sensors data
while (zed.grab() == ERROR_CODE::SUCCESS) {
  zed.getSensorsData(sensors_data, TIME_REFERENCE::IMAGE); // Retrieve only frame synchronized data

  // Extract IMU data
  imu_data = sensors_data.imu;

  // Retrieve linear acceleration and angular velocity
  float3 linear_acceleration = imu_data.linear_acceleration;
  float3 angular_velocity = imu_data.angular_velocity;
}
```

#### Python

```python
sensors_data = sl.SensorsData()

# Grab new frames and retrieve sensors data
while zed.grab() == sl.ERROR_CODE.SUCCESS :
  zed.get_sensors_data(sensors_data, sl.TIME_REFERENCE.IMAGE) # Retrieve only frame synchronized data

  # Extract IMU data
  imu_data = sensors_data.get_imu_data()

  # Retrieve linear acceleration and angular velocity
  linear_acceleration = imu_data.get_linear_acceleration()
  angular_velocity = imu_data.get_angular_velocity()
```

#### C#

```csharp
SensorsData sensors_data = new SensorsData();
IMUData imu_data = new IMUData();

RuntimeParameters runtimeParameters = new RuntimeParameters();
// Grab new frames and retrieve sensors data
while (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
  zed.GetSensorsData(ref sensors_data, TIME_REFERENCE.IMAGE); // Retrieve only frame synchronized data

  // Extract IMU data
  imu_data = sensors_data.imu;

  // Retrieve linear acceleration and angular velocity
  float3 linear_acceleration = imu_data.linearAcceleration;
  float3 angular_velocity = imu_data.angularVelocity;
}
```

### Pose

One of the key reasons for having an accelerometer and gyroscope in the camera is that their data can be fused to estimate camera orientation. The accelerometer provides gravity orientation, while the gyroscope estimates the rotation applied to the camera. Fused at high frequency, the combination of both sensors provides a robust orientation estimation.

IMU pose can be retrieved in `imu_data.pose`.

For a code example, check out the Getting Sensor Data tutorial.

---

## Magnetometer

> Source: https://www.stereolabs.com/docs/sensors/magnetometer/

The magnetometer measures the intensity of the magnetic field around the camera in microteslas (uT). The magnetometer determines the orientation of the Earth's magnetic field which gives the absolute orientation of the camera regarding the magnetic north pole.

### Magnetometer Output Data

| Output Data | Description | Units |
|---|---|---|
| `magnetic_field_uncalibrated` | Ambient geomagnetic field (x, y, z axes), uncalibrated values | uT |
| `magnetic_field_calibrated` | Ambient geomagnetic field (x, y, z axes), calibrated values | uT |
| `magnetic_heading` | Camera heading relative to magnetic North Pole | deg |
| `magnetic_heading_state` | Reliability indicator for magnetic heading data | HEADING_STATE |
| `magnetic_heading_accuracy` | Heading measurement accuracy in range [0.0, 1.0] | -- |
| `timestamp` | Data measurement recording timestamp | ns |
| `effective_rate` | Real-time data acquisition rate | Hz |

### Magnetometer API Usage

Magnetometer values are stored in `SensorData::MagnetometerData`, accessible through:

#### C++

```cpp
SensorsData sensors_data;
SensorsData::MagnetometerData magnetometer_data;

// Grab new frames and retrieve sensors data
while (zed.grab() == ERROR_CODE::SUCCESS) {
  zed.getSensorsData(sensors_data, TIME_REFERENCE::IMAGE);

  // Extract magnetometer data
  magnetometer_data = sensors_data.magnetometer;

  // Retrieve uncalibrated magnetic field
  float3 magnetic_field = magnetometer_data.magnetic_field_uncalibrated;

  // Retrieve calibrated magnetic field
  float3 magnetic_field = magnetometer_data.magnetic_field_calibrated;
}
```

#### Python

```python
sensors_data = sl.SensorsData()
magnetometer_data = sl.SensorsData.MagnetometerData()

# Grab new frames and retrieve sensors data
while zed.grab() == sl.ERROR_CODE.SUCCESS :
  zed.get_sensors_data(sensors_data, sl.TIME_REFERENCE.IMAGE)

  # Extract magnetometer data
  magnetometer_data = sensors_data.get_magnetometer_data()

  # Retrieve uncalibrated magnetic field
  magnetic_field = magnetometer_data.get_magnetic_field_uncalibrated();

  # Retrieve calibrated magnetic field
  magnetic_field = magnetometer_data.get_magnetic_field_calibrated();
```

#### C#

```csharp
SensorsData sensors_data = new SensorsData();
MagnetometerData magnetometer_data = new MagnetometerData();

RuntimeParameters runtimeParameters = new RuntimeParameters();
while (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
  zed.GetSensorsData(sensors_data, TIME_REFERENCE.IMAGE);

  // Extract magnetometer data
  magnetometer_data = sensors_data.magnetometer;

  // Retrieve uncalibrated magnetic field
  float3 magnetic_field = magnetometer_data.magnetic_field_uncalibrated;

  // Retrieve calibrated magnetic field
  float3 magnetic_field = magnetometer_data.magnetic_field_calibrated;
}
```

> **Note**: Values in `magnetic_field_calibrated` differ from `magnetic_field_uncalibrated` only when the magnetometer has undergone calibration as described below.

For a code example, check out the [Getting Sensor Data](https://www.stereolabs.com/docs/tutorials/using-sensors/) tutorial.

### Magnetometer Calibration

Unlike other sensors, the magnetometer cannot be factory-calibrated. Earth's magnetic field (approximately 35-65 uT) is extremely weak, making sensor readings highly susceptible to environmental interference. Metal cases, power cables, motors, speakers, and ferromagnetic objects create significant magnetic disturbance affecting measurements.

For reliable operation, calibrate the magnetometer **after** the camera reaches its final installation location. Accurate calibration requires rotating the camera through all spatial directions to acquire field information from every orientation.

Once calibrated, the magnetometer functions as a 3D compass to determine magnetic north direction (heading/yaw).

#### Calibration Types

**Hard iron calibration** generates offset parameters compensating for active magnetic materials near the sensor.

**Soft iron calibration** generates rescaling factors compensating for non-magnetic metal objects that distort the field. This ensures uniform magnetic field intensity along three primary axes.

> **Note**: Calibration does not guarantee permanent accuracy; recalibration is necessary over time to compensate for local magnetic field variations.

Use the **ZED Sensor Viewer** application to perform tri-axis magnetometer calibration: select the Magnetometer sensor and click "Calibrate Magnetometer."

#### Calibration Process

Press **START CALIBRATION** to begin. The **CLEAR DATA** button restarts the process, erasing acquired data.

**Step 1. Initialize the XY Plane**

Perform a series of **roll rotations**, drawing a complete red circumference to fit the red ellipsoid background.

**Step 2. Initialize the YZ Plane**

Perform a series of **pitch rotations**, drawing a complete green circumference to fit the green ellipsoid background.

**Step 3. Initialize the XZ Plane**

Perform a series of **yaw rotations**, drawing a complete blue circumference to fit the blue ellipsoid background.

**Step 4. Perform Full Calibration**

Execute **mixed rotations** attempting all possible roll, pitch, and yaw combinations. The objective is filling maximum area within the three ellipsoids across XY, YZ, and XZ planes.

**Step 5. Stop and Verify Results**

When three ellipsoids are adequately filled, press **STOP CALIBRATION**. Verify calibration reliability by checking:

- The calibrated values for three planes are perfectly overlapped in the "Calibrated data" chart
- They fit (with minor outliers) the unitary ellipsoid displayed in the background

Two compasses appear on the interface: the red compass displays heading calculated using uncalibrated field values; the blue compass shows heading using calibrated values. Position the camera horizontally and rotate around the vertical axis. If calibration is successful, the blue compass displays correct camera orientation regarding the Magnetic North Pole. Verification with a standard compass is possible.

> **Note**: The North Magnetic Pole does not correspond to geographical coordinates and varies by latitude. Do not use digital smartphone compasses (which compensate using GPS) for comparison.

**Step 6. Save Calibration Parameters**

Store calibration parameters in camera non-volatile memory by pressing **STORE CALIBRATION**.

Reset magnetometer calibration to default values anytime using the **RESET CALIBRATION** button.

> **Note**: The reset process is irreversible and erases current calibration.

**Step 7. Close Dialog**

Exit the calibration dialog to return to the main Sensor Viewer. Reselect the Magnetometer sensor and confirm the display shows "Magnetometer [Calibrated]."

---

## Barometer

> Source: https://www.stereolabs.com/docs/sensors/barometer/

The barometer measures the ambient air pressure around the camera in hectopascals (hPa). As the ambient air pressure decreases with the altitude, the barometer can be used to measure the altitude variation of the camera from its initial position.

> **Important**: Weather conditions affect air pressure, making absolute altitude measurement from sea level impossible. Only relative altitude variations should be relied upon.

### Barometer Output Data

| Output Data | Description | Units |
|---|---|---|
| pressure | Ambient air pressure | hPa |
| relative_altitude | Altitude variation from initial camera position | meters |

### Barometer API Usage

#### C++

```cpp
SensorsData sensors_data;
SensorsData::BarometerData barometer_data;

// Grab new frames and retrieve sensors data
while (zed.grab() == ERROR_CODE::SUCCESS) {
  zed.getSensorsData(sensors_data, TIME_REFERENCE::IMAGE);

  // Extract barometer data
  barometer_data = sensors_data.barometer;

  // Retrieve pressure and relative altitude
  float pressure = barometer_data.pressure;
  float relative_altitude = barometer_data.relative_altitude;
}
```

#### Python

```python
sensors_data = sl.SensorsData()
barometer_data = sl.SensorsData.BarometerData()

# Grab new frames and retrieve sensors data
while zed.grab() == sl.ERROR_CODE.SUCCESS :
  zed.get_sensors_data(sensors_data, sl.TIME_REFERENCE.IMAGE)

  # Extract barometer data
  barometer_data = sensors_data.get_barometer_data()

  # Retrieve pressure and relative altitude
  pressure = barometer_data.pressure
  relative_altitude = barometer_data.relative_altitude
```

#### C#

```csharp
SensorsData sensors_data = new SensorsData();
BarometerData barometer_data = new BarometerData();

RuntimeParameters runtimeParameters = new RuntimeParameters();
// Grab new frames and retrieve sensors data
while (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
  zed.GetSensorsData(ref sensors_data, TIME_REFERENCE.IMAGE);

  // Extract barometer data
  barometer_data = sensors_data.barometer;

  // Retrieve pressure and relative altitude
  float pressure = barometer_data.pressure;
  float relative_altitude = barometer_data.relativeAltitude;
}
```

For a complete working example, refer to the Getting Sensor Data tutorial.

---

## Temperature Sensors

> Source: https://www.stereolabs.com/docs/sensors/temperature/

According to the model of the ZED Camera you are using, you can access different temperature information from sensors located in various areas of the PCB. These sensors monitor the thermal state of the camera and can be used to adjust calibration parameters as needed.

> **Note**: The ZED Mini camera does not include onboard temperature sensors.

### Temperature Output Data

| Output Data | Description | Units | Max Frequency | Note |
|---|---|---|---|---|
| Left Image Sensor | Temperature measured by the onboard sensor next to the Left Image Sensor | degC | 25 Hz | Only ZED 2i |
| Right Image Sensor | Temperature measured by the onboard sensor next to the Right Image Sensor | degC | 25 Hz | Only ZED 2i |
| IMU | Temperature measured by the sensor inside the IMU | degC | 400 Hz | -- |
| BAROMETER | Temperature measured by the sensor inside the Barometer | degC | 50 Hz | Only ZED 2i |

### Temperature API Usage

#### C++

```cpp
SensorsData::TemperatureData temperature_data;
temperature_data = sensor_data.temperature;
float temperature_left, temperature_right, temperature_imu, temperature_barometer;
temperature_data.get(SensorsData::TemperatureData::SENSOR_LOCATION::ONBOARD_LEFT, temperature_left);
temperature_data.get(SensorsData::TemperatureData::SENSOR_LOCATION::ONBOARD_RIGHT, temperature_right);
temperature_data.get(SensorsData::TemperatureData::SENSOR_LOCATION::IMU, temperature_imu);
temperature_data.get(SensorsData::TemperatureData::SENSOR_LOCATION::BAROMETER, temperature_barometer);
```

#### Python

```python
temperature_data = sensors_data.get_temperature_data()
temperature_left = temperature_data.get(sl.SENSOR_LOCATION.ONBOARD_LEFT)
temperature_right = temperature_data.get(sl.SENSOR_LOCATION.ONBOARD_RIGHT)
temperature_imu = temperature_data.get(sl.SENSOR_LOCATION.IMU)
temperature_barometer = temperature_data.get(sl.SENSOR_LOCATION.BAROMETER)
```

#### C#

```csharp
TemperatureData temperature_data = new TemperatureData();
temperature_data = sensor_data.get_temperature_data();
float temperature_left, temperature_right, temperature_imu, temperature_barometer;
temperature_left = sensors_data.temperatureSensor.onboard_left_temp;
temperature_right = sensors_data.temperatureSensor.onboard_right_temp;
temperature_imu = sensor_data.temperatureSensor.imu_temp;
temperature_barometer = sensor_data.temperatureSensor.barometer_temp;
```

> **Note**: If a temperature sensor is unavailable, a **NaN** value is returned.

### Use the Sensor to Compensate for Temperature Drift

> **Note**: This guide does not apply to the ZED Mini model, which lacks onboard temperature sensors.

The SDK performs an initial self-calibration procedure to compensate for minor optical changes caused by temperature variations or vibrations that could affect stereo calibration accuracy.

During extended operation, internal temperature changes may occur, requiring a new self-calibration to maintain accurate stereo calibration. Monitor internal temperature using the temperature sensor and trigger a new self-calibration by calling `updateSelfCalibration` when needed.

#### C++

```cpp
// Global variables
sl::Camera zed;
float ref_temp = -273.15f;
bool temp_ref_udpated=false;
const float TEMP_THRESHOLD = 10.0f;

[...]

// Check the temperature periodically (i.e. each 5 minutes)
sl::SensorsData sensors_data;
zed.getSensorsData(sensors_data);
temp_ref_udpated = temperature_changed(sensors_data);
if(temp_ref_udpated) {
    zed.updateSelfCalibration();
}

[...]

// This is the function to control if the temperature changed with respect to a reference point
bool temperature_changed(const SensorsData& sensors_data) {
    float curr_temp;
    auto temperature_data = sensors_data.temperature;

    // Read the current internal temperature from the IMU sensor.
    temperature_data.get(sl::SensorsData::TemperatureData::SENSOR_LOCATION::IMU, curr_temp);

    if(fabs(curr_temp - ref_temp) > TEMP_THRESHOLD) {
        ref_temp = curr_temp;
        return true;
    }
    return false;
}
```

#### Python

```python
zed = sl.Camera()
ref_temp = -273.15
temp_ref_updated = False
TEMP_THRESHOLD = 10.0

[...]

# Check the temperature periodically (i.e. each 5 minutes)
sensors_data = sl.SensorsData()
zed.get_sensors_data(sensors_data, sl.TIME_REFERENCE.CURRENT)
temp_ref_updated = temperature_changed(sensors_data)
if temp_ref_updated:
  zed.update_self_calibration()

[...]

def temperature_changed(sensor_data):
  temperature_data = sensor_data.get_temperature_data()
  curr_temp = temperature_data.get(sl.SENSOR_LOCATION.IMU)
  if abs(curr_temp - ref_temp > TEMP_THRESHOLD) > 0:
    ref_temp = curr_temp
    return True
  return False
```

#### C#

```csharp
sl.Camera zed = new sl.Camera(0);
float refTemp = -273.15f;
bool tempRefUpdated = false;
float TEMP_THRESHOLD = 10.0f;

[...]

// Check the temperature periodically (i.e. each 5 minutes)
sl.SensorsData sensorsData = new sl.SensorsData();
zed.GetSensorsData(ref sensorsData, TIME_REFERENCE.CURRENT);
tempRefUpdated = TemperatureChanged(ref sensorsData);
if (tempRefUpdated)
{
  zed.UpdateSelfCalibration();
}

[...]

// This is the function to control if the temperature changed with respect to a reference point
bool TemperatureChanged(ref SensorsData sensorsData)
{
  var temperatureData = sensorsData.temperatureSensor;
  float currTemp = temperatureData.imu_temp;
  if (Math.Abs(currTemp - refTemp) > TEMP_THRESHOLD)
  {
    refTemp = currTemp;
    return true;
  }
  return false;
}
```

> **Warning**: If your code uses intrinsic and extrinsic camera parameters internally, ensure you use the `temp_ref_udpated` variable and update parameters after the next `grab` using `getCameraInformation`.

---

## Time Synchronization

> Source: https://www.stereolabs.com/docs/sensors/time-synchronization/

Accurate time synchronization is required for reliable integration of data from multiple sensor sources. The ZED cameras and sensors share a common and low-drift reference clock. Incoming packets are timestamped on the host machine in Epoch time with nanosecond resolution.

These synchronized timestamps enable two primary use cases:

- Integrating multi-sensor data from a single camera (like IMU with stereo images)
- Fusing data with external sensors such as GPS or LiDAR

### Getting Time Synced Sensors Data

Sensor data retrieval uses the function `getSensorsData(sensors_data, TIME_REFERENCE)`. The `sensors_data` structure stores information from various sensors, while the `TIME_REFERENCE` variable determines synchronization behavior.

### Time Sync Reference

Since camera sensors operate at different frequencies -- for example, the ZED 2's IMU runs at 400Hz while images cap at 100Hz -- the SDK provides two `TIME_REFERENCE` options:

**TIME_REFERENCE::CURRENT** retrieves the most recent available sensor data regardless of image frame timing.

**TIME_REFERENCE::IMAGE** retrieves sensor data closest to the last captured image frame.

For implementation details on retrieving current or image-synchronized sensor data, see the [Using the Sensors API](#using-the-sensors-api) section.

---

## Using the Sensors API

> Source: https://www.stereolabs.com/docs/sensors/using-sensors/

The Sensors API lets you access sensors available on ZED depth cameras and perform a wide variety of sensor-related tasks explained below.

### Getting Sensors Data

To retrieve sensor values synchronized with image frames, follow these steps:

1. Open the camera and grab the current image
2. Get sensor data corresponding to this image using `TIME_REFERENCE::IMAGE`
3. Retrieve data from the different sensors

#### C++

```cpp
// Create and open the camera
Camera zed;
zed.open();
SensorsData sensors_data;

// Grab new frames and retrieve sensors data
while (zed.grab() == ERROR_CODE::SUCCESS) {
    zed.getSensorsData(sensors_data, TIME_REFERENCE::IMAGE);

    // Extract multi-sensor data
    imu_data = sensors_data.imu;
    barometer_data = sensors_data.barometer;
    magnetometer_data = sensors_data.magnetometer;

    // Retrieve linear acceleration and angular velocity
    float3 linear_acceleration = imu_data.linear_acceleration;
    float3 angular_velocity = imu_data.angular_velocity;

    // Retrieve pressure and relative altitude
    float pressure = barometer_data.pressure;
    float relative_altitude = barometer_data.relative_altitude;

    // Retrieve magnetic field
    float3 magnetic_field = magnetometer_data.magnetic_field_uncalibrated;
}
```

#### Python

```python
# Create and open the camera
zed = sl.Camera()
zed.open()
sensors_data = sl.SensorsData()

# Grab new frames and retrieve sensors data
while zed.grab() == sl.ERROR_CODE.SUCCESS :
  zed.get_sensors_data(sensors_data, sl.TIME_REFERENCE.IMAGE)

  # Extract multi-sensor data
  imu_data = sensors_data.get_imu_data()
  barometer_data = sensors_data.get_barometer_data()
  magnetometer_data = sensors_data.get_magnetometer_data()

  # Retrieve linear acceleration and angular velocity
  linear_acceleration = imu_data.get_linear_acceleration()
  angular_velocity = imu_data.get_angular_velocity()

  # Retrieve pressure and relative altitude
  pressure = barometer_data.pressure
  relative_altitude = barometer_data.relative_altitude

  # Retrieve magnetic field
  magnetic_field = magnetometer_data.get_magnetic_field_uncalibrated()
```

#### C#

```csharp
// Create and open the camera
Camera zed = new Camera();
InitParameters init_parameters = new InitParameters();
zed.Open(ref init_parameters);
SensorsData sensors_data = new SensorsData();

RuntimeParameters runtimeParameters = new RuntimeParameters();
// Grab new frames and retrieve sensors data
while (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
    zed.GetSensorsData(ref sensors_data, TIME_REFERENCE.IMAGE);

    // Extract multi-sensor data
    imu_data = sensors_data.imu;
    barometer_data = sensors_data.barometer;
    magnetometer_data = sensors_data.magnetometer;

    // Retrieve linear acceleration and angular velocity
    float3 linear_acceleration = imu_data.linearAcceleration;
    float3 angular_velocity = imu_data.angularVelocity;

    // Retrieve pressure and relative altitude
    float pressure = barometer_data.pressure;
    float relative_altitude = barometer_data.relativeAltitude;

    // Retrieve magnetic field
    float3 magnetic_field = magnetometer_data.magneticFieldUncalibrated;
}
```

#### Time Reference

The `getSensorsData` function accepts a `TIME_REFERENCE` parameter. Options include `TIME_REFERENCE::CURRENT` to get sensor data at function call time, or `TIME_REFERENCE::IMAGE` to synchronize data with the current camera image. Consult the [Time Synchronization](#time-synchronization) section for additional details.

### Retrieve New Sensor Data

To retrieve updated sensor data, `getSensorsData` must be called at a frequency superior to or equal to the sensor data rate.

To verify whether sensor data has been updated, compare timestamps between successive calls. Matching timestamps indicate the data hasn't refreshed.

#### C++

```cpp
Timestamp last_imu_ts = 0;
while (zed.grab() == ERROR_CODE::SUCCESS) {
    zed.getSensorsData(sensors_data, TIME_REFERENCE::IMAGE);

    // Check if a new IMU sample is available
    if (sensors_data.imu.timestamp > last_imu_ts) {
        cout << "Linear Acceleration: " << sensors_data.imu.linear_acceleration << endl;
        cout << "Angular Velocity: " << sensors_data.imu.angular_velocity << endl;
        last_imu_ts = sensors_data.imu.timestamp;
    }
}
```

#### Python

```python
last_imu_ts = sl.Timestamp()
while zed.grab() == sl.ERROR_CODE.SUCCESS:
    zed.get_sensors_data(sensors_data, sl.TIME_REFERENCE.IMAGE)

    # Check if a new IMU sample is available
    if sensors_data.get_imu_data().timestamp.get_seconds() > last_imu_ts.get_seconds():
        print("Linear Acceleration: {}".format(sensors_data.get_imu_data().get_linear_acceleration()))
        print("Angular Velocity : {}".format(sensors_data.get_imu_data().get_angular_velocity()))
        last_imu_ts = sensors_data.get_imu_data().timestamp
```

#### C#

```csharp
ulong last_imu_ts = 0;
RuntimeParameters runtimeParameters = new RuntimeParameters();

while (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
    zed.GetSensorsData(sensors_data, TIME_REFERENCE.IMAGE);

    // Check if a new IMU sample is available
    if (sensors_data.imu.timestamp > last_imu_ts) {
        Console.WriteLine("Linear Acceleration: " + sensors_data.imu.linearAcceleration);
        Console.WriteLine("Angular Velocity: " + sensors_data.imu.angularVelocity);
        last_imu_ts = sensors_data.imu.timestamp;
    }
}
```

### Accessing Raw Sensor Data

The Sensors API lets you read raw data from the depth camera's built-in motion and position sensors. Access uncalibrated values in the `sensors_data` structure to retrieve raw measurement information.

### Identifying Sensors Capabilities

Sensors factory parameters are accessible through the API but cannot be modified, as they are fixed in camera microcontroller firmware. Available parameters include:

- Sensor Type
- Sampling Rate
- Range
- Resolution
- Noise Density
- Random Walk (if applicable)
- Sensor Units

#### C++

```cpp
// Display camera information (model, serial number, firmware version)
auto info = zed.getCameraInformation();
cout << "Camera Model: " << info.camera_model << endl;
cout << "Serial Number: " << info.serial_number << endl;
cout << "Camera Firmware: " << info.camera_configuration.firmware_version << endl;
cout << "Sensors Firmware: " << info.sensors_configuration.firmware_version << endl;

// Display accelerometer sensor configuration
SensorParameters& sensor_parameters = info.sensors_configuration.accelerometer_parameters;
cout << "Sensor Type: " << sensor_parameters.type << endl;
cout << "Sampling Rate: " << sensor_parameters.sampling_rate << endl;
cout << "Range: " << sensor_parameters.range << endl;
cout << "Resolution: " << sensor_parameters.resolution << endl;
if (isfinite(sensor_parameters.noise_density)) cout << "Noise Density: " << sensor_parameters.noise_density << endl;
if (isfinite(sensor_parameters.random_walk)) cout << "Random Walk: " << sensor_parameters.random_walk << endl;
```

#### Python

```python
# Display camera information (model, serial number, firmware version)
info = zed.get_camera_information()
print("Camera model: {}".format(info.camera_model))
print("Serial Number: {}".format(info.serial_number))
print("Camera Firmware: {}".format(info.camera_configuration.firmware_version))
print("Sensors Firmware: {}".format(info.sensors_configuration.firmware_version))

# Display accelerometer sensor configuration
sensor_parameters = info.sensors_configuration.accelerometer_parameters
print("Sensor Type: {}".format(sensor_parameters.sensor_type))
print("Sampling Rate: {}".format(sensor_parameters.sampling_rate))
print("Range: {}".format(sensor_parameters.sensor_range))
print("Resolution: {}".format(sensor_parameters.resolution))

import math
if math.isfinite(sensor_parameters.noise_density):
    print("Noise Density: {}".format(sensor_parameters.noise_density))
if math.isfinite(sensor_parameters.random_walk):
    print("Random Walk: {}".format(sensor_parameters.random_walk))
```

#### C#

```csharp
// Display camera information (model, serial number, firmware version)
Console.WriteLine("Camera Model: " + zed.GetCameraModel());
Console.WriteLine("Serial Number: " + zed.GetZEDSerialNumber());
Console.WriteLine("Camera Firmware: " + zed.GetCameraFirmwareVersion());
Console.WriteLine("Sensors Firmware: " + zed.GetSensorsFirmwareVersion());

// Display accelerometer sensor configuration
SensorParameters sensorParams = new SensorParameters();
sensorParams = zed.GetSensorsConfiguration().accelerometer_parameters;
Console.WriteLine("Sensor type: " + sensorParams.type);
Console.WriteLine("Sampling Rate: " + sensorParams.sampling_rate);
Console.WriteLine("Range:" + sensorParams.range.x + " / " + sensorParams.range.y);
Console.WriteLine("Resolution: " + sensorParams.resolution);
if (!float.IsInfinity(sensorParams.noise_density)) Console.WriteLine("Noise Density: " + sensorParams.noise_density);
if (!float.IsInfinity(sensorParams.random_walk)) Console.WriteLine("Random Walk: " + sensorParams.random_walk);
```

For a complete working example, refer to the Getting Sensor Data tutorial.
