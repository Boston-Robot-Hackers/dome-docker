# Host Provisioning Plan

Target: Raspberry Pi 5 running Ubuntu Server 24.04.4 LTS, 64-bit, headless.

This is the host layer. It prepares the Pi to run Docker and provide hardware/network access to the container.

## 1. Flash Base OS

- Use Raspberry Pi Imager or equivalent.
- Select Ubuntu Server 24.04.4 LTS, 64-bit, Raspberry Pi image.
- Configure headless SSH during imaging if possible.

## 2. Create Main User

- User: `pitosalas`
- Initial password: `daniel`
- Full sudo privileges.

Candidate commands for provisioning:

```sh
sudo adduser pitosalas
sudo usermod -aG sudo pitosalas
```

For automation, set the password non-interactively only in a secured local provisioning script.

## 3. Network Setup

- Restore/recreate netplan from `/etc/netplan`.
- Current source candidate:
  - `/etc/netplan/50-cloud-init.yaml`

Review before applying because interface names, Wi-Fi credentials, and static IP choices may be host-specific.

## 4. Install Host Packages

Minimum host-side candidates:

```sh
sudo apt update
sudo apt install -y \
  ca-certificates \
  curl \
  gnupg \
  git \
  openssh-server \
  net-tools \
  ripgrep \
  rsync \
  udev \
  usbutils \
  v4l-utils
```

Install Docker using the official Docker apt repository unless Ubuntu's packaged Docker is preferred.

## 5. Docker Setup

- Install Docker Engine.
- Enable and start Docker.
- Add `pitosalas` to the `docker` group if passwordless Docker is acceptable.

Candidate commands:

```sh
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker pitosalas
```

## 6. Device And Udev Setup

Custom udev rules found on current microSD:

- `/etc/udev/rules.d/50-movidius.rules`
- `/etc/udev/rules.d/50-qualcomm-oak.rules`
- `/etc/udev/rules.d/80-movidius.rules`
- `/etc/udev/rules.d/97-ldlidar.rules`
- `/etc/udev/rules.d/98-esp32.rules`
- `/etc/udev/rules.d/99-platformio-udev.rules`

`/home/pitosalas/rosutils/dome/udev` also contains host udev material:

- `97-ldlidar.rules`
  - Creates `ldlidar` symlink for a CP210x USB serial device.
- `98-esp32.rules`
  - Creates `esp32` symlink for known ESP32 serial numbers.
- `99-platformio-udev.rules`
  - General PlatformIO board access rules.
- `install.sh`
  - Copies `*.rules` into `/etc/udev/rules.d/`, reloads rules, and triggers udev.

Review and restore these as host files, not container files.

Likely runtime device access needed by Docker:

```sh
--privileged
--network=host
-v /dev/bus/usb:/dev/bus/usb
--device-cgroup-rule='c 189:* rmw'
```

Camera access may also require passing:

- `/dev/media*`
- `/dev/video*`
- `/dev/v4l-subdev*`
- `/dev/dma_heap`

## 7. Host Services

Current candidates:

- `/etc/systemd/system/memory-compaction.service`
- `/etc/systemd/system/rt-throttling.service`
- `/opt/ros2-rt-rpi4/rt-throttling`
- `/opt/ros2-rt-rpi4/memory-compaction`

These are host-level services, not normal Dockerfile content.

## 8. User Shell Setup

Review and restore relevant user startup files:

- `/home/pitosalas/.bashrc`
- `/home/pitosalas/.profile`
- `/home/pitosalas/.bash_aliases`
- Fish config if still used
- Scripts sourced by those files

Split responsibilities:

- Host shell setup should configure Docker/host conveniences.
- Container shell setup should source ROS Kilted and workspace overlays.

## 9. Files To Mount Or Copy From Host

Candidates:

- `~/.ros/camera_info`
- `~/.control/maps`
- SSH keys only if explicitly needed and handled securely.

Likely exclusions:

- Logs
- Build directories
- Caches
- AI tool state directories
