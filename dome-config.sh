#!/usr/bin/env bash

# Source this file before running host setup or Docker builds:
#
#   nano manifest/user.txt   # set DOCKERHUB_USERNAME and DOME_USER
#   source ./dome-config.sh

_MANIFEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/manifest"
_DOCKERHUB_USERNAME=$(grep '^DOCKERHUB_USERNAME=' "${_MANIFEST_DIR}/user.txt" | cut -d= -f2)
_DOME_USER=$(grep '^DOME_USER=' "${_MANIFEST_DIR}/user.txt" | cut -d= -f2)

# User created or configured on the Pi host and inside the Docker image.
export DOME_USER="${DOME_USER:-${_DOME_USER:-robot}}"

# Optional password for DOME_USER. Leave empty to preserve an existing host
# password from cloud-init or Raspberry Pi Imager. If used for Docker image
# builds, the value is baked into the image and may be visible in local image
# metadata or build logs. Do not commit real passwords.
export DOME_PASSWORD="${DOME_PASSWORD:-}"

# Docker Hub image names. Tags are appended automatically from manifest/config.txt.
# Set DOCKERHUB_USERNAME in manifest/user.txt.
export DOME_BASE_IMAGE="${DOME_BASE_IMAGE:-docker.io/${_DOCKERHUB_USERNAME}/dome-base}"
export DOME_IMAGE="${DOME_IMAGE:-docker.io/${_DOCKERHUB_USERNAME}/dome-docker}"

# Repository URL for cloning this public setup repo onto a fresh Pi.
export DOME_DOCKER_REPO_URL="${DOME_DOCKER_REPO_URL:-https://github.com/Boston-Robot-Hackers/dome-docker.git}"

# SSH key settings used by pi-build.sh.
export DOME_SSH_KEY="${DOME_SSH_KEY:-${HOME}/.ssh/id_ed25519}"
export DOME_SSH_KEY_COMMENT="${DOME_SSH_KEY_COMMENT:-${USER:-robot}@$(hostname -s 2>/dev/null || echo dome)}"
