#!/usr/bin/env bash
set -euo pipefail

MANIFEST="${1:-}"
WS="${WS:-/workspace}"
SRC_ROOT="$WS/src"
BUILD_ROOT="$WS/build"
INSTALL_ROOT="$WS/install"
LOG_ROOT="$WS/log"
TMP_ROOT="$WS/tmp/apt-source-work"

if [ -z "$MANIFEST" ]; then
  echo "usage: validate-colcon-workspace.sh <manifest-file>" >&2
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "manifest not found: $MANIFEST" >&2
  exit 1
fi

mkdir -p "$SRC_ROOT" "$BUILD_ROOT" "$INSTALL_ROOT" "$LOG_ROOT" "$TMP_ROOT"
rm -rf "$TMP_ROOT"/*

sudo apt-get update
rosdep update || true

while IFS= read -r pkg; do
  pkg="${pkg%%#*}"
  pkg="$(echo "$pkg" | xargs)"
  [ -z "$pkg" ] && continue

  echo "=== Fetching apt source for workspace package: $pkg ==="
  workdir="$TMP_ROOT/$pkg"
  mkdir -p "$workdir"
  pushd "$workdir" >/dev/null
  sudo apt-get source "$pkg"

  extracted=$(find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' | head -n1)
  if [ -z "$extracted" ]; then
    echo "No extracted source dir found for $pkg" >&2
    exit 1
  fi

  echo "=== Copying candidate ROS packages from: $extracted ==="
  while IFS= read -r package_xml; do
    pkg_dir=$(dirname "$package_xml")
    target="$SRC_ROOT/$(basename "$pkg_dir")"
    rm -rf "$target"
    cp -a "$pkg_dir" "$target"
  done < <(find "$extracted" -name package.xml -type f)

  popd >/dev/null
done < "$MANIFEST"

sudo rosdep install --from-paths "$SRC_ROOT" --ignore-src --rosdistro "${ROS_DISTRO:-jazzy}" -y || true

cd "$WS"
colcon build \
  --merge-install \
  --build-base "$BUILD_ROOT" \
  --install-base "$INSTALL_ROOT" \
  --log-base "$LOG_ROOT" \
  --continue-on-error \
  --event-handlers console_direct+ \
  --cmake-args -DCMAKE_BUILD_TYPE=Release
