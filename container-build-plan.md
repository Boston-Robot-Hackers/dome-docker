# Container Build Plan

Target base:

```Dockerfile
FROM ros:kilted-ros-base-noble
```

This container holds the ROS/application stack. Host networking, udev, Docker installation, and hardware permissions stay in the host provisioning layer.

## 1. Base Setup

Install common build and runtime tools:

```sh
apt-get update
apt-get install -y \
  build-essential \
  cmake \
  curl \
  git \
  iproute2 \
  iptables \
  iputils-ping \
  jq \
  make \
  meson \
  micro \
  nano \
  netcat-openbsd \
  ninja-build \
  python3-colcon-common-extensions \
  python3-pip \
  python3-venv \
  python3-yaml \
  ripgrep \
  software-properties-common \
  tar \
  wget
```

## 2. ROS Kilted Packages

Verified key Kilted packages are listed in `archive/ros-kilted-package-verification.md`.

Candidate package group:

```sh
apt-get install -y \
  ros-kilted-ros-base \
  ros-kilted-rviz2 \
  ros-kilted-libcamera \
  ros-kilted-camera-ros \
  ros-kilted-depthai \
  ros-kilted-depthai-ros \
  ros-kilted-depthai-ros-driver \
  ros-kilted-depthai-bridge \
  ros-kilted-depthai-examples \
  ros-kilted-diagnostic-updater \
  ros-kilted-diagnostics \
  ros-kilted-nav2-bringup \
  ros-kilted-navigation2 \
  ros-kilted-slam-toolbox \
  ros-kilted-depthimage-to-laserscan \
  ros-kilted-foxglove-bridge \
  ros-kilted-imu-filter-madgwick \
  ros-kilted-imu-tools \
  ros-kilted-robot-calibration \
  ros-kilted-robot-localization \
  ros-kilted-robot-state-publisher \
  ros-kilted-joint-state-publisher \
  ros-kilted-joy-teleop \
  ros-kilted-teleop-twist-joy \
  ros-kilted-teleop-twist-keyboard \
  ros-kilted-tf2 \
  ros-kilted-tf2-ros \
  ros-kilted-xacro \
  ros-kilted-compressed-image-transport \
  ros-kilted-camera-info-manager \
  ros-kilted-tf-transformations \
  ros-kilted-rqt-graph \
  ros-kilted-nav2-rviz-plugins \
  ros-kilted-rviz-imu-plugin \
  ros-kilted-rqt-image-view \
  ros-kilted-laser-filters \
  ros-kilted-joy-linux \
  ros-kilted-image-tools \
  python3-opencv
```

This list should be pruned before final Dockerfile generation.

Additional optional ROS 1-era equivalents from `Dockerfile-old`, not included by default:

- TurtleBot3 simulation/support:
  - `ros-kilted-turtlebot3`
  - `ros-kilted-turtlebot3-msgs`
  - `ros-kilted-turtlebot3-gazebo`
  - `ros-kilted-turtlebot3-teleop`
  - `ros-kilted-turtlebot3-simulations`
- Dynamixel:
  - `ros-kilted-dynamixel-sdk`
- Old YDLidar/linorobot ROS 1 repos:
  - Need ROS 2 replacement review before adding.

## 3. Camera / Native Libraries

Current microSD has locally built Raspberry Pi camera components under `/usr/local`, and source trees:

- `/home/pitosalas/libcamera`
- `/home/pitosalas/libcamera-apps`
- `/home/pitosalas/libpisp`

First strategy:

- Prefer Kilted/Ubuntu packages where they work.
- Build from these Git repos only if required for Raspberry Pi 5 camera behavior.

## 4. Git Clone Set

Clone selected repositories instead of copying their files.

Required/included so far:

```sh
git clone git@github.com:campusrover/rosutils.git /home/pitosalas/rosutils
```

`/home/pitosalas/rosutils/dome/*.sh` was inspected and contributes:

- Dome repo set: `dome`, `linorobot2`, `control`, `ros2diag`, `better_launch`, `ldlidar_stl_ros2`.
- `better_launch` is a regular ROS 2 package and should be built by `colcon`; do not special-case it with `pip install`.
- Additional ROS packages now included above:
  - `ros-kilted-robot-calibration`
  - `ros-kilted-slam-toolbox`
  - `ros-kilted-tf-transformations`
  - `ros-kilted-rqt-graph`
  - `ros-kilted-nav2-rviz-plugins`
  - `ros-kilted-rviz-imu-plugin`
  - `ros-kilted-diagnostic-updater`
  - `ros-kilted-diagnostics`
  - `ros-kilted-joy-teleop`
  - `python3-opencv`

`Dockerfile-old` was inspected and contributes useful modernized ideas:

