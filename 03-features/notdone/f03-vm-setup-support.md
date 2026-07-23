# Feature description for feature F03
## F03 — Support VMware/generic VM as a bare-metal-build target, not just Raspberry Pi

**Priority**: Medium
**Done:** no
**Tasks File Created:** yes
**Tests Written:** yes
**Test Passing:** yes
**Description**: `bare-metal-base.sh` and `bare-metal-build.sh` currently assume a fresh Raspberry Pi (Ubuntu 24.04 on Pi hardware) and install Pi-only pieces unconditionally: `raspi-config` and `i2c-tools` (apt), `RPi.GPIO` (pip), and Pi-hardware repos like `libcamera-apps` and `seeed-linux-dtoverlays` (`manifest/repos.txt` `[root]` section). Some of these (`raspi-config` in particular) are not installable on a plain Ubuntu VM and will fail the script outright. Add a target concept (e.g. `DOME_TARGET=pi|vm` in `manifest/config.txt`, override via `manifest/user.txt` like `DOME_USER`) so the same scripts can provision a VMware/Parallels/cloud Ubuntu 24.04 VM for development, skipping hardware-only steps that don't apply off-Pi. Robot-software packages (ROS, depthai, etc.) install the same either way — only the Pi-hardware-specific subset is conditional.

**Observed failure on non-Pi VM**: `install: invalid target '/boot/firmware/overlays/respeaker-2mic-v2_0.dtbo': No such file or directory`. Comes from the `mic_hat` (respeaker) device-tree overlay `make install` step (`manifest/repos.txt` `[root]`), which writes to `/boot/firmware/overlays/` — a path that only exists on Raspberry Pi OS boot partitions, not on a generic Ubuntu VM. `seeed-linux-dtoverlays` has the same class of failure (dtbo overlay install to `/boot/firmware/overlays/`). Both need their overlay-install step skipped, not just the `git clone`, when `DOME_TARGET=vm`.

**Scope correction (found during task planning/implementation):** the observed
`/boot/firmware/overlays/` failure actually comes from `scripts/host-setup.sh`'s
own hardcoded `seeed-linux-dtoverlays` clone + `make install` (not from
`manifest/repos.txt` `[root]` cloning as stated below). `host-setup.sh` is
in scope alongside `bare-metal-base.sh`/`bare-metal-build.sh` — see TF03 T07.

## Scope

**Add:**
- `DOME_TARGET` config key (default `pi`) in `manifest/config.txt`, overridable in `manifest/user.txt`
- Mark Pi-only entries in `manifest/packages.txt` (`raspi-config`, `i2c-tools`), `manifest/pip.txt` (`RPi.GPIO`, `spidev`), and `manifest/repos.txt` `[root]` (`libcamera-apps`, `seeed-linux-dtoverlays`, `mic_hat`) so they can be conditionally skipped — exact mechanism (tag/section vs. separate manifest file) to be decided during task planning
- Skip (or make target-aware) any post-clone `make install`/overlay-install step for `mic_hat` and `seeed-linux-dtoverlays` that writes to `/boot/firmware/overlays/` — that path does not exist off-Pi and currently fails hard (`install: invalid target '/boot/firmware/overlays/respeaker-2mic-v2_0.dtbo': No such file or directory`)
- `bare-metal-base.sh` and `bare-metal-build.sh` read `DOME_TARGET` and skip Pi-only installs/clones when `vm`
- Document VM setup path in `README.md` (e.g. "Setting up a development VM")

**Do not change:**
- Docker build path (`Dockerfile`, `Dockerfile.base`) — out of scope, VMs use the bare-metal path directly
- ROS/robot software package lists — identical on Pi and VM

**Prerequisite, not a code fix (see closed [[I01]])**: the VM's Ubuntu release
must exactly match `UBUNTU_CODENAME` in `manifest/config.txt` (currently
`noble`/24.04). A mismatched release produces confusing mid-install `apt`
dependency errors, not a clear version-mismatch message — `02-doc/shell-howto.md`
now has an `/etc/os-release` check in Prerequisites to catch this before Step 2.

## How to Demo

**Setup**: Fresh Ubuntu 24.04 VMware VM, `DOME_TARGET=vm` set in `manifest/user.txt`.

**Steps**:
1. `sudo ./bare-metal-base.sh` — completes without error, skips `raspi-config`/`i2c-tools`/`RPi.GPIO`
2. `./bare-metal-build.sh` — completes without error, skips Pi-hardware repo clones
3. Same scripts run unmodified on a real Pi with `DOME_TARGET=pi` (or unset/default) and behavior is unchanged from current

**Expected output**: One script pair works for both a physical Pi and a generic VM, differing only in the Pi-hardware subset.
