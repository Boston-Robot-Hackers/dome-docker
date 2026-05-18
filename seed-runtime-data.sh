#!/usr/bin/env bash
# seed-runtime-data.sh — populate runtime-data/ from dotfiles for container volume mounts.
# Safe to re-run: skips files that already exist in destination.
# Author: Pito Salas and Claude Code
# Open Source Under MIT license

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
SRC="${SCRIPT_DIR}/runtime-data"

echo "runtime-data/ is already seeded in the repo. Nothing to do."
echo "To update maps or config, edit files under runtime-data/ directly."
