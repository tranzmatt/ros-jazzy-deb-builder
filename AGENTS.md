# Repo guidance for coding agents

## Purpose

This repository validates and packages ROS 2 Jazzy on Debian Bookworm using **ROS apt source packages** as the source of truth.

Do not redesign this repo around cloning upstream ROS Git repositories unless explicitly asked.

## Ground rules

1. Prefer `apt-get source` over cloning upstream ROS repositories.
2. Treat Debian package build validation as the primary truth.
3. Treat `colcon` validation as a secondary workspace-level check.
4. Keep manifests small and explicit.
5. Preserve repo separation from any upstream-clone source-build repo.
6. Document all Bookworm-specific workarounds in `README.md` and `overrides/rosdep-bookworm-overrides.yaml`.

## Repository conventions

- `manifests/*.txt` contain **apt source package names**.
- `scripts/*.sh` should be idempotent where practical.
- Shell scripts should use `set -euo pipefail`.
- Write scripts to be usable both interactively and in CI.
- Copy generated `.deb`, `.changes`, and `.buildinfo` files to `/workspace/out`.

## Preferred evolution path

When improving this repo, prefer this order:

1. make source package discovery reliable
2. make single-package Debian validation reliable
3. make artifact packaging reliable
4. then improve `colcon` workspace reconstruction from apt source trees

## Avoid

- turning this into an upstream Git clone workflow
- assuming source package names and binary package names always match
- assuming every Debian source package can be dropped into a clean `colcon` workspace unchanged
