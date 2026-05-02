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
- `mac-build-dockerhub.md`
  - Preferred when the image takes too long to build on the Pi.
  - Builds and pushes a `linux/arm64` image from the Mac, then the Pi pulls and
    runs it.
- `build-and-run.md`
  - Use this after the host is already provisioned and you only need the Docker
    build/run commands.

## Repository Layout

- `Dockerfile`: builds the ROS 2 Kilted image.
- `Dockerfile.base`: builds the reusable ROS Kilted base image.
- `compose.yaml`: runs the container with host networking and broad device
  access for the first working hardware-connected draft.
- `docker-entrypoint.sh`: sources ROS and workspace overlays.
- `host-setup.sh`: provisions the Pi host with Docker, user setup, optional
  udev/netplan restore, and optional `/boot/firmware` restore.
- `host-file-templates/`: sanitized templates for host files that may need to
  be copied to a new Pi.

Ignored local directories:

- `host-files/`: reviewed host-specific files to install on a Pi.
- `runtime-data/`: mutable container runtime state mounted by Compose.
- `local-cloud-init/`: edited cloud-init files that may contain secrets.
- `dome-config.sh`: local user, image, and repository settings.

## Local Configuration

Copy the example config and edit it for your robot:

```sh
cp dome-config.example.sh dome-config.sh
nano dome-config.sh
source ./dome-config.sh
```

Important settings:

- `DOME_HOST_USER`: Linux user on the Pi host.
- `DOME_HOST_PASSWORD`: optional host password; leave empty to preserve a
  cloud-init or Raspberry Pi Imager password.
- `DOME_CONTAINER_USER`: Linux user inside the Docker image.
- `DOME_BASE_IMAGE`: reusable base image with shared ROS Kilted dependencies.
- `DOME_IMAGE`: overlay image built from the base image.
- `DOME_DOCKER_REPO_URL`: URL used to clone this setup repo on a fresh Pi.
- `DOME_ROOT_REPOS`, `DOME_ROS_REPOS`, `DOME_UROS_REPOS`: semicolon-separated
  `repo_url destination_dir` entries cloned during the Docker build.

Do not commit `dome-config.sh`.

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

`--ssh default=$SSH_AUTH_SOCK` is important on macOS. It forwards your Mac SSH
agent into the BuildKit step without copying private keys into the image.

If no key is loaded:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

## Build On Raspberry Pi

The Docker build clones private GitHub repositories. On the Pi, use the helper:

```sh
./pi-build.sh
```

If the Pi's GitHub key is not authorized yet, the helper prints the public key
to add to GitHub. Add it, then rerun `./pi-build.sh`. For local Pi builds, the
helper also builds `DOME_BASE_IMAGE` first if it is not already present.

For faster setup, build and push the image from the Mac instead, then pull it on
the Pi. See `mac-build-dockerhub.md`.

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

## Host Setup

On a freshly flashed Pi:

```sh
cd ~
sudo apt update
sudo apt install -y git ca-certificates
git clone "${DOME_DOCKER_REPO_URL:-https://github.com/Boston-Robot-Hackers/dome-docker.git}" dome-docker
cd dome-docker
cp dome-config.example.sh dome-config.sh
nano dome-config.sh
source ./dome-config.sh
sudo --preserve-env=DOME_HOST_USER,DOME_HOST_PASSWORD ./host-setup.sh
```

Default user provisioning:

- User: `DOME_HOST_USER`, default `robot`
- Password: unchanged when `DOME_HOST_PASSWORD` is empty
- Override with `DOME_HOST_PASSWORD` if desired:

```sh
sudo --preserve-env=DOME_HOST_USER,DOME_HOST_PASSWORD ./host-setup.sh
```

Boot firmware templates are tracked under `host-file-templates/boot/firmware/`.
Review them before use. To restore reviewed `config.txt` and `cmdline.txt` on a
Pi, copy them into ignored `host-files/boot/firmware/` and run:

```sh
sudo RESTORE_BOOT_FIRMWARE=1 ./host-setup.sh
```

Do not commit real `user-data` or `network-config` files with password hashes or
Wi-Fi credentials.

## SSH Repositories

The Dockerfile uses SSH GitHub URLs for private/internal repos. Build with SSH forwarding; SSH keys are forwarded during build and are not copied into the image.

## Public Repo Notes

This repo intentionally excludes generated inventory and runtime state through `.gitignore`. Do not commit private keys, `.env` files, host Wi-Fi credentials, or copied `/etc/netplan` files without reviewing them.
