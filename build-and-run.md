# Build And Run Notes

This draft assumes private GitHub repositories are cloned with SSH during Docker build.

For the full process starting from a formatted microSD card attached to a Mac,
use `microsd-card-build.md`.

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
cd ~
sudo apt update
sudo apt install -y git ca-certificates
git clone https://github.com/Boston-Robot-Hackers/dome-docker.git dome-docker
cd dome-docker
sudo ./host-setup.sh
```

If setup stops with `Could not resolve host: download.docker.com`, fix the Pi's
network/DNS first:

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

To restore reviewed Raspberry Pi boot firmware files:

```sh
mkdir -p host-files/boot/firmware
cp host-file-templates/boot/firmware/config.txt host-files/boot/firmware/config.txt
cp host-file-templates/boot/firmware/cmdline.txt host-files/boot/firmware/cmdline.txt
sudo RESTORE_BOOT_FIRMWARE=1 ./host-setup.sh
```

Review `user-data.template` and `network-config.template` manually before using
them because real versions can contain password hashes and Wi-Fi credentials.

## Notes

- SSH keys are forwarded during build and are not copied into the image.
- Host udev rules, netplan, and `/boot/firmware` belong on the Pi host, not in the container.
- `compose.yaml` uses `network_mode: host` and `privileged: true` for the first working draft. We can tighten privileges after the image works.
- Runtime state is mounted under `./runtime-data/`.
