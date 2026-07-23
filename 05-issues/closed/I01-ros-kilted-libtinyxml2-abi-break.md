# I01 ros-kilted-ros-base uninstallable — wrong Ubuntu release on VM

* **Symptom**: On a VM intended as an Ubuntu 24.04 (noble) target, `sudo ./bare-metal-base.sh` fails at step [3/8] (`apt-get install -y ros-kilted-ros-base`) with:
  ```
  E: Unable to satisfy dependencies. Reached two conflicting assignments:
     1. ros-kilted-urdf:arm64 is selected for install because:
        1. ros-kilted-ros-base:arm64=0.12.0-2noble.20260604.145738 is selected for install
        2. ros-kilted-ros-base:arm64 Depends ros-kilted-urdf
     2. ros-kilted-urdf:arm64 Depends libtinyxml2-10 (>= 10.0.0)
        but none of the choices are installable:
        [no choices]
  ```
* **What tests were done**:
  - `apt-cache policy libtinyxml2-10` → no candidate in any enabled repo
  - `apt-cache search libtinyxml2` → only `libtinyxml2-11` and old `libtinyxml2.6.2v5` present
  - Tried pinning `libtinyxml2-10` via an Ubuntu snapshot-archive repo — snapshot fetch itself returned `401 UNAUTHORIZED`, a dead end
  - Inspected full `apt-get update` output — the VM's **own** distro repos resolved as:
    ```
    Hit:1 http://us.archive.ubuntu.com/ubuntu resolute InRelease
    ```
    i.e. the VM was running Ubuntu `resolute`, not `noble` (24.04)
* **Root cause**: Not a dome-docker or ROS packaging defect. The VM was provisioned with the wrong Ubuntu release. `manifest/config.txt` declares `UBUNTU_CODENAME=noble`, and `bare-metal-base.sh` adds the ROS 2 apt repo pinned to that codename — but the VM's base OS was a different, newer Ubuntu release (`resolute`) whose system libraries (including `tinyxml2`) are already ahead of what ROS kilted's noble-built binaries expect. Installing noble-targeted ROS packages on a non-noble base is fundamentally unsupported, independent of any transient upstream timing issue.
* **Resolution**: Re-provision the VM with actual Ubuntu 24.04 (noble) — verify with `cat /etc/os-release` before running any build script. No code or manifest change needed.
* **Follow-up**: Added an explicit `/etc/os-release` verification step to `02-doc/shell-howto.md` Prerequisites so this is caught before Step 2 instead of surfacing as a cryptic apt dependency error at Step 4. See [[F03]].
