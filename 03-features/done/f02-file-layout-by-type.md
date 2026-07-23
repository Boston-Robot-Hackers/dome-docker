# Feature description for feature F02
## F02 — Reorganize root files into type-based subdirectories

**Priority**: Medium
**Done:** yes
**Tasks File Created:** yes
**Tests Written:** yes
**Test Passing:** yes
**Description**: All shell scripts, YAML files, and Markdown docs currently live in the repo root mixed with Dockerfiles and other artifacts. Move them into `scripts/`, `compose/`, and `docs/` subdirectories respectively. Update all internal references (Dockerfile FROM/COPY paths, script source paths, compose references, README).

## Scope

**Move:**
| From (root) | To |
|---|---|
| `bare-metal-base.sh` | `scripts/` |
| `bare-metal-build.sh` | `scripts/` |
| `collect-inventory.sh` | `scripts/` |
| `docker-entrypoint.sh` | `scripts/` |
| `dome-config.sh` | `scripts/` |
| `host-setup.sh` | `scripts/` |
| `install-optional-deps.sh` | `scripts/` |
| `mac-build-base.sh` | `scripts/` |
| `mac-build-overlay.sh` | `scripts/` |
| `compose.yaml` | `compose/` |
| `README.md` | stays in root (GitHub convention) |
| `CLAUDE.md` | stays in root (Claude Code convention) |

**Do not move:**
- `manifest/lib.sh` — belongs to manifest subsystem
- `tests/test_f01_manifest.sh` — belongs to tests subsystem
- `.claude/*.md` — tooling config
- `02-doc/*.md`, `03-features/**`, etc. — already in correct homes

**Update after move:**
- `Dockerfile` and `Dockerfile.base`: any `COPY` or `RUN` paths referencing root scripts
- `compose.yaml` (new location): `entrypoint:` or `volumes:` paths
- Any script that sources another script by relative path
- `README.md`: usage instructions referencing script names

## How to Demo

**Setup**: Fresh clone of repo.

**Steps**:
1. `ls scripts/` — all `.sh` files present
2. `ls compose/` — `compose.yaml` present
3. `docker compose -f compose/compose.yaml build` — builds without error
4. `bash scripts/bare-metal-base.sh --dry-run` (if dry-run added) or inspect sourcing
5. All existing tests still pass: `bash tests/test_f01_manifest.sh`

**Expected output**: No `.sh` or `.yaml` files in repo root. All builds and scripts function identically.
