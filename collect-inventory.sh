#!/usr/bin/env bash
# collect-inventory.sh — snapshot installed packages and system state to inventory/
# Run on live Pi (or inside container). Output dir defaults to ./inventory.
# Author: Pito Salas and Claude Code
# Open Source Under MIT license

set -euo pipefail

OUT="${1:-$(dirname "$0")/inventory}"
PKG="$OUT/packages"
mkdir -p "$OUT" "$PKG"

echo "Collecting inventory to $OUT ..."

# --- top-level system state ---

# listening sockets
ss -tlnup > "$OUT/listening-sockets.txt"

# systemd unit files and active units
systemctl list-unit-files --no-pager > "$OUT/systemd-unit-files.txt"
systemctl list-units --all --no-pager > "$OUT/systemd-units-all.txt"

# user crontab (exit 1 with no crontab is normal; treat as empty)
crontab -l > "$OUT/user-crontab.txt" 2>/dev/null || true

# dpkg full install state (top-level copy)
dpkg-query -W -f='${Package}\t${Version}\t${Architecture}\t${db:Status-Abbrev}\n' \
    > "$OUT/dpkg-packages.tsv"

# apt manually installed (top-level copy)
apt-mark showmanual > "$OUT/apt-manual.txt"

# --- packages/ detailed apt state ---

dpkg-query -W -f='${Package}\t${Version}\t${Architecture}\t${db:Status-Abbrev}\n' \
    > "$PKG/dpkg-installed.tsv"

apt-mark showmanual > "$PKG/apt-mark-manual.txt"
apt-mark showauto   > "$PKG/apt-mark-auto.txt"

# apt install history from log
cp /var/log/apt/history.log "$PKG/apt-history-installs.txt"

# extract Install: commandlines from apt history (grep exits 1 on no match)
grep -E "^(Start-Date|Commandline|Install):" "$PKG/apt-history-installs.txt" \
    | grep -A1 "^Commandline:.*apt.*install" \
    > "$PKG/apt-install-commandlines.txt" || true

# sudo apt install lines from shell history
grep -hE "sudo apt(-get)? install" ~/.bash_history ~/.zsh_history \
    | sort -u > "$PKG/sudo-apt-install-candidates.txt" || true

# all install-flavored lines from shell history
grep -hE "(apt|pip3?|snap|cargo|npm|gem) (install|add)" ~/.bash_history ~/.zsh_history \
    | sort -u > "$PKG/shell-history-install-commands.txt" || true

# ROS package search cache (kilted)
apt-cache search "^ros-kilted" > "$PKG/apt-cache-search-ros-kilted.txt"

# --- python ---

pip3 freeze > "$PKG/pip3-freeze.txt"
pip3 freeze --user > "$PKG/pip3-user-freeze.txt"

# pip packages installed as user that are not in system freeze (install candidates)
comm -23 \
    <(sort "$PKG/pip3-user-freeze.txt") \
    <(sort "$PKG/pip3-freeze.txt") \
    > "$PKG/pip3-install-user-candidates.txt"

# python dependency files found under home
find ~ -maxdepth 6 \( -name "requirements*.txt" -o -name "pyproject.toml" \) \
    | sort > "$PKG/python-dependency-files.txt"

echo "Done."
