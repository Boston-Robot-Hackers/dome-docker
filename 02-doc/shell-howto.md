# Shell Build: Blank microSD or VM to Native ROS

Complete path installing ROS natively on the **target** — either a Raspberry Pi
or a generic VM (VMware, Parallels, etc.). No other machine required after the
target is reachable over SSH. Everything reads from `manifest/` — same source
of truth as the Docker build.

Two machines are involved throughout:
- **Primary** — your Mac/laptop, used to flash media, copy SSH keys, and SSH in.
- **Target** — the Pi or VM being set up. All build scripts (`host-setup.sh`,
  `bare-metal-base.sh`, `bare-metal-build.sh`) run here, as root.

Each step below is labeled **Primary** or **Target**. Steps 1 is Pi-only
(flashing microSD) — skip it for a VM and boot/create the VM instead with
Ubuntu 24.04 already installed.

---

## Prerequisites

**Hardware (Pi target only):**
- Raspberry Pi 4 or 5
- microSD card (16 GB or larger)
- microSD card reader (any machine for flashing)

**VM target:** must be **Ubuntu 24.04 (noble)** specifically — matching
`UBUNTU_CODENAME=noble` in `manifest/config.txt` and the ROS 2 apt repo the
scripts configure. A different Ubuntu release (older or newer) has mismatched
system library versions and will fail with cryptic `apt` dependency errors
partway through `bare-metal-base.sh`, not with a clear "wrong OS" message.
Reachable over SSH, with a known IP address. Verify before doing anything else:

```sh
cat /etc/os-release   # VERSION_CODENAME must be "noble"
```

**GitHub SSH key** on the target — required for private repos (`rosutils`, `dome`, etc.).

---

## Step 1: Primary — Flash microSD (Pi only — skip for VM)

See **[howto.md](howto.md) → Flash the microSD**.

---

## Step 2: Target — First Boot

Pi: see **[howto.md](howto.md) → First boot** for SSH and clone steps.
VM: boot the VM, note its IP, `ssh` in, and `git clone` this repo.

After cloning, create `manifest/user.txt` on the **target** — this file is gitignored and must be created manually on every machine:

```sh
printf 'DOME_USER=pitosalas\nDOCKERHUB_USERNAME=pitosalas\n' > manifest/user.txt
cat manifest/user.txt
```

Replace `pitosalas` with your actual Linux username. `DOME_USER` must match the user created by `host-setup.sh` (or the user created by Raspberry Pi Imager during flashing). All build scripts read this file to know which user to set up.

---

## Step 3: Target — Host Setup

Run host setup — creates user, configures udev, sets up system services:

```sh
export DOME_PASSWORD=yourpassword
sudo --preserve-env=DOME_USER,DOME_PASSWORD scripts/host-setup.sh
```

Reboot when complete:

```sh
sudo reboot
```

**Primary** — SSH back in (replace `dome.local` with the target's IP if `.local`
mDNS doesn't resolve, e.g. most VMs):

```sh
ssh pitosalas@dome.local
cd ~/dome-docker
```

---

## Step 4: Target — Install ROS And Packages

Runs as root. Reads from `manifest/` to install:
- ROS 2 apt repository and `ros-kilted-ros-base`
- All apt, ROS, and pip packages from `manifest/packages.txt` and `manifest/pip.txt`
- Third-party apt repos (Doppler, GitHub CLI) from `manifest/apt-repos.txt`
- Curl-installed tools (mcfly) from `manifest/tools.txt`
- Initialises rosdep

```sh
sudo scripts/bare-metal-base.sh
```

Takes 10-30 min depending on Pi and network speed.

---

## Step 5: Target — Clone Repos And Build Workspace

Runs as root. Reads from `manifest/` to:
- Create home directory structure from `manifest/dirs.txt`
- Clone all repos from `manifest/repos.txt`
- Run `rosdep install` with skip-keys from `manifest/rosdep.txt`
- Run `colcon build` with flags from `manifest/colcon.txt`
- Install `manifest/bashrc` and `bru` symlink

Requires GitHub SSH key present for private repos.

**Primary** — copy your key from Mac to target. Replace `dome.local`
with the target's IP address if `.local` mDNS resolution isn't available (e.g. a VM):

```sh
scp ~/.ssh/id_ed25519 pitosalas@dome.local:~/.ssh/id_ed25519
scp ~/.ssh/id_ed25519.pub pitosalas@dome.local:~/.ssh/id_ed25519.pub
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

Takes 20-60 min on Pi (colcon build is slow on ARM); faster on a VM with more CPU.

---

## Step 6: Target — Smoke Test

```sh
source /opt/ros/kilted/setup.bash
source ~/ros2_ws/install/setup.bash
echo "$ROS_DISTRO"
ros2 --help
ls ~/ros2_ws/src
```

Expected: `kilted`, ros2 usage, list of cloned repos.

`.bashrc` is already configured by `bare-metal-build.sh` to source both overlays on login.

---

## Development Cycle

All commands below run on the **target**.

**Pull latest repo changes and rebuild:**

```sh
cd ~/dome-docker
git pull
sudo scripts/bare-metal-build.sh   # re-clones changed repos, rebuilds workspace
```

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

All commands below run on the **target**.

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