- General CLI/network tools: `nano`, `micro`, `wget`, `tar`, `make`, `iptables`, `iproute2`, `iputils-ping`, `netcat-openbsd`, `jq`.
- `rosutils/bashrc_template.bash` confirms `bru.py` and common aliases are part of the expected workflow, though the old template sources ROS Noetic and must not be copied verbatim.
- `bru.py` should be executable and available on `PATH`.
- Tailscale and code-server were present in the old image but are not included by default in this first Kilted draft.
- Old Noetic/TurtleBot/YDLidar/linorobot repos are review candidates only; do not add them without checking ROS 2/Kilted relevance.

The current Dockerfile now adds:

```sh
source /home/pitosalas/rosutils/common_alias.bash
ln -s /home/pitosalas/rosutils/bru.py /home/pitosalas/.local/bin/bru
```

ROS workspace clone candidates:

```sh
mkdir -p /home/pitosalas/ros2_ws/src
git clone https://github.com/micro-ROS/micro-ROS-Agent.git /home/pitosalas/ros2_ws/src/micro-ROS-Agent
git clone git@github.com:Boston-Robot-Hackers/explore.git /home/pitosalas/ros2_ws/src/explore
git clone git@github.com:Boston-Robot-Hackers/oak-roboflow.git /home/pitosalas/ros2_ws/src/oak_roboflow
git clone https://github.com/christianrauch/camera_ros.git /home/pitosalas/ros2_ws/src/camera_ros
git clone git@github.com:campusrover/dome.git /home/pitosalas/ros2_ws/src/dome
git clone https://github.com/dfki-ric/better_launch.git /home/pitosalas/ros2_ws/src/better_launch
git clone https://github.com/micro-ROS/micro_ros_msgs.git /home/pitosalas/ros2_ws/src/micro_ros_msgs
git clone git@github.com:Boston-Robot-Hackers/ros2diag.git /home/pitosalas/ros2_ws/src/ros2diag
git clone https://github.com/hippo5329/ldlidar_stl_ros2.git /home/pitosalas/ros2_ws/src/ldlidar_stl_ros2
git clone git@github.com:pitosalas/status_panel.git /home/pitosalas/ros2_ws/src/status_panel
git clone git@github.com:pitosalas/control.git /home/pitosalas/ros2_ws/src/control
git clone git@github.com:pitosalas/linorobot2.git /home/pitosalas/ros2_ws/src/linorobot2
```

Top-level optional clone candidates:

```sh
git clone https://github.com/Seeed-Studio/seeed-linux-dtoverlays.git /home/pitosalas/seeed-linux-dtoverlays
git clone https://github.com/raspberrypi/libcamera-apps.git /home/pitosalas/libcamera-apps
git clone https://github.com/pitosalas/linorobot2_hardware /home/pitosalas/linorobot2_hardware
git clone https://github.com/luxonis/oak-examples.git /home/pitosalas/oak-examples
git clone https://github.com/raspberrypi/libpisp.git /home/pitosalas/libpisp
git clone https://github.com/raspberrypi/libcamera.git /home/pitosalas/libcamera
git clone https://github.com/luxonis/depthai-python.git /home/pitosalas/depthai-python
git clone https://github.com/respeaker/mic_hat.git /home/pitosalas/mic_hat
```

Next pass should decide which SSH URLs need HTTPS equivalents for automated builds.

## 5. Pip Dependencies

Start from package-local dependency files after cloning.

User-level pip candidates from current card:

- `depthai==2.32.0.0`
- `depthai-sdk==1.15.1`
- `depthai-nodes==0.3.4`
- `opencv-python==4.13.0.92`
- `opencv-contrib-python==4.11.0.86`
- `roboflowoak==0.0.12`
- `torch==2.11.0+cpu`
- `torchvision==0.26.0+cpu`
- `PyAudio==0.2.14`
- `RPi.GPIO==0.7.1`
- `spidev==3.8`
- `ty==0.0.32`

Do not blindly install full `pip3-freeze.txt`.

## 6. Workspace Build

Candidate build sequence:

```sh
source /opt/ros/kilted/setup.bash
cd /home/pitosalas/ros2_ws
rosdep update
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
```

Potential issue:

- `rosdep update` needs network access during image build.
- Some packages may need source changes for Kilted compatibility.

## 7. Runtime Entrypoint

Container startup should source:

```sh
source /opt/ros/kilted/setup.bash
source /home/pitosalas/ros2_ws/install/setup.bash
```

Runtime command is still undecided. Candidate modes:

- Interactive development shell.
- Launch main robot bringup.
- Launch specific camera/OAK pipeline.

## 8. Things Not To Bake Into The Image

- Netplan.
- Docker installation.
- Host user password.
- Udev reload commands.
- Device-specific logs and caches.
- Secrets and SSH private keys.
