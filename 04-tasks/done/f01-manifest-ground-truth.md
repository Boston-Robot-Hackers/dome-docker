# F01 Tasks — manifest as single source of truth

## T01 — create missing manifest files
**Status**: done
**Description**: Create `manifest/apt-repos.txt`, `manifest/tools.txt`, `manifest/colcon.txt`, `manifest/rosdep.txt`, `manifest/dirs.txt`. Extend `manifest/config.txt` with `DOME_USER=robot`. Formats defined in `02-doc/manifest-as-ground-truth.md`.

## T02 — refactor Dockerfile.base to read apt-repos.txt and tools.txt
**Status**: done
**Description**: Replace hardcoded Doppler and GitHub CLI repo setup in `Dockerfile.base` with a loop that parses `manifest/apt-repos.txt`. Replace mcfly curl install with loop over `manifest/tools.txt`. No behavior change.

## T03 — refactor Dockerfile to read colcon.txt, rosdep.txt, dirs.txt
**Status**: done
**Description**: Replace hardcoded `--symlink-install --packages-skip depthai_rospi` with values from `manifest/colcon.txt`. Replace hardcoded rosdep skip-keys with `manifest/rosdep.txt`. Replace hardcoded `mkdir -p` list with loop over `manifest/dirs.txt`. No behavior change.

## T04 — update dome-config.sh to read DOME_USER from manifest/config.txt
**Status**: done
**Description**: `dome-config.sh` currently defines `DOME_USER`. Change it to read the value from `manifest/config.txt` so config.txt is authoritative.

## T05 — write bare-metal-base.sh
**Status**: done
**Description**: Shell script that runs on a fresh Ubuntu 24.04 Pi. Installs ROS distro, apt packages from `manifest/packages.txt` [apt] section, ROS packages from [ros] section, third-party repos from `manifest/apt-repos.txt`, pip packages from `manifest/pip.txt`, curl tools from `manifest/tools.txt`. Mirrors what `Dockerfile.base` does.

## T06 — write bare-metal-build.sh
**Status**: done
**Description**: Shell script that runs on Pi after bare-metal-base.sh. Creates dir structure from `manifest/dirs.txt`, clones repos from `manifest/repos.txt`, runs rosdep install using `manifest/rosdep.txt` skip-keys, builds ros2_ws using `manifest/colcon.txt` flags. Mirrors what `Dockerfile` does.

## T07 — remove oak_roboflow dead code
**Status**: done
**Description**: oak_roboflow was renamed to dome_vision and no longer exists. Removed the inline patch block from Dockerfile and bare-metal-build.sh. No patches/ directory needed.

## T08 — write tests
**Status**: done
**Description**: Verify manifest files are parseable and complete. Verify Docker build succeeds and reads from manifest (no hardcoded values remain in Dockerfiles for things covered by manifest). Verify bare-metal scripts are shellcheck-clean. Smoke test that both build paths produce same package list.
