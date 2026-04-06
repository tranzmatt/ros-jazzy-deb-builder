#!/usr/bin/env bash
set -euo pipefail

# fetch-apt-source.sh — download and unpack apt source packages.
# Each package is fetched into its own subdirectory under DEST so that
# validate-debian-build.sh can pick up the pre-fetched source without
# re-downloading.
#
# Usage: fetch-apt-source.sh <apt-source-package> [apt-source-package ...]

DEST="${DEST:-/workspace/src}"
mkdir -p "$DEST"

if [ "$#" -eq 0 ]; then
  echo "usage: fetch-apt-source.sh <apt-source-package> [apt-source-package ...]" >&2
  exit 1
fi

sudo apt-get update

for pkg in "$@"; do
  echo "=== Fetching source package: $pkg ==="
  workdir="$DEST/$pkg"
  mkdir -p "$workdir"
  pushd "$workdir" >/dev/null
  sudo apt-get source "$pkg"
  popd >/dev/null
done
