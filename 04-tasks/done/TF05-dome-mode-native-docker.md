# Tasks for Feature F05 — `DOME_MODE` flag: skip Docker install for native scenarios

## T01 — Add `DOME_MODE` to manifest/config.txt
**Status**: done
**Description**: Add `DOME_MODE=native` with a one-line comment, following
the existing `DOME_TARGET` comment style. Document the `native|docker`
values and that only Scenario 3 (Docker) needs to set it.

## T02 — Gate the Docker/dome.service block in host-setup.sh
**Status**: done
**Description**: Read `DOME_MODE` with env > `user.txt` > `config.txt`
precedence (matching `DOME_USER`/`DOME_TARGET` lookup pattern already in the
script). Wrap the Docker apt-repo setup, `docker-ce`/`docker-ce-cli`/
`containerd.io`/`docker-buildx-plugin`/`docker-compose-plugin` install,
`docker.service` enable/start, `usermod -aG docker`, and the `dome.service`
templating/`systemctl enable dome` block in an `if [[ "${DOME_MODE}" ==
"docker" ]]` check. Print a one-line skip message in the `else` branch.

## T03 — Regression test: mode-gating
**Status**: done
**Description**: New `tests/test_f05_dome_mode.sh` (matching
`test_f04_pi_swap.sh` style/harness): (a) `config.txt` defaults `DOME_MODE`
to `native`, (b) `host-setup.sh` references `DOME_MODE`, (c) syntax check
(`bash -n`), (d) behavior test extracting/stubbing the gated block (mock
`apt-get`/`systemctl`/`docker` calls, no real installs) confirming
`DOME_MODE=native` makes zero Docker-related calls and `DOME_MODE=docker`
makes them, matching current behavior.

## T04 — Document in README / docker-howto
**Status**: done
**Description**: Add `DOME_MODE` to the `README.md` manifest table (same row
style as `DOME_TARGET`/`SWAP_SIZE_MB`). Add `DOME_MODE=docker` to the
`manifest/user.txt` snippet in `02-doc/docker-howto.md` Step 1, with a
one-line note on why it's needed (Scenario 3 shares `DOME_TARGET=pi` with
Scenario 1, so `DOME_MODE` is what actually turns Docker on).

## T05 — Full test suite pass
**Status**: done
**Description**: Run full existing test suite plus new T03 tests, confirm
0 failures before moving feature/task files to `done/`.
