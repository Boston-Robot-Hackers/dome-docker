# Dome Docker

Automation and runbooks for rebuilding the Raspberry Pi 5 dome/robot
environment as an Ubuntu host running a ROS 2 Docker container.

The system is split into two layers:

- Host: Raspberry Pi 5, Ubuntu Server 24.04 LTS 64-bit, Docker Engine, udev,
  boot firmware, networking, and hardware access.
- Container: ROS 2 Kilted on `ros:kilted-ros-base-noble`, with robot source
  repositories cloned and built during the Docker image build.

## Which Runbook To Use

- `microsd-card-build.md`
  - Use this for the normal path.
  - Starts with a microSD card attached to a Mac.
  - Covers erasing/formatting the card, flashing Ubuntu with Raspberry Pi
    Imager, copying boot firmware templates, booting the Pi, running host setup,
    building the Docker image, and smoke testing.
- `mac-prebuilt-microsd.md`
  - Use this when you want to build the arm64 Docker image on the Mac before the
    Pi boots.
  - Pushes the image to a registry, writes cloud-init files to the boot
    partition, then lets the Pi install Docker, clone this repo, and pull the
    prebuilt image on first boot.
  - This is the closest practical version of a Mac-prebuilt card without using
    a Linux VM to edit the ext4 root filesystem.
- `build-and-run.md`
  - Use this after the host is already provisioned and you only need the Docker
    build/run commands.

## Repository Layout

- `Dockerfile`: builds the ROS 2 Kilted image.
- `compose.yaml`: runs the container with host networking and broad device
  access for the first working hardware-connected draft.
- `docker-entrypoint.sh`: sources ROS and workspace overlays.
- `host-setup.sh`: provisions the Pi host with Docker, user setup, optional
  udev/netplan restore, and optional `/boot/firmware` restore.
- `host-file-templates/`: sanitized templates for host files that may need to
  be copied to a new Pi.
- `host-provisioning-plan.md`: host-side design notes and responsibilities.
- `container-build-plan.md`: container/image design notes and source/package
  decisions.
- `archive/`: first-pass research notes kept for history, not normal workflow.

Ignored local directories:

- `host-files/`: reviewed host-specific files to install on a Pi.
- `runtime-data/`: mutable container runtime state mounted by Compose.
- `local-cloud-init/`: edited cloud-init files that may contain secrets.

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

## Build On Apple Silicon Mac

Make sure Docker Desktop is running and your GitHub SSH key is loaded:

```sh
ssh -T git@github.com
ssh-add -l
```

Build for Raspberry Pi / arm64:

```sh
DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/arm64 \
  --ssh default=$SSH_AUTH_SOCK \
  --load \
  -t dome-docker:dome-kilted .
```

`--ssh default=$SSH_AUTH_SOCK` is important on macOS. It forwards your Mac SSH agent into the BuildKit step without copying private keys into the image. The Dockerfile runs private `git clone` commands as root using the forwarded SSH socket, then changes ownership of `/home/pitosalas` back to the non-root `pitosalas` user. This avoids Docker Desktop SSH socket permission issues during build.

If no key is loaded:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

## Run

On the Pi:

```sh
docker compose run --rm dome
```

Smoke tests inside the container:

```sh
echo "$ROS_DISTRO"
ros2 --help
ls ~/ros2_ws/src
```

Expected ROS distribution:

```text
kilted
```

The compose file currently uses `network_mode: host` and `privileged: true` to
get the first hardware-connected version working. Tighten privileges after the
image runs correctly.

## Builder Troubleshooting

If a private `git clone` fails with `Permission denied (publickey)` but
`ssh -T git@github.com` works on the Mac, the active Buildx builder may not be
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

During image build, `rosdep install` runs as root because it may need to install apt packages. The Dockerfile currently skips two rosdep keys while we sort out Kilted compatibility:

- `ament_python` from `oak_roboflow`
- `gazebo_ros_pkgs` from `linorobot2_gazebo`

Those packages remain in the source tree, but their unresolved rosdep keys do not block the first image build.

## SSH Repositories

The Dockerfile uses SSH GitHub URLs for private/internal repos. Build with SSH forwarding; SSH keys are forwarded during build and are not copied into the image.

## Public Repo Notes

This repo intentionally excludes generated inventory and runtime state through `.gitignore`. Do not commit private keys, `.env` files, host Wi-Fi credentials, or copied `/etc/netplan` files without reviewing them.
