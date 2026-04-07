---
description: >
  ZED SDK Spatial Mapping documentation — spatial mapping overview,
  using the Spatial Mapping API, and plane detection.
sources:
  - https://www.stereolabs.com/docs/spatial-mapping/
  - https://www.stereolabs.com/docs/spatial-mapping/using-mapping/
  - https://www.stereolabs.com/docs/spatial-mapping/plane-detection/
fetched: 2026-04-07
---

# Spatial Mapping

## Table of Contents

- [Spatial Mapping Overview](#spatial-mapping-overview)
- [Using the Spatial Mapping API](#using-the-spatial-mapping-api)
- [Plane Detection](#plane-detection)

---

## Spatial Mapping Overview

Source: https://www.stereolabs.com/docs/spatial-mapping/

### Overview

Spatial mapping, also called 3D reconstruction, enables devices to create digital models of physical environments. This capability supports collision avoidance, motion planning, and realistic blending of real and virtual worlds.

### How It Works

The ZED camera continuously scans its surroundings to build a 3D environmental model. As the device moves, it refines this understanding by integrating new depth and positional data over time. The system can quickly reconstruct large indoor and outdoor areas because the camera perceives distances beyond traditional RGB-D sensor ranges.

Mapping data is saved relative to a fixed World Frame reference coordinate system. When Area Memory is enabled with a provided Area file during initialization, maps can be loaded across sessions while maintaining their physical location.

### Capturing a Spatial Map

Spatial maps represent real-world geometry as either a Mesh or Fused Point Cloud structure.

#### Mesh

A mesh represents scene geometry through surfaces -- specifically, a set of watertight triangles defined by vertices and faces. These surfaces can be filtered and textured after scanning.

#### Fused Point Cloud

A point cloud represents geometry using a set of colored 3D points distributed throughout the scene.

### Spatial Mapping Parameters

Resolution and range can be adjusted during initialization for both map types. Mesh texturing is an optional feature (disabled by default).

#### Mapping Resolution

Resolution controls the detail level of the spatial map, ranging from 1cm to 12cm. Higher resolution yields more detailed maps but requires more memory and computational resources. Users should select the lowest density suitable for their application.

#### Mapping Range

Range determines which depth data builds the spatial map, spanning 2m to 20m. Greater range captures larger volumes quickly but sacrifices accuracy. Reducing range improves performance.

#### Mesh Filtering

Filtering reduces polygon count after capture to improve performance. Three presets exist: HIGH, MEDIUM, and LOW. The LOW mode fills holes and removes outliers, while others perform mesh decimation.

#### Mesh Texturing

The SDK can project 2D captured images onto 3D model surfaces. During mapping, the system records left camera images, processes them, and assembles them into a single texture map, then projects this onto mesh faces using automatically generated UV coordinates.

---

## Using the Spatial Mapping API

Source: https://www.stereolabs.com/docs/spatial-mapping/using-mapping/

### Spatial Mapping Configuration

Configuration setup resembles other SDK modules. Use `InitParameters` to establish video mode, coordinate system, and measurement units.

**C++:**
```cpp
// Set configuration parameters
InitParameters init_params;
init_params.camera_resolution = RESOLUTION::HD720; // Use HD720 video mode (default fps: 60)
init_params.coordinate_system = COORDINATE_SYSTEM::RIGHT_HANDED_Y_UP; // Use a right-handed Y-up coordinate system
init_params.coordinate_units = UNIT::METER; // Set units in meters
```

**Python:**
```python
#Set configuration parameters
init_params = sl.InitParameters()
init_params.camera_resolution = sl.RESOLUTION.HD720 # Use HD720 video mode (default fps: 60)
init_params.coordinate_system = sl.COORDINATE_SYSTEM.RIGHT_HANDED_Y_UP # Use a right-handed Y-up coordinate system
init_params.coordinate_units = sl.UNIT.METER # Set units in meters
```

**C#:**
```csharp
// Set configuration parameters
InitParameters init_params = new InitParameters();
init_params.resolution = RESOLUTION.HD720; // Use HD720 video mode (default fps: 60)
init_params.coordinateSystem = COORDINATE_SYSTEM.RIGHT_HANDED_Y_UP; // Use a right-handed Y-up coordinate system
init_params.coordinateUnits = UNIT.METER; // Set units in meters
```

The coordinate system determines spatial map axes convention, while coordinate units specify metrics. HD720 at 60fps is recommended for optimal results.

### Enabling Spatial Mapping

After camera initialization, activate positional tracking via `enablePositionalTracking()` and spatial mapping using `enableSpatialMapping()` with `SpatialMappingParameters`.

`SpatialMappingParameters` offers two primary adjustments: resolution and range.

#### Adjusting Resolution

Manually specify mapping resolution in meters or choose from presets:

- `MAPPING_RESOLUTION::HIGH`: 2cm resolution for small areas
- `MAPPING_RESOLUTION::MEDIUM`: 5cm resolution balancing performance and detail
- `MAPPING_RESOLUTION::LOW`: 8cm resolution for large areas or collision meshes

> **Note**: HIGH resolution mapping consumes significant resources and slows spatial map updates.

**C++:**
```cpp
SpatialMappingParameters mapping_parameters;
mapping_parameters.resolution_meter = 0.03;  // Set resolution to 3cm
mapping_parameters.resolution_meter = SpatialMappingParameters::get(MAPPING_RESOLUTION::LOW); // Or use preset
```

**Python:**
```python
mapping_parameters = sl.SpatialMappingParameters()
mapping_parameters.resolution_meter = 0.03 # Set resolution to 3cm
mapping_parameters.resolution_meter = mapping_parameters.get_resolution_preset(sl.MAPPING_RESOLUTION.LOW) # Or use preset
```

**C#:**
```csharp
SpatialMappingParameters mapping_parameters = new SpatialMappingParameters();
mapping_parameters.resolutionMeter = 0.03f; // Set resolution to 3cm
mapping_parameters.resolutionMeter = SpatialMappingParameters.get(MAPPING_RESOLUTION.LOW); // Or use preset.
```

#### Adjusting Range

Manually define depth integration range or select from presets:

- `MAPPING_RANGE::NEAR`: Integrates depth up to 3.5 meters
- `MAPPING_RANGE::MEDIUM`: Integrates depth up to 5 meters
- `MAPPING_RANGE::FAR`: Integrates depth up to 10 meters

Depth accuracy decreases with distance, limiting mapping to 10 meters. Balance resolution and range carefully for quality/performance optimization.

**C++:**
```cpp
SpatialMappingParameters mapping_parameters;
mapping_parameters.range_meter = 5 ;  // Set maximum depth mapping range to 5m
mapping_parameters.range_meter = SpatialMappingParameters::get(MAPPING_RANGE::MEDIUM); // Or use preset
```

**Python:**
```python
mapping_parameters = sl.SpatialMappingParameters()
mapping_parameters.range_meter = 5 # Set maximum depth mapping range to 5m
mapping_parameters.range_meter = mapping_parameters.get_range_preset(sl.MAPPING_RANGE.MEDIUM) # Or use preset
```

**C#:**
```csharp
SpatialMappingParameters mapping_parameters = new SpatialMappingParameters();
mapping_parameters.rangeMeter = 5f; // Set maximum depth mapping range to 5m
mapping_parameters.rangeMeter = SpatialMappingParameters.get(MAPPING_RANGE.MEDIUM); // Or use preset.
```

#### Choosing the Map Type

The spatial map supports two formats:

- `SPATIAL_MAP_TYPE::MESH`: Generates mesh with points, faces, and edges
- `SPATIAL_MAP_TYPE::FUSED_POINT_CLOUD`: Generates colored point cloud requiring more memory

**C++:**
```cpp
SpatialMappingParameters mapping_parameters;
// Set mapping with mesh output
spatial_mapping_parameters.map_type = SpatialMappingParameters::SPATIAL_MAP_TYPE::MESH;
// or select point cloud output
spatial_mapping_parameters.map_type = SpatialMappingParameters::SPATIAL_MAP_TYPE::FUSED_POINT_CLOUD;
```

**Python:**
```python
mapping_parameters = sl.SpatialMappingParameters()
# Set mapping with mesh output
mapping_parameters.map_type = sl.SPATIAL_MAP_TYPE.MESH
# or select point cloud output
mapping_parameters.map_type = sl.SPATIAL_MAP_TYPE.FUSED_POINT_CLOUD 
```

**C#:**
```csharp
SpatialMappingParameters mapping_parameters = new SpatialMappingParameters();
// Set mapping with mesh output
mapping_parameters.map_type = sl.SPATIAL_MAP_TYPE.MESH;
// or select point cloud output
mapping_parameters.map_type = sl.SPATIAL_MAP_TYPE.FUSED_POINT_CLOUD;
```

#### Enabling Textures

Allow spatial mapping to record scene images for exporting textured mesh versions. Available for meshes only, not fused point clouds which carry inherent color information.

**C++:**
```cpp
SpatialMappingParameters mapping_parameters;
mapping_parameters.save_texture = true;  // Scene texture will be recorded
```

**Python:**
```python
mapping_parameters = sl.SpatialMappingParameters()
mapping_parameters.save_texture = True # Scene texture will be recorded
```

**C#:**
```csharp
SpatialMappingParameters mapping_parameters = new SpatialMappingParameters();
mapping_parameters.saveTexture = true;  // Scene texture will be recorded
```

### Getting a 3D Map

Invoke `grab()` to initiate spatial mapping. The system ingests new images, depth information, and tracking poses in the background for spatial map generation.

#### One-time Mapping

Steps for mapping an entire area and preserving results:

1. Begin spatial mapping and capture complete area
2. Upon completion, use `extractWholeSpatialMap()` to retrieve map (potentially time-consuming based on size/resolution)

For mesh creation:
- Apply `mesh.filter()` for refinement
- Generate mesh texture with `mesh.applyTexture()`

For both types:
- Store map using `map.save("filename.obj")`

**C++:**
```cpp
// Configure spatial mapping parameters
sl::SpatialMappingParameters mapping_parameters(SpatialMappingParameters::MAPPING_RESOLUTION::LOW,
                                                SpatialMappingParameters::MAPPING_RANGE::FAR);
// In this cas we want to create a Mesh
mapping_parameters.map_type = SpatialMappingParameters::SPATIAL_MAP_TYPE::MESH;
mapping_parameters.save_texture = true;
filter_params.set(MeshFilterParameters::MESH_FILTER::LOW); // not available for fused point cloud

// Enable tracking and mapping
zed.enableTracking();
zed.enableSpatialMapping(mapping_parameters);

sl::Mesh mesh; // Create a mesh object
int timer = 0;

// Grab 500 frames and stop
while (timer < 500) {
  if (zed.grab() == ERROR_CODE::SUCCESS) {
    // When grab() = SUCCESS, a new image, depth and pose is available.
    // Spatial mapping automatically ingests the new data to build the mesh.
    timer++;
  }
}

// Retrieve the spatial map
zed.extractWholeSpatialMap(mesh);
// Filter the mesh
mesh.filter(filter_params); // not available for fused point cloud
// Apply the texture
mesh.applyTexture(); // not available for fused point cloud
// Save the mesh in .obj format
mesh.save("mesh.obj");
```

**Python:**
```python
# Configure spatial mapping parameters
mapping_parameters = sl.SpatialMappingParameters(sl.MAPPING_RESOLUTION.LOW,
                                                 sl.MAPPING_RANGE.FAR)
mapping_parameters.map_type = sl.MAP_TYPE.MESH
mapping_parameters.save_texture = True
filter_params = sl.MeshFilterParameters() # not available for fused point cloud
filter_params.set(sl.MESH_FILTER.LOW) # not available for fused point cloud

# Enable tracking and mapping
tracking_parameters = sl.TrackingParameters()
zed.enable_tracking(tracking_parameters)
zed.enable_spatial_mapping(mapping_parameters)

mesh = sl.Mesh() # Create a mesh object
timer = 0

# Grab 500 frames and stop
while timer < 500 :
  if zed.grab() == sl.ERROR_CODE.SUCCESS :
    # When grab() = SUCCESS, a new image, depth and pose is available.
    # Spatial mapping automatically ingests the new data to build the mesh.
    timer += 1

# Retrieve the spatial map
zed.extract_whole_spatial_map(mesh)
# Filter the mesh
mesh.filter(filter_params) # not available for fused point cloud
# Apply the texture
mesh.apply_texture() # not available for fused point cloud
# Save the mesh in .obj format
mesh.save("mesh.obj")
```

**C#:**
```csharp
// Configure spatial mapping parameters
SpatialMappingParameters mappingParams = new SpatialMappingParameters();
mappingParams.resolutionMeter = SpatialMappingParameters.get(MAPPING_RESOLUTION.LOW);
mappingParams.rangeMeter = SpatialMappingParameters.get(MAPPING_RANGE.FAR);
mappingParams.saveTexture = true;

//Enable tracking and mapping
PositionalTrackingParameters trackingParams = new PositionalTrackingParameters();
zed.EnablePositionalTracking(ref trackingParams);
zed.EnableSpatialMapping(ref mappingParams);

RuntimeParameters runtimeParameters = new RuntimeParameters();

int timer = 0;
Mesh mesh = new Mesh();

// Grab 500 frames and stop
while (timer < 500) {
  if (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
    // When grab() = SUCCESS, a new image, depth and pose is available.
    // Spatial mapping automatically ingests the new data to build the mesh.
    timer++;
  }
}
// Retrieve the spatial map
zed.ExtractWholeSpatialMap();
// Filter the mesh
zed.FilterMesh(FILTER.LOW, ref mesh); // not available for fused point cloud
// Apply the texture
zed.ApplyTexture(ref mesh); // not available for fused point cloud
// Save the mesh in .obj format
zed.SaveMesh("mesh.obj", MESH_FILE_FORMAT.OBJ);
```

#### Continuous Mapping

For ongoing spatial map acquisition, use a request-update mechanism:

1. Activate spatial mapping
2. Request updated map via `requestSpatialMapAsync()` (launches background extraction)
3. Monitor request status with `getSpatialMapRequestStatusAsync()` (SUCCESS when prepared)
4. Access map using `retrieveSpatialMapAsync(sl::Mesh)`
5. Use within application

Requesting and retrieving maps consumes resources. Avoid frequent requests to maintain performance.

**C++:**
```cpp
// Request an updated spatial map every 0.5s
sl::Mesh mesh; // Create a Mesh object or a FusedPointCloudObject
int timer = 0;
while (1) {
  if (zed.grab() == ERROR_CODE::SUCCESS) {

      // Request an update of the mesh every 30 frames (0.5s in HD720 mode)
      if (timer%30 == 0)
         zed.requestSpatialMapAsync();

      // Retrieve spatial map when ready
      if (zed.getSpatialMapRequestStatusAsync() == ERROR_CODE::SUCCESS && timer > 0)
         zed.retrieveSpatialMapAsync(mesh);

      timer++;
  }
}
```

**Python:**
```python
# Request an updated spatial map every 0.5s
mesh = sl.Mesh() # Create a Mesh object or FusedPointCloud
timer = 0

while 1:
  if zed.grab() == sl.ERROR_CODE.SUCCESS:

      # Request an update of the spatial map every 30 frames (0.5s in HD720 mode)
      if timer % 30 == 0 :
         zed.request_spatial_map_async()

      # Retrieve spatial_map when ready
      if zed.get_spatial_map_request_status_async() == sl.ERROR_CODE.SUCCESS and timer > 0:
         zed.retrieve_spatial_map_async(mesh)

      timer += 1
```

**C#:**
```csharp
// Request an updated spatial map every 0.5s
int timer = 0;
RuntimeParameters runtimeParameters = new RuntimeParameters();
Mesh mesh = new Mesh();

while (1) {
  if (zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS) {
      // Request an update of the mesh every 30 frames (0.5s in HD720 mode)
      if (timer % 30 == 0)
        zed.RequestSpatialMap();

      // Retrieve spatial map when ready
      if (zedCamera.GetMeshRequestStatus() == ERROR_CODE.SUCCESS && timer > 0){
        zed.RetrieveSpatialMap(ref mesh);
      }       

      timer++;
  }
}
```

#### Disabling Spatial Mapping

Once spatial mapping disengages, map retrieval becomes unavailable. Extract the map before disabling modules and closing the camera.

**C++:**
```cpp
// Disable spatial mapping, positional tracking and close the camera
zed.disableSpatialMapping();
zed.disableTracking();
zed.close();
```

**Python:**
```python
# Disable spatial mapping, positional tracking and close the camera
zed.disable_spatial_mapping()
zed.disable_tracking()
zed.close()
```

**C#:**
```csharp
// Disable spatial mapping, positional tracking and close the camera
zed.DisableSpatialMapping();
zed.DisablePositionalTracking();
zed.Close();
```

#### Spatial Mapping States

Check spatial mapping status through `getSpatialMappingState()`.

**C++:**
```cpp
SPATIAL_MAPPING_STATE state = zed.getSpatialMappingState();
```

**Python:**
```python
state = zed.get_spatial_mapping_state()
```

**C#:**
```csharp
SPATIAL_MAPPING_STATE state = zed.GetSpatialMappingState();
```

When operating correctly, the module returns `SPATIAL_MAPPING_STATE::OK`. Systems unable to maintain required framerate receive `SPATIAL_MAPPING_STATE::FPS_TOO_LOW`. Memory limit violations return `SPATIAL_MAPPING_STATE::NOT_ENOUGH_MEMORY`. In both situations, spatial mapping ceases integrating new data but extraction remains possible.

### Code Example

For implementation examples, reference the Tutorial and Sample repositories on GitHub.

---

## Plane Detection

Source: https://www.stereolabs.com/docs/spatial-mapping/plane-detection/

### Introduction

The ZED camera can estimate plane positions in a scene using 3D environmental information. To detect planes, positional tracking must be enabled via `zed.enablePositionalTracking()`, and the camera's tracking state must be `OK`.

The basic procedure involves:
- Enable the positional tracking module
- Grab an image from the ZED
- Verify tracking state is `OK`
- Estimate plane position

### Detecting Planes

Use the `findPlaneAtHit` function with 2D pixel coordinates to detect a plane at a specific location.

**C++:**
```cpp
sl::Plane plane;
sl::uint2 coord; // Fill it with the coordinates taken from the full size image  
while (zed.grab() == ERROR_CODE::SUCCESS) {
  tracking_state = zed.getPosition(pose); // Get the tracking state of the camera
  if (tracking_state == TRACKING_STATE::OK) {  
    // Detect the plane passing by the depth value of pixel coord
    find_plane_status = zed.findPlaneAtHit(coord, plane);
  }
}
```

**Python:**
```python
plane = sl.Plane() # Structure that stores the estimated plane
coord = sl.uint2() # Fill it with the coordinates taken from the full size image
while zed.grab() == sl.ERROR_CODE.SUCCESS:
  tracking_state = zed.get_position(pose) # Get the tracking state of the camera
  if tracking_state == sl.TRACKING_STATE.OK:  
    # Detect the plane passing by the depth value of pixel coord
    find_plane_status = zed.find_plane_at_hit(coord, plane)
```

**C#:**
```csharp
sl.PlaneData plane = new sl.PlaneData();
Vector2 coord = new Vector2();
sl.RuntimeParameters runtimeParameters = new sl.RuntimeParameters();
while (zed.Grab(ref runtimeParameters) == sl.ERROR_CODE.SUCCESS) {
    sl.Pose pose = new sl.Pose();
    sl.POSITIONAL_TRACKING_STATE tracking_state = zed.GetPosition(ref pose);
    if (tracking_state == sl.POSITIONAL_TRACKING_STATE.OK)
    {
       sl.ERROR_CODE e = zed.findPlaneAtHit(ref plane, coord);
    }
}
```

If successful, the function stores the detected plane in an `sl::Plane` object containing useful information such as 3D position, normal, polygon boundaries, and plane type (vertical/horizontal).

### Accessing Plane Data

The `sl::Plane` class contains information for defining planes in space including normal, center, and equation. Access this information using class getters:

**C++:**
```cpp
if (find_plane_status == ERROR_CODE::SUCCESS) {
  sl::float3 normal = plane.getNormal(); // Get the normal vector of the detected plane
  sl::float4 plane_equation = plane.getPlaneEquation(); // Get (a,b,c,d) where ax+by+cz+d=0
}
```

**Python:**
```python
if find_plane_status == sl.ERROR_CODE.SUCCESS:
  normal = plane.get_normal() # Get the normal vector of the detected plane
  plane_equation = plane.get_plane_equation() # Get (a,b,c,d) where ax+by+cz+d=0
```

**C#:**
```csharp
if (find_plane_status == ERROR_CODE.SUCCESS) {
  Vector3 normal = plane.PlaneNormal; // Get the normal vector of the detected plane
  Vector4 plane_equation = plane.PlaneEquation; // Get (a,b,c,d) where ax+by+cz+d=0
}
```

For AR purposes, obtain the plane's `Transform` relative to the global reference frame:

**C++:**
```cpp
if (find_plane_status == ERROR_CODE::SUCCESS) {
  // Get the transform of the plane according to the global reference frame
  sl::Transform plane_transform = plane.getPose();
}
```

**Python:**
```python
if find_plane_status == sl.ERROR_CODE.SUCCESS :
  # Get the transform of the plane according to the global reference frame
  plane_transform = sl.Transform()
  plane_equation = plane.get_transform()
```

**C#:**
```csharp
if (find_plane_status == ERROR_CODE.SUCCESS) {
  // Get the transform of the plane according to the global reference frame
  public Quaternion rotation;
  public Vector3 translation;
  translation = plane.PlaneTransformPosition;
  rotation = plane.PlaneTransformOrientation;
}
```

#### Convert Plane to Mesh

Detected planes can be converted to a `Mesh` for visualization purposes:

**C++:**
```cpp
sl::Mesh mesh = plane.extractMesh();
```

**Python:**
```python
mesh = sl.Mesh()
mesh = plane.extract_mesh()
```

**C#:**
```csharp
Vector3[] planeMeshVertices = new Vector3[65000];
int[] planeMeshTriangles = new int[65000];
int numVertices = 0;
int numTriangles = 0;
zed.convertFloorPlaneToMesh(planeMeshVertices, planeMeshTriangles, out numVertices, out numTriangles);
```

### Detecting Floor Plane

With 3D environmental information, ZED cameras can automatically estimate ground floor location in a scene.

### Getting Floor Plane

Call `findFloorPlane` instead of `findPlaneAtHit` to automatically detect the floor plane and obtain the transform between the floor plane frame and camera frame:

**C++:**
```cpp
sl::Plane plane;
sl::Transform resetTrackingFloorFrame;
find_plane_status = zed.findFloorPlane(plane, resetTrackingFloorFrame);
if (find_plane_status == ERROR_CODE::SUCCESS) {
  // Reset positional tracking to align it with the floor plane frame
  zed.resetPositionalTracking(resetTrackingFloorFrame);
}
```

**Python:**
```python
plane = sl.Plane()
resetTrackingFloorFrame = sl.Transform()
find_plane_status = zed.find_floor_plane(plane, resetTrackingFloorFrame)
if find_plane_status == sl.ERROR_CODE.SUCCESS:
  # Reset positional tracking to align it with the floor plane frame
  zed.reset_positional_tracking(resetTrackingFloorFrame)
```

**C#:**
```csharp
PlaneData plane = new PlaneData();
float playerHeight = 0;
Quaternion priorQuat = Quaternion.Identity;
Vector3 priorVec = Vector3.Zero;
ERROR_CODE find_plane_status = zedCamera.findFloorPlane(ref plane, out playerHeight, priorQuat, priorVec);
if (find_plane_status == ERROR_CODE.SUCCESS) {
    // Reset positional tracking to align it with the floor plane frame
    zed.ResetPositionalTracking(plane.PlaneTransformOrientation, plane.PlaneTransformPosition);
}
```

Simplify this process using `PositionalTrackingParameters::set_floor_as_origin` to align the positional tracking reference frame on the ground floor:

**C++:**
```cpp
PositionalTrackingParameters positional_tracking_parameters;
positional_tracking_parameters.set_floor_as_origin = true;
zed.enablePositionalTracking(positional_tracking_parameters);

RuntimeParameters runtime_parameters;
runtime_parameters.measure3D_reference_frame = REFERENCE_FRAME::WORLD;
sl::Mat cloud;
while (zed.grab(runtime_parameters) == ERROR_CODE::SUCCESS) {
  zed.retrieveMeasure(cloud, MEASURE::XYZRGBA);
  // The point cloud is aligned on the floor plane.
  // A threshold on the height could then be used as a simple object detection method
}
```

**Python:**
```python
positional_tracking_parameters = sl.PositionalTrackingParameters()
positional_tracking_parameters.set_floor_as_origin = True
zed.enable_positional_tracking(positional_tracking_parameters)

runtime_parameters = sl.RuntimeParameters()
runtime_parameters.measure3D_reference_frame = sl.REFERENCE_FRAME::WORLD
cloud = sl.Mat()

while zed.grab(runtime_parameters) == sl.ERROR_CODE.SUCCESS:
  zed.retrieveMeasure(cloud, sl.MEASURE::XYZRGBA)
  # The point cloud is aligned on the floor plane.
  # A threshold on the height could then be used as a simple object detection method
```

**C#:**
```csharp
PositionalTrackingParameters trackingParams = new PositionalTrackingParameters();
trackingParams.setFloorAsOrigin = true;
zed.EnablePositionalTracking(ref trackingParams);

RuntimeParameters runtimeParameters = new RuntimeParameters();
runtimeParameters.measure3DReferenceFrame = REFERENCE_FRAME.WORLD;
Mat cloud = new Mat();
while(zed.Grab(ref runtimeParameters) == ERROR_CODE.SUCCESS)
{
    zed.RetrieveMeasure(cloud, MEASURE.XYZRGBA);
    // The point cloud is aligned on the floor plane.
    // A threshold on the height could then be used as a simple object detection method
}
```

Floor plane estimation can be refined by passing prior parameters (such as prior height or orientation) to the `findFloorPlane` function. For additional details, consult the API Reference.
