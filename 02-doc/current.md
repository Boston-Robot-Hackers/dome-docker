# Current Status

**Date:** 2026-05-17
**Session:** Bootstrap + housekeeping

## Status
Project bootstrapped. Scripts cleaned up. Docs updated.

## What Was Done
- Added `collect-inventory.sh` — snapshots live Pi state to `inventory/`
- Added `seed-runtime-data.sh` — seeds `runtime-data/` from `~/.control` and `~/.dome`
- Added `manifest/bashrc` — container shell env sourced from here instead of rosutils fallback
- `compose.yaml` — added `runtime-data/dome` → `~/.dome` volume mount
- `host-setup.sh` — creates `runtime-data/dome`; simplified DNS check; removed DOME_DIR guard
- All `.sh` scripts — removed over-defensive error handling; fail fast on bad state
- `doc/setup-and-run.md` moved to `02-doc/setup-and-run.md`
- `README.md` updated to reflect all new scripts and layout

## Active Features
None defined yet.

## Blockers
None.

## Next Steps
1. Fill in `02-doc/spec.md`
2. Define first feature in `03-features/notdone/`
