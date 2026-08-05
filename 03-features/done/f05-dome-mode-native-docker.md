# Feature description for feature F05

## F05 — `DOME_MODE` flag: skip Docker install for native scenarios

**Priority**: Medium
**Done:** yes
**Tasks File Created:** yes
**Tests Written:** yes
**Test Passing:** yes
**Description**: `scripts/host-setup.sh` unconditionally installs Docker and
enables `dome.service` (which runs `docker compose run --rm dome`) on every
target, regardless of scenario. But per `02-doc/howto.md`'s scenario table,
Docker is only used by Scenario 3 — Scenarios 1 (Pi native) and 2 (VM
native) never touch it. `DOME_TARGET` (`pi|vm`) can't distinguish this,
since Scenario 1 and Scenario 3 both flash a Pi microSD and both default to
`DOME_TARGET=pi`. Result: Pi-native and VM-native hosts get Docker installed
and an inert/failing `dome.service` enabled for no reason. Found live during
a Scenario-1 Pi bring-up (`pi-howto.md`) — host-setup.sh ran the full Docker
block even though this setup never uses it.

## Scope

**Add:**
- `DOME_MODE` key in `manifest/config.txt`, default `native`, values
  `native|docker`, same load precedence as `DOME_USER`/`DOME_TARGET` (env >
  `user.txt` > `config.txt`)
- Gate the Docker-apt-repo setup, `docker-ce`/`docker-ce-cli`/etc. install,
  `docker.service` enable/start, and `dome.service` templating/enable block
  in `scripts/host-setup.sh` behind `DOME_MODE=docker`. When `DOME_MODE=native`
  (default), skip that whole block and print a one-line skip message instead.
- `02-doc/docker-howto.md` Step 1: add `DOME_MODE=docker` to the
  `manifest/user.txt` snippet (Scenario 3 is the only one that sets it).
- `README.md` manifest table: add the `DOME_MODE` row.

**Do not change:**
- `DOME_TARGET` semantics (`pi|vm`) — orthogonal axis, untouched.
- `pi-howto.md`/`vm-howto.md` — no changes needed, `DOME_MODE` defaults to
  `native` so Scenario 1/2 users never need to set it.
- Already-provisioned hosts — not retroactive; a host that already has
  Docker installed from a prior run keeps it (script doesn't uninstall).

## How to Demo

**Setup**: Fresh Ubuntu 24.04 Pi, `manifest/user.txt` with no `DOME_MODE`
line (defaults to `native`).

**Steps**:
1. `sudo scripts/host-setup.sh` — Docker install and `dome.service` block
   skipped, one-line skip message printed
2. `dpkg -l | grep docker-ce` — not installed
3. `systemctl status dome` — unit not found / not enabled
4. Add `DOME_MODE=docker` to `manifest/user.txt`, re-run
   `sudo scripts/host-setup.sh` — Docker installed, `dome.service` enabled,
   same as current behavior

**Expected output**: Scenario 1 (Pi native) and Scenario 2 (VM native) hosts
get no Docker install and no `dome.service`; Scenario 3 (Docker) behavior is
unchanged from today.
