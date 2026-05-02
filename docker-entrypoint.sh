#!/usr/bin/env bash
set -e

source "/opt/ros/${ROS_DISTRO:-kilted}/setup.bash"

if [[ -f "${DOME_HOME:-$HOME}/ros2_ws/install/setup.bash" ]]; then
  source "${DOME_HOME:-$HOME}/ros2_ws/install/setup.bash"
fi

exec "$@"
