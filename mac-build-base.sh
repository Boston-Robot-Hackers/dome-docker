#!/usr/bin/env bash
set -euo pipefail

if [[ -f ./dome-config.sh ]]; then
  # shellcheck disable=SC1091
  source ./dome-config.sh
fi

DOME_BASE_IMAGE="${DOME_BASE_IMAGE:-dome-docker-base:kilted}"

DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/arm64 \
  --push \
  -f Dockerfile.base \
  -t "${DOME_BASE_IMAGE}" .
