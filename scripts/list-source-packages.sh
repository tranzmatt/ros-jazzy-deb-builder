#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update >/dev/null

if [ "$#" -eq 0 ]; then
  if command -v grep-dctrl >/dev/null 2>&1; then
    grep-dctrl -n -s Package '' /var/lib/apt/lists/*_source_Sources 2>/dev/null | sort -u
  else
    grep -h '^Package: ' /var/lib/apt/lists/*_source_Sources 2>/dev/null | awk '{print $2}' | sort -u
  fi
  exit 0
fi

for pattern in "$@"; do
  if command -v grep-dctrl >/dev/null 2>&1; then
    grep-dctrl -n -s Package -F Package "$pattern" /var/lib/apt/lists/*_source_Sources 2>/dev/null || true
  else
    grep -h '^Package: ' /var/lib/apt/lists/*_source_Sources 2>/dev/null | awk '{print $2}' | grep "$pattern" || true
  fi
done
