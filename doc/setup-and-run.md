# Dome Docker: Setup And Run

Complete path from a blank microSD to a running ROS 2 container on a Raspberry Pi 5.

---

## Prerequisites

**Mac:**
- [Docker Desktop](https://docs.docker.com/desktop/mac/install/) installed and running (whale icon in menu bar)
- Free [Docker Hub](https://hub.docker.com) account — your username appears top-right after login
- GitHub SSH key loaded in your Mac agent

**Hardware:**
- Raspberry Pi 5
- microSD card (16 GB or larger)
- microSD card reader for the Mac

---

## Part 1: Mac — Configure

Edit `manifest/user.txt` (gitignored, stays local):

```sh
cd ~/mydev/dome-docker
nano manifest/user.txt
```

Set:

```
DOCKERHUB_USERNAME=pitosalas
DOME_USER=pitosalas
```

- `DOCKERHUB_USERNAME`: your Docker Hub login name
- `DOME_USER`: Linux username that will be created on the Pi and inside the container

Set the password as an environment variable (keeps it out of files):

```sh
export DOME_PASSWORD=yourpassword
```

> **Note:** The password is baked into the Docker image. Do not use a sensitive password.

Verify your GitHub SSH key is loaded:

```sh
ssh -T git@github.com
ssh-add -l
```

If no key is loaded:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

---

## Part 2: Mac — Build And Push Docker Images

Log in to Docker Hub:

```sh
docker login
```

**Build the base image** (do once, then only when `manifest/packages.txt` changes):

```sh
source ./dome-config.sh
./mac-build-base.sh
```

This builds a `linux/arm64` ROS base image and pushes it to `docker.io/pitosalas/dome-base:kilted`.

**Build the overlay image** (do for every code or repo change):

Confirm your GitHub SSH key is loaded — private repos (`rosutils`, `dome`, `dome2`, etc.) are cloned via SSH during the build. If the key is missing, the build fails immediately with `ERROR: failed to clone ...`.

```sh
ssh-add -l   # must show a key
./mac-build-overlay.sh
```

This clones robot repos, runs `colcon build`, and pushes to `docker.io/pitosalas/dome-docker:dome-kilted`.

---

## Part 3: Mac — Flash The microSD

Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/) on the Mac.

Settings:
- **Device:** Raspberry Pi 5
- **OS:** Ubuntu Server 24.04 LTS, 64-bit
- **Storage:** your microSD card

In the Imager advanced settings (gear icon), configure:
- **Hostname:** `dome`
- **Username:** same as `DOME_USER` (e.g. `pitosalas`)
- **Password:** your chosen password
- **SSH:** enabled
- **Wi-Fi:** set SSID and password if using Wi-Fi

Write the image. This erases the card.

After flashing, eject and reinsert the card. On macOS it mounts as `/Volumes/system-boot`. Copy the boot firmware templates:

```sh
cp host-file-templates/boot/firmware/config.txt /Volumes/system-boot/config.txt
cp host-file-templates/boot/firmware/cmdline.txt /Volumes/system-boot/cmdline.txt
diskutil eject /Volumes/system-boot
```

---

## Part 4: Pi — First Boot And Host Setup

Insert the card into the Pi and power it on. Wait ~60 seconds, then SSH in:

```sh
ssh pitosalas@dome.local
```

If mDNS is unavailable, find the Pi's IP from your router and use:

```sh
ssh pitosalas@<pi-ip-address>
```

Clone this repo on the Pi:

```sh
sudo apt update && sudo apt install -y git ca-certificates
git clone https://github.com/Boston-Robot-Hackers/dome-docker.git ~/dome-docker
cd ~/dome-docker
```

Create `manifest/user.txt` (gitignored, must be created manually after cloning):

```sh
cat > manifest/user.txt <<EOF
DOCKERHUB_USERNAME=pitosalas
DOME_USER=pitosalas
EOF
```

Run host setup — this installs Docker, creates the Pi user, and configures the system:

```sh
export DOME_USER=pitosalas
export DOME_PASSWORD=yourpassword
sudo --preserve-env=DOME_USER,DOME_PASSWORD ./host-setup.sh
```

When it prints `Host setup complete`, reboot:

```sh
sudo reboot
```

---

## Part 5: Pi — Pull And Run

SSH back in after reboot:

```sh
ssh pitosalas@dome.local
cd ~/dome-docker
```

Log in to Docker Hub (required — image is private):

```sh
docker login
```

Source config, then pull and run:

```sh
source ./dome-config.sh
docker compose pull dome
docker compose run --rm dome
```

> **Note:** `source ./dome-config.sh` sets `DOME_IMAGE`, `DOME_USER`, and `DOME_PASSWORD`. Without it, Compose falls back to placeholder values and `docker compose pull` will fail with "pull access denied".

---

## Part 6: Pi — Auto-start Container On Boot (Optional)

Install the systemd service so the container starts automatically on reboot:

```sh
sudo cp ~/dome-docker/host-file-templates/etc/systemd/system/dome.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable dome
sudo systemctl start dome
```

Check it's running:
```sh
sudo systemctl status dome
journalctl -u dome -f
```

To disable auto-start:
```sh
sudo systemctl disable dome
```

---

## Part 7: Smoke Test

Inside the container:

```sh
echo "$ROS_DISTRO"
ros2 --help
ls ~/ros2_ws/src
```

Expected: `ROS_DISTRO` prints `kilted`, `ros2 --help` shows usage.

---

## Part 8: ML Dependencies (Optional)

`dome_vision` ML features (object embedding, world tracker) require `torch` and `torchvision` (~1GB). These are not baked into the image to keep it lean. Install on demand inside the container:

```sh
install-ml-deps.sh
```

First run takes 10-15 minutes on Pi. Safe to re-run — skips already-installed packages. Not needed unless running `dome_vision_ros`.

---

## Development Cycle

After the initial setup, the turnaround for code changes is:

**On Mac:**
```sh
# When manifest/packages.txt or Dockerfile.base changes (slow — full ROS rebuild):
source ./dome-config.sh
./mac-build-base.sh

# When code, repos, or Dockerfile changes (fast — uses cached base):
source ./dome-config.sh
./mac-build-overlay.sh
```

**On Pi:**
```sh
cd ~/dome-docker
source ./dome-config.sh
docker compose pull dome
docker compose run --rm dome
```

Rule of thumb:
- Changed `manifest/packages.txt` or `Dockerfile.base` → rebuild base then overlay
- Changed anything else → overlay only

---

## Troubleshooting

**"Cannot connect to Docker daemon"** — Docker Desktop not running:
```sh
open -a Docker
```

**`host-setup.sh` fails with "Could not resolve host: github.com"** — transient DNS failure, rerun:
```sh
sudo --preserve-env=DOME_USER,DOME_PASSWORD ./host-setup.sh
```

**DNS returns only IPv6 for `download.docker.com`:**
```sh
sudo resolvectl dns wlan0 1.1.1.1 8.8.8.8
sudo resolvectl flush-caches
sudo --preserve-env=DOME_USER,DOME_PASSWORD ./host-setup.sh
```

**SSH key not forwarded during Mac build (`Permission denied (publickey)` or `ERROR: failed to clone`):**

First confirm the key is loaded:
```sh
ssh-add -l
ssh-add --apple-use-keychain ~/.ssh/id_ed25519   # if not listed
```

If key is loaded but build still fails, the active Buildx builder may not be receiving SSH forwarding. Switch to the default builder:
```sh
docker context use default
docker buildx use default
./mac-build-overlay.sh
```

**`docker compose pull` fails with "pull access denied" on Pi** — `DOME_IMAGE` not set. Always source config first:
```sh
source ./dome-config.sh
docker compose pull dome
```

**Base or overlay push fails with network error, timeout, or connection reset** — often transient. Steps:
1. Check network connection is up
2. Verify Docker Desktop is current version (Docker Desktop → Check for Updates)
3. Restart Docker Desktop and wait for whale icon to stop animating
4. Retry the same build script — most failures are transient and clear on second run

If push still fails after restart:
```sh
source ./dome-config.sh
# build and push as separate steps — base:
docker buildx build --platform linux/arm64 --push -t "${DOME_BASE_IMAGE}" -f Dockerfile.base .
# or for overlay:
docker buildx build --platform linux/arm64 --push -t "${DOME_IMAGE}" .
```

**Mac build push fails with "use of closed network connection"** — Docker Desktop proxy bug. Restart Docker Desktop, then retry. If it keeps failing:
```sh
source ./dome-config.sh
docker buildx build --platform linux/arm64 --load -t "${DOME_IMAGE}" .
docker push "${DOME_IMAGE}"
```

**Overlay build is all CACHED but changes not included** — base image is stale. Rebuild base first:
```sh
source ./dome-config.sh
./mac-build-base.sh   # pushes new base
./mac-build-overlay.sh
```
Then on Pi: `source ./dome-config.sh && docker compose pull dome && docker compose run --rm dome`

**Doppler not available inside container** — was it added before or after the last base build? Rebuild base (see above).
