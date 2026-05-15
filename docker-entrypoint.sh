#!/usr/bin/env bash
# Container entrypoint: sources ROS and workspace overlays, then execs the given command.
set -e

source "/opt/ros/${ROS_DISTRO:-kilted}/setup.bash"

if [[ -f "${DOME_HOME:-$HOME}/ros2_ws/install/setup.bash" ]]; then
  source "${DOME_HOME:-$HOME}/ros2_ws/install/setup.bash"
fi

exec "$@"
