# Shell Howto: Native ROS Install

Covers two of the three supported scenarios (see `02-doc/howto.md`):

- **Scenario 1 — Raspberry Pi, microSD**
- **Scenario 2 — VM, bare Ubuntu already installed**

Both scenarios run the exact same three scripts (`host-setup.sh`,
`bare-metal-base.sh`, `bare-metal-build.sh`); only `DOME_TARGET` differs. No
other machine required after the target is reachable over SSH. Everything
reads from `manifest/` — same source of truth as the Docker build (scenario 3).

Two label axes are used throughout:
- **Primary** / **Target** — which machine you type the command on. Primary =
  your Mac/laptop. Target = the Pi or VM being set up; all three build scripts
  run here, as root.
- **Pi:** / **VM:** — called out inline only where the two scenarios differ.
  No tag means the step is identical for both.

## Quick reference: what differs

| | Scenario 1 — Pi | Scenario 2 — VM |
|---|---|---|
| Step 1 (flash microSD) | Do it | Skip — boot/create the VM with Ubuntu 24.04 instead |
| `manifest/user.txt` | `DOME_TARGET=pi` (default, can omit) | `DOME_TARGET=vm` (required) |
| Reaching the target | `ssh user@dome.local` (mDNS) | `ssh user@<vm-ip>` (mDNS often unavailable) |
| `bare-metal-base.sh` / `bare-metal-build.sh` / `host-setup.sh` | Installs Pi-hardware packages, repos, ReSpeaker overlay | Skips all of it — same scripts, no edits needed |
| Everything else | identical | identical |

---

## Prerequisites

**Pi:**
- Raspberry Pi 4 or 5
- microSD card (16 GB or larger)
- microSD card reader (any machine for flashing)

**VM:** must be **Ubuntu 24.04 (noble)** specifically — matching
`UBUNTU_CODENAME=noble` in `manifest/config.txt` and the ROS 2 apt repo the
scripts configure. A different Ubuntu release (older or newer) has mismatched
system library versions and will fail with cryptic `apt` dependency errors
partway through `bare-metal-base.sh`, not with a clear "wrong OS" message.
Reachable over SSH, with a known IP address. Verify before doing anything else:

```sh
cat /etc/os-release   # VERSION_CODENAME must be "noble"
```

**Both:** GitHub SSH key on your **Primary** machine — copied to the target in Step 5, required for private repos (`rosutils`, `dome`, etc.).

---

## Step 1: Primary — Flash microSD

**Pi:** see **[howto.md](howto.md) → Flash the microSD**.

**VM:** skip this step entirely — boot or create the VM with Ubuntu 24.04
(noble) already installed, then continue at Step 2.

---

## Step 2: Target — First Boot

**Pi:** see **[howto.md](howto.md) → First boot** for SSH and clone steps.

**VM:** boot the VM, then run the following either in the VM's console window
directly, or over SSH from Primary (`ssh pitosalas@<vm-ip>` — note the IP first):

```sh
sudo apt update && sudo apt install -y git ca-certificates
git clone https://github.com/Boston-Robot-Hackers/dome-docker.git ~/dome-docker
cd ~/dome-docker
```

After cloning, create `manifest/user.txt` on the **target** — this file is gitignored and must be created manually on every machine:

```sh
printf 'DOME_USER=pitosalas\nDOCKERHUB_USERNAME=pitosalas\n' > manifest/user.txt
cat manifest/user.txt
```

Replace `pitosalas` with your actual Linux username. `DOME_USER` must match the user created by `host-setup.sh` (or the user created by Raspberry Pi Imager during flashing). All build scripts read this file to know which user to set up.

**Primary** — set these once so every later `ssh`/`scp` command below can just
reuse them instead of retyping the username and address each time:

```sh
export TARGET_USER=pitosalas   # match DOME_USER above
export TARGET_HOST=dome.local  # Pi: dome.local; VM: the VM's IP
```

**VM only** — also add `DOME_TARGET=vm`, or every script below installs
Pi-hardware-only packages/repos and the ReSpeaker overlay build fails (no
`/boot/firmware` on a VM). **Pi needs no action here** — `DOME_TARGET` defaults
to `pi` in `manifest/config.txt`:

```sh
printf 'DOME_TARGET=vm\n' >> manifest/user.txt
```

