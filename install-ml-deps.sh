#!/usr/bin/env bash
# Install large ML dependencies not baked into the Docker image.
# Run manually inside the container when dome_vision ML features are needed.
# Safe to re-run — pip skips already-installed packages.
set -euo pipefail

echo "Installing torch and torchvision (arm64 ~1GB, may take 10-15 min)..."
pip3 install --break-system-packages torch torchvision

echo "Installing dome_vision package..."
pip3 install --break-system-packages "${DOME_HOME:-$HOME}/ros2_ws/src/dome_vision/dome_vision/"

echo "Done. dome_vision ML features ready."
