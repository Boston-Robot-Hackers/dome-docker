#!/usr/bin/env bash
# Container entrypoint: sources ROS and workspace overlays, then execs the given command.
set -e

source "/opt/ros/${ROS_DISTRO}/setup.bash"
source "${DOME_HOME}/ros2_ws/install/setup.bash"

exec "$@"
