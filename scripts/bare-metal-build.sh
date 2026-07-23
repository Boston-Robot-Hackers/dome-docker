#!/usr/bin/env bash
# Bare-metal build: creates workspace, clones repos, rosdep, colcon build.
# Mirrors Dockerfile. Run as root after bare-metal-base.sh completes.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: run as root: sudo scripts/bare-metal-build.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${SCRIPT_DIR}/../manifest"

source "${MANIFEST_DIR}/lib.sh"

ROS_DISTRO=$(manifest_config ROS_DISTRO "${MANIFEST_DIR}/config.txt")
_DOME_USER_DEFAULT=$(manifest_config DOME_USER "${MANIFEST_DIR}/config.txt")
_DOME_USER_FILE=$(grep '^[[:space:]]*DOME_USER=' "${MANIFEST_DIR}/user.txt" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]' || true)
# Priority: env var > user.txt > config.txt default
DOME_USER="${DOME_USER:-${_DOME_USER_FILE:-${_DOME_USER_DEFAULT}}}"
echo "==> DOME_USER='${DOME_USER}' (from: env=${DOME_USER:-} file=${_DOME_USER_FILE} default=${_DOME_USER_DEFAULT})"

DOME_HOME="/home/${DOME_USER}"

if ! id "${DOME_USER}" >/dev/null 2>&1; then
    echo "ERROR: user '${DOME_USER}' does not exist. Run host-setup.sh first." >&2
    exit 1
fi

echo "==> DOME_USER=${DOME_USER}  ROS_DISTRO=${ROS_DISTRO}  DOME_HOME=${DOME_HOME}"

# --- Directory structure ---
echo "==> Creating home directory structure"
while IFS= read -r d; do
    [[ -z "$d" || "$d" == \#* ]] && continue
    mkdir -p "${DOME_HOME}/${d}"
done < "${MANIFEST_DIR}/dirs.txt"
touch "${DOME_HOME}/.bash_history"
chmod 600 "${DOME_HOME}/.bash_history"
chown -R "${DOME_USER}:${DOME_USER}" "${DOME_HOME}"

# --- SSH known hosts for github.com ---
echo "==> Adding github.com to known_hosts"
mkdir -p -m 0700 "${DOME_HOME}/.ssh"
ssh-keyscan github.com >> "${DOME_HOME}/.ssh/known_hosts" 2>/dev/null
chown -R "${DOME_USER}:${DOME_USER}" "${DOME_HOME}/.ssh"

# --- Clone repos ---
echo "==> Cloning repositories"
clone_section() {
    local section="$1"
    local base_dir="$2"
    mkdir -p "${base_dir}"
    while read -r repo dest branch; do
        [[ -z "${repo}" ]] && continue
        echo "  Cloning ${repo} -> ${base_dir}/${dest}"
        if [[ -n "${branch}" ]]; then
            sudo -u "${DOME_USER}" git clone --branch "${branch}" "${repo}" "${base_dir}/${dest}" \
                || { echo "ERROR: failed to clone ${repo}" >&2; exit 1; }
        else
            sudo -u "${DOME_USER}" git clone "${repo}" "${base_dir}/${dest}" \
                || { echo "ERROR: failed to clone ${repo}" >&2; exit 1; }
        fi
    done < <(awk -v s="${section}" '$0=="["s"]"{f=1;next} /^\[/{f=0} f && /^[^#[:space:]]/ && NF' "${MANIFEST_DIR}/repos.txt")
}
clone_section root "${DOME_HOME}"
clone_section ros_ws "${DOME_HOME}/ros2_ws/src"
clone_section uros_ws "${DOME_HOME}/uros_ws/src"
chown -R "${DOME_USER}:${DOME_USER}" "${DOME_HOME}"

# --- dome_vision pyproject.toml handling ---
if [[ -f "${DOME_HOME}/ros2_ws/src/dome_vision/dome_vision/pyproject.toml" ]]; then
    echo "==> Installing dome_vision package"
    rm -f "${DOME_HOME}/ros2_ws/src/dome_vision/dome_vision/setup.py"
    pip3 install --break-system-packages "${DOME_HOME}/ros2_ws/src/dome_vision/dome_vision/"
fi

# --- Clean build artifacts before rosdep ---
echo "==> Cleaning pre-existing build artifacts"
find "${DOME_HOME}/ros2_ws/src" -type d \
    \( -name build -o -name install -o -name log -o -name prefix_override \
       -o -name __pycache__ -o -name .pytest_cache \) \
    -prune -exec rm -rf {} + 2>/dev/null || true
find "${DOME_HOME}/ros2_ws/src" -type d -name "*.egg-info" -prune -exec rm -rf {} + 2>/dev/null || true

# --- rosdep ---
echo "==> Running rosdep"
sudo -u "${DOME_USER}" rosdep update
skip_keys=$(awk -F'=[[:space:]]*' '/^skip_keys/{print $2}' "${MANIFEST_DIR}/rosdep.txt")
if [[ -z "$skip_keys" ]]; then
    echo "ERROR: skip_keys not set in ${MANIFEST_DIR}/rosdep.txt" >&2
    exit 1
fi
sudo -u "${DOME_USER}" bash -c "
    cd ${DOME_HOME}/ros2_ws
    rosdep install --from-paths src --ignore-src -r -y --skip-keys='${skip_keys}'
"
chown -R "${DOME_USER}:${DOME_USER}" "${DOME_HOME}"

# --- colcon build ---
echo "==> Building ros2_ws"
flags=$(awk -F'=[[:space:]]*' '/^flags/{print $2}' "${MANIFEST_DIR}/colcon.txt")
skip=$(awk -F'=[[:space:]]*' '/^packages_skip/{print $2}' "${MANIFEST_DIR}/colcon.txt")
if [[ -z "$flags" ]]; then
    echo "ERROR: flags not set in ${MANIFEST_DIR}/colcon.txt" >&2
    exit 1
fi
sudo -u "${DOME_USER}" bash -c "
    source /opt/ros/${ROS_DISTRO}/setup.bash
    cd ${DOME_HOME}/ros2_ws
    colcon build ${flags} --packages-skip ${skip}
"

# --- bashrc and bru symlink ---
echo "==> Installing bashrc"
install -m 0644 -o "${DOME_USER}" -g "${DOME_USER}" \
    "${MANIFEST_DIR}/bashrc" "${DOME_HOME}/.bashrc"

if [[ -f "${DOME_HOME}/rosutils/bru.py" ]]; then
    chmod +x "${DOME_HOME}/rosutils/bru.py"
    sudo -u "${DOME_USER}" ln -sf "${DOME_HOME}/rosutils/bru.py" "${DOME_HOME}/.local/bin/bru"
fi

echo "==> bare-metal-build.sh complete"
