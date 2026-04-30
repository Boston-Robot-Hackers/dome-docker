# Docker Rebuild Candidate Checklist

First-pass checklist for deciding what belongs in the rebuilt Docker image.

Legend for review:

- `[ ]` undecided
- `[x]` include
- `[-]` exclude / runtime leftover
- `[?]` investigate in next pass

## Base Image / Platform

- `[x]` Ubuntu 24.04.4 LTS Noble, arm64/aarch64
- `[x]` ROS 2 Kilted target for the rebuild.
  - Current microSD evidence is ROS 2 Jazzy under `/opt/ros/jazzy`.
  - Rebuild should translate selected ROS package candidates from `ros-jazzy-*` to `ros-kilted-*` where available.
- `[x]` Raspberry Pi camera stack and local camera libraries from `/usr/local`
- `[x]` Real-time Raspberry Pi tuning assets from `/opt/ros2-rt-rpi4`

## ROS Workspaces

- `[x]` `/home/pitosalas/ros2_ws`
  - Primary ROS 2 workspace candidate.
  - Source packages found:
    - `micro-ROS-Agent`
    - `explore`
    - `oak_roboflow`
    - `camera_ros`
    - `dome`
    - `depthai_rospi`
    - `better_launch`
    - `micro_ros_msgs`
    - `ros2diag`
    - `ldlidar_stl_ros2`
    - `status_panel`
    - `control`
    - `linorobot2`
  - Likely exclude from image source copy: `build/`, `install/`, `log/`, `.pytest_cache/`, `__pycache__/`.

- `[x]` `/home/pitosalas/uros_ws`
  - Appears to be a smaller micro-ROS workspace.
  - Source packages found:
    - `micro-ROS-Agent`
    - `micro_ros_msgs`
  - May be duplicate of packages already in `ros2_ws`.

- `[-]` `/home/pitosalas/test_ws`
  - Contains `better_launch`.
  - Likely test/experiment workspace unless you mark it needed.

- `[-]` `/home/pitosalas/install` and `/home/pitosalas/build`
  - Looks like colcon build/install output for `dome` and `depthai_rospi`.
  - Candidate only as evidence of build process, not content to copy directly.

## Git Repositories To Recreate By Clone

These directories should be recreated with `git clone` commands, not by copying their individual files from this microSD. Later passes should decide whether to pin branches, tags, or exact commits, and whether any local uncommitted changes need separate patch handling.

Top-level home repositories:

- `[x]` `https://github.com/Seeed-Studio/seeed-linux-dtoverlays.git` -> `/home/pitosalas/seeed-linux-dtoverlays`
- `[x]` `https://github.com/raspberrypi/libcamera-apps.git` -> `/home/pitosalas/libcamera-apps`
- `[x]` `https://github.com/pitosalas/linorobot2_hardware` -> `/home/pitosalas/linorobot2_hardware`
- `[x]` `git@github.com:campusrover/rosutils.git` -> `/home/pitosalas/rosutils`
- `[ ]` `https://github.com/luxonis/oak-examples.git` -> `/home/pitosalas/oak-examples`
- `[ ]` `https://github.com/raspberrypi/libpisp.git` -> `/home/pitosalas/libpisp`
- `[ ]` `https://github.com/raspberrypi/libcamera.git` -> `/home/pitosalas/libcamera`
- `[ ]` `https://github.com/luxonis/depthai-python.git` -> `/home/pitosalas/depthai-python`
- `[ ]` `https://github.com/respeaker/mic_hat.git` -> `/home/pitosalas/mic_hat`

ROS workspace repositories:

- `[x]` `https://github.com/micro-ROS/micro-ROS-Agent.git` -> `/home/pitosalas/ros2_ws/src/micro-ROS-Agent`
- `[x]` `git@github.com:Boston-Robot-Hackers/explore.git` -> `/home/pitosalas/ros2_ws/src/explore`
- `[x]` `git@github.com:Boston-Robot-Hackers/oak-roboflow.git` -> `/home/pitosalas/ros2_ws/src/oak_roboflow`
- `[x]` `https://github.com/christianrauch/camera_ros.git` -> `/home/pitosalas/ros2_ws/src/camera_ros`
- `[x]` `git@github.com:campusrover/dome.git` -> `/home/pitosalas/ros2_ws/src/dome`
- `[x]` `https://github.com/slgrobotics/depthai_rospi.git` -> `/home/pitosalas/ros2_ws/src/depthai_rospi`
- `[x]` `https://github.com/dfki-ric/better_launch.git` -> `/home/pitosalas/ros2_ws/src/better_launch`
- `[x]` `https://github.com/micro-ROS/micro_ros_msgs.git` -> `/home/pitosalas/ros2_ws/src/micro_ros_msgs`
- `[x]` `git@github.com:Boston-Robot-Hackers/ros2diag.git` -> `/home/pitosalas/ros2_ws/src/ros2diag`
- `[x]` `https://github.com/hippo5329/ldlidar_stl_ros2.git` -> `/home/pitosalas/ros2_ws/src/ldlidar_stl_ros2`
- `[x]` `git@github.com:pitosalas/status_panel.git` -> `/home/pitosalas/ros2_ws/src/status_panel`
- `[x]` `git@github.com:pitosalas/control.git` -> `/home/pitosalas/ros2_ws/src/control`
- `[x]` `git@github.com:pitosalas/linorobot2.git` -> `/home/pitosalas/ros2_ws/src/linorobot2`

