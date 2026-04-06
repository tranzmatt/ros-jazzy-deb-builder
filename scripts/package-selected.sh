#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: package-selected.sh <apt-source-package> [apt-source-package ...]" >&2
  exit 1
fi

exec /usr/local/bin/build-debs.sh "$@"
