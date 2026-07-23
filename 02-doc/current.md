# Current Status

**Date:** 2026-07-23
**Session:** F02 — file layout reorg; F03 implemented (VM support), pending real-hardware verification

## Status
F02 complete. F03 (`DOME_TARGET=pi|vm`) implemented and unit-tested (T01-T09 done); T10 (manual VM/Pi verification) still outstanding — needs real hardware/VM access not available in this environment.

## What Was Done
- F02: moved 9 root shell scripts to `scripts/`, `compose.yaml` to `compose/`
- Fixed `Dockerfile` `COPY` paths for `scripts/docker-entrypoint.sh`, `scripts/install-optional-deps.sh`
- Fixed `MANIFEST_DIR`/`_MANIFEST_DIR` relative-path bugs in `bare-metal-base.sh`, `bare-metal-build.sh`, `dome-config.sh`, `mac-build-base.sh`, `mac-build-overlay.sh` (all assumed manifest/ next to script, now one level up)
- Fixed `mac-build-base.sh`/`mac-build-overlay.sh` `source ./dome-config.sh` (cwd-dependent) → resolves via own `SCRIPT_DIR`
- Updated `README.md`, `02-doc/docker-howto.md`, `02-doc/shell-howto.md` invocation paths; `docker compose` calls now use `-f compose/compose.yaml --project-directory .`
- Fixed stale `bare-metal-*.sh` root-path refs in `tests/test_f01_manifest.sh` (still 40/40 passing)
- Added `tests/test_f02_file_layout.sh` — 43 tests, all passing
- `02-doc/shell-howto.md` rewritten with explicit Primary/Target machine labels per step, plus VM prerequisite check (`/etc/os-release` must show `noble`)
- I01 opened then closed: `ros-kilted-ros-base` install failure on a VM traced to the VM running Ubuntu `resolute`, not `noble` — user/environment issue, not a repo defect; folded into F03 scope and `shell-howto.md` prerequisites
- F03 implemented (TF03 T01-T09): added `DOME_TARGET=pi|vm` to `manifest/config.txt` (default `pi`, override in `user.txt`); split `manifest/packages.txt` (`[apt]`/`[apt-pi]`), `manifest/pip.txt` (`[pip]`/`[pip-pi]`), `manifest/repos.txt` (`[root]`/`[root-pi]`) so Pi-only entries (`raspi-config`, `i2c-tools`, `RPi.GPIO`, `spidev`, `libcamera-apps`, `seeed-linux-dtoverlays`, `mic_hat`) are isolated; `bare-metal-base.sh`, `bare-metal-build.sh`, `host-setup.sh` all read `DOME_TARGET` (env > user.txt > config default) and skip the `-pi` sections/overlay build when `vm`
- Scope correction found during implementation: the reported `/boot/firmware/overlays/` failure actually comes from `host-setup.sh`'s own hardcoded ReSpeaker overlay build (not `repos.txt` `[root]` cloning as the feature doc originally stated) — `host-setup.sh` added to F03 scope
- Regression caught and fixed: splitting the manifest files also would have silently changed the **Docker** image (Dockerfile/Dockerfile.base only parsed the base section names) — fixed both to install `[apt]`+`[apt-pi]`, `[pip]`+`[pip-pi]`, and clone `root`+`root-pi`, so Docker image contents are unchanged
- Added `tests/test_f03_vm_target.sh` — 28 tests, all passing; `test_f01_manifest.sh` (40/40) and `test_f02_file_layout.sh` (43/43) rerun clean, no regressions
- Documented VM setup in `README.md` ("Setting Up A Development VM")

## Active Features
- F03 — VM setup support (`notdone`; code+tests done, T10 manual hardware verification outstanding)

## Blockers
None for code. T10 needs real Ubuntu 24.04 VM + real Pi access, not available in this environment.

## Next Steps
1. Re-attempt VM bring-up on an actual Ubuntu 24.04 (noble) VM with `DOME_TARGET=vm`, using the corrected `shell-howto.md` (TF03 T10)
2. Confirm unchanged behavior with `DOME_TARGET=pi` (or unset) on a real Pi, then close out F03 (move feature+task files to `done/`)
3. Test bare-metal-base.sh + bare-metal-build.sh on a real Pi (carried over from F01)
