#!/usr/bin/env bash
# Bare-metal base setup: installs ROS, apt/pip/curl packages from manifest.
# Mirrors Dockerfile.base. Run as root on a fresh Ubuntu 24.04 Pi.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: run as root: sudo ./bare-metal-base.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${SCRIPT_DIR}/manifest"

source "${MANIFEST_DIR}/lib.sh"

ROS_DISTRO=$(manifest_config ROS_DISTRO "${MANIFEST_DIR}/config.txt")
UBUNTU_CODENAME=$(manifest_config UBUNTU_CODENAME "${MANIFEST_DIR}/config.txt")

echo "==> ROS_DISTRO=${ROS_DISTRO}  UBUNTU_CODENAME=${UBUNTU_CODENAME}"

# --- Locale ---
echo "==> Setting locale"
apt-get install -y locales
locale-gen en_US en_US.UTF-8
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# --- ROS 2 apt repository ---
echo "==> Adding ROS 2 apt repository"
apt-get install -y software-properties-common curl gnupg apt-transport-https
add-apt-repository -y universe
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu ${UBUNTU_CODENAME} main" \
    > /etc/apt/sources.list.d/ros2.list
apt-get update

# --- ROS base install ---
echo "==> Installing ros-${ROS_DISTRO}-ros-base"
apt-get install -y "ros-${ROS_DISTRO}-ros-base"

# --- apt packages from manifest/packages.txt ---
echo "==> Installing apt packages"
awk '/^\[apt\]/{f=1;next} /^\[/{f=0} f && /^[^#[:space:]]/' "${MANIFEST_DIR}/packages.txt" \
    | xargs apt-get install -y --no-install-recommends

# --- ROS packages from manifest/packages.txt ---
echo "==> Installing ROS packages"
awk -v d="${ROS_DISTRO}" \
    '/^\[ros\]/{f=1;next} /^\[/{f=0} f && /^[^#[:space:]]/{print "ros-"d"-"$0}' \
    "${MANIFEST_DIR}/packages.txt" \
    | xargs apt-get install -y --no-install-recommends

# --- curl-installed tools from manifest/tools.txt ---
echo "==> Installing curl tools"
for sect in $(manifest_sections "${MANIFEST_DIR}/tools.txt"); do
    method=$(manifest_require "$sect" method "${MANIFEST_DIR}/tools.txt")
    url=$(manifest_require "$sect" url "${MANIFEST_DIR}/tools.txt")
    args=$(manifest_field "$sect" args "${MANIFEST_DIR}/tools.txt")
    if [[ "$method" == "curl-sh" ]]; then
        curl -LSfs "$url" | sudo sh -s -- $args
    else
        echo "ERROR: unknown tool method '$method' for [$sect]" >&2
        exit 1
    fi
done

# --- third-party apt repos from manifest/apt-repos.txt ---
echo "==> Adding third-party apt repositories"
arch=$(dpkg --print-architecture)
for sect in $(manifest_sections "${MANIFEST_DIR}/apt-repos.txt"); do
    key_url=$(manifest_require "$sect" key_url "${MANIFEST_DIR}/apt-repos.txt")
    key_file=$(manifest_require "$sect" key_file "${MANIFEST_DIR}/apt-repos.txt")
    key_dearmor=$(manifest_require "$sect" key_dearmor "${MANIFEST_DIR}/apt-repos.txt")
    list=$(manifest_require "$sect" list "${MANIFEST_DIR}/apt-repos.txt")
    list="${list//\{arch\}/$arch}"
    list="${list//\{key_file\}/$key_file}"
    if [[ "$key_dearmor" == "yes" ]]; then
        curl -sLf --retry 3 --tlsv1.2 --proto "=https" "$key_url" | gpg --dearmor -o "$key_file"
    else
        curl -fsSL --retry 3 --tlsv1.2 --proto "=https" "$key_url" -o "$key_file"
        chmod go+r "$key_file"
    fi
    echo "$list" > "/etc/apt/sources.list.d/${sect}.list"
done
apt-get update
awk '/^\[/{next} /^packages[[:space:]]*=/{sub(/^packages[[:space:]]*=[[:space:]]*/,""); print}' \
    "${MANIFEST_DIR}/apt-repos.txt" \
    | tr ' ' '\n' | grep -v '^$' | xargs apt-get install -y

# --- pip packages from manifest/pip.txt ---
echo "==> Installing pip packages"
if grep -q '^[^#[:space:]]' "${MANIFEST_DIR}/pip.txt" 2>/dev/null; then
    awk '/^[^#[:space:]]/ && NF' "${MANIFEST_DIR}/pip.txt" \
        | xargs pip3 install --break-system-packages --ignore-installed
fi

# --- rosdep ---
echo "==> Initialising rosdep"
rosdep init || true

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "==> bare-metal-base.sh complete"
