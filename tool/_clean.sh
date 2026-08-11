#!/bin/sh
# Wipe every build artefact. Sourced by set-up.sh, never run on its own.
set -e

echo "→ flutter clean (app)"
fvm flutter clean >/dev/null

if [ -d packages/system_design ]; then
  echo "→ flutter clean (system_design)"
  (cd packages/system_design && fvm flutter clean >/dev/null)
fi

echo "→ removing android build output"
rm -rf android/.gradle android/app/build build
