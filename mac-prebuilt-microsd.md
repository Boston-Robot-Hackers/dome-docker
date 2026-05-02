# Mac-Prebuilt microSD Strategy

macOS can write the Raspberry Pi boot partition directly, but it does not
natively mount and edit the Ubuntu root filesystem because that partition is
ext4. A truly offline, fully provisioned card from macOS requires a Linux VM,
USB card-reader passthrough, and rootfs customization.

For the normal build-on-Mac/pull-on-Pi workflow, see `mac-build-dockerhub.md`.

The more automated first-boot approach is:

1. Build the arm64 Docker image on the Mac.
2. Push it to a registry the Pi can read.
3. Write boot firmware and cloud-init files to the microSD boot partition.
4. Let cloud-init install Docker, clone this repo, and pull the image on first
   boot.

This gives a nearly hands-off card while avoiding fragile macOS ext4/chroot
work.

## 1. Build And Push The Image From The Mac

Make sure Docker Desktop is running and GitHub SSH access works:

```sh
cd ~/mydev/dome-docker
ssh -T git@github.com
ssh-add -l
```

Set the registry image name. Replace this with your real registry target:

```sh
export DOME_IMAGE=ghcr.io/YOUR_GITHUB_USER/dome-docker:dome-kilted
```

Build and push an arm64 image:

```sh
DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/arm64 \
  --ssh default=$SSH_AUTH_SOCK \
  --push \
  -t "$DOME_IMAGE" .
```

The Pi must be able to pull this image. For a private registry, configure Docker
login on the Pi during first boot or make the image readable by the Pi's
credentials.

## 2. Prepare Cloud-Init Files

Copy the templates to a local, ignored working area:

```sh
mkdir -p local-cloud-init
cp host-file-templates/boot/firmware/user-data.template local-cloud-init/user-data
cp host-file-templates/boot/firmware/network-config.template local-cloud-init/network-config
```

Edit `local-cloud-init/user-data`:

- Replace `REPLACE_WITH_PASSWORD_HASH`.
- Add the first-boot commands from the example below.
- Replace `REPLACE_WITH_REPO_URL` with the URL for this setup repo.
- Replace `REPLACE_WITH_IMAGE`.

Edit `local-cloud-init/network-config`:

- Replace `REPLACE_WITH_WIFI_SSID`.
- Replace `REPLACE_WITH_WIFI_PASSWORD`.

Do not commit `local-cloud-init/`.

## 3. First-Boot Cloud-Init Example

Add this to `local-cloud-init/user-data`, below the `users:` section:

```yaml
write_files:
  - path: /usr/local/sbin/dome-firstboot.sh
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -euo pipefail

      apt-get update
      apt-get install -y ca-certificates curl git gnupg openssh-server ripgrep rsync sudo udev usbutils v4l-utils

      install -m 0755 -d /etc/apt/keyrings
      if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
      fi

      . /etc/os-release
      cat >/etc/apt/sources.list.d/docker.list <<EOF
      deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable
      EOF

      apt-get update
      apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      systemctl enable docker
      systemctl start docker
      usermod -aG docker REPLACE_WITH_HOST_USER

      if [[ ! -d /home/REPLACE_WITH_HOST_USER/dome-docker ]]; then
        git clone REPLACE_WITH_REPO_URL /home/REPLACE_WITH_HOST_USER/dome-docker
      fi
      chown -R REPLACE_WITH_HOST_USER:REPLACE_WITH_HOST_USER /home/REPLACE_WITH_HOST_USER/dome-docker

      cd /home/REPLACE_WITH_HOST_USER/dome-docker
      sed -i 's#image: .*#image: REPLACE_WITH_IMAGE#' compose.yaml
      docker compose pull dome

runcmd:
  - [bash, /usr/local/sbin/dome-firstboot.sh]
```

If the image is private, add a `docker login` step before `docker compose pull`.
Use a narrowly scoped token and do not commit it.

## 4. Write The microSD Boot Partition

Identify and erase the microSD card using the steps in
`microsd-card-build.md`, then flash Ubuntu Server with Raspberry Pi Imager. Eject
and reinsert the card if the boot partition is not mounted.

On macOS, the boot partition is usually `/Volumes/system-boot`:

```sh
cp host-file-templates/boot/firmware/config.txt /Volumes/system-boot/config.txt
cp host-file-templates/boot/firmware/cmdline.txt /Volumes/system-boot/cmdline.txt
cp local-cloud-init/user-data /Volumes/system-boot/user-data
cp local-cloud-init/network-config /Volumes/system-boot/network-config
diskutil eject /Volumes/system-boot
```

Boot the Pi. On first boot, cloud-init installs Docker, clones this repo, and
pulls the prebuilt image.

## Fully Offline Alternative

If the card must be completely built before it ever boots, use a Linux VM on the
Mac with the USB card reader passed through to the VM. From there, mount the
ext4 root filesystem and provision it as Linux. That route is more powerful but
more brittle than cloud-init and should be treated as a separate procedure.
