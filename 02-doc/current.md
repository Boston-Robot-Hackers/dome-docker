# Current Status

**Date:** 2026-05-18
**Session:** F01 — manifest as single source of truth

## Status
F01 complete. manifest/ is now authoritative for both Docker and bare-metal Pi builds.

## What Was Done
- Created `manifest/apt-repos.txt`, `tools.txt`, `colcon.txt`, `rosdep.txt`, `dirs.txt`
- Extended `manifest/config.txt` with `DOME_USER=robot` default
- Created `manifest/lib.sh` — shared parsing helpers (manifest_field, manifest_require, manifest_sections, manifest_config)
- Refactored `Dockerfile.base` — replaces hardcoded Doppler/gh/mcfly with manifest loops
- Refactored `Dockerfile` — replaces hardcoded dirs, rosdep skip-keys, colcon flags with manifest reads
- Updated `dome-config.sh` — reads DOME_USER default from config.txt, user.txt overrides, errors on missing required fields
- Wrote `bare-metal-base.sh` — installs ROS + all packages on fresh Ubuntu 24.04 Pi, reads from manifest
- Wrote `bare-metal-build.sh` — clones repos, rosdep, colcon build on Pi, reads from manifest
- Removed dead oak_roboflow patch code (repo renamed to dome_vision, no longer exists)
- Wrote `tests/test_f01_manifest.sh` — 40 tests, all passing

## Active Features
None pending.

## Blockers
None.

## Next Steps
1. Test bare-metal-base.sh + bare-metal-build.sh on a real Pi
2. Define next feature