Possible duplicate workspace repositories:

- `[x]` `https://github.com/micro-ROS/micro-ROS-Agent.git` -> `/home/pitosalas/uros_ws/src/micro-ROS-Agent`
- `[x]` `https://github.com/micro-ROS/micro_ros_msgs.git` -> `/home/pitosalas/uros_ws/src/micro_ros_msgs`
- `[x]` `https://github.com/dfki-ric/better_launch.git` -> `/home/pitosalas/test_ws/src/better_launch`

## Local Non-Git Code / Data Candidates

These are candidates for file-copy or archive handling only when they are not Git clones. If a directory is later found to contain `.git`, move it to the clone list instead.

- `[-]` `/home/pitosalas/play-oak`
  - Local OAK experiments and scripts.
  - Contains Python scripts, markdown notes, and dataset captures.
  - Dataset capture directories may be runtime data, not image content.

- `[x]` `/home/pitosalas/.control`
  - Contains `maps/` and `logs/`.
  - Maps may be needed; logs likely excluded.

- `[x]` `/home/pitosalas/.ros/camera_info`
  - Camera calibration/config candidate.

- `[x]` `/home/pitosalas/.ros/rosdep`
  - Probably cache/state, likely exclude unless it reveals required rosdep setup.

## System Configuration Candidates

- `[x]` host user account `pitosalas`
  - Initial password: `daniel`
  - Full sudo privileges
- `[x]` netplan configuration from `/etc/netplan`
- `[x]` `/etc/systemd/system/memory-compaction.service`
- `[x]` `/etc/systemd/system/rt-throttling.service`
- `[x]` `/opt/ros2-rt-rpi4/rt-throttling`
- `[x]` `/opt/ros2-rt-rpi4/memory-compaction`
- `[x]` udev rules for sensors/cameras/lidar, if present
- `[x]` shell setup files that source ROS workspaces or define robot environment
  - Include `/home/pitosalas/.bashrc`.
  - Also review `.profile`, `.bash_aliases`, shell-specific config, and any scripts sourced from those files.
- `[x]` network/device permissions needed for OAK, camera, lidar, microcontroller, or GPIO access

## Python / Tooling Candidates

- `[x]` Python 3.12 environment and installed packages
- `[x]` DepthAI / Luxonis tooling
- `[x]` Roboflow-related dependencies
- `[x]` PlatformIO, if microcontroller firmware builds are part of the image
- `[x]` ROS build tooling: `colcon`, `rosdep`, `vcs`, compiler toolchain
- `[x]` User-level CLI tools from `/home/pitosalas/.local/bin`

## Package Install Candidates

- `[?]` Apt package candidates are captured in `rebuild-package-candidates.md`.
  - Main apt candidate file: `inventory/packages/sudo-apt-install-candidates.txt`.
  - Historical install commands: `inventory/packages/apt-install-commandlines.txt`.
  - Full dpkg evidence: `inventory/packages/dpkg-installed.tsv`.

- `[?]` Pip package candidates are captured in `rebuild-package-candidates.md`.
  - Main pip candidate file: `inventory/packages/pip3-install-user-candidates.txt`.
  - Full Python environment evidence: `inventory/packages/pip3-freeze.txt`.
  - Source dependency files: `inventory/packages/python-dependency-files.txt`.

## Likely Exclusions Unless You Say Otherwise

- `~/.cache`
- `~/.npm/_cacache`
- `~/.pytest_cache`
- `~/.vscode-server`
- `~/.claude`
- `~/.codex`
- `~/.copilot`
- build logs under `~/log`
- ROS/colcon `build/`, `install/`, `log/` directories
- Python `__pycache__/`
- dataset captures and generated images unless selected explicitly

## Deferred Until After Your Review

- Full apt package list filtering.
- Full pip/package inventory.
- Exact branch/tag/SHA pinning for every Git clone.
- Dirty working tree detection and local-only patch capture.
- Secret/config review.
- Device mount and Docker runtime flag design.
- Actual Dockerfile and compose file generation.
