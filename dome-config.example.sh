#!/usr/bin/env bash

# Copy this file to dome-config.sh and edit it for your robot before running
# host setup or Docker builds:
#
#   cp dome-config.example.sh dome-config.sh
#   nano dome-config.sh
#   source ./dome-config.sh

_MANIFEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/manifest"
_ROS_DISTRO=$(grep '^ROS_DISTRO=' "${_MANIFEST_DIR}/config.txt" | cut -d= -f2)

# User created or configured on the Pi host and inside the Docker image.
export DOME_USER="${DOME_USER:-robot}"

# Optional password for DOME_USER. Leave empty to preserve an existing host
# password from cloud-init or Raspberry Pi Imager. If used for Docker image
# builds, the value is baked into the image and may be visible in local image
# metadata or build logs. Do not commit real passwords.
export DOME_PASSWORD="${DOME_PASSWORD:-}"

# Image names derived from ROS_DISTRO in manifest/config.txt.
export DOME_BASE_IMAGE="${DOME_BASE_IMAGE:-dome-docker-base:${_ROS_DISTRO}}"
export DOME_IMAGE="${DOME_IMAGE:-dome-docker:dome-${_ROS_DISTRO}}"

# Repository URL for cloning this public setup repo onto a fresh Pi.
export DOME_DOCKER_REPO_URL="${DOME_DOCKER_REPO_URL:-https://github.com/Boston-Robot-Hackers/dome-docker.git}"

# SSH key settings used by pi-build.sh.
export DOME_SSH_KEY="${DOME_SSH_KEY:-${HOME}/.ssh/id_ed25519}"
export DOME_SSH_KEY_COMMENT="${DOME_SSH_KEY_COMMENT:-${USER:-robot}@$(hostname -s 2>/dev/null || echo dome)}"
