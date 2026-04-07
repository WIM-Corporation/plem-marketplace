---
description: >
  ZED SDK Docker integration -- overview, Linux install guide, Jetson install guide,
  creating custom images, using ROS/ROS 2, configuring ROS 2 Dockerfiles,
  and building ARM containers on x86.
source_urls:
  - https://www.stereolabs.com/docs/docker/
  - https://www.stereolabs.com/docs/docker/install-guide-linux/
  - https://www.stereolabs.com/docs/docker/install-guide-jetson/
  - https://www.stereolabs.com/docs/docker/creating-your-image/
  - https://www.stereolabs.com/docs/docker/using-ros/
  - https://www.stereolabs.com/docs/docker/configure-ros2-dockerfile/
  - https://www.stereolabs.com/docs/docker/building-arm-container-on-x86/
fetched: 2026-04-07
---

# ZED SDK Docker Integration

## Table of Contents

- [Docker Overview](#docker-overview)
- [Install Guide on Linux](#install-guide-on-linux)
- [Install Guide on Jetson](#install-guide-on-jetson)
- [Creating a Docker Image](#creating-a-docker-image)
- [Using ROS/ROS 2](#using-rosros-2)
- [Create a ROS 2 Image](#create-a-ros-2-image)
- [Building ARM Containers on x86](#building-arm-containers-on-x86)

---

## Docker Overview

Docker enables running code in isolated containers with all dependencies included. For the ZED SDK, this approach proves particularly valuable given its specific OS and NVIDIA CUDA requirements.

**Key benefits:**

- Running the ZED SDK on unsupported Linux distributions without requiring OS changes or CUDA version conflicts
- Testing multiple SDK versions simultaneously without reinstallation overhead
- Building isolated environments for CI/CD pipelines to ensure reproducible deployments
- What you build is much more portable since it can be docked to other devices in the same way

### Use Cases

1. **Unsupported OS environments**: Run ZED SDK inside an Ubuntu container on distributions like Debian or CentOS without switching operating systems.
2. **Version testing**: Quickly switch between SDK versions to compare performance improvements.
3. **Reproducible builds**: Ensure applications depend only on stated dependencies through isolated containerization.

---

## Install Guide on Linux

### Setting Up Docker

Install Docker on your host machine using the automatic setup script:

```bash
curl -sSL https://get.docker.com/ | sh
sudo docker run hello-world
```

> **Note**: To run Docker commands without `sudo`, create a Unix group called `docker` and add users to it. This grants privileges equivalent to root access. Consult Docker's official documentation for detailed instructions.

### NVIDIA Docker Setup

For systems with NVIDIA GPUs (skip this for NVIDIA Jetson boards), install NVIDIA Container Toolkit to enable GPU-accelerated containers. Ensure you've already installed the NVIDIA driver before proceeding.

**Ubuntu/Debian:**

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl daemon-reload && sudo systemctl restart docker
```

**CentOS/RHEL:**

```bash
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo yum install -y nvidia-container-toolkit
sudo systemctl daemon-reload && sudo systemctl restart docker
```

### Download a ZED SDK Docker Image

Official ZED SDK Docker images are available in the Stereolabs DockerHub repository, tagged with ZED SDK version, CUDA version, Ubuntu version, and optional features like OpenGL or ROS support.

```bash
docker pull stereolabs/zed:4.2-runtime-cuda12.1-ubuntu22.04
docker pull stereolabs/zed:4.2-gl-devel-cuda11.4-ubuntu20.04
docker pull stereolabs/zed:4.0-devel-cuda11.8-ubuntu20.04
```

### Start a Docker Container

```bash
docker run --gpus all -it --privileged stereolabs/zed:<container_tag>
```

The `--gpus all` flag enables all available GPUs, while `--privileged` grants permission to access connected USB cameras.

### Test with ZED Explorer GUI

To verify the installation and display the ZED Explorer GUI, use a container with OpenGL support:

```bash
docker pull stereolabs/zed:3.7-gl-devel-cuda11.4-ubuntu20.04
xhost +si:localuser:root
docker run -it --runtime nvidia --privileged -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix stereolabs/zed:3.7-gl-devel-cuda11.4-ubuntu20.04
```

Key flags:
- `--runtime nvidia`: Uses the NVIDIA container runtime
- `-v /tmp/.X11-unix:/tmp/.X11-unix`: Enables display access
- `-e DISPLAY`: Passes the display environment variable

Run ZED Explorer inside the container:

```bash
/usr/local/zed/tools/ZED_Explorer
```

### Run a Sample Application

Build and execute the Depth Sensing sample:

```bash
apt update && apt install cmake -y
cp -r /usr/local/zed/samples/depth\ sensing/ /tmp/depth-sensing
cd /tmp/depth-sensing/cpp && mkdir build && cd build
cmake .. && make
./ZED_Depth_Sensing
```

---

## Install Guide on Jetson

### Setting Up Docker

On NVIDIA Jetson devices, the Container Runtime for Docker enables GPU-accelerated container functionality. This runtime is included with NVIDIA JetPack and can be verified using:

```bash
sudo dpkg --get-selections | grep nvidia
sudo docker info | grep nvidia
```

Expected output should show `nvidia-container-runtime` and `nvidia runc` in the available runtimes.

### Download a ZED SDK Docker Image

The official ZED SDK Docker images for Jetson are available on the Stereolabs DockerHub repository, tagged by ZED SDK and JetPack versions. These images build upon the NVIDIA l4t-base container.

```bash
docker pull stereolabs/zed:3.0-devel-jetson-jp4.2
```

> **Important**: Ensure that the L4T (Linux for Tegra) version of your host system matches the L4T version of the container you are using.

### Start a Docker Container

```bash
docker run --gpus all -it --privileged stereolabs/zed:<container_tag>
```

### Run ZED Explorer Tool

```bash
xhost +si:localuser:root
docker run -it --runtime nvidia --privileged -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix stereolabs/zed:<container_tag>
/usr/local/zed/tools/ZED_Explorer
```

### Run a Sample Application

```bash
apt update && apt install cmake -y
cp -r /usr/local/zed/samples/depth\ sensing/ /tmp/depth-sensing
cd /tmp/depth-sensing ; mkdir build ; cd build
cmake .. && make
./ZED_Depth_Sensing
```

---

## Creating a Docker Image

### Write the Dockerfile

A Dockerfile example building the Hello ZED tutorial application:

```dockerfile
# Specify the parent image from which we build
FROM stereolabs/zed:3.7-gl-devel-cuda11.4-ubuntu20.04

# Set the working directory
WORKDIR /app

# Copy files from your host to your current working directory
COPY cpp hello_zed_src

# Build the application with cmake
RUN mkdir /app/hello_zed_src/build && cd /app/hello_zed_src/build && \
    cmake -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
      -DCMAKE_CXX_FLAGS="-Wl,--allow-shlib-undefined" .. && \
    make

# Run the application
CMD ["/app/hello_zed_src/build/ZED_Tutorial_1"]
```

The CMake arguments ensure proper CUDA library discovery and allow linking despite undefined symbols that become available at runtime through the NVIDIA container toolkit.

### Build your Docker Image

```bash
docker build -t hellozed:v1 .
```

> **Tip**: On NVIDIA Jetson, consider building containers on x86 hosts to avoid lengthy compilation times on embedded boards like Jetson Nano.

### Test the Image

```bash
docker run -it --gpus all -e NVIDIA_DRIVER_CAPABILITIES=all --privileged -v /dev:/dev hellozed:v1
```

For NVIDIA Jetson or older Docker versions:

```bash
docker run -it --runtime nvidia --privileged -v /dev:/dev hellozed:v1
```

For ZED X cameras, additional volume mounts are required:

```bash
docker run -it --runtime nvidia --privileged -v /dev:/dev -v /tmp:/tmp \
  -v /etc/systemd/system/zed_x_daemon.service:/etc/systemd/system/zed_x_daemon.service \
  -v /var/nvidia/nvcam/settings/:/var/nvidia/nvcam/settings/ hellozed:v1
```

> **Important**: Ensure L4T (Linux for Tegra) versions match between host and container when running on NVIDIA Jetson devices.

### Volumes

Essential volume mounts when running ZED Docker images:

| Volume | Purpose | Required |
|---|---|---|
| `/usr/local/zed/resources:/usr/local/zed/resources` | AI modules (Object Detection, Skeleton Tracking, NEURAL depth) -- avoids re-downloading on restart | Optional (recommended) |
| `/dev:/dev` | Shares video devices | Required |
| `/tmp:/tmp` | ZED X GMSL2 cameras | GMSL2 only |
| `/var/nvidia/nvcam/settings/:/var/nvidia/nvcam/settings/` | ZED X GMSL2 cameras | GMSL2 only |
| `/etc/systemd/system/zed_x_daemon.service:/etc/systemd/system/zed_x_daemon.service` | ZED X GMSL2 cameras | GMSL2 only |

### Optimize your Image Size

**Best Practices:**
- Consolidate `RUN` commands to minimize image layers.
- Use `--no-install-recommends` with `apt-get install` to skip optional packages.
- Remove downloaded package lists using `rm -rf /var/lib/apt/lists/*` in the same step.
- Delete unnecessary archives and temporary files within their creation layer.
- Create separate development and production images.
- Implement multi-stage builds, pushing only production images.

```dockerfile
# Good approach
RUN apt-get update -y && \
    apt-get autoremove -y && \
    apt-get install --no-install-recommends lsb-release && \
    tar -xvf archive.tar.gz && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf archive.tar.gz
```

### Host your Docker Image

**Docker Hub Registry**: Official ZED SDK images are available at [Stereolabs DockerHub](https://hub.docker.com/r/stereolabs/zed/).

**Save and Load Images as Files**:

```bash
# Export
docker save hellozed:v1 -o hellozed_v1.tar

# Load on destination
docker load -i hellozed_v1.tar
```

---

## Using ROS/ROS 2

### Download and Run the Docker Image

```bash
docker pull <container_tag>
xhost +si:localuser:root
docker run --gpus all --runtime nvidia --privileged -e DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev:/dev \
  -e NVIDIA_DRIVER_CAPABILITIES=all <container_tag>
```

RVIZ visualization requires OpenGL support in the container.

### Run a ROS Sample Example

```bash
cd ~/catkin_ws/src
git clone --recursive https://github.com/stereolabs/zed-ros-wrapper.git
cd ../
rosdep install --from-paths src --ignore-src -r -y
catkin_make -DCMAKE_BUILD_TYPE=Release
source ./devel/setup.bash
```

Launch the ZED node based on your camera model:

```bash
# For ZED 2i
roslaunch zed_wrapper zed2i.launch

# For ZED 2
roslaunch zed_wrapper zed2.launch

# For ZED Mini
roslaunch zed_wrapper zedm.launch

# For ZED
roslaunch zed_wrapper zed.launch
```

### Run a ROS 2 Sample Example

```bash
cd ~/ros2_ws/src/
git clone --recursive https://github.com/stereolabs/zed-ros2-wrapper.git
cd ..
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --cmake-args=-DCMAKE_BUILD_TYPE=Release
echo source $(pwd)/install/local_setup.bash >> ~/.bashrc
source ~/.bashrc
```

---

## Create a ROS 2 Image

### ZED ROS2 Wrapper Repository Resources

The ZED ROS2 Wrapper GitHub repository contains Dockerfiles in its `docker` folder:

- **Dockerfile.desktop-humble**: Development image for ROS2 Humble on specified Ubuntu and CUDA versions
- **Dockerfile.l4t-humble**: Jetson image for ROS2 Humble on given L4T versions

> **Note**: The entrypoint files set the `ROS_DOMAIN_ID` environment variable to `0` as the default ROS 2 value. Users can modify this in entrypoint files before building or use `export ROS_DOMAIN_ID=<value>` when starting interactive sessions.

### Cross Compilation

To compile Jetson images from desktop systems:

```bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### Building Docker Images

**Jetson Build:**

```bash
./jetson_build_dockerfile_from_sdk_and_l4T_version.sh <l4T version> <ZED SDK version>
```

Example for JP6.0 with ZED SDK v4.2.3:

```bash
./jetson_build_dockerfile_from_sdk_and_l4T_version.sh l4t-r36.3.0 zedsdk-4.2.3
```

**Desktop Build:**

```bash
./desktop_build_dockerfile_from_sdk_ubuntu_and_cuda_version.sh <Ubuntu version> <CUDA version> <ZED SDK version>
```

Example for Ubuntu 22.04 with CUDA 12.6.3 and ZED SDK v4.2.3:

```bash
./desktop_build_dockerfile_from_sdk_ubuntu_and_cuda_version.sh ubuntu-22.04 cuda-12.6.3 zedsdk-4.2.3
```

> **WARNING**: Some configurations won't work if specific ZED SDK versions don't exist for given OS/CUDA/L4T combinations or wrapper versions are incompatible.

### Running Docker Images

#### Prerequisites

**NVIDIA Runtime:**
- Install nvidia container runtime
- Use `--gpus all` or `-e NVIDIA_DRIVER_CAPABILITIES=all`
- Enable Docker privileged mode with `--privileged`

**Network Configuration:**
- `--network=host`: Remove container/host network isolation
- `--ipc=host`: Use host Inter-Process Communication namespace
- `--pid=host`: Use host process ID namespace

**Display Configuration:**
- Use `-e DISPLAY=$DISPLAY` for CUDA-based applications
- Mount `/tmp/.X11-unix/:/tmp/.X11-unix` volume

#### Shared Volumes

| Volume | Purpose |
|---|---|
| `/tmp/.X11-unix/:/tmp/.X11-unix` | X11 server communication |
| `/usr/local/zed/settings` | Camera calibration files for offline environments |
| `/usr/local/zed/resources` | AI models (Object Detection, Skeleton Tracking) |
| `/dev:/dev` and `/dev/shm:/dev/shm` | Video and ROS 2 shared memory devices |

**For GMSL2 cameras (ZED X, ZED X One):**
- `/tmp:/tmp`
- `/var/nvidia/nvcam/settings/:/var/nvidia/nvcam/settings/`
- `/etc/systemd/system/zed_x_daemon.service:/etc/systemd/system/zed_x_daemon.service`

#### Starting Containers

First, allow EGL access (run once):

```bash
sudo xhost +si:localuser:root
```

**USB3 Cameras:**

```bash
docker run --runtime nvidia -it --privileged --network=host --ipc=host --pid=host \
  -e NVIDIA_DRIVER_CAPABILITIES=all -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix/:/tmp/.X11-unix \
  -v /dev:/dev \
  -v /dev/shm:/dev/shm \
  -v /usr/local/zed/resources/:/usr/local/zed/resources/ \
  -v /usr/local/zed/settings/:/usr/local/zed/settings/ \
  <docker_image_tag>
```

**GMSL Cameras:**

```bash
docker run --runtime nvidia -it --privileged --network=host --ipc=host --pid=host \
  -e NVIDIA_DRIVER_CAPABILITIES=all -e DISPLAY=$DISPLAY \
  -v /tmp:/tmp \
  -v /dev:/dev \
  -v /var/nvidia/nvcam/settings/:/var/nvidia/nvcam/settings/ \
  -v /etc/systemd/system/zed_x_daemon.service:/etc/systemd/system/zed_x_daemon.service \
  -v /usr/local/zed/resources/:/usr/local/zed/resources/ \
  -v /usr/local/zed/settings/:/usr/local/zed/settings/ \
  <docker_image_tag>
```

---

## Building ARM Containers on x86

### Overview

This section explains how to build applications on x86_64 platforms for deployment on NVIDIA Jetson devices with ARM architecture.

Two primary advantages:
1. **Accelerated development**: Building directly on Jetson Nano is slow; ARM emulation enables faster builds on x86 workstations.
2. **Resource efficiency**: Jetson platforms have limited memory and storage, making complex package compilation challenging.

### Setting Up ARM Emulation on x86

Install required packages:

```bash
sudo apt-get install qemu binfmt-support qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### Testing the Setup

```bash
uname -m
#x86_64

docker run --platform=linux/arm64/v8 --rm -t arm64v8/ubuntu uname -m
#aarch64
```

> **Note**: QEMU alone cannot build CUDA-accelerated applications. Use Linux for Tegra (L4T) base images from NVIDIA DockerHub for CUDA support.

### Building Jetson Containers

For basic CUDA support:

```dockerfile
FROM nvidia/l4t-base:r32.2.1
```

For CUDA with ZED SDK:

```dockerfile
FROM stereolabs/zed:3.0-devel-jetson-jp4.2
```

### Deploying Images to Jetson

The standard deployment pattern:
- **Host machine**: Write Dockerfile and source code
- **Build phase**: Construct image on host
- **Registry**: Push to Docker registry
- **Target machine**: Pull and run container

```bash
docker pull {user}/{custom_image}:{custom_tag}
docker run --privileged --runtime nvidia --rm {user}/{custom_image}:{custom_tag}
```

> **Note**: `docker run` automatically pulls the image if not already present locally.
