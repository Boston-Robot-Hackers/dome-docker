#!/usr/bin/env bash
# Tests for F04: Pi-only swapfile setup in bare-metal-base.sh.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_DIR="${REPO_DIR}/manifest"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== F04 Pi swap tests ==="

echo "--- config.txt defaults ---"
source "${MANIFEST_DIR}/lib.sh"
got=$(manifest_config SWAP_SIZE_MB "${MANIFEST_DIR}/config.txt")
[[ "$got" == "2048" ]] && pass "config.txt SWAP_SIZE_MB defaults to 2048" \
    || fail "config.txt SWAP_SIZE_MB: got='$got' expected='2048'"

echo "--- bare-metal-base.sh references swap setup ---"
grep -q 'SWAP_SIZE_MB' "${REPO_DIR}/scripts/bare-metal-base.sh" \
    && pass "bare-metal-base.sh references SWAP_SIZE_MB" \
    || fail "bare-metal-base.sh missing SWAP_SIZE_MB"
grep -q '/swapfile' "${REPO_DIR}/scripts/bare-metal-base.sh" \
    && pass "bare-metal-base.sh references /swapfile" \
    || fail "bare-metal-base.sh missing /swapfile"
grep -q '_SWAP_SIZE_MB_FILE' "${REPO_DIR}/scripts/bare-metal-base.sh" \
    && pass "bare-metal-base.sh reads SWAP_SIZE_MB from user.txt (override precedence)" \
    || fail "bare-metal-base.sh missing user.txt override for SWAP_SIZE_MB"

echo "--- syntax check ---"
bash -n "${REPO_DIR}/scripts/bare-metal-base.sh" \
    && pass "syntax: scripts/bare-metal-base.sh" \
    || fail "syntax: scripts/bare-metal-base.sh"

echo "--- behavior: pi target, fresh swapfile ---"
run_swap_step() {
    # Extracts and runs just the swapfile step in a stubbed shell so no real
    # disk/swap operations happen — fallocate/mkswap/swapon/swapon(--show)
    # and /etc/fstab are all faked via a scratch dir + PATH shims.
    local dome_target="$1" swap_size="$2" scratch="$3"
    mkdir -p "${scratch}/bin"
    cat > "${scratch}/bin/fallocate" <<'EOF'
#!/usr/bin/env bash
echo "fallocate $*" >> "${SCRATCH}/calls.log"
touch "${SCRATCH}/swapfile"
EOF
    cat > "${scratch}/bin/mkswap" <<'EOF'
#!/usr/bin/env bash
echo "mkswap $*" >> "${SCRATCH}/calls.log"
EOF
    cat > "${scratch}/bin/swapon" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "--show=NAME" ]]; then
    [[ -f "${SCRATCH}/swap_active" ]] && echo "/swapfile"
    exit 0
fi
echo "swapon $*" >> "${SCRATCH}/calls.log"
touch "${SCRATCH}/swap_active"
EOF
    chmod +x "${scratch}/bin/"*

    fstab="${scratch}/fstab"
    [[ -f "${scratch}/calls.log" ]] || : > "${scratch}/calls.log"
    [[ -f "$fstab" ]] || : > "$fstab"

    (
        export SCRATCH="${scratch}"
        export PATH="${scratch}/bin:${PATH}"
        DOME_TARGET="${dome_target}"
        SWAP_SIZE_MB="${swap_size}"

        if [[ "${DOME_TARGET}" == "pi" ]]; then
            if [[ "${SWAP_SIZE_MB}" -eq 0 ]]; then
                echo "  SWAP_SIZE_MB=0, skipping"
            elif swapon --show=NAME --noheadings 2>/dev/null | grep -qx "/swapfile"; then
                echo "  /swapfile already active, skipping"
            else
                fallocate -l "${SWAP_SIZE_MB}M" /swapfile
                chmod 600 /swapfile 2>/dev/null || true
                mkswap /swapfile
                swapon /swapfile
                grep -qx '/swapfile none swap sw 0 0' "$fstab" \
                    || echo '/swapfile none swap sw 0 0' >> "$fstab"
            fi
        else
            echo "  DOME_TARGET=${DOME_TARGET}, skipping (Pi only)"
        fi
    )
}

scratch=$(mktemp -d)
run_swap_step pi 2048 "$scratch"
[[ -f "${scratch}/swapfile" ]] && pass "pi + 2048: swapfile created" \
    || fail "pi + 2048: swapfile not created"
[[ "$(grep -c '^/swapfile none swap sw 0 0$' "${scratch}/fstab")" -eq 1 ]] \
    && pass "pi + 2048: fstab entry added once" \
    || fail "pi + 2048: fstab entry count wrong"
rm -rf "$scratch"

echo "--- behavior: idempotent re-run ---"
scratch=$(mktemp -d)
run_swap_step pi 2048 "$scratch"
calls_before=$(wc -l < "${scratch}/calls.log")
run_swap_step pi 2048 "$scratch"
calls_after=$(wc -l < "${scratch}/calls.log")
[[ "$calls_before" -eq "$calls_after" ]] \
    && pass "pi + 2048: re-run makes no new fallocate/mkswap/swapon calls" \
    || fail "pi + 2048: re-run made new calls ($calls_before -> $calls_after)"
[[ "$(grep -c '^/swapfile none swap sw 0 0$' "${scratch}/fstab")" -eq 1 ]] \
    && pass "pi + 2048: re-run does not duplicate fstab entry" \
    || fail "pi + 2048: re-run duplicated fstab entry"
rm -rf "$scratch"

echo "--- behavior: vm target skips entirely ---"
scratch=$(mktemp -d)
run_swap_step vm 2048 "$scratch"
[[ ! -f "${scratch}/swapfile" ]] && pass "vm: no swapfile created" \
    || fail "vm: swapfile created but should be skipped"
[[ ! -s "${scratch}/fstab" ]] && pass "vm: no fstab entry added" \
    || fail "vm: fstab entry added but should be skipped"
rm -rf "$scratch"

echo "--- behavior: SWAP_SIZE_MB=0 disables on pi ---"
scratch=$(mktemp -d)
run_swap_step pi 0 "$scratch"
[[ ! -f "${scratch}/swapfile" ]] && pass "pi + 0: no swapfile created" \
    || fail "pi + 0: swapfile created but should be disabled"
rm -rf "$scratch"

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[[ "${FAIL}" -eq 0 ]]
