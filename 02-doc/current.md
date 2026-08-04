# Current Status

**Date:** 2026-08-04
**Session:** F04 (Pi swap config) added and closed same-session; F03 T10 still in progress

## Status
F02 complete. F04 (Pi-only swapfile config) done — added, implemented, tested,
closed same session. F03 (`DOME_TARGET=pi|vm`) code+tests done (T01-T09). T10
(manual VM/Pi verification) is still actively in progress — most recent prior
session covered a live Pi microSD bring-up, plus a `.claude/` scaffold sync
from `mydev/j3` and a doc restructure requested by the user.

## What Was Done

### This session (2026-08-04) — F04 Pi swap config
- New feature `F04`/`TF04`: `SWAP_SIZE_MB` config key in `manifest/config.txt`
  (default `2048`, same env > `user.txt` > `config.txt` precedence as
  `DOME_TARGET`), Pi-only swapfile step added to `bare-metal-base.sh`
  (`fallocate`/`mkswap`/`swapon`/`/etc/fstab`, idempotent, `SWAP_SIZE_MB=0`
  disables). Motivated by `colcon build` OOM risk on 4GB Pi5 boards since
  `manifest/colcon.txt` sets no parallel-job cap.
- `tests/test_f04_pi_swap.sh` added (12 tests, mocked disk/swap ops — no real
  `fallocate`/`mkswap`/`swapon` calls in the test run).
- Docs updated: `README.md` manifest table, `02-doc/pi-howto.md` (new
  `SWAP_SIZE_MB` note near the `manifest/user.txt` section).
- Full suite passes: 59+43+28+12 = 142 passed, 0 failed.
- F04 feature + TF04 task file moved to `done/`.
- Live-verified on a real Pi: `bare-metal-base.sh` created/activated
  `/swapfile`, confirmed by user.

### Previous session (2026-08-03) — Pi bring-up, doc restructure
- Copied `.claude/` from `mydev/j3` over dome-docker's, replacing
  bootstrap/literate/process/style_guide/templates/commands/settings.json;
  kept dome-docker's own `settings.local.json` (had uncommitted local
  permission grants).
- README was confusing about where to start for a Pi microSD install — its
  "Local Configuration" section read as a universal first step but is
  actually Docker-only. Fixed by adding a scenario-routing "Getting Started"
  section up top.
- Bigger restructure per explicit user request: `02-doc/shell-howto.md`
  (interleaved Pi/VM steps with Primary/Target + Pi:/VM: tags every step)
  was confusing — split into single-thread `02-doc/pi-howto.md` and
  `02-doc/vm-howto.md`, each self-contained start to finish, repeating
  shared steps rather than cross-referencing. `shell-howto.md` deleted;
  `README.md`/`02-doc/howto.md`/`02-doc/docker-howto.md` cross-refs updated.
- Live Pi bring-up: DNS resolution failure on `curl -sSL` (mcfly install)
  — transient, resolved by fixing target's DNS. Re-running
  `bare-metal-base.sh` after a DNS fix is safe (idempotent, apt/pip skip
  fast on already-satisfied state).
- Investigated "`dome_nav` missing from `~/ros2_ws/src`" — traced to
  `manifest/repos.txt` having local, uncommitted additions (`dome_mission`,
  `dome_nav`, `dome_nav_msgs`, `dome_semantic`, `dome_semantic_msgs`,
  `metawtf`) and a removal (`camera_ros`) that the Pi's checkout, cloned
  from GitHub, never received — not a script bug. Resolves once pushed and
  `git pull`ed on the Pi.
- `/checkpoint` caught a real regression before it shipped:
  `manifest/colcon.txt`'s `flags` field was deleted (user intentionally
  switched off `--symlink-install` for full installs), but
  `bare-metal-build.sh` hard-required `flags` to be non-empty and would
  have errored out at the colcon-build step on every target. Fixed the
  script (empty `flags` is now valid) and the test assertion; full test
  suite passes (47+43+28, 0 failed).
- All fixes logged in `04-tasks/chores.md` (bug-fix chores don't need
  feature/task files per process.md).

