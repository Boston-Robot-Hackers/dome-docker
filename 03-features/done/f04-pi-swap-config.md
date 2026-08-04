# Feature description for feature F04

## F04 — Configurable swapfile setup for Pi targets

**Priority**: Medium
**Done:** yes
**Tasks File Created:** yes
**Tests Written:** yes
**Test Passing:** yes
**Description**: `bare-metal-base.sh`/`bare-metal-build.sh` have no swap setup. Pi
boards (especially 4GB Pi5) can OOM during `colcon build` since `manifest/colcon.txt`
sets no `-j` cap and colcon defaults to using all cores in parallel. Add a
Pi-only swapfile step, sized via a new manifest config key, following the
existing `manifest/` single-source-of-truth pattern (`DOME_TARGET` etc.).

## Scope

**Add:**
- `SWAP_SIZE_MB` key in `manifest/config.txt`, default `2048` (2GB), same
  load precedence as `DOME_USER`/`DOME_TARGET` (env > `user.txt` > `config.txt`)
- Swapfile setup step in `bare-metal-base.sh`, gated on `DOME_TARGET=pi`
  (skipped for `vm` — hypervisor host sizing covers it)
- Method: `fallocate` + `chmod 600` + `mkswap` + `swapon` on `/swapfile`,
  persisted via `/etc/fstab` entry — standard Ubuntu approach (no
  `dphys-swapfile`, that's Raspbian-only and not present on Ubuntu 24.04)
- Idempotent: skip creation if `/swapfile` already active per `swapon --show`,
  so reruns of `bare-metal-base.sh` don't fail or double-allocate
- `SWAP_SIZE_MB=0` disables swap setup entirely

**Do not change:**
- VM target — no swap step added there
- `colcon.txt` build parallelism — out of scope, swap is the mitigation, not
  a build-flag change

## How to Demo

**Setup**: Fresh Ubuntu 24.04 Pi, `DOME_TARGET=pi` (default).

**Steps**:
1. `sudo ./bare-metal-base.sh` — creates and activates `/swapfile` (2GB default)
2. `swapon --show` — shows `/swapfile` active
3. Reboot, `swapon --show` again — still active (fstab entry persisted)
4. Re-run `sudo ./bare-metal-base.sh` — no error, no duplicate swapfile/fstab entry
5. `DOME_TARGET=vm` run — swap step skipped entirely

**Expected output**: Pi targets get a working, persistent, idempotent swapfile
sized from `manifest/config.txt`; VM targets are unaffected.
