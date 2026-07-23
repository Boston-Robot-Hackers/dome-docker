# Howto: Dome Docker Scenarios

Three scenarios for getting to a running ROS 2 environment. All three read
from the same `manifest/` — single source of truth for packages, repos, and
build flags.

## Which scenario?

| | 1. Raspberry Pi (microSD) | 2. VM (bare Ubuntu) | 3. Docker |
|---|---|---|---|
| Hardware | Pi 4 or 5 | VMware/Parallels/cloud VM | Pi 4 or 5 |
| Setup starts from | Flashing a microSD | An already-installed Ubuntu 24.04 VM | Flashing a microSD |
| ROS runs in | Natively on the Pi | Natively in the VM | Container |
| Build happens on | The Pi itself | The VM itself | Mac (cross-compile) |
| Config | `DOME_TARGET=pi` (default) | `DOME_TARGET=vm` | n/a |
| Image update | `git pull` + re-run scripts | `git pull` + re-run scripts | `docker compose pull` |
| Best for | Pi-only, no Mac needed | Development without Pi hardware | Most users deploying to a Pi |
| Guide | [shell-howto.md](shell-howto.md) | [shell-howto.md](shell-howto.md) | [docker-howto.md](docker-howto.md) |

Scenarios 1 and 2 both use the bare-metal shell path (`shell-howto.md`) — the
only difference is `DOME_TARGET` and whether you flash a microSD or already
have a VM running Ubuntu 24.04. Scenario 3 (Docker) is Pi-only — VMs use the
bare-metal path directly.

## Common to scenarios 1 and 3 (Raspberry Pi)

### Flash the microSD

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
- **Wi-Fi:** SSID and password if using Wi-Fi

Write the image. This erases the card.

After flashing, eject and reinsert. On macOS it mounts as `/Volumes/system-boot`:

```sh
cp host-file-templates/boot/firmware/config.txt /Volumes/system-boot/config.txt
cp host-file-templates/boot/firmware/cmdline.txt /Volumes/system-boot/cmdline.txt
diskutil eject /Volumes/system-boot
```

### First boot — clone repo and configure

Insert card, power on, wait ~60 seconds, SSH in:

```sh
ssh pitosalas@dome.local
```

Install git and clone:

```sh
sudo apt update && sudo apt install -y git ca-certificates
git clone https://github.com/Boston-Robot-Hackers/dome-docker.git ~/dome-docker
cd ~/dome-docker
```

Create `manifest/user.txt` (gitignored — stays local):

```sh
printf 'DOME_USER=pitosalas\nDOCKERHUB_USERNAME=your-dockerhub-username\n' > manifest/user.txt
cat manifest/user.txt
```

