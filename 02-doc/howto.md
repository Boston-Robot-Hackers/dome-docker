# Dome Docker: How To

Two paths from a blank microSD to a running ROS 2 environment on a Raspberry Pi 4 or 5.

## Which path?

| | Docker | Bare-Metal Shell |
|---|---|---|
| ROS runs in | Container | Natively on Pi |
| Build happens on | Mac (cross-compile) | Pi itself |
| Image update | `docker compose pull` | `git pull` + re-run scripts |
| Isolation | Strong | None |
| Resource overhead | Higher | Lower |
| Best for | Most users | Pi-only, no Mac needed |

## Guides

- **[docker-howto.md](docker-howto.md)** — Build on Mac, push to Docker Hub, pull and run on Pi
- **[shell-howto.md](shell-howto.md)** — Install ROS natively on Pi directly from manifest

## Common to both paths

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
cat > manifest/user.txt <<EOF
DOCKERHUB_USERNAME=your-dockerhub-username
DOME_USER=pitosalas
EOF
```

