#!/usr/bin/env bash
# Tests for F02: reorganize root files into type-based subdirectories.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

assert_file() {
    local f="$1"
    [[ -f "$f" ]] && pass "exists: ${f#$REPO_DIR/}" || fail "missing: ${f#$REPO_DIR/}"
}

assert_absent() {
    local f="$1"
    [[ ! -e "$f" ]] && pass "not in root: ${f#$REPO_DIR/}" || fail "still present: ${f#$REPO_DIR/}"
}

assert_executable() {
    local f="$1"
    [[ -x "$f" ]] && pass "executable: ${f#$REPO_DIR/}" || fail "not executable: ${f#$REPO_DIR/}"
}

echo "=== F02 file layout tests ==="

echo "--- scripts/ populated ---"
for f in bare-metal-base.sh bare-metal-build.sh collect-inventory.sh docker-entrypoint.sh \
         dome-config.sh host-setup.sh install-optional-deps.sh mac-build-base.sh mac-build-overlay.sh; do
    assert_file "${REPO_DIR}/scripts/${f}"
done

# dome-config.sh is sourced, never executed directly.
# install-optional-deps.sh gets +x from Dockerfile:80 at image build time, not in-repo.
for f in bare-metal-base.sh bare-metal-build.sh collect-inventory.sh docker-entrypoint.sh \
         host-setup.sh mac-build-base.sh mac-build-overlay.sh; do
    assert_executable "${REPO_DIR}/scripts/${f}"
done

echo "--- compose/ populated ---"
assert_file "${REPO_DIR}/compose/compose.yaml"

echo "--- root no longer has moved files ---"
for f in bare-metal-base.sh bare-metal-build.sh collect-inventory.sh docker-entrypoint.sh \
         dome-config.sh host-setup.sh install-optional-deps.sh mac-build-base.sh mac-build-overlay.sh \
         compose.yaml; do
    assert_absent "${REPO_DIR}/${f}"
done

echo "--- README and CLAUDE.md stay in root ---"
assert_file "${REPO_DIR}/README.md"
assert_file "${REPO_DIR}/CLAUDE.md"

echo "--- moved scripts pass syntax check ---"
for f in "${REPO_DIR}"/scripts/*.sh; do
    bash -n "$f" && pass "syntax: ${f#$REPO_DIR/}" || fail "syntax: ${f#$REPO_DIR/}"
done

echo "--- no stale manifest-relative-to-scripts-dir bug ---"
grep -q 'MANIFEST_DIR="\${SCRIPT_DIR}/manifest"' "${REPO_DIR}/scripts/bare-metal-base.sh" \
    && fail "bare-metal-base.sh MANIFEST_DIR not fixed for scripts/ depth" \
    || pass "bare-metal-base.sh MANIFEST_DIR fixed for scripts/ depth"
grep -q 'MANIFEST_DIR="\${SCRIPT_DIR}/manifest"' "${REPO_DIR}/scripts/bare-metal-build.sh" \
    && fail "bare-metal-build.sh MANIFEST_DIR not fixed for scripts/ depth" \
    || pass "bare-metal-build.sh MANIFEST_DIR fixed for scripts/ depth"

echo "--- Dockerfile COPY paths point at scripts/ ---"
grep -q 'COPY scripts/docker-entrypoint.sh' "${REPO_DIR}/Dockerfile" \
    && pass "Dockerfile COPY docker-entrypoint.sh from scripts/" \
    || fail "Dockerfile COPY docker-entrypoint.sh not updated"
grep -q 'COPY scripts/install-optional-deps.sh' "${REPO_DIR}/Dockerfile" \
    && pass "Dockerfile COPY install-optional-deps.sh from scripts/" \
    || fail "Dockerfile COPY install-optional-deps.sh not updated"

echo "--- docker compose config resolves cleanly ---"
if command -v docker >/dev/null 2>&1; then
    if (cd "${REPO_DIR}" && docker compose -f compose/compose.yaml --project-directory . config >/dev/null 2>&1); then
        pass "docker compose config resolves"
    else
        fail "docker compose config failed to resolve"
    fi
else
    echo "  SKIP: docker not installed"
fi

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[[ "${FAIL}" -eq 0 ]]
