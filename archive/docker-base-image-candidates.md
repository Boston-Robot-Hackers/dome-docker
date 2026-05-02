# Docker Base Image Candidates

First-pass survey of Docker Hub starting points for the Raspberry Pi microSD rebuild.

## Best Starting Candidates

## Host OS Target

For the replacement microSD card itself, use the latest Ubuntu Server LTS image for Raspberry Pi 5:

```text
Ubuntu Server 24.04.4 LTS for Raspberry Pi 5, 64-bit, headless
```

Rationale:

- Ubuntu's Raspberry Pi download page lists Ubuntu Server 24.04.4 LTS as the current LTS server image.
- Raspberry Pi 5 is certified for Ubuntu 24.04 LTS.
- Ubuntu 25.10 is also listed for Raspberry Pi 5, but it is an interim release with short support.
- ROS 2 Kilted targets Ubuntu Noble 24.04 on arm64, so using 24.04 LTS keeps host OS, Docker base, and ROS packages aligned.

This means the Docker image should generally target Ubuntu Noble as well, even if built from a ROS base image.

### 1. `ros:kilted-ros-base-noble` or `ros:kilted`

- `[ ]` Primary candidate for the rebuild.
- Why:
  - Matches the revised target ROS 2 distribution: Kilted.
  - Built on Ubuntu Noble, matching Ubuntu 24.04.
  - Available for `arm64v8 / aarch64`.
  - Gives us ROS packaging and environment conventions immediately.
- Tradeoff:
  - We still need to add Raspberry Pi camera/libcamera, DepthAI/OAK, robot packages, udev/runtime device access, and local Git clones.
  - The current microSD was observed using Jazzy, so package availability and source compatibility must be checked against Kilted.

Useful variants:

```sh
docker pull ros:kilted-ros-core-noble
docker pull ros:kilted-ros-base-noble
docker pull ros:kilted-perception-noble
docker pull ros:kilted
```

Initial preference: `ros:kilted-ros-base-noble`.

### 2. `ubuntu:24.04`

- `[ ]` Clean fallback candidate.
- Why:
  - Official Ubuntu image.
  - Has `linux/arm64/v8` support.
  - Small and predictable.
- Tradeoff:
  - Requires us to recreate ROS apt sources and install ROS from scratch.
  - More Dockerfile work, less leverage than `ros:kilted-*`.

Useful variant:

```sh
docker pull ubuntu:24.04
```

### 3. `osrf/ros:kilted-desktop` or `osrf/ros:kilted-desktop-full`

- `[ ]` Candidate only if GUI tools like RViz are central inside the container.
- Why:
  - Includes heavier desktop/GUI ROS tooling.
  - May reduce setup for RViz, simulation, or GUI debugging.
- Tradeoff:
  - Larger image.
  - May not support all architectures as broadly as the official `ros:*` images; verify before choosing for Pi.

Useful variants:

```sh
docker pull osrf/ros:kilted-desktop
docker pull osrf/ros:kilted-desktop-full
```

## DepthAI / OAK Related Images

### `luxonis/depthai-library`

- `[?]` Reference image, not yet preferred as base.
- Why:
  - Official Luxonis docs say this image contains DepthAI, dependencies, and helpful tools.
  - Good source of Docker runtime patterns for OAK USB and OAK PoE access.
- Tradeoff:
  - Not obviously aligned with ROS 2 Kilted/Noble as the primary base.
  - We now want ROS/Kilted as the central system shape.

Runtime clues from Luxonis docs:

```sh
--privileged
-v /dev/bus/usb:/dev/bus/usb
--device-cgroup-rule='c 189:* rmw'
--network=host   # for OAK PoE
```

### `luxonis/depthai-base`

- `[?]` Reference image.
- Why:
  - Luxonis base image for DepthAI development dependencies.
- Tradeoff:
  - Docker Hub page indicates it is old, so it is probably not a good modern base for this ROS 2 Kilted rebuild.

### `luxonis/depthai-ros:*`

- `[?]` Investigate later if a Kilted/arm64 tag exists.
- Current shallow signal:
  - Found a `humble-arm64-latest` layer, which is useful evidence for ROS + DepthAI on arm64.
  - Humble does not match the Kilted target.

## Raspberry Pi Camera / Libcamera Candidates

### ROS package route inside `ros:kilted-*`

- `[ ]` Preferred first approach.
- Install/add:
  - `ros-kilted-libcamera`
  - `ros-kilted-camera-ros`
  - `libcamera` / `rpicam-apps` dependencies as needed
- Why:
  - The existing microSD has ROS Jazzy libcamera packages plus locally built Raspberry Pi camera libraries.
  - Starting from ROS Kilted and adding camera pieces keeps the target dependency tree coherent.
  - Each `ros-kilted-*` camera package must be verified because the observed package names came from Jazzy.

### Third-party Raspberry Pi camera images

- `[?]` Reference only unless one exactly matches Kilted + arm64 + libcamera.
- Found examples around Raspberry Pi Camera Module 3 and ROS Humble, but Humble is not our target.

## Current Recommendation

Start from:

```Dockerfile
FROM ros:kilted-ros-base-noble
```

Then layer in:

1. Apt packages from `rebuild-package-candidates.md`.
2. Raspberry Pi camera/libcamera packages.
3. DepthAI/OAK dependencies and runtime device rules.
4. Git clones from `docker-rebuild-candidates.md`.
5. Colcon build steps for the selected ROS workspaces.

Host-side setup outside the Docker image still needs:

- Netplan configuration from `/etc/netplan`
- User account provisioning:
  - Create user `pitosalas`.
  - Set initial password to `daniel`.
  - Grant full sudo privileges.
- Docker installation and service enablement
- Device permissions, udev rules, and any systemd services needed before the container starts

Keep `ubuntu:24.04` as the fallback if the official ROS image hides too much or blocks the Raspberry Pi camera stack.

## Sources Checked

- Docker Hub official Ubuntu `24.04` tag: https://hub.docker.com/_/ubuntu/tags?name=24.04
- Ubuntu Raspberry Pi downloads: https://ubuntu.com/download/raspberry-pi
- Raspberry Pi 5 Ubuntu 24.04 LTS certification: https://ubuntu.com/certified/202310-32202
- ROS Kilted release notes: https://docs.ros.org/en/rolling/Releases/Release-Kilted-Kaiju.html
- ROS Kilted Ubuntu deb install docs: https://docs.ros.org/en/kilted/Installation/Ubuntu-Install-Debs.html
- OSRF Docker image definitions: https://github.com/osrf/docker_images
- Luxonis DepthAI Docker documentation: https://docs.luxonis.com/software/depthai/manual-install
- Luxonis `depthai-base` Docker Hub page: https://hub.docker.com/r/luxonis/depthai-base
- ROS `camera_ros` docs for Kilted should be checked during package verification.
