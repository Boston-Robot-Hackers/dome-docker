#!/usr/bin/env bash
# Builds and pushes the ROS base image for linux/arm64 from a Mac.
# Reads ROS_DISTRO and UBUNTU_CODENAME from manifest/config.txt.
set -euo pipefail

# shellcheck disable=SC1091
source ./dome-config.sh

_MANIFEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/manifest"
ROS_DISTRO=$(grep '^ROS_DISTRO=' "${_MANIFEST_DIR}/config.txt" | cut -d= -f2)
UBUNTU_CODENAME=$(grep '^UBUNTU_CODENAME=' "${_MANIFEST_DIR}/config.txt" | cut -d= -f2)

DOME_BASE_IMAGE="${DOME_BASE_IMAGE:-dome-docker-base:${ROS_DISTRO}}"

DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/arm64 \
  --build-arg "ROS_DISTRO=${ROS_DISTRO}" \
  --build-arg "UBUNTU_CODENAME=${UBUNTU_CODENAME}" \
  --push \
  -f Dockerfile.base \
  -t "${DOME_BASE_IMAGE}" .
