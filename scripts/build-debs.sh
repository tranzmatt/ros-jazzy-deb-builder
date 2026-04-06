#!/usr/bin/env bash
set -euo pipefail

# build-debs.sh — build .deb artifacts from apt source packages and verify
# that artifacts were produced.
#
# Delegates the actual build to validate-debian-build.sh, then asserts that
# at least one .deb was written to OUT and lists what was produced.
#
# Usage: build-debs.sh <apt-source-package> [apt-source-package ...]

OUT="${OUT:-/workspace/out}"

if [ "$#" -eq 0 ]; then
  echo "usage: build-debs.sh <apt-source-package> [apt-source-package ...]" >&2
  exit 1
fi

/usr/local/bin/validate-debian-build.sh "$@"

# Fail loudly if no .deb artifacts landed in OUT.
shopt -s nullglob
debs=("$OUT"/*.deb)
if [ "${#debs[@]}" -eq 0 ]; then
  echo "build-debs.sh: ERROR — no .deb artifacts found in $OUT after build" >&2
  exit 1
fi

echo ""
echo "=== Artifacts written to $OUT ==="
printf '  %s\n' "${debs[@]}"
