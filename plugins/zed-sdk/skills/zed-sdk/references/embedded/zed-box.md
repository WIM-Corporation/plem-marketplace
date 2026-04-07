---
description: >
  ZED Box Mini and ZED Box Orin embedded systems -- overview, installation,
  GMSL configuration, real-time kernel flashing, and troubleshooting.
source_urls:
  - https://www.stereolabs.com/docs/embedded/zed-box-mini/
  - https://www.stereolabs.com/docs/embedded/zed-box-mini/installation/
  - https://www.stereolabs.com/docs/embedded/zed-box-mini/real-time/
  - https://www.stereolabs.com/docs/embedded/zed-box-mini/troubleshooting/
  - https://www.stereolabs.com/docs/embedded/zed-box-orin/
  - https://www.stereolabs.com/docs/embedded/zed-box-orin/installation/
  - https://www.stereolabs.com/docs/embedded/zed-box-orin/gmsl/
  - https://www.stereolabs.com/docs/embedded/zed-box-orin/real-time/
  - https://www.stereolabs.com/docs/embedded/zed-box-orin/troubleshooting/
fetched: 2026-04-07
---

# ZED Box Mini & ZED Box Orin

## Table of Contents

- [ZED Box Mini Overview](#zed-box-mini-overview)
- [ZED Box Mini Installation](#zed-box-mini-installation)
- [ZED Box Mini Real-Time Kernel](#zed-box-mini-real-time-kernel)
- [ZED Box Mini Troubleshooting](#zed-box-mini-troubleshooting)
- [ZED Box Orin Overview](#zed-box-orin-overview)
- [ZED Box Orin Installation](#zed-box-orin-installation)
- [ZED Box Orin Using GMSL](#zed-box-orin-using-gmsl)
- [ZED Box Orin Real-Time Kernel](#zed-box-orin-real-time-kernel)
- [ZED Box Orin Troubleshooting](#zed-box-orin-troubleshooting)

---

## ZED Box Mini Overview

The ZED Box Mini is a compact, cost-effective embedded system designed for camera-based applications. It features essential I/O, portability, and advanced GMSL2 connectivity, leveraging NVIDIA Jetson modules as its processing core for real-time AI applications.

A key capability allows the device to directly convert GMSL2 or USB3.0 camera input into Gigabit Ethernet streams, facilitating high-speed, long-distance data transmission using the ZED SDK's streaming module.

### Compute Module Options

The Mini Carrier Board supports various NVIDIA Jetson modules:

| Module | AI Performance |
|---|---|
| NVIDIA Jetson Orin Nano 4 GB | 34 TOPS |
| NVIDIA Jetson Orin Nano 8 GB | 67 TOPS |
| NVIDIA Jetson Orin NX 8 GB | 117 TOPS |
| NVIDIA Jetson Orin NX 16 GB | 157 TOPS |

> **Note**: The Mini Carrier Board requires a Jetson compute module to operate; it is not a standalone product.

### Connectivity Features

- 2x GMSL2 FAKRA-Z Connectors
- 1x USB3.0 Type-A port
- 1x 10/100/1000 Gigabit Ethernet RJ45
- Optional Intel AX210 WiFi module (M.2 Key-E 2230)
- 1x HDMI 1.4
- 1x Micro USB2.0 for system flashing
- GMSL2 camera synchronization trigger ports
- GPIO port with CAN, UART, and general-purpose connections

### Storage

An SSD 256GB mounted on M.2 Key-M 2242 socket comes included with all configurations.

---

## ZED Box Mini Installation

The ZED Box Mini is an embedded Linux device functioning as a standard Linux-based PC. While designed for compatibility with ZED cameras, their use is optional.

### 1. Camera Connection (Optional)

**GMSL2 Cameras:**
Push the Fakra connector firmly until hearing a "click" for secure connection. These cameras must be connected before powering on to ensure proper OS detection.

> **Note**: The device does not support two ZED X One 4K cameras simultaneously.

**USB 3 Cameras:**
These are plug-and-play and can be connected anytime, even after boot.

**Hybrid Setup:**
Connect up to three cameras total:
- 1x USB 3 ZED Stereo Camera
- 2x GMSL2 Cameras

### 2. Power Connection

Connect the provided power supply to the power connector. The device powers on automatically.

### 3. Network Connection

Use the Ethernet port to connect to your network.

### 4. Display Setup

**Option A - Monitor:**
Connect via HDMI 1.4 to 2.1 type-A connector (supports up to 3840x2160 @60Hz).

**Option B - Headless Mode:**
Use a Dummy HDMI plug to simulate a connected display, enabling X11 forwarding and OpenGL applications.

### 5. Input Devices

Connect a USB 3 hub to attach a keyboard and mouse to the USB 3 Type A port.

### 6. Operating System Setup

**Default Credentials:**
- Username: `user`
- Password: `admin`

**Change Password via Terminal:**

```bash
passwd
```

**Change Password via GUI:**
Navigate to Settings -> Users -> Select Account -> Password

**System Update:**

```bash
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
```

### 7. Software Installation

**Check ZED SDK Version:**

```bash
ZED_Explorer -v
```

**Check ZED X Driver Version:**

```bash
dpkg -l | grep stereolabs
```

Visit the Stereolabs website downloads section to ensure running the latest versions.

### 8. Add New User (Optional)

```bash
sudo useradd -m <username>
sudo passwd <username>
sudo usermod -aG adm i2c tty dialout sudo audio video gdm zed
```

---

## ZED Box Mini Real-Time Kernel

This guide enables advanced users to install a Real-Time Kernel on the ZED Box Mini for applications requiring low-latency processing and high determinism, particularly useful for robotics and industrial automation.

> **WARNING**: This is for advanced users only. If you're unfamiliar with device flashing or don't require real-time capabilities, skip this guide.

### Prerequisites

- Ubuntu 22.04 or 20.04 Linux host machine
- Minimum 30GB free disk space
- ZED Box Mini device (Orin NX or Orin Nano series) or Mini Carrier Board

### Download Flashing Script

Stereolabs provides ready-to-use scripts for RT kernel installation:
- NVIDIA Jetpack 6.2 / L4T 36.4 available for download

The automation handles these operations:
1. Downloads required NVIDIA and Stereolabs files
2. Extracts and configures build environment
3. Builds RT kernel with ZED Box optimizations
4. Flashes device or creates bootable USB key

### Flashing Procedure

1. **Set workspace directory**:

```bash
export BSP_ROOT=$(pwd)/J62RT
```

2. **Make script executable**:

```bash
chmod +x rt_zedbox_mini_usb_flash_rXYZ.sh
```

Replace `XYZ` with your version (e.g., `364` for L4T 36.4).

3. **Optional - Set custom hostname**:

```bash
export ZBOX_NAME=my-zedbox-name
```

4. Force ZED Box into recovery mode per official guidelines.

5. Connect ZED Box to host via USB.

6. **Run flashing script**:

```bash
./rt_zedbox_mini_usb_flash_rXYZ.sh
```

7. Boot the ZED Box Mini.

8. **Hold kernel packages from updates**:

```bash
sudo apt-mark hold nvidia-l4t-display-kernel nvidia-l4t-kernel \
  nvidia-l4t-kernel-dtbs nvidia-l4t-kernel-headers \
  nvidia-l4t-kernel-oot-headers nvidia-l4t-kernel-oot-modules
```

This prevents system updates from overwriting real-time patches.

### Creating Bootable USB Key

Alternative to flashing internal storage:

1. Insert 16GB+ USB drive.
2. Set USB device: `export SDX=sda`
3. Set workspace: `export BSP_ROOT=$(pwd)/J62RT`
4. Execute the flashing script.
5. Boot ZED Box from USB without modifying internal storage.

### Troubleshooting

- Review `logs` directory for detailed error messages.
- Verify sufficient host disk space.
- Confirm ZED Box is properly in recovery mode.
- Try alternative USB cable (shorter connection preferred).
- Contact support@stereolabs.com with relevant logs if issues persist.

---

## ZED Box Mini Troubleshooting

### ZED Box Mini Not Booting

#### Check Power Connection

If your device won't power on after shutdown:
- Unplug both power cables.
- Use a voltmeter to verify 12V output.
- Contact support if voltage is incorrect.

#### Check Power LED Status

**LED is ON** -- Indicates a software issue requiring a hard reset. The device may have suffered corruption from improper shutdown. Always use proper software shutdown before removing power.

**LED is OFF** -- Suggests hardware failure. Contact Stereolabs Support.

### Cannot Flash ZED Box Mini

#### Force Recovery Mode

If flashing fails, the device likely isn't in Recovery Mode. Verify with:

```bash
lsusb -d '0955:'
```

Expected outputs by model:
- **Orin Nano 4GB**: VID:PID `0955:7623`
- **Orin NX 8GB**: VID:PID `0955:7423`
- **Orin NX 16GB**: VID:PID `0955:7323`

#### Bad Communication

If the device is in Recovery Mode but flashing fails:
- Avoid virtual machines and WSL2.
- Use a shorter USB cable.
- Try different host PC USB ports (preferably motherboard-soldered).
- Attempt flashing from a different Ubuntu PC.
- Disable USB autosuspend:

```bash
sudo bash -c 'echo -1 > /sys/module/usbcore/parameters/autosuspend'
```

### Chromium and Firefox Issues with Jetson Linux 36.4.4

Upgrading to Jetson Linux (L4T) 36.4.4 introduces Snapd 2.70, which breaks Snap-based applications with the error: "cannot set capabilities: Operation not permitted"

The Jetson Orin kernel lacks security features required by newer Snapd versions. Revert Snapd to a working version:

```bash
snap download snapd --revision=24724
sudo snap ack snapd_24724.assert
sudo snap install snapd_24724.snap
sudo snap refresh --hold snapd
```

For additional details, refer to [JetsonHacks](https://jetsonhacks.com/2025/07/12/why-chromium-suddenly-broke-on-jetson-orin-and-how-to-bring-it-back/).

### Package nvidia-l4t-kernel Configuration Error

After `sudo apt upgrade`, reinstalling the ZED X Driver may fail with dependency errors. Resolve with:

```bash
sudo apt-get autoclean
sudo mv /var/lib/dpkg/info/ /var/lib/dpkg/backup/
sudo mkdir /var/lib/dpkg/info/
sudo apt-get update
sudo apt-get -f install
```

### Blurry Images After System Update

System updates may overwrite the patched library used by the ZED Link driver. To restore:

1. Download the latest ZED Link driver from the [ZED X Drivers page](https://www.stereolabs.com/developers/drivers).

2. Extract and copy the patched library:

```bash
ar x stereolabs-zed<model>_<version>-<deser>-<l4t_version>_arm64.deb
tar xvf data.tar.xz
sudo cp ./tmp/R<l4t_version>/libnvisppg.so /usr/lib/aarch64-linux-gnu/tegra/libnvisppg.so
```

3. Reboot:

```bash
sudo reboot
```

Replace `<l4t_version>` with your current L4T version (e.g., R36.4.3).

### Contact Support

For unresolved issues, reach out to the [community forum](https://community.stereolabs.com/).

---

## ZED Box Orin Overview

The ZED Box Orin is a compact gateway powered by NVIDIA Jetson for challenging AIoT (Artificial Intelligence of Things) in mobile and field situations. It delivers spatial perception capabilities at the edge, enabling aggregation and analysis of data from 3D sensors in demanding field environments.

### Key Options

**GMSL2 Option**

Facilitates high-speed, low-latency communication between the processor and ZED GMSL2 cameras, suited for industrial grade applications. A dedicated guide covers driver installation and multi-camera setup procedures.

**GPS/GNSS Option**

The integrated GNSS module allows developers to build AI systems that operate with high precision and accuracy, even in challenging environmental conditions.

---

## ZED Box Orin Installation

### Connection Panel

All connection ports are located in the front panel, including GMSL camera connections and standard peripherals.

**PoE+ Specifications:**

| Parameter | Value |
|---|---|
| Max Power Mode | 15 W |
| Voltage | 42.5 ~ 57 V |
| Current | 600 mA |
| Cabling | Category 5 |

### 01. Plug in the Power Supply

Connect the provided power supply to the jack connector if you're not using PoE+. The jack connector allows the ZED Box to operate in 25W power mode.

> **Note**: You may supply power via PoE+ instead of the jack connector, but do not exceed 15W power mode in that configuration.

### 02. Connect to Your Network

Use the Ethernet port to connect to your network. A PoE+-enabled switch can power the system without the jack connector, though the 15W power limit applies.

### 03. Connect to Your Display

Connect a display using the HDMI port.

### 04. Connect Keyboard and Mouse

Connect input devices through USB ports with a USB hub.

### 05. Complete Operating System Setup

**Default Access Credentials:**
- Username: `user`
- Password: `admin`

For security, change the default password after first boot.

**Changing Your Password via Terminal:**

```bash
passwd
```

**Changing Your Password via GUI:**
Navigate through Activities > Settings, or access via System Tray, or launch `gnome-control-center` from terminal. Go to Users section and update your password.

**ZED SDK Update:**

Determine your current JetPack version:

```bash
apt-cache policy nvidia-jetpack
```

Visit www.stereolabs.com/developers/release/ to download the corresponding ZED SDK version for your JetPack installation.

### 06. Connect Your ZED Camera

**USB Camera Connection:**
Connect ZED USB cameras to USB 3.0 ports for maximum resolution and framerate.

**GMSL Camera Connection:**
The ZED Box supports multiple GMSL2 camera configurations:
- Up to 4 cameras on a single 4-wire GMSL2 Fakra connector (maximum 30 FPS for HD or 60 FPS for SVGA)
- When using ZED X One 4K: only two supported simultaneously, or one 4K with one Global Shutter model (4K must use lower-ranked port index)

### Install on Wall with Brackets

Screw brackets to the case, then screw the ZED Box to the wall. Wall mounting screws are not included.

### Add a New User

```bash
sudo useradd -m <username>
sudo passwd <username>
sudo usermod -aG adm i2c tty dialout sudo audio video gdm zed
```

Log out and reboot to verify everything functions properly with the new credentials.

---

## ZED Box Orin Using GMSL

### GMSL Driver

The ZED X camera requires a GMSL driver that comes pre-installed on the ZED Box. However, you may need to install it manually if you upgrade your system version.

To check your JetPack version:

```bash
cat /etc/nv_tegra_release
```

This will display output like: `# R35 (release), REVISION: 4.1, GCID: 33958178...`

In this example, the L4T version is 35.4.1. Download the matching driver from the Stereolabs website and install it:

```bash
sudo dpkg -i <the deb file path>
```

Then reboot your system.

### Multi-Camera Configurations

#### ZED Box Orin with 4-Wire GMSL2 Connectivity

The ZED Box Orin provides 4 GMSL2 ports organized in 2 groups:
- **Group A**: ports #0 and #1
- **Group B**: ports #2 and #3

**Camera Configuration Limits:**

| Camera Type | Model | Max per Group | Max Resolution/FPS |
|---|---|---|---|
| Monocular | ZED X One GS, ZED X One S | 2 cameras | HD1200@60fps, HD1080@60fps, SVGA@120fps |
| Monocular | ZED X One 4K | 1 camera (port #0, #2 only) | 4K@15fps, HD1080@60fps, SVGA@60fps |
| Stereo | ZED X, ZED X Mini | 1 camera | HD1200@60fps, HD1080@60fps, SVGA@120fps |
| Stereo | ZED X, ZED X Mini | Up to 2 cameras | HD1200@30fps, HD1080@30fps, SVGA@60fps |
| Mixed | ZED X One GS/S + ZED X/Mini | 1 of each type | HD1200@60fps, HD1080@60fps, SVGA@120fps |

> **Note**: Maximum resolution and framerate require no more than 2 cameras per 4-wire GMSL2 Fakra connector.

#### ZED Box Orin with Mono GMSL2 Port (Out of Production)

This earlier ZED Box Orin version provides a single GMSL2 port supporting one camera:

| Camera Type | Model | Max Resolution/FPS |
|---|---|---|
| Monocular | ZED X One GS, ZED X One S | HD1200@60fps, HD1080@60fps, SVGA@120fps |
| Monocular | ZED X One 4K | 4K@15fps, HD1080@60fps, SVGA@60fps |
| Stereo | ZED X, ZED X Mini | HD1200@60fps, HD1080@60fps, SVGA@120fps |

### Developing Your Own Driver

For custom GMSL device integration alongside Stereolabs ZED X cameras, a custom driver may be required. Contact the support team at support@stereolabs.com for guidance.

---

## ZED Box Orin Real-Time Kernel

This guide enables advanced users to deploy a Real-Time Kernel on the ZED Box Orin for low-latency, high-determinism applications in robotics and industrial automation.

> **WARNING**: This process is only for experienced users familiar with device flashing. Standard users without real-time requirements should skip this guide.

### Prerequisites

- Ubuntu 20.04 or 22.04 Linux host machine
- Minimum 30GB free disk space
- ZED Box Orin device (Orin NX or Orin Nano)

### Available Scripts

Two flashing scripts are provided based on your system version:

- **L4T 36.3/Jetpack 6.0-6.1**: `rt_zedbox_onx_usb_flash_r363.sh`
- **L4T 36.4/Jetpack 6.2**: `rt_zedbox_onx_usb_flash_r364.sh`

The scripts automate: downloading NVIDIA and Stereolabs files, extracting build environments, compiling the RT kernel with ZED Box optimizations, and preparing the device or bootable media.

### Flashing Steps

1. Set workspace directory:

```bash
export BSP_ROOT=$(pwd)/J62RT
```

2. Make script executable (replace XYZ with your version):

```bash
chmod +x rt_zedbox_onx_usb_flash_rXYZ.sh
```

3. Optional -- set custom hostname:

```bash
export ZBOX_NAME=my-zedbox-name
```

4. Place ZED Box in recovery mode per the manufacturer's guidelines.

5. Connect device via USB cable.

6. Execute flashing script:

```bash
./rt_zedbox_onx_usb_flash_rXYZ.sh
```

7. Boot the ZED Box after completion.

8. **Critical**: Hold kernel package updates to prevent overwriting patches:

```bash
sudo apt-mark hold nvidia-l4t-display-kernel nvidia-l4t-kernel \
  nvidia-l4t-kernel-dtbs nvidia-l4t-kernel-headers \
  nvidia-l4t-kernel-oot-headers nvidia-l4t-kernel-oot-modules
```

### Creating Bootable USB

For non-destructive testing without internal storage modification:

1. Insert 16GB+ USB drive.
2. Set device path: `export SDX=sda`
3. Set workspace: `export BSP_ROOT=$(pwd)/J62RT`
4. Execute script with optional USB device selection.
5. Process duration depends on USB speed.

### Troubleshooting

- Review log files for detailed error messages.
- Verify adequate host disk space.
- Confirm proper recovery mode activation.
- Test alternative USB cables.
- Contact support@stereolabs.com with logs for assistance.

---

## ZED Box Orin Troubleshooting

### Device Boot Problems

If your ZED Box Orin won't power on, try unplugging both power cables and reconnecting only one at a time. The carrier board cannot reboot when multiple power sources are already connected.

**Power LED Status:**
- **Green LED** -- Suggests software corruption.
- **LED OFF** -- May indicate file system or hardware failure.

### Full Disk Recovery

When the internal storage fills completely, the device fails to boot. Recovery requires an 8GB or larger USB 3.0 drive and a host PC running Ubuntu 20.04 or 22.04. The process involves downloading a recovery script, creating a bootable USB, and manually deleting files to free space.

### GNSS/GPS Issues

If experiencing no GPS data despite being outdoors, verify the antenna is properly connected to port 5. Avoid using `gpsd` with `systemd` due to incompatibilities. Instead use:

```bash
sudo gpsd -nG -P /run/gpsd.pid /dev/ttyACM0
```

### WiFi Failure After Updates

System updates occasionally install incorrect WiFi drivers. Fix by removing the problematic firmware file at `/lib/firmware/iwlwifi-ty-a0-gf-a0-66.ucode` and reloading the correct driver module.

### Cannot Flash ZED Box Orin

Ensure the device is in Recovery Mode by checking USB devices. Use `lsusb` to verify the vendor ID. Recommendations:
- Use native Linux rather than virtual machines or WSL2.
- Use a shorter USB cable.
- Try different USB ports on the host PC.

### Package Dependency Errors

Installation failures related to `nvidia-l4t-kernel` can be resolved through package cache cleanup and dependency fixes:

```bash
sudo apt-get autoclean
sudo mv /var/lib/dpkg/info/ /var/lib/dpkg/backup/
sudo mkdir /var/lib/dpkg/info/
sudo apt-get update
sudo apt-get -f install
```

### Chromium and Firefox Issues

Snapd 2.70 breaks Chromium and Firefox on Jetson Orin. Downgrade Snapd to an earlier working version:

```bash
snap download snapd --revision=24724
sudo snap ack snapd_24724.assert
sudo snap install snapd_24724.snap
sudo snap refresh --hold snapd
```

### Blurry Images After System Update

System updates may overwrite the patched library used by the ZED Link driver. Restore by extracting from the driver package:

```bash
ar x stereolabs-zed<model>_<version>-<deser>-<l4t_version>_arm64.deb
tar xvf data.tar.xz
sudo cp ./tmp/R<l4t_version>/libnvisppg.so /usr/lib/aarch64-linux-gnu/tegra/libnvisppg.so
sudo reboot
```

### Contact Support

For unresolved issues, reach out to the [Stereolabs community](https://community.stereolabs.com/).
