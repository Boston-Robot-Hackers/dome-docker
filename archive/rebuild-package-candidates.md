# Rebuild Package Candidates

First-pass package inventory for recreating this microSD as a Docker image.

## Apt Package Sources

- Full currently installed dpkg list: `inventory/packages/dpkg-installed.tsv`
  - 2,266 installed packages with version and architecture.
  - Use this as evidence, not as a direct Docker install list.

- Manual/top-level apt packages: `inventory/packages/sudo-apt-install-candidates.txt`
  - 261 packages from `apt-mark showmanual`.
  - This is the main candidate list for `sudo apt install ...`.

- Auto-installed apt dependencies: `inventory/packages/apt-mark-auto.txt`
  - 1,993 packages.
  - Usually do not list these directly in a Dockerfile unless needed.

- Historical apt install commands: `inventory/packages/apt-install-commandlines.txt`
  - 48 unique `apt install` / `apt-get install` command lines from `/var/log/apt/history.log*`.
  - Useful for reconstructing intent.

- Shell-history install commands: `inventory/packages/shell-history-install-commands.txt`
  - 25 matching apt/pip install commands found in `/home/pitosalas/.bash_history`.
  - Useful for reconstructing recent manual work.

## Pip Package Sources

- User-level pip packages: `inventory/packages/pip3-install-user-candidates.txt`
  - 55 packages from `python3 -m pip list --user --format=freeze`.
  - This is the main candidate list for `pip3 install ...`.

- Full Python package freeze: `inventory/packages/pip3-freeze.txt`
  - 364 packages from `python3 -m pip list --format=freeze`.
  - Includes ROS/apt-provided Python packages and editable local packages, so do not blindly replay it with pip.

- Python dependency files found in source trees: `inventory/packages/python-dependency-files.txt`
  - 133 files including `requirements.txt`, `pyproject.toml`, `setup.py`, and `setup.cfg`.
  - These should be preferred over hand-installing packages when they belong to Git clones.

## Apt Install Command Candidates

These came from apt history and shell history. They should be reviewed and consolidated before turning into a Dockerfile.

Important: the current microSD evidence uses ROS 2 Jazzy package names. The rebuild target is now ROS 2 Kilted, so each selected `ros-jazzy-*` package below should be translated to the matching `ros-kilted-*` package where available.

```sh
apt install -y python3-venv build-essential cmake git curl software-properties-common
apt install -y ros-jazzy-desktop ros-dev-tools python3-colcon-common-extensions python3-pip
apt install -y git cmake meson ninja-build build-essential python3-pip python3-yaml python3-ply libboost-dev libgnutls28-dev openssl libjpeg-dev libtiff5-dev libpng-dev libdrm-dev libexpat1-dev libcamera-dev v4l-utils
apt install -y libavcodec-dev libavformat-dev libavutil-dev libswresample-dev
apt-get install -y cpufrequtils libraspberrypi-bin rt-tests cpuset stress stress-ng
apt-get install -y ros-jazzy-ros-base
apt-get install -y ros-jazzy-rviz2
apt-get install -y ros-jazzy-libcamera
apt install ros-jazzy-depthai-ros
apt install ros-jazzy-depthai ros-jazzy-depthai-ros-driver ros-jazzy-depthai-bridge ros-jazzy-depthai-examples
apt-get install -y ros-jazzy-ament-cmake-clang-format
apt-get install -y ros-jazzy-ament-cmake-mypy
apt-get install -y ros-jazzy-ament-cmake-pyflakes
apt-get install -y ros-jazzy-depthimage-to-laserscan
apt-get install -y ros-jazzy-imu-filter-madgwick ros-jazzy-robot-localization ros-jazzy-teleop-twist-keyboard ros-jazzy-tf2 ros-jazzy-tf2-ros python3-scipy ros-jazzy-xacro ros-jazzy-robot-state-publisher ros-jazzy-joint-state-publisher ros-jazzy-compressed-image-transport ros-jazzy-camera-info-manager
apt-get install -y ros-jazzy-imu-tools
apt-get install -y ros-jazzy-nav2-bringup
apt-get install -y ros-jazzy-rqt-image-view
apt install ros-jazzy-teleop-twist-joy
apt-get install ros-jazzy-navigation2
apt-get install ros-jazzy-laser-filters
apt-get install ros-jazzy-joy-linux
apt-get install ros-jazzy-camera-ros
apt-get install ros-jazzy-image-tools
apt install -u ros-jazzy-foxglove-bridge
apt install joystick
apt install net-tools
apt install ripgrep
apt install ffmpeg
apt install i2c-tools
apt install v4l-utils
apt install x11-apps
apt install alsa-utils
apt-get install portaudio19-dev libatlas-base-dev
apt install samba
apt install bubblewrap
apt-get install -y nodejs
```

Additional packages found in `/home/pitosalas/rosutils/dome/install_ros_packages.sh`, translated for Kilted:

```sh
apt-get install -y \
  ros-kilted-robot-calibration \
  ros-kilted-slam-toolbox \
  ros-kilted-tf-transformations \
  ros-kilted-rqt-graph \
  ros-kilted-nav2-rviz-plugins \
  ros-kilted-rviz-imu-plugin \
  python3-opencv
```

## Pip Install Command Candidates

These came from shell history and current user-level pip packages. Prefer package-local `requirements.txt` / `pyproject.toml` when the dependency belongs to a Git clone.

```sh
pip3 install roboflowoak
pip3 install opencv-python
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install --upgrade roboflowoak depthai requests urllib3
python3 -m pip install "depthai<3.0.0"
pip3 install ty
pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cpu
pip3 install -e .
```

Do not use `pip3 install -r requirements.txt` for `better_launch`; it is a regular ROS 2 package and should be built by `colcon`.

## Current User-Level Pip Packages

See `inventory/packages/pip3-install-user-candidates.txt` for exact versions. Notable candidates:

- `depthai==2.32.0.0`
- `depthai-sdk==1.15.1`
- `depthai-nodes==0.3.4`
- `opencv-python==4.13.0.92`
- `opencv-contrib-python==4.11.0.86`
- `opencv-python-headless==4.10.0.84`
- `roboflowoak==0.0.12`
- `torch==2.11.0+cpu`
- `torchvision==0.26.0+cpu`
- `PyAudio==0.2.14`
- `RPi.GPIO==0.7.1`
- `spidev==3.8`
- `ty==0.0.32`

## Review Notes

- Do not install all 2,266 dpkg packages directly. Start with manual packages and historical install commands.
- Do not blindly replay full `pip3-freeze.txt`; it includes packages installed by apt/ROS and local editable packages.
- For Git clones, prefer running their documented install steps or dependency files after cloning.
- Later pass should consolidate duplicate ROS package installs, translate selected ROS packages from Jazzy to Kilted, verify availability, and remove packages that only supported one-time experiments.
