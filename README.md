# ros-jazzy-deb-builder

A separate repo for validating and packaging ROS 2 Jazzy **from ROS apt source packages** on **Debian Bookworm**.

This repo is intentionally distinct from a source-lab repo that clones upstream ROS Git repositories. Here, the provenance is the ROS apt repository itself:

- enable ROS `deb` and `deb-src`
- fetch source with `apt-get source`
- validate builds from those source packages
- produce deployable `.deb` artifacts from the same source origin

That lets you answer two slightly different questions with one toolchain:

1. Does the ROS apt source package build on Debian Bookworm?
2. Can the underlying ROS code from the apt source package also be assembled into a `colcon` workspace and built there?

## Why this repo exists

This repo is the package forge. It is meant to stay cleanly separated from any repo that:

- clones `ros2/ros2`
- consumes `ros2.repos`
- acts as an upstream source-build experiment sandbox

In this repo, both the Debian package build path and the `colcon` validation path start from **apt source packages**.

## Repository layout

```text
ros-jazzy-deb-builder/
├── Dockerfile
├── README.md
├── AGENTS.md
├── .gitignore
├── manifests/
│   ├── core-packages.txt
│   └── workspace-packages.txt
├── overrides/
│   └── rosdep-bookworm-overrides.yaml
├── out/
└── scripts/
    ├── build-debs.sh
    ├── fetch-apt-source.sh
    ├── list-source-packages.sh
    ├── package-selected.sh
    ├── validate-colcon-workspace.sh
    └── validate-debian-build.sh
```

## Expected workflow

### 1. Build the container

```bash
docker build -t ros-jazzy-deb-builder .
```

### 2. Start an interactive shell

```bash
docker run --rm -it \
  -v "$PWD/out:/workspace/out" \
  ros-jazzy-deb-builder
```

### 3. List apt source packages you want to test

```bash
list-source-packages.sh ros-jazzy-rclcpp
```

Or inspect all configured source package metadata:

```bash
grep-dctrl -n -s Package '' /var/lib/apt/lists/*_source_Sources
```

Note that source package names do not always match binary package names one-for-one.

### 4. Fetch source packages from the ROS apt repository

```bash
fetch-apt-source.sh ros-jazzy-rclcpp ros-jazzy-rclpy
```

This unpacks source into `/workspace/src`.

### 5. Validate Debian package builds

```bash
validate-debian-build.sh ros-jazzy-rclcpp
```

This installs build-deps and runs `dpkg-buildpackage` in the unpacked apt source tree.

### 6. Validate a `colcon` workspace assembled from apt source packages

```bash
validate-colcon-workspace.sh manifests/workspace-packages.txt
```

This fetches each listed apt source package, extracts candidate ROS package directories into `/workspace/src`, and attempts a `colcon build`.

### 7. Build `.deb` artifacts for selected packages

```bash
package-selected.sh ros-jazzy-rclcpp ros-jazzy-rclpy
```

Artifacts are copied to `/workspace/out`.

## Manifests

`manifests/core-packages.txt` and `manifests/workspace-packages.txt` are plain text lists of **apt source package names**. Example:

```text
ros-jazzy-ament-cmake
ros-jazzy-rcl
ros-jazzy-rclcpp
```

Keep them intentionally small at first. Bookworm validation goes faster when you work outward from a tiny stable set instead of trying to swallow the whole ROS galaxy in one gulp.

## Important nuance: apt source vs `colcon`

`apt-get source` fetches **Debian source packages**. Those source trees often contain:

- upstream ROS source
- Debian packaging metadata under `debian/`
- patches or layout choices specific to Debian packaging

That means Debian package validation is the primary truth in this repo.

`colcon` validation is still useful, but it is secondary and best applied to selected package groups, because a Debian source package does not always map perfectly to a neat upstream workspace layout.

## Bookworm caveats

Debian Bookworm is not the primary target environment for Jazzy. Expect some friction:

- missing or renamed dependencies
- partial `rosdep` resolution
- generated or packaged dependencies that assume Ubuntu naming
- middleware packages that need special handling

That is why `overrides/rosdep-bookworm-overrides.yaml` exists.

## Working with Codex in VS Code

This repo is meant to be friendly to repo-aware tools. The important files are:

- `README.md` for the overall workflow
- `AGENTS.md` for repo conventions and expectations
- `manifests/*.txt` for source package sets
- `scripts/*.sh` for the operational flow

Suggested first Codex tasks inside VS Code:

1. inspect which apt source package names actually exist for Jazzy on Bookworm
2. tighten `fetch-apt-source.sh` and `validate-colcon-workspace.sh` for the specific packages you care about
3. add package-specific exclusions or layout heuristics where Debian source trees differ from upstream ROS expectations
4. fill in `rosdep-bookworm-overrides.yaml` from real failures

## Suggested first validation target

Start with one or two packages, not a huge workspace. Good initial categories are:

- ament package
- a core client library package
- one package you actually deploy

## Example session

```bash
docker build -t ros-jazzy-deb-builder .

docker run --rm -it -v "$PWD/out:/workspace/out" ros-jazzy-deb-builder

fetch-apt-source.sh ros-jazzy-rclcpp
validate-debian-build.sh ros-jazzy-rclcpp
```

Then expand to workspace validation only after the single-package Debian build is behaving.
