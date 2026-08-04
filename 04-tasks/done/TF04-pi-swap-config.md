# Tasks for Feature F04 — Configurable swapfile setup for Pi targets

## T01 — Add `SWAP_SIZE_MB` to manifest/config.txt
**Status**: done
**Description**: Add `SWAP_SIZE_MB=2048` with a one-line comment, following
the existing `DOME_TARGET`/`DOME_USER` comment style. Document the `0` =
disabled convention.

## T02 — Add swapfile step to bare-metal-base.sh
**Status**: done
**Description**: New step, gated on `DOME_TARGET == "pi"`: read `SWAP_SIZE_MB`
via `manifest_config`, skip entirely if `0`. If not already active
(`swapon --show` check), `fallocate -l`, `chmod 600`, `mkswap`, `swapon` on
`/swapfile`, append `/etc/fstab` entry only if not already present.
Renumber existing step-count comments/echoes to include the new step.

## T03 — Regression test: idempotency and target-gating
**Status**: done
**Description**: Test (matching existing `bare-metal-base.sh` test style/harness)
covering: (a) `DOME_TARGET=pi` + `SWAP_SIZE_MB=2048` creates swapfile + fstab
entry, (b) re-run does not duplicate the fstab entry or fail, (c)
`DOME_TARGET=vm` skips the step entirely, (d) `SWAP_SIZE_MB=0` skips the step
on `pi`. Mock `fallocate`/`mkswap`/`swapon`/`swapon --show`/`/etc/fstab` — no
real disk/swap operations in the test run.

## T04 — Document in README / pi-howto
**Status**: done
**Description**: Note the `SWAP_SIZE_MB` config key and default in
`02-doc/pi-howto.md` (and `README.md` if it lists other `config.txt` keys),
including the rationale (colcon build OOM risk on 4GB Pi5) and the `0`-disables
override via `manifest/user.txt`.

## T05 — Full test suite pass
**Status**: done
**Description**: Run full existing test suite plus new T03 tests, confirm
0 failures before moving feature/task files to `done/`.
