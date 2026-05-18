---
name: fail-fast-no-silent-fallbacks
description: Scripts must error explicitly on missing required config, not silently fall back to empty or wrong values
metadata:
  type: feedback
---

Error on missing required config — do not silently fall back.

**Why:** Silent fallbacks hide misconfiguration. User wants errors that surface problems so they can be fixed.

**How to apply:** Use explicit checks with `ERROR:` messages and `exit 1` / `return 1` for any required field (config.txt values, required manifest entries, etc.). Optional overrides (user.txt) may be silently absent. Applied in `dome-config.sh` and `manifest/lib.sh` (`manifest_require`, `manifest_config`).
