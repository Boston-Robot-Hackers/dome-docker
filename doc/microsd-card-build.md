# Build A New Raspberry Pi microSD Card

This runbook starts from a formatted microSD card attached to a Mac and ends
with a Raspberry Pi 5 host ready to build and run the Dome Docker stack.

For a more automated Mac workflow that builds the arm64 Docker image before the
Pi boots and uses cloud-init to pull it on first boot, see
`mac-prebuilt-microsd.md`.

## 1. Identify And Erase The microSD Card

Plug the microSD card into the Mac, then list disks:

```sh
diskutil list
```

Find the microSD device, such as `/dev/disk4`. Verify it by checking size,
external/removable status, and partition names. Do not use the Mac internal
disk.

Unmount the whole disk:

```sh
diskutil unmountDisk /dev/diskN
```

Erase and format it as a single FAT32 volume:

```sh
diskutil eraseDisk FAT32 RPIBOOT MBRFormat /dev/diskN
```

Replace `/dev/diskN` with the actual microSD disk, for example `/dev/disk4`.
This deletes everything on that device.

## 2. Flash Ubuntu Server

Use Raspberry Pi Imager on the Mac.

Settings:

- Device: Raspberry Pi 5
- OS: Ubuntu Server 24.04 LTS, 64-bit
- Storage: attached microSD card

In Imager settings, configure:

- Hostname: `dome`
- User: your chosen Pi user, for example `robot`
- SSH: enabled
- Wi-Fi: configure here if this Pi needs Wi-Fi on first boot
- Locale/timezone as needed

Write the image. This erases the selected microSD card.

If using Wi-Fi, prefer writing a reviewed `network-config` based on
`host-file-templates/boot/firmware/network-config.template` so the Pi uses DNS
servers that return IPv4 records for Docker's package repository.

## 3. Copy Boot Firmware Templates

After flashing, eject and reinsert the card if the boot partition is not mounted.
On macOS it is usually mounted as `/Volumes/system-boot`.

From this repo on the Mac:

```sh
cd ~/mydev/dome-docker
cp host-file-templates/boot/firmware/config.txt /Volumes/system-boot/config.txt
cp host-file-templates/boot/firmware/cmdline.txt /Volumes/system-boot/cmdline.txt
diskutil eject /Volumes/system-boot
```

Do not copy `user-data.template` or `network-config.template` without replacing
their placeholders and reviewing the result for password hashes or Wi-Fi
credentials.

## 4. Boot And SSH Into The Pi

Insert the card into the Raspberry Pi 5 and boot it.

Try mDNS first:

```sh
ssh <your-pi-user>@dome.local
```

If mDNS is unavailable, find the Pi address from the router and use:

```sh
ssh <your-pi-user>@<pi-ip-address>
```

## 5. Clone This Repo On The Pi

```sh
cd ~
sudo apt update
sudo apt install -y git ca-certificates
git clone https://github.com/Boston-Robot-Hackers/dome-docker.git dome-docker
cd dome-docker
# Create manifest/user.txt — gitignored, must be created manually:
cat > manifest/user.txt <<EOF
DOCKERHUB_USERNAME=pitosalas
DOME_USER=pitosalas
EOF
source ./dome-config.sh
```

If the repository is private, use the SSH URL instead and make sure the Pi can
authenticate to GitHub before cloning:

```sh
git clone git@github.com:Boston-Robot-Hackers/dome-docker.git dome-docker
```

If `~/dome-docker` is missing later, return to this step before running Docker
commands. Docker is installed by `host-setup.sh`, which lives inside this repo.

## 6. Prepare Optional Host Files

Runtime secrets and host-specific files belong under ignored `host-files/`, not
in git.

To restore reviewed boot firmware files through `host-setup.sh`:

```sh
mkdir -p host-files/boot/firmware
cp host-file-templates/boot/firmware/config.txt host-files/boot/firmware/config.txt
cp host-file-templates/boot/firmware/cmdline.txt host-files/boot/firmware/cmdline.txt
```

If restoring udev or netplan files, place reviewed files under:

```text
host-files/etc/udev/rules.d/
host-files/etc/netplan/
```

## 7. Run Host Setup

This installs Docker, creates the Pi user, and configures the system.

Basic setup:

```sh
sudo --preserve-env=DOME_USER,DOME_PASSWORD ./host-setup.sh
```

If setup stops with a DNS error such as `Could not resolve host:
download.docker.com`, verify the Pi has working internet and DNS before
rerunning:

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

To also restore reviewed `/boot/firmware/config.txt` and
`/boot/firmware/cmdline.txt`:

```sh
sudo --preserve-env=DOME_USER,DOME_PASSWORD RESTORE_BOOT_FIRMWARE=1 ./host-setup.sh
```

Reboot after host setup:

```sh
sudo reboot
```

Log back in after reboot. Docker group membership may require this new login.

## 8. Build Or Pull The Docker Image

Preferred: build and push the image from the Mac, then pull it on the Pi. See
`mac-build-dockerhub.md`.

If `DOME_IMAGE` points to a pushed Docker Hub image:

```sh
docker compose pull dome
docker compose run --rm --no-build dome
```

Fallback: build directly on the Pi.

The Docker build clones private GitHub repositories. On the Pi, use the helper:

```sh
./pi-build.sh
```

If the Pi's GitHub key is not authorized yet, the helper prints the public key
to add to GitHub. Add it, then rerun `./pi-build.sh`. For local Pi builds, the
helper also builds `DOME_BASE_IMAGE` first if it is not already present.

If building on a Mac for Raspberry Pi arm64 instead of building on the Pi:

```sh
DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/arm64 \
  --ssh default=$SSH_AUTH_SOCK \
  --load \
  -t dome-docker:dome-kilted .
```

## 9. Run The Container

```sh
docker compose run --rm --no-build dome
```

Smoke tests inside the container:

```sh
echo "$ROS_DISTRO"
ros2 --help
ls ~/ros2_ws/src
```

Expected ROS distribution:

```text
kilted
```

## 10. Hardware Checks

Run these on the Pi host or inside the container as appropriate:

```sh
ls /dev/video*
ls /dev/media*
ls /dev/dma_heap
ls /dev/ldlidar
ros2 topic list
```

If device paths are missing, check host-side boot firmware, udev rules, cabling,
and Docker device mounts before changing the image.
