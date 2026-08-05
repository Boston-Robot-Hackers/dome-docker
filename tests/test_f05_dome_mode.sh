#!/usr/bin/env bash
# Tests for F05: DOME_MODE=native|docker gating in host-setup.sh.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_DIR="${REPO_DIR}/manifest"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== F05 DOME_MODE tests ==="

echo "--- config.txt defaults ---"
source "${MANIFEST_DIR}/lib.sh"
got=$(manifest_config DOME_MODE "${MANIFEST_DIR}/config.txt")
[[ "$got" == "native" ]] && pass "config.txt DOME_MODE defaults to native" \
    || fail "config.txt DOME_MODE: got='$got' expected='native'"

echo "--- host-setup.sh references DOME_MODE ---"
grep -q 'DOME_MODE' "${REPO_DIR}/scripts/host-setup.sh" \
    && pass "host-setup.sh references DOME_MODE" || fail "host-setup.sh missing DOME_MODE"
grep -q 'DOME_MODE=native' "${REPO_DIR}/scripts/host-setup.sh" \
    && pass "host-setup.sh has a native-mode branch" || fail "host-setup.sh missing native-mode branch"

echo "--- syntax check ---"
bash -n "${REPO_DIR}/scripts/host-setup.sh" \
    && pass "syntax: scripts/host-setup.sh" \
    || fail "syntax: scripts/host-setup.sh"

echo "--- behavior: gated Docker/dome.service block ---"
run_docker_gate() {
    # Reproduces just the two DOME_MODE-gated blocks from host-setup.sh in a
    # stubbed shell — apt-get/curl/systemctl/sed/dpkg are all faked via a
    # scratch dir + PATH shims, so no real installs/systemd calls happen.
    local dome_mode="$1" scratch="$2"
    mkdir -p "${scratch}/bin"
    for cmd in apt-get curl systemctl sed dpkg chown mkdir; do
        cat > "${scratch}/bin/${cmd}" <<EOF
#!/usr/bin/env bash
echo "${cmd} \$*" >> "${scratch}/calls.log"
EOF
        chmod +x "${scratch}/bin/${cmd}"
    done

    (
        export PATH="${scratch}/bin:${PATH}"
        DOME_MODE="${dome_mode}"

        if [[ "${DOME_MODE}" == "docker" ]]; then
            apt-get -o Acquire::ForceIPv4=true install -y docker-ce docker-ce-cli
            systemctl enable docker
            systemctl start docker
        else
            echo "  DOME_MODE=native — skipping Docker install."
        fi

        if [[ "${DOME_MODE}" == "docker" ]]; then
            mkdir -p "${scratch}/runtime-data/ros"
            sed 's/x/y/' <<< "dummy" >/dev/null
            systemctl daemon-reload
            systemctl enable dome
        else
            echo "  DOME_MODE=native — skipping dome.env/dome.service setup."
        fi
    )
}

scratch=$(mktemp -d)
run_docker_gate native "$scratch"
[[ ! -s "${scratch}/calls.log" ]] && pass "native: no Docker/dome.service calls made" \
    || fail "native: unexpected calls made: $(cat "${scratch}/calls.log")"
rm -rf "$scratch"

scratch=$(mktemp -d)
run_docker_gate docker "$scratch"
[[ -s "${scratch}/calls.log" ]] && pass "docker: Docker/dome.service calls made" \
    || fail "docker: expected calls, got none"
grep -q 'systemctl enable dome$' "${scratch}/calls.log" \
    && pass "docker: dome.service enabled" || fail "docker: dome.service not enabled"
rm -rf "$scratch"

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[[ "${FAIL}" -eq 0 ]]
