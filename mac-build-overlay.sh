#!/usr/bin/env bash
# Builds and pushes the robot overlay image for linux/arm64 from a Mac.
# Reads ROS_DISTRO from manifest/config.txt; clones repos via SSH forwarding.
set -euo pipefail

if [[ -f ./dome-config.sh ]]; then
  # shellcheck disable=SC1091
  source ./dome-config.sh
fi

_MANIFEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/manifest"
ROS_DISTRO=$(grep '^ROS_DISTRO=' "${_MANIFEST_DIR}/config.txt" | cut -d= -f2)

DOME_BASE_IMAGE="${DOME_BASE_IMAGE:-dome-docker-base:${ROS_DISTRO}}"
DOME_IMAGE="${DOME_IMAGE:-dome-docker:dome-${ROS_DISTRO}}"
DOME_USER="${DOME_USER:-robot}"
DOME_PASSWORD="${DOME_PASSWORD:-}"

DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/arm64 \
  --ssh default="${SSH_AUTH_SOCK}" \
  --push \
  --build-arg "ROS_DISTRO=${ROS_DISTRO}" \
  --build-arg "DOME_BASE_IMAGE=${DOME_BASE_IMAGE}" \
  --build-arg "DOME_USER=${DOME_USER}" \
  --build-arg "DOME_PASSWORD=${DOME_PASSWORD}" \
  -t "${DOME_IMAGE}" .
