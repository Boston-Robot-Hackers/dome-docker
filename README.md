# Dome Docker

Draft automation for rebuilding the Raspberry Pi 5 dome/robot environment as a Docker-based system.

Target host:

- Raspberry Pi 5
- Ubuntu Server 24.04.4 LTS, 64-bit, headless
- Docker Engine

Target container:

- `ros:kilted-ros-base-noble`
- ROS 2 Kilted packages for DepthAI/OAK, camera, Nav2, lidar, diagnostics, RViz/Foxglove, and robot support
- Source repos cloned with SSH during Docker build

## Files

- `host-setup.sh` provisions the Pi host with Docker, user `pitosalas`, and optional host files.
- `Dockerfile` builds the ROS 2 Kilted image.
- `compose.yaml` runs the container with host networking and broad device access for the first working draft.
- `docker-entrypoint.sh` sources ROS and workspace overlays.
- `build-and-run.md` has build/run command notes.
- `*-plan.md` files capture design notes and candidate decisions.

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
  --ssh default \
  --load \
  -t pidockerexperiment:dome-kilted .
```

Or with Compose:

```sh
DOCKER_BUILDKIT=1 docker compose build --ssh default
```

## Run

```sh
docker compose run --rm dome
```

The compose file currently uses `network_mode: host` and `privileged: true` to get the first hardware-connected version working. Tighten privileges after the image runs correctly.

## Host Setup

On a freshly flashed Pi:

```sh
sudo ./host-setup.sh
```

Default user provisioning:

- User: `pitosalas`
- Default password: `daniel`
- Override with `PITOSALAS_PASSWORD` if desired:

```sh
sudo PITOSALAS_PASSWORD='new-password' ./host-setup.sh
```

## SSH Repositories

The Dockerfile uses SSH GitHub URLs for private/internal repos. Build with `--ssh default`; SSH keys are forwarded during build and are not copied into the image.

## Public Repo Notes

This repo intentionally excludes generated inventory and runtime state through `.gitignore`. Do not commit private keys, `.env` files, host Wi-Fi credentials, or copied `/etc/netplan` files without reviewing them.
