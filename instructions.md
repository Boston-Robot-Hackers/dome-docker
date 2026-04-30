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
