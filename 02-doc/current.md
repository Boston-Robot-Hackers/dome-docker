# Current Status

**Date:** 2026-07-23
**Session:** F02 — file layout reorg; F03 defined (VM support)

## Status
F02 complete. Root scripts moved to `scripts/`, `compose.yaml` moved to `compose/`. F03 (VM target support) defined, no task file yet — blocked/informed by real-world testing on a mis-provisioned VM (see closed I01).

## What Was Done
- F02: moved 9 root shell scripts to `scripts/`, `compose.yaml` to `compose/`
- Fixed `Dockerfile` `COPY` paths for `scripts/docker-entrypoint.sh`, `scripts/install-optional-deps.sh`
- Fixed `MANIFEST_DIR`/`_MANIFEST_DIR` relative-path bugs in `bare-metal-base.sh`, `bare-metal-build.sh`, `dome-config.sh`, `mac-build-base.sh`, `mac-build-overlay.sh` (all assumed manifest/ next to script, now one level up)
- Fixed `mac-build-base.sh`/`mac-build-overlay.sh` `source ./dome-config.sh` (cwd-dependent) → resolves via own `SCRIPT_DIR`
- Updated `README.md`, `02-doc/docker-howto.md`, `02-doc/shell-howto.md` invocation paths; `docker compose` calls now use `-f compose/compose.yaml --project-directory .`
- Fixed stale `bare-metal-*.sh` root-path refs in `tests/test_f01_manifest.sh` (still 40/40 passing)
- Added `tests/test_f02_file_layout.sh` — 43 tests, all passing
- `02-doc/shell-howto.md` rewritten with explicit Primary/Target machine labels per step, plus VM prerequisite check (`/etc/os-release` must show `noble`)
- F03 feature defined: `DOME_TARGET=pi|vm` concept to skip Pi-only packages/repos (`raspi-config`, `i2c-tools`, `RPi.GPIO`, `libcamera-apps`, `seeed-linux-dtoverlays`, `mic_hat` overlay installs) when provisioning a generic VM
- I01 opened then closed: `ros-kilted-ros-base` install failure on a VM traced to the VM running Ubuntu `resolute`, not `noble` — user/environment issue, not a repo defect; folded into F03 scope and `shell-howto.md` prerequisites

## Active Features
- F03 — VM setup support (`notdone`, no task file yet)

## Blockers
None. (Prior VM blocker was a mis-provisioned VM, not a code issue — see closed I01.)

## Next Steps
1. Write task file for F03
2. Re-attempt VM bring-up on an actual Ubuntu 24.04 (noble) VM, using the corrected `shell-howto.md`
3. Test bare-metal-base.sh + bare-metal-build.sh on a real Pi (carried over from F01)
