# Current Status

**Date:** 2026-08-05

Full session-by-session log lives in `02-doc/history.md`. This file holds
only current status and open items.

## Status

F02, F03, F04, F05 all complete — no open dome-docker features. F05
(`DOME_MODE=native|docker`) closed this session. F03 T10 (manual VM/Pi
verification) completed this session: full chain (`host-setup.sh` →
`bare-metal-base.sh` → `bare-metal-build.sh`) confirmed live on the Pi, VM
path re-confirmed by user — F03/TF03 moved to `done/`.

## Open

- `Boston-Robot-Hackers/dome_vision` needs a fix in a **separate repo**, not
  tracked here: `dome_vision/dome_vision/pyproject.toml` (package
  `oak-roboflow`) has unpinned `numpy` and a duplicate `opencv-python` —
  `colcon build`'s per-package `pip install .` doesn't share
  `bare-metal-base.sh`'s combined resolver context, so it silently upgraded
  numpy to 2.5.1, breaking `depthai-sdk`'s hard `numpy<2.0.0` requirement,
  and installed a conflicting second OpenCV wheel. User has a fix prompt to
  run against that repo directly (pin `numpy<2`, drop `opencv-python`).
- No open dome-docker features. Next feature work starts fresh from a new ask.

## Blockers

None.
