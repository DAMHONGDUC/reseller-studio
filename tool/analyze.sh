#!/bin/sh
# Exactly what CI runs. Must pass with zero findings before any task is done.
#
# The design system is analyzed on its own first: it must compile without the
# host app, and running it from inside the app would hide an app dependency
# leaking into the package.
set -e

echo "→ analyze system_design (standalone)"
(cd packages/system_design && fvm flutter analyze --fatal-infos)

echo "→ analyze app"
fvm flutter analyze --fatal-infos

echo "✓ analyze clean"
