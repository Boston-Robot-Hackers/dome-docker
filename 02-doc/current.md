# Current Status

**Date:** 2026-07-23
**Session:** F03 T10 in progress — live VM bring-up surfacing and fixing real bugs

## Status
F02 complete. F03 (`DOME_TARGET=pi|vm`) code+tests done (T01-T09). T10 (manual
VM/Pi verification) is now actively in progress — the user is running a real
Ubuntu 24.04 VM bring-up and this session has been fixing bugs and doc gaps
as they surface live, rather than doing it in this environment.

## What Was Done
- F02: moved 9 root shell scripts to `scripts/`, `compose.yaml` to `compose/`
- F03 implemented (TF03 T01-T09): `DOME_TARGET=pi|vm` in `manifest/config.txt`; split `packages.txt`/`pip.txt`/`repos.txt` into base/`-pi` sections; `bare-metal-base.sh`/`bare-metal-build.sh`/`host-setup.sh` all target-aware
- I01 opened then closed: earlier VM failure traced to wrong Ubuntu release, not a repo defect
- Docs reframed around 3 explicit scenarios (Pi microSD / VM bare Ubuntu / Docker) across `README.md`, `02-doc/howto.md`, `02-doc/shell-howto.md`, `02-doc/docker-howto.md`

### This session — bugs found live during actual T10 VM bring-up:
- `scripts/dome-config.sh`: resolved `manifest/` one level above repo root when `source`d under zsh (`BASH_SOURCE` not populated by zsh on plain `source`). Fixed to resolve from `$(pwd)`; regression test added.
- `scripts/host-setup.sh`: resolved `DOME_USER` as `root` — only read the env var, never `manifest/user.txt`, so under `sudo` (`$USER=root`) it computed the wrong home dir and manifest lookup failed. Fixed to use env > user.txt > config precedence, matching other scripts.
- `manifest/packages.txt` `[ros]`: had a bogus `dome-docker` entry (the repo's own name, introduced in an earlier commit with no rationale) — caused `apt-get install ros-kilted-dome-docker` to fail with package-not-found. Removed; regression test added guarding against this exact mistake recurring.
- `scripts/host-setup.sh` now prints the target's global IPv4 addresses at the end of its run, so VM users (where `dome.local` mDNS often fails) don't have to find the IP externally.
- `02-doc/shell-howto.md`: fixed several real doc gaps found by walking the VM path live — never told VM users to set `DOME_TARGET=vm`; mixed the Primary/Target (which machine you type on) and Pi/VM (which hardware) label axes inconsistently; implied an SSH key needed to already be on the target when Step 5 is what puts it there; hardcoded `pitosalas`/`dome.local` in the scp commands instead of being generic; didn't note that VM users working in the console directly don't need SSH at all; Step 6 had users manually re-source ROS/workspace setup when `.bashrc` (installed by `bare-metal-build.sh`) already auto-sources `~/rosutils/ros2_robot_bashrc.bash` in every new shell — fixed to say "open a new terminal" instead.
- Added `TARGET_USER`/`TARGET_HOST` env var convention in `shell-howto.md` Step 2 so later `ssh`/`scp` commands don't need the username/address retyped each time.
- Removed all time estimates ("10-30 min", "5-15 min", etc.) from docs and script echo/comments per explicit feedback — duration varies too much across Pi/VM/network to be meaningful.
- Renamed the 3 howto doc headers to start with their filename (`README: Dome Docker`, `Howto: Dome Docker Scenarios`, `Shell Howto: ...`, `Docker Howto: ...`) per explicit convention request.
- All fixes logged in `04-tasks/chores.md` (bug-fix chores don't need feature/task files per process.md).

## Active Features
- F03 — VM setup support (`notdone`; code+tests done, T10 live bring-up actively in progress and surfacing real fixes as it goes)

## Blockers
None. T10 is unblocked and progressing — each bug hit live has been fixed and pushed same-session.

## Next Steps
1. Continue T10: keep working through the live VM bring-up, fixing bugs/doc gaps as they surface
2. Once VM bring-up completes clean, confirm unchanged behavior with `DOME_TARGET=pi` (or unset) on a real Pi, then close out F03 (move feature+task files to `done/`)
3. Test bare-metal-base.sh + bare-metal-build.sh on a real Pi (carried over from F01)
