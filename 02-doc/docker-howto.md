# Docker Howto: Blank microSD to Running Container

Scenario 3 of 3 (see `02-doc/howto.md`) — Pi-only. Build happens on Mac;
container runs on Pi. VMs use the bare-metal path instead (`shell-howto.md`).

---

## Prerequisites

**Mac:**
- [Docker Desktop](https://docs.docker.com/desktop/mac/install/) installed and running
- Free [Docker Hub](https://hub.docker.com) account
- GitHub SSH key loaded in your Mac agent

**Hardware:**
- Raspberry Pi 4 or 5
- microSD card (16 GB or larger)
- microSD card reader for the Mac

---

## Step 1: Mac — Configure

Edit `manifest/user.txt` (gitignored, stays local):

```sh
cd ~/mydev/dome-docker
nano manifest/user.txt
```

Set:

```
DOCKERHUB_USERNAME=your-dockerhub-username
DOME_USER=pitosalas
```

Set password as environment variable (keeps it out of files):

```sh
export DOME_PASSWORD=yourpassword
```

> **Note:** Password is baked into the Docker image. Do not use a sensitive password.

Verify GitHub SSH key is loaded:

```sh
ssh -T git@github.com
ssh-add -l
```

If no key loaded:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

---

## Step 2: Mac — Build And Push

Log in to Docker Hub:

```sh
docker login
```

**Build base image** (once, then only when `manifest/packages.txt` or `Dockerfile.base` changes):

```sh
source scripts/dome-config.sh
scripts/mac-build-base.sh
```

Builds `linux/arm64` ROS base image and pushes to `docker.io/<DOCKERHUB_USERNAME>/dome-base:<ROS_DISTRO>`.

**Build overlay image** (for every code or repo change):

```sh
source scripts/dome-config.sh   # must be sourced first
ssh-add -l                # must show a key — private repos cloned via SSH
scripts/mac-build-overlay.sh
```

Clones robot repos, runs `colcon build`, pushes to `docker.io/<DOCKERHUB_USERNAME>/dome-docker:dome-<ROS_DISTRO>`.

---

## Step 3: Flash microSD

See **[howto.md](howto.md) → Flash the microSD**.

---

## Step 4: Pi — First Boot And Host Setup

See **[howto.md](howto.md) → First boot**.

After cloning and creating `manifest/user.txt`, run host setup — installs Docker, creates Pi user, configures udev, installs `dome.service`:

```sh
export DOME_PASSWORD=yourpassword
sudo --preserve-env=DOME_USER,DOME_PASSWORD scripts/host-setup.sh
```

`host-setup.sh` prints the Pi's IP addresses just before finishing — useful if
`dome.local` (mDNS) doesn't resolve. Reboot when complete:

```sh
sudo reboot
```

---

## Step 5: Pi — Pull And Run

SSH back in after reboot:

```sh
ssh pitosalas@dome.local
cd ~/dome-docker
```

Log in to Docker Hub (image is private):

```sh
docker login
```

Source config, pull, and run:

```sh
source scripts/dome-config.sh
docker compose -f compose/compose.yaml --project-directory . pull dome
docker compose -f compose/compose.yaml --project-directory . run --rm dome
```

> `source scripts/dome-config.sh` is required — sets `DOME_IMAGE`, `DOME_USER`, `DOME_PASSWORD`. Without it, Compose falls back to placeholder values and pull fails.

---

## Step 6: Smoke Test

Inside the container:

```sh
echo "$ROS_DISTRO"
ros2 --help
ls ~/ros2_ws/src
```

Expected: `kilted`, ros2 usage, list of cloned repos.

---

## Step 7: Optional Large Dependencies

Install on demand inside the container:

```sh
install-optional-deps.sh           # everything
install-optional-deps.sh torch     # torch + torchvision (~1 GB, dome_vision ML)
install-optional-deps.sh piper     # piper TTS + voice model (~110 MB, dome_voice)
```

Safe to re-run. `torch` takes 10-15 min on Pi first run.

After installing piper:

```sh
export PIPER_BIN=~/.local/bin/piper
export PIPER_MODEL_PATH=~/.local/share/piper/en_US-amy-medium.onnx
```

---

## Auto-Start On Boot

`host-setup.sh` installs and enables `dome.service` automatically:

```sh
sudo systemctl status dome
journalctl -u dome -f
sudo systemctl disable dome   # to turn off
```

---

## Development Cycle

**On Mac** — after any change:

```sh
source scripts/dome-config.sh

# packages.txt or Dockerfile.base changed (slow):
scripts/mac-build-base.sh && scripts/mac-build-overlay.sh

# code, repos, or Dockerfile changed (fast — cached base):
scripts/mac-build-overlay.sh
```

**On Pi:**

```sh
source scripts/dome-config.sh
docker compose -f compose/compose.yaml --project-directory . pull dome
docker compose -f compose/compose.yaml --project-directory . run --rm dome
```

---

## Troubleshooting

**"Cannot connect to Docker daemon"** — Docker Desktop not running:
```sh
open -a Docker
```

**`host-setup.sh` fails "Could not resolve host: github.com"** — transient DNS, rerun:
```sh
sudo --preserve-env=DOME_USER,DOME_PASSWORD scripts/host-setup.sh
```

**DNS returns only IPv6 for `download.docker.com`:**
```sh
sudo resolvectl dns wlan0 1.1.1.1 8.8.8.8
sudo resolvectl flush-caches
sudo --preserve-env=DOME_USER,DOME_PASSWORD scripts/host-setup.sh
```

**`Permission denied (publickey)` or `ERROR: failed to clone` during Mac build:**
```sh
ssh-add -l
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
# If still failing, switch to default builder:
docker context use default && docker buildx use default
scripts/mac-build-overlay.sh
```

**`docker compose pull` fails "pull access denied"** — always source config first:
```sh
source scripts/dome-config.sh
docker compose -f compose/compose.yaml --project-directory . pull dome
```

**Push fails with network error or timeout** — usually transient:
1. Check network
2. Update Docker Desktop
3. Restart Docker Desktop
4. Retry

Manual push if still failing:
```sh
source scripts/dome-config.sh
docker buildx build --platform linux/arm64 --push -t "${DOME_BASE_IMAGE}" -f Dockerfile.base .
docker buildx build --platform linux/arm64 --push -t "${DOME_IMAGE}" .
```

**Overlay build all CACHED but changes not included** — rebuild base first:
```sh
source scripts/dome-config.sh
scripts/mac-build-base.sh
scripts/mac-build-overlay.sh
```
