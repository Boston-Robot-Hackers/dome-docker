# Notes

Semi-permanent architecture decisions, research, calibration notes.

## manifest/ as single source of truth (2026-05-18)

All build configuration lives in `manifest/`. Scripts are thin executors — no package names,
repo URLs, build flags, or directory lists in script bodies. If adding something requires
editing a script rather than a manifest file, the abstraction is broken.

**Manifest files and what they own:**

| File | Owns |
|---|---|
| `config.txt` | ROS_DISTRO, UBUNTU_CODENAME, DOME_USER default |
| `packages.txt` | apt and ROS packages ([apt]/[ros] sections) |
| `pip.txt` | pip3 packages |
| `repos.txt` | git repos to clone ([root]/[ros_ws]/[uros_ws] sections) |
| `apt-repos.txt` | third-party apt repositories (Doppler, GitHub CLI) |
| `tools.txt` | curl-installed tools (mcfly) |
| `colcon.txt` | colcon build flags and skip list |
| `rosdep.txt` | rosdep install skip keys |
| `dirs.txt` | home subdirectory structure |

**Two build paths, same manifest:**

```
manifest/
    |
    +---> Dockerfile.base + Dockerfile      (docker compose build on Mac)
    |
    +---> scripts/bare-metal-base.sh + scripts/bare-metal-build.sh  (run as root on target)
```

**User overrides:** `manifest/user.txt` (gitignored) overrides `DOME_USER` and sets
`DOCKERHUB_USERNAME` and `DOME_PASSWORD`. `config.txt` holds project defaults;
`user.txt` holds per-user values. Load order: config.txt → user.txt → env var.

**Shared helpers:** `manifest/lib.sh` — source this in any script that needs to parse
manifest files. Provides `manifest_field`, `manifest_require`, `manifest_sections`,
`manifest_config`. All fail fast with explicit ERROR messages on missing required fields.

**Design doc:** `02-doc/manifest-as-ground-truth.md`
