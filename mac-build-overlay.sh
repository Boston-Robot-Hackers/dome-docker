#!/usr/bin/env bash
set -euo pipefail

if [[ -f ./dome-config.sh ]]; then
  # shellcheck disable=SC1091
  source ./dome-config.sh
fi

DOME_BASE_IMAGE="${DOME_BASE_IMAGE:-dome-docker-base:kilted}"
DOME_IMAGE="${DOME_IMAGE:-dome-docker:dome-kilted}"
DOME_CONTAINER_USER="${DOME_CONTAINER_USER:-robot}"
DOME_ROOT_REPOS="${DOME_ROOT_REPOS:-https://github.com/Seeed-Studio/seeed-linux-dtoverlays.git seeed-linux-dtoverlays;https://github.com/raspberrypi/libcamera-apps.git libcamera-apps}"
DOME_ROS_REPOS="${DOME_ROS_REPOS:-https://github.com/dfki-ric/better_launch.git better_launch;https://github.com/hippo5329/ldlidar_stl_ros2.git ldlidar_stl_ros2;https://github.com/micro-ROS/micro-ROS-Agent.git micro-ROS-Agent;https://github.com/micro-ROS/micro_ros_msgs.git micro_ros_msgs;https://github.com/christianrauch/camera_ros.git camera_ros}"
DOME_UROS_REPOS="${DOME_UROS_REPOS:-https://github.com/micro-ROS/micro-ROS-Agent.git micro-ROS-Agent;https://github.com/micro-ROS/micro_ros_msgs.git micro_ros_msgs}"

DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/arm64 \
  --ssh default="${SSH_AUTH_SOCK}" \
  --push \
  --build-arg "DOME_BASE_IMAGE=${DOME_BASE_IMAGE}" \
  --build-arg "DOME_CONTAINER_USER=${DOME_CONTAINER_USER}" \
  --build-arg "DOME_ROOT_REPOS=${DOME_ROOT_REPOS}" \
  --build-arg "DOME_ROS_REPOS=${DOME_ROS_REPOS}" \
  --build-arg "DOME_UROS_REPOS=${DOME_UROS_REPOS}" \
  -t "${DOME_IMAGE}" .
