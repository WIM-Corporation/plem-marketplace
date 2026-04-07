# Peripheral Mapping — Model → Vendor Package

Reference mapping table used by plem-init when generating `.repos` files.
Determines which git repositories are required based on the model selected by the user.

## Robot Models

| Vendor | Model | Package | Repository |
|--------|-------|---------|------------|
| neuromeka | indy7 | `neuromeka_description` | `plem-neuromeka` |
| neuromeka | indy7_v2 | `neuromeka_description` | `plem-neuromeka` |
| neuromeka | indy12 | `neuromeka_description` | `plem-neuromeka` |
| neuromeka | indy12_v2 | `neuromeka_description` | `plem-neuromeka` |

## Gripper Models

| Model | Vendor | Description Package | Driver Package | Repository |
|-------|--------|-------------------|----------------|------------|
| rg6 | OnRobot | `onrobot_description` | `neuromeka_onrobot_driver` | `plem-onrobot` (description) + `plem-neuromeka` (driver) |

**Auto-launch:** When `gripper:=rg6` is specified, the driver node is automatically started via the `gripper_drivers.yaml` mapping.

## Camera Models

| Model | Vendor | Description Package | Driver | Repository |
|-------|--------|-------------------|--------|------------|
| zedxm | Stereolabs | `stereolabs_description` | **external** (zed-ros2-wrapper) | `plem-stereolabs` (description only) |

**Note:** The camera description package provides only URDF/TF frames. A separate driver installation is required to receive camera image streams. See `zed-driver-setup.md`.

## .repos Generation Rules

```yaml
repositories:
  # always included
  plem-msgs:
    type: git
    url: https://github.com/WIM-Corporation/plem-msgs.git
    version: master

  # only when plem_install=source (internal dev only; default=apt, omitted)
  # plem:
  #   type: git
  #   url: https://github.com/WIM-Corporation/plem.git
  #   version: master

  # robot_vendor=neuromeka
  plem-neuromeka:
    type: git
    url: https://github.com/WIM-Corporation/plem-neuromeka.git
    version: master

  # gripper is OnRobot family (rg6)
  plem-onrobot:
    type: git
    url: https://github.com/WIM-Corporation/plem-onrobot.git
    version: master

  # camera is Stereolabs family (zedxm)
  plem-stereolabs:
    type: git
    url: https://github.com/WIM-Corporation/plem-stereolabs.git
    version: master
```

## Adding New Peripherals

Adding an entry to this mapping table will make it automatically supported by plem-init.
Use the `/plem-extend` skill to add the peripheral itself.
