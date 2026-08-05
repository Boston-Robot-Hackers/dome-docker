# TF03 Tasks — DOME_TARGET=pi|vm support for bare-metal provisioning

**Scope correction found during planning**: the observed `/boot/firmware/overlays/`
failure comes from `scripts/host-setup.sh` (its own hardcoded
`seeed-linux-dtoverlays` clone + `make install` at lines 121-134), not from
`manifest/repos.txt` `[root]` cloning in `bare-metal-build.sh` as the feature
doc states. `host-setup.sh` is added to scope below; feature doc's "Do not
change" list is unaffected.

## T01 — add DOME_TARGET config key
**Status**: done
**Description**: Add `DOME_TARGET=pi` to `manifest/config.txt` (default), document override via `manifest/user.txt` in the same comment style as `DOME_USER`. No script logic yet — this task just adds the key and read-path precedent (env > user.txt > config default), matching the existing `DOME_USER` pattern in `bare-metal-build.sh`/`dome-config.sh`. Test: `manifest_config DOME_TARGET manifest/config.txt` returns `pi`.

## T02 — split manifest/packages.txt apt section
**Status**: done
**Description**: Add `[apt-pi]` section to `manifest/packages.txt` containing `raspi-config`, `i2c-tools` (moved out of `[apt]`). `[ros]` section unchanged (identical both targets). Test: `[apt]` no longer contains `raspi-config`/`i2c-tools`; `[apt-pi]` does.

## T03 — split manifest/pip.txt into sectioned format
**Status**: done
**Description**: `pip.txt` is currently a flat comment-annotated list with no `[section]` headers. Add `[pip]` and `[pip-pi]` headers, preserving existing category comments under the right header. Move `RPi.GPIO` and `spidev` into `[pip-pi]`; everything else (including `PyAudio`) stays in `[pip]`. Test: section split parses correctly via `manifest_field`/awk; pi-only packages present in `[pip-pi]` only.

## T04 — split manifest/repos.txt [root] section
**Status**: done
**Description**: Add `[root-pi]` section containing `libcamera-apps`, `seeed-linux-dtoverlays`, `mic_hat` (moved out of `[root]`). `rosutils`, `depthai-python`, `linorobot2_hardware` stay in `[root]`. `[ros_ws]`/`[uros_ws]` unchanged. Test: `[root]` no longer contains the three Pi-only repos; `[root-pi]` does.

## T05 — bare-metal-base.sh reads DOME_TARGET, skips apt-pi/pip-pi
**Status**: done
**Description**: Read `DOME_TARGET` with same env > user.txt > config.txt precedence used for `DOME_USER` in `bare-metal-build.sh`. In step [4/8], additionally install `[apt-pi]` packages only when `DOME_TARGET=pi`. In step [8/8], parse `pip.txt` section-aware (current flat awk grab breaks once `[section]` headers exist — must skip header lines, not install them as packages) and install `[pip-pi]` only when `DOME_TARGET=pi`. Test: syntax-check script; run pip/apt section-extraction awk against fixture manifest content for both target values.

## T06 — bare-metal-build.sh reads DOME_TARGET, skips root-pi clone
**Status**: done
**Description**: Read `DOME_TARGET` (same precedence as `DOME_USER`, already read in this script). Call `clone_section root-pi "${DOME_HOME}"` only when `DOME_TARGET=pi`. Test: syntax-check script; verify `clone_section` invocation is conditional.

## T07 — host-setup.sh reads DOME_TARGET, skips Pi-only overlay build
**Status**: done
**Description**: Read `DOME_TARGET` (env > user.txt > config.txt, consistent with other scripts). Skip the `flex bison libssl-dev bc libncurses5-dev libncursesw5-dev` apt-get install and the entire ReSpeaker overlay build/install block (lines 119-134) when `DOME_TARGET=vm` — this is the actual reported failure site (see scope correction above). Test: syntax-check script; verify overlay block is behind the target guard.

## T08 — document VM setup path in README.md
**Status**: done
**Description**: Add a "Setting up a development VM" section to `README.md` covering: fresh Ubuntu 24.04 (noble) VM prerequisite, setting `DOME_TARGET=vm` in `manifest/user.txt`, and that the same three scripts (`host-setup.sh`, `bare-metal-base.sh`, `bare-metal-build.sh`) run unchanged. Cross-reference `02-doc/shell-howto.md`'s existing `/etc/os-release` prerequisite check. No test (doc-only).

## T09 — write tests for F03
**Status**: done
**Description**: Add `tests/test_f03_vm_target.sh`: `DOME_TARGET` defaults to `pi` in `config.txt`; `[apt-pi]`/`[pip-pi]`/`[root-pi]` sections exist and contain the expected Pi-only entries while `[apt]`/`[pip]`/`[root]` don't; all three scripts syntax-check (`bash -n`); `host-setup.sh`, `bare-metal-base.sh`, `bare-metal-build.sh` each reference `DOME_TARGET`. Rerun `test_f01_manifest.sh` and `test_f02_file_layout.sh` to confirm no regressions. All three suites pass (40/40, 43/43, 28/28).

**Regression found and fixed during this task**: splitting `packages.txt`/`pip.txt`/`repos.txt` into `-pi` sections silently changed what `Dockerfile`/`Dockerfile.base` installs — Docker only ever parsed the base section names (`[apt]`, `[pip]` flat, `[root]`), so it would have dropped `raspi-config`, `i2c-tools`, `RPi.GPIO`, `spidev`, `libcamera-apps`, `seeed-linux-dtoverlays`, `mic_hat` from the image, violating the feature's "Do not change Docker build path" scope. Fixed by having `Dockerfile.base` install both `[apt]`+`[apt-pi]` and `[pip]`+`[pip-pi]`, and `Dockerfile` clone both `root` and `root-pi` — Docker image content is unchanged from before this feature. Added regression checks for this in `test_f03_vm_target.sh`.

## T10 — manual verification (not automatable here)
**Status**: done
**Description**: Per feature "How to Demo": run `host-setup.sh` → `bare-metal-base.sh` → `bare-metal-build.sh` with `DOME_TARGET=vm` on a fresh Ubuntu 24.04 (noble) VM, confirm no Pi-only failures; then confirm unchanged behavior with `DOME_TARGET=pi` (or unset) on a real Pi. Confirmed live: full chain completed on the Pi (`dome-R1`) this session (`host-setup.sh` → `bare-metal-base.sh` → `bare-metal-build.sh`), and the VM path (`DOME_TARGET=vm`) re-confirmed separately by the user.