---

## Step 3: Target — Host Setup

Identical for both scenarios. Creates user, configures udev, sets up system services:

```sh
export DOME_PASSWORD=yourpassword
sudo --preserve-env=DOME_USER,DOME_PASSWORD scripts/host-setup.sh
```

`host-setup.sh` prints the target's IP addresses just before finishing. If
`TARGET_HOST` (set in Step 2) doesn't match one of them, update it now — then
reboot when complete:

```sh
sudo reboot
```

**Pi:** SSH back in from Primary:

```sh
ssh "${TARGET_USER}@${TARGET_HOST}"   # mDNS usually works for dome.local
cd ~/dome-docker
```

**VM:** if you're working directly in the VM's console window, no SSH needed —
just wait for the reboot and continue there. Only reconnect over SSH if
you're accessing the VM remotely from Primary:

```sh
ssh "${TARGET_USER}@${TARGET_HOST}"
cd ~/dome-docker
```

---

## Step 4: Target — Install ROS And Packages

Identical for both scenarios — `DOME_TARGET` set in Step 2 controls what gets
installed. Runs as root. Reads from `manifest/` to install:
- ROS 2 apt repository and `ros-kilted-ros-base`
- All apt, ROS, and pip packages from `manifest/packages.txt` and `manifest/pip.txt`
  (**Pi only:** `raspi-config`, `i2c-tools`, `RPi.GPIO`, `spidev` also install — skipped when `DOME_TARGET=vm`)
- Third-party apt repos (Doppler, GitHub CLI, VS Code) from `manifest/apt-repos.txt`
- Curl-installed tools (mcfly) from `manifest/tools.txt`
- Initialises rosdep

```sh
sudo scripts/bare-metal-base.sh
```

Time varies by target hardware and network speed.

---

## Step 5: Target — Clone Repos And Build Workspace

Identical for both scenarios. Runs as root. Reads from `manifest/` to:
- Create home directory structure from `manifest/dirs.txt`
- Clone all repos from `manifest/repos.txt`
  (**Pi only:** `libcamera-apps`, `seeed-linux-dtoverlays`, `mic_hat` also clone — skipped when `DOME_TARGET=vm`)
- Run `rosdep install` with skip-keys from `manifest/rosdep.txt`
- Run `colcon build` with flags from `manifest/colcon.txt`
- Install `manifest/bashrc` and `bru` symlink

Requires GitHub SSH key present for private repos.

**Primary** — copy your key from Mac to target:

```sh
scp ~/.ssh/id_ed25519 "${TARGET_USER}@${TARGET_HOST}:~/.ssh/id_ed25519"
scp ~/.ssh/id_ed25519.pub "${TARGET_USER}@${TARGET_HOST}:~/.ssh/id_ed25519.pub"
```

**Target** — set permissions and verify GitHub access:

```sh
chmod 600 ~/.ssh/id_ed25519
ssh -T git@github.com   # expect: "Hi <user>! You've successfully authenticated"
```

**Target** — load the key into the agent:

```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

**Target** — then build:

```sh
sudo scripts/bare-metal-build.sh
```

colcon build is slow on ARM; time varies a lot by target CPU.

---

## Step 6: Target — Smoke Test

`bare-metal-build.sh` installed `.bashrc` so ROS and the workspace overlay are
sourced automatically in every new shell — **open a new terminal / SSH
session** (don't reuse the one `bare-metal-build.sh` ran in) and run:

```sh
echo "$ROS_DISTRO"
ros2 --help
ls ~/ros2_ws/src
```

Expected: `kilted`, ros2 usage, list of cloned repos.

---

## Development Cycle

All commands below run on the **target**, identically for Pi and VM.

**Pull latest repo changes and rebuild:**

```sh
cd ~/dome-docker
git pull
sudo scripts/bare-metal-build.sh   # re-clones changed repos, rebuilds workspace
```

Open a new terminal / SSH session afterward to pick up the rebuilt workspace overlay.

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

All commands below run on the **target**, identically for Pi and VM unless noted.

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

**VM: `install: invalid target '/boot/firmware/overlays/...'`** — `DOME_TARGET=vm`
missing from `manifest/user.txt` (Step 2). Add it, then rerun the failing script.
