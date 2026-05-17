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

See `doc/setup-and-run.md` — single end-to-end runbook from blank microSD to running container.

## Repository Layout

- `Dockerfile`: builds the ROS 2 overlay image.
- `Dockerfile.base`: builds the reusable ROS base image.
- `compose.yaml`: runs the container with host networking and broad device
  access for the first working hardware-connected draft.
- `docker-entrypoint.sh`: sources ROS and workspace overlays.
- `host-setup.sh`: provisions the Pi host with Docker, user setup, ReSpeaker
  overlay, optional udev/netplan restore, and optional `/boot/firmware` restore.
- `manifest/`: declarative configuration read by Dockerfiles and build scripts.
  - `config.txt`: `ROS_DISTRO` and `UBUNTU_CODENAME` — change here to upgrade ROS.
  - `packages.txt`: apt and ROS packages installed in the base image.
  - `repos.txt`: GitHub repos cloned during the overlay image build.
- `host-file-templates/`: sanitized templates for host files that may need to
  be copied to a new Pi.
- `doc/`: step-by-step runbooks for specific build/setup scenarios.

Ignored local directories:

- `host-files/`: reviewed host-specific files to install on a Pi.
- `runtime-data/`: mutable container runtime state mounted by Compose.
- `local-cloud-init/`: edited cloud-init files that may contain secrets.
- `dome-config.sh`: local user, image, and repository settings.

## Local Configuration

Edit `manifest/user.txt` for your personal settings — this file is gitignored so it stays local:

```sh
nano manifest/user.txt
```

Key settings in `manifest/user.txt`:

- `DOCKERHUB_USERNAME`: your Docker Hub username (hub.docker.com — shown top-right after login).
- `DOME_USER`: Linux user created on the Pi host and inside the Docker image.

For the password, set it as an environment variable before building (keeps it out of files entirely):

```sh
export DOME_PASSWORD=yourpassword
```

Then source the config:

```sh
source ./dome-config.sh
```

Do not commit `manifest/user.txt`.

Before publishing a repository that previously contained personal paths,
private repository names, passwords, or other local details, rewrite or recreate
Git history. Removing those values from the current tree is not enough to remove
them from older commits.

## Host Files And Secrets

Boot firmware templates are tracked under:

- `host-file-templates/boot/firmware/config.txt`
- `host-file-templates/boot/firmware/cmdline.txt`
- `host-file-templates/boot/firmware/user-data.template`
- `host-file-templates/boot/firmware/network-config.template`

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

`host-setup.sh` backs up existing boot files as `.pre-dome-docker` before
replacing them.

## Host Setup DNS Troubleshooting

If `host-setup.sh` stops with `Could not resolve host: download.docker.com`,
fix the Pi's network/DNS first:

```sh
ip route get 1.1.1.1
ping -c 3 1.1.1.1
getent hosts download.docker.com
resolvectl status
```

If DNS returns only IPv6 addresses for `download.docker.com`, force working DNS
servers on Wi-Fi and retry:

```sh
sudo resolvectl dns wlan0 1.1.1.1 8.8.8.8
sudo resolvectl domain wlan0 '~.'
sudo resolvectl flush-caches
getent ahostsv4 download.docker.com
```

Then log out and back in so Docker group membership applies.

## Builder Troubleshooting

If a private `git clone` fails with `Permission denied (publickey)` or
`ERROR: failed to clone` but `ssh -T git@github.com` works on the Mac,
either the SSH key is not loaded or the active Buildx builder is not receiving
SSH forwarding.

First confirm the key is loaded: `ssh-add -l`. If missing: `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`.

If the key is present but clones still fail, the active Buildx builder may not be
receiving SSH forwarding.

Check builders:

```sh
docker buildx ls
```

The active builder has `*`. If a custom builder such as `mymultiarchbuilder*` is
active, switch to Docker Desktop's default context/builder and rerun the build:

```sh
docker context use default
docker buildx use default
```

## Package Build Patches

The Dockerfile currently applies a small in-image patch to `oak_roboflow/setup.py` so setuptools explicitly packages only `oak_roboflow`. Without this, setuptools may auto-discover generated folders such as `prefix_override` and fail with a flat-layout package discovery error.

## Source Tree Cleanup

Before `rosdep` and `colcon build`, the Dockerfile removes common generated directories from cloned source trees, including `build`, `install`, `log`, `prefix_override`, `__pycache__`, `.pytest_cache`, and `*.egg-info`. This avoids setuptools flat-layout discovery failures when old build artifacts exist in a repository.

## Rosdep Notes

During image build, `rosdep install` runs as root because it may need to install apt packages. The Dockerfile currently skips two rosdep keys while we sort out compatibility:

- `ament_python` from `oak_roboflow`
- `gazebo_ros_pkgs` from `linorobot2_gazebo`

Those packages remain in the source tree, but their unresolved rosdep keys do not block the first image build.

## ML Dependencies

`torch` and `torchvision` are not baked into the image (~1GB, arm64). Required only for `dome_vision` ML features. Install on demand inside the container:

```sh
install-ml-deps.sh
```

Safe to re-run. Takes 10-15 min on first install.

## SSH Repositories

The Dockerfile uses SSH GitHub URLs for private/internal repos. SSH keys are
forwarded during build via `--mount=type=ssh` and are not copied into the image.
If any clone fails, the build aborts immediately with `ERROR: failed to clone <url>`.
Load your key before building:

```sh
ssh-add -l                                        # confirm key is present
ssh-add --apple-use-keychain ~/.ssh/id_ed25519    # load if missing
```

- Host udev rules, netplan, and `/boot/firmware` belong on the Pi host, not in
  the container.
- Runtime state is mounted under `./runtime-data/`.

## Public Repo Notes

This repo intentionally excludes generated inventory and runtime state through `.gitignore`. Do not commit private keys, `.env` files, host Wi-Fi credentials, or copied `/etc/netplan` files without reviewing them.
