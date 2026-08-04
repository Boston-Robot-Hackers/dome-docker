# Pi Howto: Raspberry Pi, microSD to Native ROS

Scenario 1 of 3 (see `02-doc/howto.md`) — flash a microSD, install ROS 2
natively on the Pi (`DOME_TARGET=pi`, the default). No Mac/VM build step;
everything after flashing runs on the Pi itself, over SSH from your Mac
("Primary").

---

## Prerequisites

- Raspberry Pi 4 or 5
- microSD card (16 GB or larger)
- microSD card reader (any machine for flashing)
- GitHub SSH key on your **Primary** machine (Mac) — copied to the Pi in
  Step 5, required for private repos (`rosutils`, `dome`, etc.)

---

## Step 1: Primary — Flash microSD

Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/).

Settings:
- **Device:** Raspberry Pi 4 or 5
- **OS:** Ubuntu Server 24.04 LTS, 64-bit
- **Storage:** your microSD card

In the advanced settings (gear icon):
- **Hostname:** `dome`
- **Username:** same as `DOME_USER` (e.g. `pitosalas`)
- **Password:** your chosen password
- **SSH:** enabled

Write, insert the card into the Pi, and power it on.

---

## Step 2: Pi — First Boot

SSH in from Primary (mDNS usually resolves `dome.local`):

```sh
ssh pitosalas@dome.local
```

Clone the repo and enter it:

```sh
sudo apt update && sudo apt install -y git ca-certificates
git clone https://github.com/Boston-Robot-Hackers/dome-docker.git ~/dome-docker
cd ~/dome-docker
```

Create `manifest/user.txt` on the **Pi** — this file is gitignored and must
be created manually on every machine:

```sh
printf 'DOME_USER=pitosalas\nDOCKERHUB_USERNAME=pitosalas\n' > manifest/user.txt
cat manifest/user.txt
```

Replace `pitosalas` with your actual Linux username. `DOME_USER` must match
the username you set in Raspberry Pi Imager during flashing. All build
scripts read this file to know which user to set up. No `DOME_TARGET` line
needed — it defaults to `pi` in `manifest/config.txt`.

**Primary** — set these once so every later `ssh`/`scp` command below can
just reuse them instead of retyping the username and address each time:

```sh
export TARGET_USER=pitosalas   # match DOME_USER above
export TARGET_HOST=dome.local
```

---

## Step 3: Pi — Host Setup

Creates the Pi user, configures udev, sets up system services:

```sh
export DOME_PASSWORD=yourpassword
sudo --preserve-env=DOME_USER,DOME_PASSWORD scripts/host-setup.sh
```

`host-setup.sh` prints the Pi's IP addresses just before finishing. If
`TARGET_HOST` (set in Step 2) doesn't match one of them, update it now —
then reboot when complete:

```sh
sudo reboot
```

SSH back in from Primary:

```sh
ssh "${TARGET_USER}@${TARGET_HOST}"   # mDNS usually works for dome.local
cd ~/dome-docker
```

---

## Step 4: Pi — Install ROS And Packages

Runs as root. Reads from `manifest/` to install:
- ROS 2 apt repository and `ros-kilted-ros-base`
- All apt, ROS, and pip packages from `manifest/packages.txt` and
  `manifest/pip.txt`, including Pi-hardware packages: `raspi-config`,
  `i2c-tools`, `RPi.GPIO`, `spidev`
- Third-party apt repos (Doppler, GitHub CLI, VS Code) from
  `manifest/apt-repos.txt`
- Curl-installed tools (mcfly) from `manifest/tools.txt`
- Initialises rosdep

```sh
sudo scripts/bare-metal-base.sh
```

Time varies by target hardware and network speed.

---

## Step 5: Pi — Clone Repos And Build Workspace

Runs as root. Reads from `manifest/` to:
- Create home directory structure from `manifest/dirs.txt`
- Clone all repos from `manifest/repos.txt`, including Pi-hardware repos:
  `libcamera-apps`, `seeed-linux-dtoverlays`, `mic_hat`
- Run `rosdep install` with skip-keys from `manifest/rosdep.txt`
- Run `colcon build` with flags from `manifest/colcon.txt`
- Install `manifest/bashrc` and `bru` symlink

Requires GitHub SSH key present for private repos.

**Primary** — copy your key from Mac to the Pi:

```sh
scp ~/.ssh/id_ed25519 "${TARGET_USER}@${TARGET_HOST}:~/.ssh/id_ed25519"
scp ~/.ssh/id_ed25519.pub "${TARGET_USER}@${TARGET_HOST}:~/.ssh/id_ed25519.pub"
```

**Pi** — set permissions and verify GitHub access:

```sh
chmod 600 ~/.ssh/id_ed25519
ssh -T git@github.com   # expect: "Hi <user>! You've successfully authenticated"
```

**Pi** — load the key into the agent:

```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

**Pi** — then build:

```sh
sudo scripts/bare-metal-build.sh
```

colcon build is slow on ARM; time varies a lot by target CPU.

---

## Step 6: Pi — Smoke Test

`bare-metal-build.sh` installed `.bashrc` so ROS and the workspace overlay
are sourced automatically in every new shell — **open a new terminal / SSH
session** (don't reuse the one `bare-metal-build.sh` ran in) and run:

```sh
echo "$ROS_DISTRO"
ros2 --help
ls ~/ros2_ws/src
```

Expected: `kilted`, ros2 usage, list of cloned repos.

---

## Development Cycle

All commands below run on the **Pi**.

**Pull latest repo changes and rebuild:**

```sh
cd ~/dome-docker
git pull
sudo scripts/bare-metal-build.sh   # re-clones changed repos, rebuilds workspace
```

Open a new terminal / SSH session afterward to pick up the rebuilt workspace
overlay.

**Add a package** — edit `manifest/packages.txt` or `manifest/pip.txt`, then:

```sh
sudo scripts/bare-metal-base.sh    # reinstalls packages (idempotent)
```

**Add a repo** — edit `manifest/repos.txt`, then:

```sh
sudo scripts/bare-metal-build.sh   # clones new repo, rebuilds
```

---

## Troubleshooting

All commands below run on the **Pi** unless noted.

**`bare-metal-base.sh` fails on apt-get** — network issue or stale cache:
```sh
sudo apt-get update
sudo scripts/bare-metal-base.sh
```

**`ERROR: failed to clone <private-repo>`** — SSH key not available to sudo:
```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh -T git@github.com          # confirm: "Hi <user>! You've successfully authenticated"
sudo scripts/bare-metal-build.sh
```

**colcon build fails** — rosdep may be missing a dependency:
```sh
cd ~/ros2_ws
rosdep update
rosdep install --from-paths src --ignore-src -r -y --skip-keys="ament_python gazebo_ros_pkgs"
colcon build --symlink-install --packages-skip depthai_rospi
```

**`ERROR: 'X' not set in manifest/config.txt`** — required field missing from manifest:
```sh
cat manifest/config.txt   # verify ROS_DISTRO, UBUNTU_CODENAME, DOME_USER present
```
