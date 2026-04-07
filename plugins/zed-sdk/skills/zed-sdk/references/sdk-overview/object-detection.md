---
description: >
  ZED SDK Object Detection documentation — 3D object detection overview,
  using the Object Detection API, and custom detector integration.
sources:
  - https://www.stereolabs.com/docs/object-detection/
  - https://www.stereolabs.com/docs/object-detection/using-object-detection/
  - https://www.stereolabs.com/docs/object-detection/custom-od/
fetched: 2026-04-07
---

# Object Detection

## Table of Contents

- [Object Detection Overview](#object-detection-overview)
- [Using the Object Detection API](#using-the-object-detection-api)
- [Custom Detector](#custom-detector)

---

## Object Detection Overview

Source: https://www.stereolabs.com/docs/object-detection/

### How It Works

The ZED SDK leverages AI and neural networks to identify objects in stereo images, then computes their 3D positions and bounding boxes using depth data. Objects can be tracked over time when positional tracking is enabled, maintaining consistent IDs even as the camera moves.

#### 3D Object Detection

The system detects all objects present in images and calculates their 3D position and velocity in metric units (measured from the camera's left eye). The SDK also computes a 2D mask showing which pixels belong to each detected object, enabling accurate 2D and 3D bounding box calculation via the depth map.

#### 3D Object Tracking

When positional tracking is active, the ZED SDK maintains object identity across frames, allowing visualization of object paths over time.

### Detection Outputs

Each detected object contains the following data:

| Object Data | Description | Output |
|---|---|---|
| **ID** | Fixed identifier for tracking objects over time | Integer |
| **Label** | Object type classification | Person, Vehicle |
| **Tracking state** | Current tracking status | Ok, Off, Searching, Terminate |
| **Action state** | Movement status | Idle, Moving |
| **Position** | 3D location relative to camera | [x, y, z] |
| **Velocity** | 3D movement vector | [vx, vy, vz] |
| **Dimensions** | Physical measurements | [width, height, length] |
| **Detection confidence** | Localization and label certainty | 0 - 100 |
| **2D bounding box** | Image-space box boundaries | Four pixel coordinates |
| **3D bounding box** | Space-based box boundaries | Eight 3D coordinates |
| **Mask** | Object vs. background pixel classification | Binary mask |

> **Important Note:** Currently, only specific object classes are detectable with the 3D Object Detection API (ZED cameras except ZED 1). For general detection, the PyTorch integration is recommended. Custom detectors have been supported since SDK 3.6.

---

## Using the Object Detection API

Source: https://www.stereolabs.com/docs/object-detection/using-object-detection/

### Object Detection Configuration

To configure the object detection module, use `ObjectDetectionParameters` at initialization and `ObjectDetectionRuntimeParameters` to change specific parameters during use.

**C++:**
```cpp
// Set initialization parameters
ObjectDetectionParameters detection_parameters;
detection_parameters.enable_tracking = true; // Objects will keep the same ID between frames
detection_parameters.enable_segmentation = true; // Outputs 2D masks over detected objects

// Set runtime parameters
ObjectDetectionRuntimeParameters detection_parameters_rt;
detection_parameters_rt.detection_confidence_threshold = 25;
```

**Python:**
```python
# Set initialization parameters
detection_parameters = sl.ObjectDetectionParameters()
detection_parameters.enable_tracking = True # Objects will keep the same ID between frames
detection_parameters.enable_segmentation = True # Outputs 2D masks over detected objects

# Set runtime parameters
detection_parameters_rt = sl.ObjectDetectionRuntimeParameters()
detection_parameters_rt.detection_confidence_threshold = 25
```

**C#:**
```csharp
// Set initialization parameters
ObjectDetectionParameters detection_parameters = new ObjectDetectionParameters();
detection_parameters.enableObjectTracking = true; // Objects will keep the same ID between frames
detection_parameters.enableSegmentation = true; // Outputs 2D masks over detected objects

// Set runtime parameters
ObjectDetectionRuntimeParameters detection_parameters_rt = new ObjectDetectionRuntimeParameters();
detection_parameters_rt.detectionConfidenceThreshold = 25;
```

### Available Detection Models

Various Object **Box** detection models are available in the ZED SDK:

- **General purpose detection models**: `OBJECT_DETECTION_MODEL::MULTI_CLASS_BOX`, `OBJECT_DETECTION_MODEL::MULTI_CLASS_BOX_MEDIUM`, and `OBJECT_DETECTION_MODEL::MULTI_CLASS_BOX_ACCURATE` - choose based on desired performance/accuracy trade-off. These detect multiple object classes.

- **Head detection model**: `OBJECT_DETECTION_MODEL::PERSON_HEAD_BOX` - specialized for person head detection and tracking, beneficial for crowded scenes. Detects only `OBJECT_CLASS::PERSON` with subclass `OBJECT_SUBCLASS::PERSON_HEAD`.

Set the detection model using `detection_parameters.detection_model`:

**C++:**
```cpp
// choose a detection model
detection_parameters.detection_model = OBJECT_DETECTION_MODEL::MULTI_CLASS_BOX;
```

**Python:**
```python
# choose a detection model
detection_parameters.detection_model = sl.OBJECT_DETECTION_MODEL.MULTI_CLASS_BOX
```

**C#:**
```csharp
// choose a detection model
detection_parameters.detectionModel = sl.OBJECT_DETECTION_MODEL.MULTI_CLASS_BOX;
```

### Object Tracking Configuration

To track objects' motion within their environment, first activate the positional tracking module, then set `detection_parameters.enable_tracking` to `true`.

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
if detection_parameters.enable_tracking :
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

### Enabling Object Detection

With parameters configured, enable the object detection module:

**C++:**
```cpp
// Enable object detection with initialization parameters
zed_error = zed.enableObjectDetection(detection_parameters);
if (zed_error != ERROR_CODE::SUCCESS) {
    cout << "enableObjectDetection: " << zed_error << "\nExit program.";
    zed.close();
    exit(-1);
}
```

**Python:**
```python
# Enable object detection with initialization parameters
zed_error = zed.enable_object_detection(detection_parameters)
if zed_error != sl.ERROR_CODE.SUCCESS:
    print("enable_object_detection", zed_error, "\nExit program.")
    zed.close()
    exit(-1)
```

**C#:**
```csharp
// Enable object detection with initialization parameters
zed_error = zedCamera.EnableObjectDetection(ref detection_parameters);
if (zed_error != ERROR_CODE.SUCCESS) {
    Console.WriteLine("enableObjectDetection: " + zed_error + "\nExit program.");
    zed.Close();
    Environment.Exit(-1);
}
```

> **Note**: Object Detection has been optimized for ZED 2/ZED 2i and uses the camera motion sensors for improved reliability.

### Getting Object Data

To get detected objects, use `grab(...)` to capture a new image and `retrieveObjects()` to extract detected objects. The objects' 2D positions are relative to the left image, while 3D positions are in either `CAMERA` or `WORLD` reference frame depending on `RuntimeParameters.measure3D_reference_frame`.

**C++:**
```cpp
sl::Objects objects; // Structure containing all the detected objects
if (zed.grab() == ERROR_CODE::SUCCESS) {
  zed.retrieveObjects(objects, detection_parameters_rt); // Retrieve the detected objects
}
```

**Python:**
```python
objects = sl.Objects() # Structure containing all the detected objects
if zed.grab() == sl.ERROR_CODE.SUCCESS:
  zed.retrieve_objects(objects, obj_runtime_param) # Retrieve the detected objects
```

**C#:**
```csharp
sl.Objects objects = new sl.Objects(); // Structure containing all the detected objects
RuntimeParameters runtimeParameters = new RuntimeParameters();
if (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
  zed.RetrieveObjects(ref objects, ref obj_runtime_param); // Retrieve the detected objects
}
```

The `sl::Objects` class stores all detected objects in the `object_list` attribute. Each object is stored as `sl::ObjectData` containing bounding box, position, mask, and other information. The `sl::Objects` class also contains the detection timestamp.

#### Iterating Through Objects

**C++:**
```cpp
for (auto object : objects.object_list)
  std::cout << object.id << " " << object.position << std::endl;
```

**Python:**
```python
for object in objects.object_list:
  print("{} {}".format(object.id, object.position))
```

**C#:**
```csharp
for (int idx = 0; idx < objects.numObject; idx++)
  Console.WriteLine(objects.objectData[idx].id + " " + objects.objectData[idx].position);
```

#### Accessing Individual Objects

**C++:**
```cpp
sl::ObjectData object;
objects.getObjectDataFromId(object, 0); // Get the object with ID = O
```

**Python:**
```python
object = sl.ObjectData()
objects.get_object_data_from_id(object, 0); # Get the object with ID = O
```

**C#:**
```csharp
sl.ObjectData objectData = new ObjectData();
objects.GetObjectDataFromId(ref objectData, 0); // Get the object with ID = O
```

### Accessing Object Information

Once retrieved, access object data such as ID, position, velocity, label, and tracking state:

**C++:**
```cpp
unsigned int object_id = object.id; // Get the object id
sl::float3 object_position = object.position; // Get the object position
sl::float3 object_velocity = object.velocity; // Get the object velocity
sl::OBJECT_TRACKING_STATE object_tracking_state = object.tracking_state; // Get the tracking state of the object
if (object_tracking_state == sl::OBJECT_TRACKING_STATE::OK) {
    cout << "Object " << object_id << " is tracked" << endl;
}
```

**Python:**
```python
object_id = object.id # Get the object id
object_position = object.position # Get the object position
object_velocity = object.velocity # Get the object velocity
object_tracking_state = object.tracking_state # Get the tracking state of the object
if object_tracking_state == sl.OBJECT_TRACKING_STATE.OK:
    print("Object {0} is tracked\n".format(object_id))
```

**C#:**
```csharp
uint object_id = object.id // Get the object id
Vector3 object_position = object.position // Get the object position
Vector3 object_velocity = object.velocity // Get the object velocity
OBJECT_TRACKING_STATE object_tracking_state = object.objectTrackingState; // Get the tracking state of the object
if (object_tracking_state == sl.OBJECT_TRACKING_STATE.OK) {
    Console.WriteLine("Object " + object_id + " is tracked");
}
```

### Detection Confidence Filtering

Access detection confidence for each object to post-filter results. For example, ignore objects with confidence less than 10%:

**C++:**
```cpp
for (auto object : objects.object_list) {
  if (object.confidence < 0.1f)
    continue;
  // Work with other objects
}
```

**Python:**
```python
for object in objects.object_list:
  if object.confidence < 0.1 :
    continue
  # Work with other objects
```

**C#:**
```csharp
for (int idx = 0; idx < objects.numObject; idx++) {
  if (objects.objectData[idx].confidence < 0.1f)
    continue;
  // Work with other objects
}
```

### Getting 3D Bounding Boxes

Each detected object contains both 2D and 3D bounding boxes. The 2D bounding box is defined in the image frame; the 3D bounding box includes depth information.

The 2D bounding box is represented as four 2D points starting from the top left corner. The 3D bounding box is represented by eight 3D points starting from the top left front corner.

**C++:**
```cpp
vector<sl::uint2> object_2Dbbox = object.bounding_box_2d; // Get the 2D bounding box of the object
vector<sl::float3> object_3Dbbox = object.bounding_box; // Get the 3D bounding box of the object
```

**Python:**
```python
object_2Dbbox = object.bounding_box_2d; # Get the 2D bounding box of the object
object_3Dbbox = object.bounding_box; # Get the 3D Bounding Box of the object
```

**C#:**
```csharp
Vector2[] object_2Dbbox = objects.objectData[idx].boundingBox2D; // Get the 2D bounding box of the object
Vector3[] object_3Dbbox = objects.objectData[idx].boundingBox; // Get the 3D bounding box of the object
```

### Getting the Object Mask

Each object is represented by a mask showing pixels belonging to the object within the 2D bounding box. Object pixels are set to 255; background pixels are set to 0. Access the mask using `sl::Mat object_mask = object.mask;`.

### Code Examples

For complete code examples, consult the [Tutorial](https://github.com/stereolabs/zed-examples/tree/master/tutorials) and [Sample](https://github.com/stereolabs/zed-examples/tree/master/object%20detection) on GitHub.

---

## Custom Detector

Source: https://www.stereolabs.com/docs/object-detection/custom-od/

### How It Works

You can implement your own bounding box detector and feed 2D detections into the ZED SDK. The SDK then computes 3D positions, 3D bounding boxes, and tracks objects using depth and positional tracking data.

#### 3D Object Detection and Tracking

The ZED SDK processes 2D bounding boxes from your detector to identify objects and calculate their 3D position and velocity. Distance is measured in metric units from the camera's left eye to the scene object.

The system generates a 2D mask indicating which pixels belong to detected objects, enabling accurate 3D bounding box computation using the depth map. With positional tracking enabled, objects maintain consistent IDs across frames even when the camera moves.

### Object Detection Steps

#### Training

State-of-the-art object detection algorithms can be trained on annotated datasets. The documentation references training a custom YOLOv5 model and selecting variants based on accuracy versus inference speed requirements.

#### Inference

Optimized inference samples support YOLOv5 models using TensorRT library, which is installed with the ZED SDK AI module. The system also supports YOLOv4 with OpenCV DNN module trained via darknet.

TensorRT provides built-in quantization to fp16/int8, offering optimal performance on smaller devices like NVIDIA Jetson. Models can be exported in ONNX format and used with TensorRT. Direct Python inference using PyTorch is also supported.

### Workflow

After each camera grab, send the image to your detector and ingest the bounding box results into the ZED SDK. Use `retrieveObjects` to access tracked 3D objects.

Detections must reference the left rectified image at native resolution and be rescaled if inference occurred at lower resolution.

#### Object Detection Configuration

Configure detection via `ObjectDetectionParameters` at initialization. Set `detection_model` to `CUSTOM_BOX_OBJECTS`:

**C++:**
```cpp
ObjectDetectionParameters detection_parameters;
detection_parameters.detection_model = OBJECT_DETECTION_MODEL::CUSTOM_BOX_OBJECTS;
detection_parameters.enable_tracking = true;
detection_parameters.enable_mask_output = true;
```

**Python:**
```python
detection_parameters = sl.ObjectDetectionParameters()
detection_parameters.detection_model = sl.OBJECT_DETECTION_MODEL.CUSTOM_BOX_OBJECTS
detection_parameters.enable_tracking = True
detection_parameters.enable_mask_output = True
```

**C#:**
```csharp
ObjectDetectionParameters detection_parameters = new ObjectDetectionParameters();
detection_parameters.detectionModel = sl.OBJECT_DETECTION_MODEL.CUSTOM_BOX_OBJECTS;
detection_parameters.enableObjectTracking = true;
detection_parameters.enable2DMask = true;
```

Enable positional tracking if object motion tracking is required:

**C++:**
```cpp
if (detection_parameters.enable_tracking) {
    PositionalTrackingParameters positional_tracking_parameters;
    zed.enablePositionalTracking(positional_tracking_parameters);
}
```

**Python:**
```python
if detection_parameters.enable_tracking:
    positional_tracking_parameters = sl.PositionalTrackingParameters()
    zed.enable_positional_tracking(positional_tracking_parameters)
```

**C#:**
```csharp
if (detection_parameters.enableObjectTracking) {
    PositionalTrackingParameters trackingParams = new PositionalTrackingParameters();
    zed.EnablePositionalTracking(ref trackingParams);
}
```

Enable the object detection module:

**C++:**
```cpp
zed_error = zed.enableObjectDetection(detection_parameters);
if (zed_error != ERROR_CODE::SUCCESS) {
    cout << "enableObjectDetection: " << zed_error << "\nExit program.";
    zed.close();
    exit(-1);
}
```

**Python:**
```python
zed_error = zed.enable_object_detection(detection_parameters)
if zed_error != sl.ERROR_CODE.SUCCESS :
    print("enable_object_detection", zed_error, "\nExit program.")
    zed.close()
    exit(-1)
```

**C#:**
```csharp
zed_error = zedCamera.EnableObjectDetection(ref detection_parameters);
if (zed_error != ERROR_CODE.SUCCESS) {
    Console.WriteLine("enableObjectDetection: " + zed_error + "\nExit program.");
    zed.Close();
    Environment.Exit(-1);
}
```

> **Note:** Object Detection requires ZED 2/ZED 2i/ZED Mini with sensors enabled.

#### Ingesting Custom Bounding Boxes

A 2D bounding box comprises four points starting from the top-left corner. The detector output must use the `CustomBoxObjectData` structure containing:

- `unique_object_id`: tracking identifier for the object
- `probability`: detector confidence score
- `label`: object class from your detector
- `bounding_box_2d`: 2D bounding box in native camera resolution

**C++:**
```cpp
std::vector<sl::CustomBoxObjectData> objects_in;
for (auto &it : detections) {
    sl::CustomBoxObjectData tmp;
    tmp.unique_object_id = sl::generate_unique_id();
    tmp.probability = it.conf;
    tmp.label = (int) it.class_id;
    tmp.bounding_box_2d = it.bounding_box;
    tmp.is_grounded = true;
    objects_in.push_back(tmp);
}
zed.ingestCustomBoxObjects(objects_in);
```

**Python:**
```python
objects_in = []
for it in detections:
    tmp = sl.CustomBoxObjectData()
    tmp.unique_object_id = sl.generate_unique_id()
    tmp.probability = it.conf
    tmp.label = (int) it.class_id
    tmp.bounding_box_2d = it.bounding_box
    tmp.is_grounded = True
    objects_in.append(tmp)
zed.ingest_custom_box_objects(objects_in)
```

**C#:**
```csharp
List<sl::CustomBoxObjectData> objects_in = new List<sl::CustomBoxObjectData>();
for (auto &it : detections) {
    sl::CustomBoxObjectData tmp;
    tmp.uniqueObjectId = sl.Camera.GenerateUniqueID();
    tmp.probability = it.conf;
    tmp.label = (int) it.class_id;
    tmp.boundingBox2D = it.bounding_box;
    tmp.is_grounded = true;
    objects_in.push_back(tmp);
}
zed.ingestCustomBoxObjects(objects_in);
```

#### Getting Object Data

3D positions can be referenced in different coordinate frames based on grab parameters. Retrieve tracked objects using:

**C++:**
```cpp
sl::Objects objects;
zed.retrieveObjects(objects, detection_parameters_rt);
```

**Python:**
```python
objects = sl.Objects()
zed.retrieve_objects(objects, obj_runtime_param)
```

**C#:**
```csharp
sl.Objects objects = new sl.Objects();
zed.RetrieveObjects(ref objects, ref obj_runtime_param);
```

The `sl::Objects` class stores all detected objects in its `object_list` attribute. Each `sl::ObjectData` contains bounding box, position, mask, and other information.

Iterate through objects:

**C++:**
```cpp
for(auto object : objects.object_list)
    std::cout << object.id << " " << object.position << std::endl;
```

**Python:**
```python
for object in objects.object_list:
    print("{} {}".format(object.id, object.position))
```

**C#:**
```csharp
for (int idx = 0; idx < objects.numObject; idx++)
    Console.WriteLine(objects.objectData[idx].id + " " + objects.objectData[idx].position);
```

#### Accessing Object Information

**C++:**
```cpp
unsigned int object_id = object.id;
int object_label = object.raw_label;
sl::float3 object_position = object.position;
sl::float3 object_velocity = object.velocity;
sl::OBJECT_TRACKING_STATE object_tracking_state = object.tracking_state;
if (object_tracking_state == sl::OBJECT_TRACKING_STATE::OK) {
    cout << "Object " << object_id << " is tracked" << endl;
}
```

**Python:**
```python
object_id = object.id
object_label = object.raw_label
object_position = object.position
object_velocity = object.velocity
object_tracking_state = object.tracking_state
if object_tracking_state == sl.OBJECT_TRACKING_STATE.OK:
    print("Object {0} is tracked\n".format(object_id))
```

**C#:**
```csharp
uint object_id = object.id;
int object_label = object.rawLabel;
Vector3 object_position = object.position;
Vector3 object_velocity = object.velocity;
OBJECT_TRACKING_STATE object_tracking_state = object.objectTrackingState;
if (object_tracking_state == sl.OBJECT_TRACKING_STATE.OK) {
    Console.WriteLine("Object " + object_id + " is tracked");
}
```

> **Note:** Use `raw_label` to access your custom detector's label values. The `label` field is reserved for the SDK's built-in Object Detection classes.

A 3D bounding box comprises eight 3D points starting from the top-left front corner. 3D bounding boxes and masks are accessible from the `ObjectData` structure.

### Code Example

For complete code examples, refer to the tutorials and samples available on GitHub.
