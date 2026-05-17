# Design: manifest as single source of truth

## Goal

The `manifest/` directory should contain all configuration needed to reproduce
a working dome robot environment — whether the target is a Docker image or a
bare-metal Raspberry Pi. Build scripts (Docker or bash) become thin executors
that read from manifest; no build logic is duplicated between them.

## Current state

Four manifest files exist:

| File | Contents |
|---|---|
| `config.txt` | `ROS_DISTRO`, `UBUNTU_CODENAME` |
| `packages.txt` | apt and ROS packages in `[apt]` / `[ros]` sections |
| `pip.txt` | pip3 packages, one per line |
| `repos.txt` | git repos in `[root]` / `[ros_ws]` / `[uros_ws]` sections |

Several values are hardcoded in `Dockerfile` and `Dockerfile.base` that have
no manifest equivalent. A bare-metal script written today would have to
duplicate all of them.

## Gaps to close

### 1. `manifest/apt-repos.txt` — third-party apt repositories

Doppler and GitHub CLI repos are hardcoded in `Dockerfile.base`. Format
proposal (INI sections, one repo per section):

```
[doppler]
key_url  = https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key
key_file = /usr/share/keyrings/doppler-archive-keyring.gpg
list     = deb [signed-by={key_file}] https://packages.doppler.com/public/cli/deb/debian any-version main
packages = doppler

[github-cli]
key_url  = https://cli.github.com/packages/githubcli-archive-keyring.gpg
key_file = /usr/share/keyrings/githubcli-archive-keyring.gpg
list     = deb [arch={arch} signed-by={key_file}] https://cli.github.com/packages stable main
packages = gh
```

Both Docker and bash scripts parse this with a small awk/bash loop to add each
repo and install its packages. No repo-specific code lives in the scripts.

### 2. `manifest/tools.txt` — curl-installed tools

mcfly is installed via `curl | sh`. Capturing this in manifest makes it
auditable and scriptable:

```
[mcfly]
method  = curl-sh
url     = https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh
args    = --git cantino/mcfly
```

Long-term, replace `method = curl-sh` entries with pinned release tarballs and
SHA256 checksums to address the supply-chain risk noted in the repo review.

### 3. `manifest/colcon.txt` — colcon build configuration

`Dockerfile:65` hardcodes `--symlink-install --packages-skip depthai_rospi`.

```
flags        = --symlink-install
packages_skip = depthai_rospi
```

Scripts read this file and construct the colcon invocation:

```bash
FLAGS=$(grep '^flags' manifest/colcon.txt | cut -d= -f2 | xargs)
SKIP=$(awk -F= '/^packages_skip/{print $2}' manifest/colcon.txt | xargs)
colcon build $FLAGS --packages-skip $SKIP
```

### 4. `manifest/rosdep.txt` — rosdep skip keys

`Dockerfile:59` hardcodes `--skip-keys="ament_python gazebo_ros_pkgs"`.

```
skip_keys = ament_python gazebo_ros_pkgs
```

### 5. `manifest/dirs.txt` — home directory structure

`Dockerfile:21-27` creates six subdirectories under `$DOME_HOME`. Any new
directory added to the Dockerfile is silently missing from a bare-metal setup.

```
.local/bin
.ros/camera_info
.control/maps
.control/logs
ros2_ws/src
uros_ws/src
```

Scripts create these with:

```bash
while read -r d; do mkdir -p "${DOME_HOME}/${d}"; done < manifest/dirs.txt
```

### 6. `manifest/config.txt` — add DOME_USER default

`DOME_USER` default (`robot`) is currently in `dome-config.sh`. A bare-metal
script sourcing only manifest would not know the username. Add:

```
DOME_USER=robot
```

`dome-config.sh` should read this value rather than define it, keeping
`config.txt` authoritative.

### 7. oak_roboflow setup.py patch — does not belong in manifest

`Dockerfile:49-51` applies an inline string-surgery patch to
`oak_roboflow/setup.py` to add `find_packages()`. This is a workaround for a
broken upstream package. It should not be represented in manifest because:

- It is a temporary fix, not configuration.
- The correct fix is a PR to the upstream repo.
- If it must persist locally, store it as `patches/oak_roboflow-setup.patch`
  and apply with `git apply` or `patch -p1`, with a comment explaining the
  upstream issue and tracking link.

## Target manifest directory layout

```
manifest/
  config.txt        # ROS_DISTRO, UBUNTU_CODENAME, DOME_USER
  packages.txt      # [apt] and [ros] sections
  pip.txt           # pip3 packages
  repos.txt         # [root], [ros_ws], [uros_ws] git repos
  apt-repos.txt     # third-party apt repositories (doppler, gh)
  tools.txt         # curl-installed tools (mcfly)
  colcon.txt        # colcon build flags and skip list
  rosdep.txt        # rosdep skip keys
  dirs.txt          # home subdirectory structure
```

## How build targets consume manifest

Both build paths share identical manifest parsing. The only difference is
execution context.

```
manifest/
    |
    +---> Dockerfile.base + Dockerfile   (docker buildx / docker compose build)
    |
    +---> bare-metal-base.sh + bare-metal-build.sh   (run directly on Pi)
```

Scripts must never contain package names, repo URLs, build flags, or directory
lists. If adding a package requires editing a script rather than a manifest
file, the abstraction is broken.

## Migration plan

1. Create the five missing manifest files (`apt-repos.txt`, `tools.txt`,
   `colcon.txt`, `rosdep.txt`, `dirs.txt`) and extend `config.txt`.
2. Refactor `Dockerfile.base` to parse `apt-repos.txt` and `tools.txt` instead
   of inline repo setup.
3. Refactor `Dockerfile` to read `colcon.txt`, `rosdep.txt`, and `dirs.txt`.
4. Write `bare-metal-base.sh` and `bare-metal-build.sh` using the same manifest
   parsers as the Dockerfiles.
5. Move oak_roboflow fix to `patches/` or upstream PR.
6. Update `dome-config.sh` to read `DOME_USER` from `manifest/config.txt`.

Steps 1-3 are refactors with no behavior change and can be done independently.
Step 4 is new work that becomes straightforward once steps 1-3 are complete.
