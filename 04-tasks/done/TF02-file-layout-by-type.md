# TF02 Tasks — reorganize root files into type-based subdirectories

## T01 — create scripts/ and compose/ directories, move files
**Status**: done
**Description**: `git mv` the following into `scripts/`: `bare-metal-base.sh`, `bare-metal-build.sh`, `collect-inventory.sh`, `docker-entrypoint.sh`, `dome-config.sh`, `host-setup.sh`, `install-optional-deps.sh`, `mac-build-base.sh`, `mac-build-overlay.sh`. `git mv compose.yaml` into `compose/`. `README.md` and `CLAUDE.md` stay in root.

## T02 — update Dockerfile and Dockerfile.base COPY paths
**Status**: done
**Description**: `Dockerfile` COPYs `docker-entrypoint.sh` and `install-optional-deps.sh` from root (lines 77-78) — update to `scripts/docker-entrypoint.sh` and `scripts/install-optional-deps.sh`. Verify `Dockerfile.base` has no root-script COPY/RUN references needing changes (it currently only touches `manifest/`).

## T03 — update compose invocations for new compose.yaml location
**Status**: done
**Description**: Moved `compose.yaml` now lives in `compose/`, one level below root. Rather than editing `context`/`volumes` paths inside the file (which would tie it to always being invoked with `-f`), left `compose.yaml` unchanged and updated all invocation sites (`02-doc/docker-howto.md`) to `docker compose -f compose/compose.yaml --project-directory . <cmd>` — `--project-directory .` keeps `context: .` and `./runtime-data/...` resolving against repo root regardless of where the compose file lives.

## T04 — fix cross-script sourcing after move
**Status**: done
**Description**: Fixed `MANIFEST_DIR="${SCRIPT_DIR}/manifest"` → `${SCRIPT_DIR}/../manifest` in `bare-metal-base.sh` and `bare-metal-build.sh`. Fixed `_MANIFEST_DIR` the same way in `dome-config.sh`, `mac-build-base.sh`, `mac-build-overlay.sh`. Fixed `mac-build-base.sh`/`mac-build-overlay.sh` `source ./dome-config.sh` (assumed cwd) → `source "${SCRIPT_DIR}/dome-config.sh"`. Fixed self-referential `sudo ./bare-metal-*.sh`/`sudo ./host-setup.sh` messages in error output to `sudo scripts/*.sh`. `host-setup.sh`'s `DOME_DIR="/home/${USERNAME}/dome-docker"` is a pre-existing absolute-path assumption, not affected by this move — left as is. `docker-entrypoint.sh` and `collect-inventory.sh` only use absolute/container-internal paths — no changes needed.

## T05 — update usage instructions across docs
**Status**: done
**Description**: Updated `README.md` (script table now under `scripts/`, `compose.yaml` → `compose/compose.yaml`), `02-doc/docker-howto.md`, and `02-doc/shell-howto.md` — all script invocations prefixed `scripts/`, all `docker compose pull`/`run` calls updated to `docker compose -f compose/compose.yaml --project-directory . <cmd>` (see T03). `02-doc/howto.md`, `02-doc/notes.md`, `02-doc/spec.md` only mention `docker compose` generically in comparison tables/diagrams, not as literal commands — left as is. `archive/*.md` are frozen historical docs — not updated. `03-features/`, `04-tasks/`, `05-issues/` entries describe past/point-in-time state — not updated.

## T06 — write tests for new layout
**Status**: done
**Description**: Added `tests/test_f02_file_layout.sh` (43 checks): `scripts/*.sh` exist and are executable (except `dome-config.sh`, sourced-only, and `install-optional-deps.sh`, chmod'd at Docker build time), moved files absent from root, `README.md`/`CLAUDE.md` still in root, syntax-check every moved script, guard against the `MANIFEST_DIR="${SCRIPT_DIR}/manifest"` regression, Dockerfile `COPY` paths point at `scripts/`, and `docker compose -f compose/compose.yaml --project-directory . config` resolves cleanly. Also fixed two now-stale `${REPO_DIR}/bare-metal-*.sh` paths in `tests/test_f01_manifest.sh` that the move broke — reran it, still 40/40 passing.
