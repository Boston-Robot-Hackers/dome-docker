# Instructions

This file is for project-specific instructions, hints, and steps.

## Ground Rules

- Read-only access is allowed across the system when needed.
- Write access is limited to `~/pidockerexperiment`.
- Ask before using elevated permissions such as `sudo`.

## Notes

- Add useful commands, findings, and repeatable steps here as the project evolves.
- First-pass goal: create a reviewable checklist of candidates for the Docker rebuild, not a deep inventory.
- Current checklist: `docker-rebuild-candidates.md`.
- Package candidate details are in `rebuild-package-candidates.md` and raw package inventories are under `inventory/packages/`.
- Rebuild target assumption: ROS 2 Kilted on Ubuntu 24.04 Noble arm64, even though the current microSD evidence shows ROS 2 Jazzy.
- Host provisioning plan: `host-provisioning-plan.md`.
- Container build plan: `container-build-plan.md`.
- ROS Kilted package verification: `ros-kilted-package-verification.md`.
- First automation draft files: `host-setup.sh`, `Dockerfile`, `docker-entrypoint.sh`, `compose.yaml`, `build-and-run.md`.

## Session Memory

- Current repo path: `~/mydev/dome-docker` on the Mac, `/home/pitosalas/domedocker` in this environment.
- Target host: Raspberry Pi 5 running Ubuntu Server 24.04.4 LTS, headless.
- Target container base: `ros:kilted-ros-base-noble`.
- Private GitHub repos are cloned during Docker build with SSH forwarding.
- On macOS, use Docker Desktop and the `default` or `desktop-linux` context/builder only if SSH forwarding works there.
- Working build command on the Mac:

```sh
DOCKER_BUILDKIT=1 docker buildx build   --platform linux/arm64   --ssh default=$SSH_AUTH_SOCK   --load   -t dome-docker:dome-kilted .
```

- Builder troubleshooting that mattered:
  - `ssh -T git@github.com` and `git ls-remote` worked on the Mac, so GitHub SSH access was fine.
  - The failing builder was the custom `mymultiarchbuilder`.
  - Switching `docker context use default` and `docker buildx use default` fixed SSH forwarding for the build.
- Dockerfile SSH clone workaround:
  - Private `git clone` steps run as `root`.
  - Cloned files are then `chown -R pitosalas:pitosalas /home/pitosalas`.
- Removed from the rebuild:
  - `depthai_rospi`
- Rosdep/build workaround:
  - `rosdep install` runs as `root` in the Dockerfile because it needs apt installs.
  - Skip keys currently used: `ament_python` and `gazebo_ros_pkgs`.
- Colcon build workaround:
  - Cleanup generated source-tree junk before build: `build`, `install`, `log`, `prefix_override`, `__pycache__`, `.pytest_cache`, `*.egg-info`.
  - `oak_roboflow` needs an in-image patch to `setup.py` so setuptools explicitly packages only `oak_roboflow`.
- Current failure history:
  - SSH forwarding to GitHub.
  - `rosdep` sudo prompts inside Docker.
  - `oak_roboflow` setuptools flat-layout package discovery with `prefix_override`.
- If resuming, first check:

```sh
git pull
git status -sb
docker buildx ls
```
