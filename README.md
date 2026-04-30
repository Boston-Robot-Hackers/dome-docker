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

If no key is loaded:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Confirm the private repo access works outside Docker:

```sh
git ls-remote git@github.com:campusrover/rosutils.git
```

Build for Raspberry Pi / arm64:

```sh
DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/arm64 \
  --ssh default=$SSH_AUTH_SOCK \
  --load \
  -t dome-docker:dome-kilted .
```

`--ssh default=$SSH_AUTH_SOCK` is important on macOS. It forwards your Mac SSH agent into the BuildKit step without copying private keys into the image. The Dockerfile mounts that forwarded SSH socket with `uid=1000,gid=1000` because the clone step runs as the non-root `pitosalas` user.

## Builder Troubleshooting

If the build fails during a private `git clone` with:

```text
git@github.com: Permission denied (publickey).
```

but `ssh -T git@github.com` and `git ls-remote ...` work on the Mac, the active Buildx builder probably is not receiving SSH forwarding.

Check builders:

```sh
docker buildx ls
```

The active builder has `*`. If a custom builder such as `mymultiarchbuilder*` is active, switch to Docker Desktop's default context/builder:

```sh
docker context use default
docker buildx use default
```

Then rerun the build command above.

If needed, switch back to Docker Desktop's context:

```sh
docker context use desktop-linux
docker buildx use desktop-linux
```

## Run

```sh
docker compose run --rm dome
```

Or run the built image directly:

```sh
docker run --rm -it dome-docker:dome-kilted bash
```

Smoke tests inside the container:

```sh
echo $ROS_DISTRO
ros2 --help
ls ~/ros2_ws/src
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

The Dockerfile uses SSH GitHub URLs for private/internal repos. Build with SSH forwarding; SSH keys are forwarded during build and are not copied into the image.

## Public Repo Notes

This repo intentionally excludes generated inventory and runtime state through `.gitignore`. Do not commit private keys, `.env` files, host Wi-Fi credentials, or copied `/etc/netplan` files without reviewing them.
