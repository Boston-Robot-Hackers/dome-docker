#!/usr/bin/env bash
# seed-runtime-data.sh — copy ~/.control and ~/.dome into runtime-data/ for container use.
# Safe to re-run: skips files that already exist in destination.
# Author: Pito Salas and Claude Code
# Open Source Under MIT license

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
DST_CONTROL="$SCRIPT_DIR/runtime-data/control"
DST_DOME="$SCRIPT_DIR/runtime-data/dome"

mkdir -p "$DST_CONTROL" "$DST_DOME"

rsync -a --ignore-existing ~/.control/ "$DST_CONTROL/"
rsync -a --ignore-existing ~/.dome/ "$DST_DOME/"

echo "Done."
