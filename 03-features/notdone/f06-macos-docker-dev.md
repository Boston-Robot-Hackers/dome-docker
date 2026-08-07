# Feature description for feature F06

## F06 — Run the Docker image on macOS as a development environment

**Priority**: Medium
**Done:** no
**Tasks File Created:** no
**Tests Written:** no
**Test Passing:** no
**Description**: Add a fourth scenario — run the existing arm64 robot image
directly on an Apple Silicon Mac under Docker Desktop, as a headless ROS 2
development environment. No Pi, no VM.

The appeal over Scenario 2 (VM native) is that it runs **the exact image the
robot runs**, so a package that builds and launches here builds and launches
there. It also removes the VM entirely — no second OS to provision, patch,
or keep at Ubuntu 24.04 noble.

The image already works unmodified. Docker Desktop on Apple Silicon runs an
arm64 Linux VM, so `--platform linux/arm64` (hardcoded in
`scripts/mac-build-base.sh` and `scripts/mac-build-overlay.sh`) runs
natively with no emulation.

**Everything that blocks this today is in `compose/compose.yaml`**, which is
wired to Pi hardware:

- `devices: /dev/dma_heap` — the only *fatal* one. Docker requires a
  `devices:` source path to exist on the host; that node comes from the Pi
  kernel's camera/video pipeline and is absent in Docker Desktop's LinuxKit
  VM, so the container refuses to start.
- `network_mode: host` — beta-only on Docker Desktop for Mac (4.34+), and
  ROS 2 DDS multicast discovery across the VM boundary is exactly where it
  is weakest.
- `volumes: /dev:/dev` — resolves to the LinuxKit VM's `/dev`, not macOS's.
  Meaningless rather than harmful.
- `device_cgroup_rules: 'c 189:* rmw'` — USB serial (the ESP32 and LD19
  lidar). Docker Desktop has no USB passthrough on macOS.

## Scope

**Decision — this is a self-contained sandbox.** The container's ROS graph
does not join the robot's. Nodes inside discover each other; they do not
discover nodes on a Pi or on the LAN.

*This is an assumption, made because it was not specified and it is by far
the simpler design.* Joining the robot's graph needs a FastDDS discovery
server or explicit unicast peer configuration, plus a decision about
`ROS_DOMAIN_ID` collisions with live robots — a separate feature, not a
variation of this one.

**Decision — selected by compose file, not by a manifest flag.** Do **not**
add `DOME_TARGET=mac` or a third axis to `manifest/`. `DOME_TARGET` and
`DOME_MODE` describe how a *host is provisioned*; this scenario provisions
nothing. The choice is made at run time by which compose files are passed.

**Add:**

- `compose/compose.mac.yaml` — an override layered on top of the existing
  file, used as:

  ```sh
  docker compose -f compose/compose.yaml -f compose/compose.mac.yaml run --rm dome
  ```

  It must null out `devices`, drop the `/dev:/dev` volume and
  `device_cgroup_rules`, replace `network_mode: host` with bridge
  networking, and rework `DISPLAY` for XQuartz
  (`host.docker.internal:0`) instead of the `/tmp/.X11-unix` socket mount.

- `02-doc/mac-howto.md` — a fourth guide, self-contained start to finish,
  matching the one-guide-per-scenario structure established when
  `shell-howto.md` was split.

- Scenario table updates in `02-doc/howto.md` (currently three columns) and
  the scenario list in `README.md`.

**Do not change:**

- `compose/compose.yaml` — Scenario 3 must be byte-identical in behavior.
  An override file is the mechanism precisely so the robot path is untouched.
- `Dockerfile` / `Dockerfile.base` — same image, unmodified. Running what
  the robot runs is the entire point of the feature.
- `DOME_TARGET` / `DOME_MODE` semantics — see the decision above.
- No wrapper script. The documented `docker compose -f ... -f ...` line is
  enough; a `scripts/mac-run-dev.sh` would be code earning nothing, against
  the style guide's bias-to-less-code rule.

## Known limitations

These are accepted, not defects to solve later:

- **No hardware at all** — no camera, lidar, ESP32, or GPIO. Docker Desktop
  for Mac cannot pass USB through.

- **The image carries inert Pi packages.** `Dockerfile.base:16` and `:55`
  pull `[apt-pi]` and `[pip-pi]` unconditionally, and `Dockerfile:46` clones
  the `root-pi` repos — neither Dockerfile gates on `DOME_TARGET`. So
  `RPi.GPIO`, `spidev`, `raspi-config`, and `libcamera-apps` ship in the
  image and simply have nothing to talk to. Gating the Dockerfiles on
  `DOME_TARGET` is a separate question, deliberately out of scope here.

- **Apple Silicon in practice.** An Intel Mac needs qemu emulation for the
  arm64 image and will be slow enough to be unpleasant. Not blocked, not
  supported.

- **rviz2 needs XQuartz** installed and configured on the Mac side.

## How to Demo

**Setup**: Apple Silicon Mac with Docker Desktop running, `manifest/user.txt`
containing `DOME_USER` and `DOCKERHUB_USERNAME`, and the robot image either
pulled from Docker Hub or built via `scripts/mac-build-overlay.sh`.

**Steps**:

1. `source scripts/dome-config.sh`
2. `docker compose -f compose/compose.yaml -f compose/compose.mac.yaml run --rm dome`
3. Inside the container: `echo "$ROS_DISTRO"` → `kilted`
4. `ros2 pkg list | grep dome` → the dome workspace packages are present
5. In a second shell into the same container, run `ros2 run demo_nodes_cpp
   talker` and `ros2 run demo_nodes_cpp listener` → they discover each other
   and exchange messages
6. Control: run step 2 **without** the `-f compose/compose.mac.yaml`
   override → fails on `/dev/dma_heap`, confirming the override is what
   makes macOS work and that Scenario 3's file is unchanged

**Expected output**: an interactive ROS 2 shell on macOS with `/opt/ros` and
the workspace overlay already sourced by `docker-entrypoint.sh`; two nodes
inside the container discover each other; no hardware devices present; the
unmodified Scenario 3 invocation still fails on macOS exactly as it does
today.
