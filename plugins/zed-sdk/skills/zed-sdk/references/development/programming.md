---
description: >
  ZED SDK programming language guides covering C++ (Windows, Linux/Jetson),
  Python (install, run, virtual environment), C# (Windows), and C (install, run)
  development workflows.
---

# ZED SDK Programming Languages

## Table of Contents

- [C++ Development Overview](#c-development-overview)
- [Building C++ on Windows](#building-c-on-windows)
- [Building C++ on Linux and Jetson](#building-c-on-linux-and-jetson)
- [Python Development](#python-development)
- [Run a Python Application](#run-a-python-application)
- [Python Virtual Environment](#python-virtual-environment)
- [C# Development](#c-development)
- [C Development - Install](#c-development---install)
- [C Development - Run](#c-development---run)

---

## C++ Development Overview

> Source: https://www.stereolabs.com/docs/development/cpp/

The ZED SDK supports development on both Windows and Linux platforms. Platform-specific build instructions are available:

- **Windows Development**: Detailed setup and compilation steps for Windows environments
- **Linux and NVIDIA Jetson**: Instructions for building on Linux systems and embedded Jetson devices

---

## Building C++ on Windows

> Source: https://www.stereolabs.com/docs/development/cpp/windows/

### Setting Up a Project

To build the **Hello ZED** tutorial application using the ZED SDK and CMake, you need:

- The latest ZED SDK (download from Stereolabs)
- ZED SDK sample code available on GitHub
- The `Tutorials/Tutorial - Hello ZED` folder containing:
  - CMakeLists.txt
  - main.cpp
  - README.md

### Requirements

- CMake 3.5.0 or higher
- Visual Studio 2015 or higher
- 64-bit compilation

> **Note**: When installing Visual Studio, ensure you select the _Visual C++_ option during setup.

### Build Process

1. **Open cmake-gui** and configure the source and build directories:
   - Set "Where is the source code" to your project folder path (containing CMakeLists.txt)
   - Set "Where to build the binaries" to the same path with `/build` appended

2. **Click Configure**:
   - Confirm creation of the "build" folder when prompted
   - Select Visual Studio in **Win64** as your generator
   - Click Finish

3. **Generate Visual Studio files**:
   - Click Generate to create project files in the build directory

4. **Open and build the solution**:
   - Click "Open Project" or navigate to the build folder
   - Open **Project.sln** in Visual Studio
   - Set the build configuration to `Release` mode
   - Set `ZED_Tutorial_1` as the startup project

5. **Compile and run**:
   - Press `Ctrl+F5` to launch the compiled program

---

## Building C++ on Linux and Jetson

> Source: https://www.stereolabs.com/docs/development/cpp/linux/

### Setting Up a Project

1. Download and install the latest ZED SDK from the official release page
2. Download ZED Examples from the GitHub repository
3. Navigate to the `Tutorials/Tutorial - Hello ZED` folder

This folder contains:
- CMakeLists.txt
- main.cpp
- README.md

### Prerequisites

Compiling with the ZED SDK requires:
- GCC (versions 5 or 6)
- CMake (minimum version 3.5.0)

Install both tools using:

```bash
sudo apt-get install build-essential cmake
```

### Build Steps

1. Navigate to your project folder:

   ```bash
   cd path/to/your/project/ZED_Tutorial_1
   ```

2. Create a build directory:

   ```bash
   mkdir build && cd build
   ```

3. Generate the project with CMake:

   ```bash
   cmake ..
   ```

4. Check the build directory contents:

   ```bash
   ls
   ```

   Expected files: CMakeCache.txt, CMakeFiles, cmake_install.cmake, Makefile

5. Compile the application:

   ```bash
   make
   ```

6. Run the compiled application:

   ```bash
   ./ZED_Tutorial_1
   ```

   The application displays your camera's serial number in the terminal upon successful execution.

### Dynamic/Static Linking

The ZED SDK on Linux supports both linking modes:

- **Dynamic linking** (default): Reduces application size but requires users to install all dependencies
- **Static linking**: Increases executable size but improves deployment portability by packaging dependencies

**Switch to Static Linking:**

During CMake configuration, use:

```bash
cmake -DLINK_SHARED_ZED=OFF ..
```

Then rebuild:

```bash
make
```

Static linking significantly increases the final executable size while simplifying distribution.

---

## Python Development

> Source: https://www.stereolabs.com/docs/development/python/install/

The ZED Python API wraps the C++ ZED SDK using Cython, making it accessible from Python code.

### System Requirements

- ZED SDK (from the [releases page](https://www.stereolabs.com/developers/release/))
- Python 3.6+ (64-bit)
- Cython 0.26+
- Numpy 1.13+
- OpenCV Python (optional)
- PyOpenGL (optional)

### Install Python Dependencies

**Linux:**

```bash
python -m pip install cython numpy opencv-python pyopengl
```

**Windows:**

```bash
py -m pip install cython numpy opencv-python pyopengl
```

### Installing the Python API

A Python installation script is included with the ZED SDK and automatically detects your platform, CUDA version, and Python version to download the appropriate pre-compiled package.

**Windows:**

The script is located at `C:\Program Files (x86)\ZED SDK\`. Ensure you have admin access or copy it elsewhere to run without permissions.

**Linux:**

The script is located at `/usr/local/zed/`. Execute it with:

```bash
cd "/usr/local/zed/"
python3 get_python_api.py
```

The script handles dependency installation automatically. Once complete, "The Python API is now installed" and you can explore the tutorials and samples.

> **Note:** Activate any virtual environment *before* running the script.

### Troubleshooting

**"Numpy binary incompatibility"**

This error typically indicates Numpy isn't installed. Resolve it by running:

```bash
python3 -m pip install cython
python3 -m pip install numpy
```

On NVIDIA Jetson (aarch64), Cython must be installed first since Numpy requires compilation.

---

## Run a Python Application

> Source: https://www.stereolabs.com/docs/development/python/run/

To use the ZED SDK in Python projects, import the `pyzed` package:

```python
import pyzed.sl as sl
```

This import gives access to all ZED SDK functionality within your Python application.

### Getting Started Resources

- **Tutorials**: Available in the [zed-examples repository](https://github.com/stereolabs/zed-examples/tree/master/tutorials), these guides walk through fundamental concepts
- **Examples**: The full [zed-examples repository](https://github.com/stereolabs/zed-examples) contains practical code samples demonstrating various SDK modules

These resources cover camera modules, depth sensing, tracking, spatial mapping, object detection, and sensor integration.

---

## Python Virtual Environment

> Source: https://www.stereolabs.com/docs/development/python/virtual_env/

This guide explains how to set up the ZED Python wrapper in a virtual environment using Anaconda.

### Create a New Environment

1. Open Anaconda and navigate to the **Environments** tab on the left panel
2. Click **Create** at the bottom of the page
3. Enter a name for your new environment in the dialog box
4. Click **Create** to complete the setup

Your newly created environment will appear in the list below the `base(root)` environment.

### Add the ZED Package

1. Click on your environment name and select the triangle icon
2. Choose **Open Terminal** from the dropdown menu
3. Copy the `get_python_api.py` file to a location where you can execute it without permission issues
4. Run the script in the terminal
5. Close the terminal once installation completes

To verify successful installation, click **Update index..** in Anaconda. The `pyzed` package should now appear listed in your environment.

> **Note:** OpenGL packages are automatically installed for Windows to support sample displays.

### Use the ZED Environment

1. Ensure you have the ZED examples downloaded or available on your computer
2. Return to the **Home** tab in Anaconda
3. Select your newly created environment
4. Choose your preferred IDE and open a Python sample
5. Confirm you're working in your virtual environment before running

The environment is now ready to execute ZED Python applications.

---

## C# Development

> Source: https://www.stereolabs.com/docs/development/csharp/use/

The ZED SDK can be utilized in C# through a wrapper around the C++ codebase.

### Requirements

- Visual Studio 2017 with C# extensions
- CMake 3.8 or later (with C# support)
- ZED SDK installed

### NuGet Package

The primary package is **Stereolabs.zed**, which contains the C wrapper of the ZED SDK and a .NET interface that imports the functions from the wrapper in C#.

This package is automatically downloaded during project builds in the provided tutorials and samples. It can also be manually added to any C# project through Visual Studio's NuGet package manager.

### Building a Sample

1. **Download ZED Examples** from the [GitHub repository](https://github.com/stereolabs/zed-examples)

2. **Configure with CMake**
   - Open cmake-gui
   - Set source code path to the project folder containing CMakeLists.txt
   - Set build path to `{source_path}/build`
   - Click Configure and confirm folder creation

3. **Generate Project Files**
   - Select Visual Studio generator (Win64 version)
   - Click Generate to create Visual Studio solution files

4. **Build in Visual Studio**
   - Open the generated `.sln` file
   - Set build configuration to Release mode
   - Right-click Hello_ZED project and select "Set As Startup Project"
   - Press Ctrl+F5 to launch

### Deployment

Upon successful compilation, two DLL files are automatically placed in the build folder alongside the executable:

| File | Description |
|------|-------------|
| `sl_zed_c.dll` | C wrapper |
| `Stereolabs.zed.dll` | C# interface |

Both files must be included when deploying applications to target systems that have the appropriate ZED SDK version installed.

---

## C Development - Install

> Source: https://www.stereolabs.com/docs/development/c/install/

The ZED C API serves as a wrapper around the C++ ZED SDK. Download the code from the [GitHub repository](https://github.com/stereolabs/zed-c-api).

### Building on Windows

Requirements: CMake and Visual Studio 2015 or later, with 64-bit compilation.

1. Open cmake-gui
2. Set "Where is the source code" to your project folder location (containing CMakeLists.txt)
3. Set "Where to build the binaries" to the same path with `/build` appended
4. Click Configure and confirm folder creation
5. Select Visual Studio generator in Win64 mode and click Finish
6. Click Generate once configuration completes
7. Open the generated `zed_c_api.sln` in the build directory
8. Set the solution to `Release` mode
9. Right-click `sl_zed_c` and select Build
10. Build the INSTALL solution

### Building on Linux

```bash
mkdir build
cd build
cmake ..
make
sudo make install
```

### Key Requirements

- **CMake**: Required for both platforms
- **Compiler**: Visual Studio 2015+ (Windows) or GCC/Clang (Linux)
- **Architecture**: 64-bit only

---

## C Development - Run

> Source: https://www.stereolabs.com/docs/development/c/run/

To execute a ZED C application, link your project to the `sl_zed_c` library and include the appropriate header.

### Linking Your Project

Link your project to the `sl_zed_c` library. This library provides the C interface for the ZED SDK and is essential for accessing camera functionality through C code.

### Including the C Interface

```c
#include <sl/c_api/zed_interface.h>
```

This header provides access to all the C API functions and types needed to work with ZED cameras.

### Getting Started

The ZED SDK includes tutorials specifically designed for C development. Check out the ZED C API tutorials to get started with C development using the different modules of the ZED SDK.

The tutorials are available in the official ZED examples repository and demonstrate practical implementations of:

- Basic camera initialization and control
- Image capture and processing
- Depth sensing capabilities
- Camera tracking functionality
- Spatial mapping
- Object detection
- Sensor integration
- Body tracking features
