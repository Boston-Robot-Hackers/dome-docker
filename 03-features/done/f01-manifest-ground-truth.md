# Feature description for feature F01
## F01 — manifest as single source of truth
**Priority**: High
**Done:** yes
**Tasks File Created:** yes
**Tests Written:** yes
**Test Passing:** yes
**Description**: `manifest/` directory should contain all configuration needed to reproduce a working dome robot environment — whether target is a Docker image or a bare-metal Raspberry Pi running Ubuntu 24.04. Build scripts (Docker or bash) become thin executors that read from manifest; no build logic is duplicated between them. Design note: `02-doc/manifest-as-ground-truth.md`.

## How to Demo
**Setup**: Fresh Ubuntu 24.04 Pi with blank microSD. Docker build environment on Mac.

**Steps**:
1. Run `bare-metal-base.sh` on Pi — installs ROS, apt packages, pip packages, third-party repos, curl tools
2. Run `bare-metal-build.sh` on Pi — clones repos, builds ros2_ws, creates dir structure
3. Separately, run `docker compose build` on Mac
4. Verify both environments have identical packages, repos, and workspace structure

**Expected output**: Both Docker and bare-metal environments functional with same ROS packages, same repos cloned, same workspace layout. Adding a package to `manifest/packages.txt` affects both without editing any script.
