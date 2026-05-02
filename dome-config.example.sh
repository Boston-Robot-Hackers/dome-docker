#!/usr/bin/env bash

# Copy this file to dome-config.sh and edit it for your robot before running
# host setup or Docker builds:
#
#   cp dome-config.example.sh dome-config.sh
#   nano dome-config.sh
#   source ./dome-config.sh

# User created or configured on the Pi host and inside the Docker image.
export DOME_USER="${DOME_USER:-robot}"

# Optional password for DOME_USER. Leave empty to preserve an existing host
# password from cloud-init or Raspberry Pi Imager. If used for Docker image
# builds, the value is baked into the image and may be visible in local image
# metadata or build logs. Do not commit real passwords.
export DOME_PASSWORD="${DOME_PASSWORD:-}"

# Image name used by Docker Compose.
export DOME_IMAGE="${DOME_IMAGE:-dome-docker:dome-kilted}"

# Generic base image containing ROS Kilted and shared system dependencies.
export DOME_BASE_IMAGE="${DOME_BASE_IMAGE:-dome-docker-base:kilted}"

# Repository URL for cloning this public setup repo onto a fresh Pi.
export DOME_DOCKER_REPO_URL="${DOME_DOCKER_REPO_URL:-https://github.com/Boston-Robot-Hackers/dome-docker.git}"

# SSH key settings used by pi-build.sh.
export DOME_SSH_KEY="${DOME_SSH_KEY:-${HOME}/.ssh/id_ed25519}"
export DOME_SSH_KEY_COMMENT="${DOME_SSH_KEY_COMMENT:-${USER:-robot}@$(hostname -s 2>/dev/null || echo dome)}"

# Semicolon-separated "repo_url destination_dir" entries cloned during Docker
# build. Use SSH URLs for private repositories after adding the Pi public key to
# GitHub.
export DOME_ROOT_REPOS="${DOME_ROOT_REPOS:-https://github.com/Seeed-Studio/seeed-linux-dtoverlays.git seeed-linux-dtoverlays;https://github.com/raspberrypi/libcamera-apps.git libcamera-apps}"
export DOME_ROS_REPOS="${DOME_ROS_REPOS:-https://github.com/dfki-ric/better_launch.git better_launch;https://github.com/hippo5329/ldlidar_stl_ros2.git ldlidar_stl_ros2;https://github.com/micro-ROS/micro-ROS-Agent.git micro-ROS-Agent;https://github.com/micro-ROS/micro_ros_msgs.git micro_ros_msgs;https://github.com/christianrauch/camera_ros.git camera_ros}"
export DOME_UROS_REPOS="${DOME_UROS_REPOS:-https://github.com/micro-ROS/micro-ROS-Agent.git micro-ROS-Agent;https://github.com/micro-ROS/micro_ros_msgs.git micro_ros_msgs}"
