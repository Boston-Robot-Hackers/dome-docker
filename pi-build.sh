#!/usr/bin/env bash
# Builds the Docker image on the Raspberry Pi. Generates an SSH key if needed,
# verifies GitHub access, builds the base image if absent, then builds the overlay.
set -euo pipefail

if [[ -f ./dome-config.sh ]]; then
  # shellcheck disable=SC1091
  source ./dome-config.sh
fi

_MANIFEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/manifest"
ROS_DISTRO=$(grep '^ROS_DISTRO=' "${_MANIFEST_DIR}/config.txt" | cut -d= -f2)

KEY_PATH="${DOME_SSH_KEY:-${HOME}/.ssh/id_ed25519}"
KEY_COMMENT="${DOME_SSH_KEY_COMMENT:-${USER:-robot}@$(hostname -s 2>/dev/null || echo dome)}"
DOME_BASE_IMAGE="${DOME_BASE_IMAGE:-dome-docker-base:${ROS_DISTRO}}"

if ! command -v docker >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Docker is not installed or is not on PATH.
Run host setup first:
  sudo ./host-setup.sh
  sudo reboot
EOF
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Docker Compose is not available.
Run host setup first:
  sudo ./host-setup.sh
  sudo reboot
EOF
  exit 1
fi

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

if [[ ! -f "${KEY_PATH}" ]]; then
  ssh-keygen -t ed25519 -C "${KEY_COMMENT}" -f "${KEY_PATH}"
fi

if [[ ! -f "${KEY_PATH}.pub" ]]; then
  ssh-keygen -y -f "${KEY_PATH}" >"${KEY_PATH}.pub"
fi

ssh-keyscan github.com >>"${HOME}/.ssh/known_hosts" 2>/dev/null || true
sort -u "${HOME}/.ssh/known_hosts" -o "${HOME}/.ssh/known_hosts"
chmod 600 "${HOME}/.ssh/known_hosts"

if [[ -z "${SSH_AUTH_SOCK:-}" ]] || ! ssh-add -l >/dev/null 2>&1; then
  eval "$(ssh-agent -s)"
fi

if ! ssh-add -l 2>/dev/null | grep -Fq "${KEY_PATH}"; then
  ssh-add "${KEY_PATH}"
fi

if ! ssh -o BatchMode=yes -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  cat >&2 <<EOF
GitHub SSH authentication is not ready.

Add this public key to GitHub, then rerun ./pi-build.sh:

$(cat "${KEY_PATH}.pub")

GitHub path:
  Settings -> SSH and GPG keys -> New SSH key
EOF
  exit 1
fi

if ! docker image inspect "${DOME_BASE_IMAGE}" >/dev/null 2>&1; then
  DOCKER_BUILDKIT=1 docker build \
    --build-arg "ROS_DISTRO=${ROS_DISTRO}" \
    -f Dockerfile.base \
    -t "${DOME_BASE_IMAGE}" .
fi

DOCKER_BUILDKIT=1 docker compose build --ssh default
