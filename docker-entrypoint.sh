#!/usr/bin/env bash
set -e

source /opt/ros/kilted/setup.bash

if [[ -f /home/pitosalas/ros2_ws/install/setup.bash ]]; then
  source /home/pitosalas/ros2_ws/install/setup.bash
fi

exec "$@"
