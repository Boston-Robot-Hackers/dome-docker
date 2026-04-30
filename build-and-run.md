# Build And Run Notes

This draft assumes private GitHub repositories are cloned with SSH during Docker build.

## Build With SSH Forwarding

Start an SSH agent on the build machine and load a key that can read the private repos:

```sh
ssh-add -l
ssh-add ~/.ssh/id_ed25519
```

Build with Docker Compose:

```sh
DOCKER_BUILDKIT=1 docker compose build --ssh default
```

Or build directly:

```sh
DOCKER_BUILDKIT=1 docker build --ssh default -t pidockerexperiment:dome-kilted .
```

## Run

```sh
docker compose run --rm dome
```

## Host Setup

On a freshly flashed Raspberry Pi 5 host:

```sh
sudo ./host-setup.sh
```

Then log out and back in so Docker group membership applies.

## Notes

- SSH keys are forwarded during build and are not copied into the image.
- Host udev rules and netplan belong on the Pi host, not in the container.
- `compose.yaml` uses `network_mode: host` and `privileged: true` for the first working draft. We can tighten privileges after the image works.
- Runtime state is mounted under `./runtime-data/`.
