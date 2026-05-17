# Dome Docker

Automation and runbooks for rebuilding the Raspberry Pi 5 dome/robot
environment as an Ubuntu host running a ROS 2 Docker container.

The system is split into two layers:

- Host: Raspberry Pi 5, Ubuntu Server 24.04 LTS 64-bit, Docker Engine, udev,
  boot firmware, networking, and hardware access.
- Container: ROS 2 (distro set in `manifest/config.txt`) on the matching
  `ros:<distro>-ros-base-<ubuntu>` base, with robot source repositories cloned
  and built during the Docker image build.

## Getting Started

See `02-doc/setup-and-run.md` — single end-to-end runbook from blank microSD to running container.

## Repository Layout

- `Dockerfile`: builds the ROS 2 overlay image.
- `Dockerfile.base`: builds the reusable ROS base image.
- `compose.yaml`: runs the container with host networking and broad device access.
- `docker-entrypoint.sh`: sources ROS and workspace overlays before exec.
- `host-setup.sh`: provisions the Pi host with Docker, user setup, ReSpeaker
  overlay, optional udev/netplan restore, and optional `/boot/firmware` restore.
- `collect-inventory.sh`: snapshots installed packages and system state to `inventory/`.
  Run on a live Pi to capture what is actually installed for comparison against `manifest/`.
- `seed-runtime-data.sh`: copies `~/.control` and `~/.dome` into `runtime-data/` for
  use as container volume mounts. Run once before first container start.
- `manifest/`: declarative configuration read by Dockerfiles and build scripts.
  - `config.txt`: `ROS_DISTRO` and `UBUNTU_CODENAME` — change here to upgrade ROS.
  - `packages.txt`: apt and ROS packages installed in the base image.
  - `pip.txt`: pip packages installed in the base image.
  - `repos.txt`: GitHub repos cloned during the overlay image build.
  - `bashrc`: shell environment baked into the container as `~/.bashrc`.
- `host-file-templates/`: sanitized templates for host files that may need to
  be copied to a new Pi.
- `02-doc/`: project documentation, architecture notes, and current status.
- `inventory/`: snapshot of what is actually installed on a live Pi (gitignored).

Ignored local directories:

- `host-files/`: reviewed host-specific files to install on a Pi.
- `runtime-data/`: mutable container runtime state mounted by Compose.
  - `runtime-data/ros/` → `~/.ros`
  - `runtime-data/control/` → `~/.control`
  - `runtime-data/dome/` → `~/.dome`
- `local-cloud-init/`: edited cloud-init files that may contain secrets.

## Local Configuration

Edit `manifest/user.txt` for personal settings — gitignored, stays local:

```sh
nano manifest/user.txt
```

Key settings:

- `DOCKERHUB_USERNAME`: your Docker Hub username.
- `DOME_USER`: Linux user created on the Pi host and inside the Docker image.

Set the password as an environment variable before building (keeps it out of files):

```sh
export DOME_PASSWORD=yourpassword
```

Then source the config:

```sh
source ./dome-config.sh
```

Do not commit `manifest/user.txt`.

## Shell Environment

The container user's `~/.bashrc` is sourced from `manifest/bashrc` at image build time.
Edit `manifest/bashrc` and rebuild the overlay to change the container shell environment.

## Runtime Data

`runtime-data/` is mounted into the container so maps, configs, and survey data persist
across container restarts. Seed it from the live Pi before first use:

```sh
./seed-runtime-data.sh
```

Safe to re-run — skips files already present in the destination.

## Inventory

To capture what is actually installed on a live Pi:

```sh
./collect-inventory.sh
```

Output goes to `inventory/` (gitignored). Diff against `manifest/` to find gaps or extras.

## Host Files And Secrets

Boot firmware templates are tracked under `host-file-templates/boot/firmware/`.

Real `user-data`, `network-config`, netplan files, private keys, `.env` files,
and anything with Wi-Fi credentials or password hashes must stay out of git.
Put reviewed local copies under ignored `host-files/` or `local-cloud-init/`.

To restore reviewed boot firmware files on a Pi:

```sh
mkdir -p host-files/boot/firmware
cp host-file-templates/boot/firmware/config.txt host-files/boot/firmware/config.txt
cp host-file-templates/boot/firmware/cmdline.txt host-files/boot/firmware/cmdline.txt
sudo RESTORE_BOOT_FIRMWARE=1 ./host-setup.sh
```

`host-setup.sh` backs up existing boot files as `.pre-dome-docker` before replacing them.

## Builder Troubleshooting

If a private `git clone` fails with `Permission denied (publickey)` during Mac build,
confirm the SSH key is loaded: `ssh-add -l`. Load if missing:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

If the key is present but clones still fail, the active Buildx builder may not be
receiving SSH forwarding. Switch to the default builder:

```sh
docker context use default
docker buildx use default
```

## Package Build Patches

The Dockerfile patches `oak_roboflow/setup.py` so setuptools explicitly packages only
`oak_roboflow`, avoiding flat-layout discovery failures from generated folders like
`prefix_override`.

## Rosdep Notes

During image build, `rosdep install` skips two keys:

- `ament_python` from `oak_roboflow`
- `gazebo_ros_pkgs` from `linorobot2_gazebo`

Those packages remain in the source tree but do not block the build.

## Optional Large Dependencies

Install on demand inside the container:

```sh
install-optional-deps.sh           # all optional deps
install-optional-deps.sh torch     # torch + torchvision (~1GB) — dome_vision ML
install-optional-deps.sh piper     # piper TTS binary + voice model (~110MB) — dome_voice speech
```

Safe to re-run. `torch` takes 10–15 min first install on Pi.

## Public Repo Notes

This repo intentionally excludes generated inventory and runtime state through `.gitignore`.
Do not commit private keys, `.env` files, host Wi-Fi credentials, or copied `/etc/netplan`
files without reviewing them.

Before publishing a repository that previously contained personal paths, private repository
names, passwords, or other local details, rewrite or recreate Git history. Removing those
values from the current tree is not enough to remove them from older commits.