### Previous session (2026-07-23) — bugs found live during T10 VM bring-up
- `scripts/dome-config.sh`: resolved `manifest/` one level above the repo root when `source`d under zsh (`BASH_SOURCE` not populated by zsh on plain `source`). Fixed to resolve from `$(pwd)`; regression test added.
- `scripts/host-setup.sh`: resolved `DOME_USER` as `root` — only read the env var, never `manifest/user.txt`, so under `sudo` (`$USER=root`) it computed the wrong home dir and manifest lookup failed. Fixed to use env > user.txt > config precedence, matching other scripts.
- `manifest/packages.txt` `[ros]`: had a bogus `dome-docker` entry (the repo's own name, introduced in an earlier commit with no rationale) — caused `apt-get install ros-kilted-dome-docker` to fail with package-not-found. Removed; regression test added guarding against this exact mistake recurring.
- `scripts/host-setup.sh` now prints the target's global IPv4 addresses at the end of its run, so VM users (where `dome.local` mDNS often fails) don't have to find the IP externally.
- `02-doc/shell-howto.md` (now split into `pi-howto.md`/`vm-howto.md`): fixed several real doc gaps found by walking the VM path live — never told VM users to set `DOME_TARGET=vm`; mixed the Primary/Target (which machine you type on) and Pi/VM (which hardware) label axes inconsistently; implied an SSH key needed to already be on the target when Step 5 is what puts it there; hardcoded `pitosalas`/`dome.local` in the scp commands instead of being generic; didn't note that VM users working in the console directly don't need SSH at all; Step 6 had users manually re-source ROS/workspace setup when `.bashrc` (installed by `bare-metal-build.sh`) already auto-sources `~/rosutils/ros2_robot_bashrc.bash` in every new shell — fixed to say "open a new terminal" instead.
- Added `TARGET_USER`/`TARGET_HOST` env var convention so later `ssh`/`scp` commands don't need the username/address retyped each time.
- Removed all time estimates ("10-30 min", "5-15 min", etc.) from docs and script echo/comments per explicit feedback — duration varies too much across Pi/VM/network to be meaningful.
- Renamed the 3 howto doc headers to start with their filename (`README: Dome Docker`, `Howto: Dome Docker Scenarios`, `Shell Howto: ...`, `Docker Howto: ...`) per explicit convention request.

## Active Features
- F04 — Pi swap config (`done`) — `SWAP_SIZE_MB` in `manifest/config.txt`,
  Pi-only idempotent swapfile step in `bare-metal-base.sh`, 12 new tests
- F03 — VM setup support (`notdone`; code+tests done, T10 live bring-up actively in progress and surfacing real fixes as it goes)
  - F02: moved 9 root shell scripts to `scripts/`, `compose.yaml` to `compose/`
  - F03 implemented (TF03 T01-T09): `DOME_TARGET=pi|vm` in `manifest/config.txt`; split `packages.txt`/`pip.txt`/`repos.txt` into base/`-pi` sections; `bare-metal-base.sh`/`bare-metal-build.sh`/`host-setup.sh` all target-aware
  - I01 opened then closed: earlier VM failure traced to wrong Ubuntu release, not a repo defect
  - Docs reframed around 3 explicit scenarios (Pi microSD / VM bare Ubuntu / Docker) across `README.md`, `02-doc/howto.md`, `02-doc/docker-howto.md`, and (this session) split into per-scenario `pi-howto.md`/`vm-howto.md`

## Blockers
None. T10 is unblocked and progressing — each bug hit live has been fixed and pushed same-session.

## Next Steps
1. Push `manifest/repos.txt`/`manifest/colcon.txt` changes so the Pi's next `git pull` + `bare-metal-build.sh` picks up the newly-added private repos (`dome_mission`, `dome_nav`, `dome_nav_msgs`, `dome_semantic`, `dome_semantic_msgs`, `metawtf`) and the full-install colcon flags.
2. Continue T10: keep working through the live Pi bring-up, fixing bugs/doc gaps as they surface.
3. Once Pi bring-up completes clean, confirm unchanged behavior with `DOME_TARGET=vm` on the VM (already exercised previous session), then close out F03 (move feature+task files to `done/`).
4. Test bare-metal-base.sh + bare-metal-build.sh on a real Pi end-to-end (carried over from F01).
