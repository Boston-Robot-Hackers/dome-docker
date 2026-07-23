# README: Dome Docker

Automation and runbooks for building a ROS 2 environment. Three scenarios:

1. **Raspberry Pi, microSD** — flash a card, install ROS natively (`DOME_TARGET=pi`, default)
2. **VM, bare Ubuntu 24.04 already installed** — same native install, no Pi hardware (`DOME_TARGET=vm`)
3. **Docker** — build on Mac, push to Docker Hub, run as container on a Pi

Scenarios 1 and 2 share the same bare-metal scripts and differ only in
`DOME_TARGET` (see [Setting Up A Development VM](#setting-up-a-development-vm)).
Scenario 3 is Pi-only. All three read from the same `manifest/` directory —
single source of truth for all packages, repos, build flags, and configuration.

## Local Configuration

Create `manifest/user.txt` (gitignored — never commit this):

```sh
printf 'DOME_USER=yourname\nDOCKERHUB_USERNAME=your-dockerhub-username\nDOME_PASSWORD=yourpassword\n' > manifest/user.txt
cat manifest/user.txt
```

Then source the config before any Docker build or compose command:

```sh
source scripts/dome-config.sh
```

## Getting Started

See `02-doc/howto.md` — overview and scenario comparison table.

- `02-doc/shell-howto.md` — scenarios 1 (Pi microSD) and 2 (VM, bare Ubuntu) → native ROS
- `02-doc/docker-howto.md` — scenario 3 (Docker): blank microSD → running container

## Setting Up A Development VM

Scenario 2: `scripts/host-setup.sh`, `scripts/bare-metal-base.sh`, and
`scripts/bare-metal-build.sh` also support provisioning a generic Ubuntu 24.04
(noble) VM (VMware, Parallels, cloud) instead of a Raspberry Pi, for
development without hardware. Set `DOME_TARGET=vm` in `manifest/user.txt`:

```sh
printf 'DOME_TARGET=vm\n' >> manifest/user.txt
```

With `DOME_TARGET=vm`, all three scripts skip Pi-hardware-only work: the
ReSpeaker overlay build (`host-setup.sh`), `raspi-config`/`i2c-tools`
(`bare-metal-base.sh` apt), `RPi.GPIO`/`spidev` (`bare-metal-base.sh` pip),
and the `libcamera-apps`/`seeed-linux-dtoverlays`/`mic_hat` repo clones
(`bare-metal-build.sh`). ROS/robot software installs identically either way.
Default is `DOME_TARGET=pi` — omit the line above for a real Pi.

The VM's Ubuntu release must match `UBUNTU_CODENAME` in
`manifest/config.txt` (currently `noble`/24.04) — see the prerequisite check
in `02-doc/shell-howto.md` before running these scripts.

## Running Tests

Verify manifest files are complete and Dockerfiles contain no hardcoded values:

```sh
bash tests/test_f01_manifest.sh
```

## Optional Large Dependencies

Install on demand inside the container:

```sh
install-optional-deps.sh           # all optional deps
install-optional-deps.sh torch     # torch + torchvision (~1 GB) — dome_vision ML
install-optional-deps.sh piper     # piper TTS + voice model (~110 MB) — dome_voice speech
```

Safe to re-run. `torch` takes 10-15 min first install on Pi.

## Runtime Data

Container volume mounts that persist across restarts:

- `runtime-data/ros/` → `~/.ros`
- `runtime-data/control/` → `~/.control`
- `runtime-data/dome/` → `~/.dome`
- `runtime-data/config/` → `~/.config`

## Security Notes

Never commit `manifest/user.txt`, `.env` files, private keys, Wi-Fi credentials,
or netplan files with passwords. Reviewed local copies go in `host-files/` (gitignored).

Removing secrets from the current tree does not remove them from git history.
Before publishing, rewrite or recreate history if it ever contained secrets.

## Repository Layout

### scripts/

| Script | Purpose |
|---|---|
| `scripts/bare-metal-base.sh` | Install ROS + all packages on Pi from manifest. Run as root. |
| `scripts/bare-metal-build.sh` | Clone repos, rosdep, colcon build on Pi from manifest. Run as root. |
| `scripts/host-setup.sh` | Provision Pi host: Docker, user, udev, boot firmware, dome.service. |
| `scripts/dome-config.sh` | Source to set `DOME_USER`, `DOME_IMAGE`, etc. from manifest. |
| `scripts/mac-build-base.sh` | Build and push base Docker image (Mac, cross-compile). |
| `scripts/mac-build-overlay.sh` | Build and push overlay Docker image (Mac, cross-compile). |
| `scripts/collect-inventory.sh` | Snapshot installed packages on live Pi to `inventory/`. |
| `scripts/install-optional-deps.sh` | Install large optional deps (torch, piper) inside container. |
| `scripts/docker-entrypoint.sh` | Sources ROS and workspace overlays before exec. |

### Dockerfiles

| File | Purpose |
|---|---|
| `Dockerfile.base` | Reusable ROS base image — apt/pip/curl packages from manifest. |
| `Dockerfile` | Overlay image — repo clones, colcon build, user setup. |
| `compose/compose.yaml` | Runs container with host networking and device access. |

### manifest/

All build configuration. Neither Dockerfiles nor bare-metal scripts contain
package names, URLs, build flags, or directory lists — those all live here.

| File | Owns |
|---|---|
| `config.txt` | ROS_DISTRO, UBUNTU_CODENAME, DOME_USER default |
| `packages.txt` | apt and ROS packages |
| `pip.txt` | pip3 packages |
| `repos.txt` | git repos to clone |
| `apt-repos.txt` | third-party apt repositories (Doppler, GitHub CLI) |
| `tools.txt` | curl-installed tools (mcfly) |
| `colcon.txt` | colcon build flags and skip list |
| `rosdep.txt` | rosdep install skip keys |
| `dirs.txt` | home subdirectory structure |
| `bashrc` | container shell environment |
| `lib.sh` | shared manifest parsing helpers |
| `user.txt` | **gitignored** — personal overrides (DOME_USER, DOCKERHUB_USERNAME, DOME_PASSWORD) |

See `02-doc/manifest-format.md` for format details on each file.

### Other directories

| Directory | Purpose |
|---|---|
| `02-doc/` | Documentation, architecture notes, current status |
| `host-file-templates/` | Sanitized templates for Pi host files (boot firmware, udev, netplan) |
| `runtime-data/` | Container volume mounts — persists across restarts (gitignored except subdirs) |
| `tests/` | Test scripts — run `bash tests/test_f01_manifest.sh` to verify manifest integrity |
| `inventory/` | Live Pi package snapshot from `collect-inventory.sh` (gitignored) |
