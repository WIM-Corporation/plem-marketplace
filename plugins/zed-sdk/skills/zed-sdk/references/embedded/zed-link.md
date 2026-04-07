---
description: >
  ZED Link GMSL2 capture cards -- overview, hardware setup guides for Mono (Orin Nano),
  Duo (AGX Orin), Quad (AGX Orin), GMSL2 power requirements, driver installation,
  and troubleshooting.
source_urls:
  - https://www.stereolabs.com/docs/embedded/zed-link/
  - https://www.stereolabs.com/docs/embedded/zed-link/mono-jetson-orin-nano-devkit-setup/
  - https://www.stereolabs.com/docs/embedded/zed-link/dual-jetson-orin-agx-devkit-setup/
  - https://www.stereolabs.com/docs/embedded/zed-link/quad-jetson-orin-agx-devkit-setup/
  - https://www.stereolabs.com/docs/embedded/zed-link/power_requirements/
  - https://www.stereolabs.com/docs/embedded/zed-link/install-the-drivers/
  - https://www.stereolabs.com/docs/embedded/zed-link/troubleshooting/
fetched: 2026-04-07
---

# ZED Link GMSL2 Capture Cards

## Table of Contents

- [ZED Link Overview](#zed-link-overview)
- [ZED Link Mono on Orin Nano DevKit Setup](#zed-link-mono-on-orin-nano-devkit-setup)
- [ZED Link Duo on AGX Orin DevKit Setup](#zed-link-duo-on-agx-orin-devkit-setup)
- [ZED Link Quad on AGX Orin DevKit Setup](#zed-link-quad-on-agx-orin-devkit-setup)
- [GMSL2 Power Requirements](#gmsl2-power-requirements)
- [Install / Upgrade ZED Link Driver](#install--upgrade-zed-link-driver)
- [Troubleshooting](#troubleshooting)

---

## ZED Link Overview

ZED Link GMSL2 capture cards enable connection of Stereolabs stereo and monocular cameras to NVIDIA Jetson devices.

### What is GMSL2?

Gigabit Multimedia Serial Link (GMSL2) is Analog Devices' proprietary technology to transport high-speed, serialized data over coax or shielded-twisted pair (STP) cables. The protocol supports fixed data rates including 3 Gbps or 6 Gbps forward channels and 187 Mbps reverse channels, depending on device configuration.

### Supported Hardware

#### ZED Link Mono

| Platform | Supported |
|---|---|
| NVIDIA Orin Nano DevKit | Yes |
| NVIDIA Xavier NX DevKit | Yes |
| AGX Orin DevKit | No |
| Xavier AGX DevKit | No |

Supports connection of ZED X, ZED X Mini, ZED X One GS, or ZED X One 4K cameras.

#### ZED Link Duo

| Platform | Supported |
|---|---|
| NVIDIA AGX Orin DevKit | Yes |
| NVIDIA Xavier AGX DevKit | Yes |
| NVIDIA Orin Nano DevKit | Yes |
| NVIDIA Xavier NX DevKit | Yes |

#### ZED Link Quad

| Platform | Supported |
|---|---|
| NVIDIA AGX Orin DevKit | Yes |
| NVIDIA Xavier AGX DevKit | Yes |
| Orin Nano DevKit | No |
| Xavier NX DevKit | No |

> **WARNING**: It is not possible to disassemble a ZED Box Orin that was purchased without a pre-installed GMSL2 capture card with the intention of installing it later. The passive heat dissipation system risks damage if opened, voiding warranty.

---

## ZED Link Mono on Orin Nano DevKit Setup

### Prerequisites

- NVIDIA Jetson Orin Nano Developer Kit (or with Orin NX module)
- ZED Link Mono GMSL2 capture card
- NVIDIA power supply (included with devkit)
- FPC Camera Cable 22-pin 0.5mm Pitch (included)
- 9V-19V power input (Barrel Jack 5.5mm outer diameter, 2.5mm inner diameter) for the capture card

> **Note**: MIPI cables transmit video signals. If the length increases, the video signal will be noisy. Max length recommended is 15 cm.

### Installation Steps

#### Power and MIPI Connections

Connect the power adapter to the white PWR J3 connector on the capture card. Attach CSI cables to the MIPI 22-pin port, ensuring correct orientation to avoid hardware damage.

#### Carrier Board Connection

Connect the CSI cable to the carrier board's 22-pin connector, respecting proper MIPI pin orientation per documentation images.

#### Camera Connection

1. Connect the GMSL2 Fakra cable's female end to your camera until clicking into place.
2. With the capture card powered off, connect the cable's female end to the card's GMSL2 input until secured with a click.

> **Note**: GMSL2 cameras must be ideally plugged before booting up. If it is not the case, you can restart the `zed_x_daemon`.

3. Apply 9V-19V power to the capture card for camera power delivery via the FAKRA cable.
4. Connect HDMI/peripherals and boot the system.

### Software Setup

1. Install the ZED Link Driver
2. Install the ZED SDK on NVIDIA Jetson

### Camera Configurations

The ZED Link Mono supports a single GMSL2 port.

| Camera Type | Model | Max Resolution/FPS |
|---|---|---|
| Monocular | ZED X One GS, ZED X One S | HD1200@60fps, HD1080@60fps, SVGA@120fps |
| Monocular | ZED X One 4K | 4K@15fps, HD1080@60fps, SVGA@60fps |
| Stereo | ZED X, ZED X Mini | HD1200@60fps, HD1080@60fps, SVGA@120fps |

---

## ZED Link Duo on AGX Orin DevKit Setup

### Prerequisites

- NVIDIA Jetson AGX Orin Developer Kit
- ZED Link Duo GMSL2 capture card
- 1-to-4 GMSL2 Fakra Male to Female cable (included)
- NVIDIA power supplier

> **Note**: The ZED Link Duo card does not need external power when connected to an NVIDIA Jetson AGX devkit.

### Physical Installation Steps

#### Mounting the Capture Card

1. Power off and disconnect the AGX DevKit.
2. Insert the card into the "Camera connector" slot.
3. Secure with three provided screws using proper spacers.

> **WARNING**: It's important to use the provided spacers and screws to ensure a secure fit and avoid damaging the equipment.

#### Camera Connection

Connect the GMSL2 Fakra cable's female end to the camera until a click confirms secure attachment. With the DevKit still powered off, attach the male end to the capture card's GMSL2 input.

#### Optional Enclosure

For AGX Orin systems, Stereolabs offers an optional enclosure that provides secure integration, enables VESA 75x75 mounting, and allows WiFi antenna addition.

### Software Installation

1. Install the ZED Link Driver
2. Install the ZED SDK on NVIDIA Jetson

### Multi-Camera Configuration

The ZED Link Duo provides 4 GMSL2 ports organized into two groups (A and B):

- **Monocular cameras** (ZED X One GS/S): Up to 2 per group; HD1200@60fps max
- **Monocular 4K** (ZED X One 4K): 1 camera to port #0 or #2 only
- **Stereo cameras** (ZED X/Mini): Single or up to 2 cameras with reduced framerates
- **Mixed configurations** also supported

Maximum performance requires no more than 2 cameras per 4-wire GMSL2 connector.

---

## ZED Link Quad on AGX Orin DevKit Setup

### Prerequisites

- NVIDIA Jetson Orin AGX Developer Kit
- ZED Link Quad capture card
- Two 1-to-4 GMSL2 Fakra cables (included)
- Power supply for the devkit
- 9V-19V minimum 6W power input for the capture card
- Optional AGX Orin enclosure

### Hardware Setup

1. Insert the capture card into the camera connector slot.
2. Secure with three provided screws using spacers.
3. Connect power adapter to the J10 connector.
4. Attach GMSL2 cameras via Fakra cables.
5. Power on the capture card before booting the devkit.

#### Optional Enclosure Integration

An optional enclosure securely integrates the capture card while maintaining equipment safety and allowing VESA 75x75 mounting capability.

### Multi-Camera Configuration

The Quad card provides 8 GMSL2 ports organized into 6 groups (A-F):

- **Monocular cameras**: Up to 2 per group at HD1200@60fps
- **Stereo cameras**: Single camera at HD1200@60fps; up to 2 cameras at HD1200@30fps
- **Mixed setups**: One monocular plus one stereo unit supported

### Synchronization Feature

For full hardware synchronization across all cameras with 15us precision:

1. Edit the zed_x_daemon service file.
2. Change `sync_mode` to `1`.
3. Connect pin 13 to pin 16 using a wire (pins aren't aligned for jumpers).
4. Restart the daemon service.

### Software Installation

1. Install the ZED Link Driver
2. Install the ZED SDK on the Jetson platform

---

## GMSL2 Power Requirements

### Capture Card Power Requirements

| Capture Card | Min. | Typ. | Max. |
|---|---|---|---|
| ZED Link Mono | 0.23 W | 0.24 W | 0.25 W |
| ZED Link Duo | 0.30 W | 0.32 W | 0.34 W |
| ZED Link Quad | 0.28 W | 0.29 W | 0.30 W |

### GMSL2 Camera Power Requirements

| GMSL2 Camera | Min. | Max. |
|---|---|---|
| ZED X / ZED X Mini | 1.01 W | 1.48 W* |
| ZED X One GS | 0.70 W | 0.94 W** |
| ZED X One 4K | 0.73 W | 1.01 W*** |

- \* Maximum consumption occurs at HD1200 resolution with 60 FPS operation
- \*\* Maximum consumption occurs at HD1200 resolution with 60 FPS operation
- \*\*\* Maximum consumption happens when HDR mode is enabled at QHD+ resolution (15 FPS)

### Total Power Requirement Calculation

To determine total maximum power for a GMSL2 setup, add the capture card power consumption to each connected camera's power consumption.

**Example configuration:** Two stereo cameras (forward/backward) plus two 4K monocular cameras (side-facing)

- ZED Link Quad Capture card
- 2x ZED X cameras
- 2x ZED X One 4K cameras

**Maximum total power = 0.30 + (2 x 1.48) + (2 x 1.01) = 5.28 W**

---

## Install / Upgrade ZED Link Driver

### Overview

The ZED Link GMSL2 capture cards require driver installation to operate correctly. The driver configures the GMSL2 device and depends on hardware specifics including the Jetson carrier board and deserializer card.

### Download the Driver

Obtain the driver from the [ZED X Camera Drivers page](https://www.stereolabs.com/developers/drivers). Always verify you're using the latest available version.

### Installation Command

```bash
sudo dpkg -i stereolabs-zedx_X.X.X-ZED-LINK-YYYY-L4TZZ.Z_arm64.deb
```

Where:
- **X.X.X** = driver version number
- **YYYY** = ZED Link model (MONO, DUO, or QUAD)
- **L4TZZ.Z** = Jetson Linux (L4T) version

### Dependency Note

If not already installed, you may need to install libqt5core5a:

```bash
sudo apt install libqt5core5a
```

### Selecting the Correct Driver

1. **Identify your capture card model**: ZED Link Mono, Duo, or Quad
   - ZED Box Orin NX 8GB includes ZED Link Mono
   - ZED Box Orin NX 16GB includes ZED Link Duo

2. **Verify Jetson Linux version** running on your device

3. **For Jetpack 5 only**: Identify your camera model (ZED X, ZED X One GS, ZED X One 4K)
   - Hybrid camera configurations aren't supported with Jetpack 5.x (available from driver v1.1.0+ for Jetpack 6)

### Example Installation

For ZED Link Duo with two ZED X cameras on Jetson running L4T v35.4.1:

```bash
sudo dpkg -i stereolabs-zedx_1.0.5-ZED-LINK-DUO-L4T35.4.1_arm64.deb
```

### System Restart

After installation, reboot your device:

```bash
sudo reboot
```

### Verification

Confirm successful driver installation:

```bash
sudo dmesg | grep zedx
```

### Important Hardware Considerations

GMSL2 cameras have reduced flexibility compared to USB cameras. Any hardware configuration changes -- such as plugging/unplugging cameras or reordering them -- require either system reboot or daemon restart:

```bash
sudo systemctl restart zed_x_daemon
```

### Upgrading the Driver

To upgrade from a previous version or switch to a different camera model:

1. **Remove the current driver**:

```bash
sudo dpkg -r stereolabs-zedXXXX
```

2. **Find the exact package name**:

```bash
sudo dpkg -l | grep stereolabs
```

3. **Install the new driver** using the standard installation procedure above.

---

## Troubleshooting

### Camera Not Detected

GMSL2 cameras require specific handling compared to USB cameras. Any hardware configuration changes -- such as plugging/unplugging cameras or reordering them -- necessitate either rebooting the Jetson device or restarting the daemon:

```bash
sudo systemctl restart zed_x_daemon
```

### Upgrading ZED Link Driver

Before installing a newer driver version, remove the previous installation:

```bash
sudo dpkg -r stereolabs-<name>
```

To identify the correct package name:

```bash
sudo dpkg -l | grep stereolabs-
```

### Troubleshooting Commands

Use these commands for quick diagnostics:

```bash
sudo dmesg | grep zedx
```

Alternatively, employ the ZED Diagnostic tool:

```bash
sudo ./ZED_Diagnostic --dmesg
```

### Xavier NX / Orin NX MIPI Bandwidth Issues

The default MIPI lane configuration may exceed capacity depending on flat cable quality and length. While diagnostic reports show no errors, camera detection fails. Solutions include using shorter cables (maximum recommended: 7 cm) or adjusting MIPI lane speed.

#### Setting MIPI Lane Speed

**For 2 Gbps per lane:**

```bash
sudo i2cset -y -f 30 0x29 0x04 0x15 0x34 i
sudo i2cset -y -f 30 0x29 0x04 0x18 0x34 i
sudo i2cset -y -f 30 0x29 0x04 0x1B 0x34 i
sudo i2cset -y -f 30 0x29 0x04 0x1E 0x34 i
```

**For 1.6 Gbps per lane (if 2 Gbps is insufficient):**

```bash
sudo i2cset -y -f 30 0x29 0x04 0x15 0x30 i
sudo i2cset -y -f 30 0x29 0x04 0x18 0x30 i
sudo i2cset -y -f 30 0x29 0x04 0x1B 0x30 i
sudo i2cset -y -f 30 0x29 0x04 0x1E 0x30 i
```

> **Note**: These commands must be rerun after each reboot and after executing `sudo systemctl restart zed_x_daemon`.

### Blurry Images After System Update

System updates may overwrite patched libraries required by the ZED Link driver, causing image degradation. Restore functionality by manually reinstalling the patched library:

1. Download the latest ZED Link driver from the [ZED X Drivers page](https://www.stereolabs.com/developers/drivers).

2. Extract and restore the library:

```bash
mkdir temp_zedx
cd temp_zedx
ar x ../stereolabs-zed<model>_<version>-<deser>-<l4t_version>_arm64.deb
tar xvf data.tar.xz
sudo cp ./tmp/R<l4t_version>/libnvisppg.so /usr/lib/aarch64-linux-gnu/tegra/libnvisppg.so
```

Replace placeholders with actual filenames and L4T version (example: `R36.4.3`).

3. Reboot the device:

```bash
sudo reboot
```

### Contact Support

For unresolved issues, reach out to the [Stereolabs community](https://community.stereolabs.com/).
