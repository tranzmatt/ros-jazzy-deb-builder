#!/usr/bin/env bash
set -euo pipefail

# validate-debian-build.sh — build Debian packages from apt source and copy
# artifacts to OUT.
#
# Each package is worked on inside its own subdirectory under SRC_ROOT
# ($SRC_ROOT/<pkg>/). If fetch-apt-source.sh has already run for a package,
# the pre-fetched source tree is reused without re-downloading.
#
# Usage: validate-debian-build.sh <apt-source-package> [apt-source-package ...]

SRC_ROOT="${SRC_ROOT:-/workspace/src}"
OUT="${OUT:-/workspace/out}"
mkdir -p "$SRC_ROOT" "$OUT"

if [ "$#" -eq 0 ]; then
  echo "usage: validate-debian-build.sh <apt-source-package> [apt-source-package ...]" >&2
  exit 1
fi

sudo apt-get update

for pkg in "$@"; do
  echo "=== Validating Debian build for: $pkg ==="
  workdir="$SRC_ROOT/$pkg"
  mkdir -p "$workdir"
  pushd "$workdir" >/dev/null

  # Reuse a source tree already fetched by fetch-apt-source.sh, or fetch now.
  src_dir=$(find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' | head -n1)
  if [ -z "$src_dir" ]; then
    echo "  No pre-fetched source found — fetching from apt..."
    sudo apt-get source "$pkg"
    src_dir=$(find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' | head -n1)
  else
    echo "  Using pre-fetched source: $src_dir"
  fi

  if [ -z "$src_dir" ]; then
    echo "ERROR: no source directory found for $pkg after fetch" >&2
    exit 1
  fi

  # Install build dependencies.
  sudo apt-get -y build-dep "$pkg" || true

  pushd "$src_dir" >/dev/null
  dpkg-buildpackage -b -uc -us
  popd >/dev/null

  # Collect artifacts — dpkg-buildpackage places them in the parent of src_dir,
  # which is $workdir (depth 0 relative to our current pushd).
  find . -maxdepth 1 -type f \( -name '*.deb' -o -name '*.changes' -o -name '*.buildinfo' -o -name '*.dsc' \) \
    -exec cp -v {} "$OUT"/ \;

  popd >/dev/null
done
