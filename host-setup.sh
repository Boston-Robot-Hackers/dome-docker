#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ./host-setup.sh" >&2
  exit 1
fi

USERNAME="pitosalas"
PASSWORD="daniel"

apt-get update
apt-get install -y \
  ca-certificates \
  curl \
  git \
  gnupg \
  net-tools \
  openssh-server \
  ripgrep \
  rsync \
  sudo \
  udev \
  usbutils \
  v4l-utils

if ! id "${USERNAME}" >/dev/null 2>&1; then
  adduser --gecos "" "${USERNAME}"
fi

echo "${USERNAME}:${PASSWORD}" | chpasswd
usermod -aG sudo "${USERNAME}"

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
usermod -aG docker "${USERNAME}"

if [[ -d ./host-files/etc/udev/rules.d ]]; then
  install -m 0755 -d /etc/udev/rules.d
  install -m 0644 ./host-files/etc/udev/rules.d/*.rules /etc/udev/rules.d/
  udevadm control --reload-rules
  udevadm trigger
else
  echo "No ./host-files/etc/udev/rules.d directory found; skipping custom udev restore."
fi

if [[ -d ./host-files/etc/netplan ]]; then
  install -m 0755 -d /etc/netplan
  install -m 0600 ./host-files/etc/netplan/*.yaml /etc/netplan/
  echo "Netplan files copied. Review them, then run: sudo netplan apply"
else
  echo "No ./host-files/etc/netplan directory found; skipping netplan restore."
fi

echo "Host setup complete. Log out and back in for docker group membership to apply."
