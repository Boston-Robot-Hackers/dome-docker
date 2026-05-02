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
- User: `pitosalas`
- SSH: enabled
- Wi-Fi: configure here if this Pi needs Wi-Fi on first boot
- Locale/timezone as needed

Write the image. This erases the selected microSD card.

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
ssh pitosalas@dome.local
```

If mDNS is unavailable, find the Pi address from the router and use:

```sh
ssh pitosalas@<pi-ip-address>
```

## 5. Clone This Repo On The Pi

```sh
cd ~
git clone <YOUR_DOME_DOCKER_REPO_URL> dome-docker
cd dome-docker
```

Use the real repository URL. If the repository is private, make sure the Pi can
authenticate to GitHub.

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

Basic setup:

```sh
sudo ./host-setup.sh
```

To also restore reviewed `/boot/firmware/config.txt` and
`/boot/firmware/cmdline.txt`:

```sh
sudo RESTORE_BOOT_FIRMWARE=1 ./host-setup.sh
```

Reboot after host setup:

```sh
sudo reboot
```

Log back in after reboot. Docker group membership may require this new login.

## 8. Build The Docker Image

Confirm GitHub SSH access for private repositories:

```sh
ssh -T git@github.com
```

Build with Docker Compose:

```sh
DOCKER_BUILDKIT=1 docker compose build --ssh default
```

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
docker compose run --rm dome
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
