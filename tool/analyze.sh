#!/bin/sh
# Exactly what CI runs. Must pass with zero findings before any task is done.
#
# The design system is analyzed on its own first: it must compile without the
# host app, and running it from inside the app would hide an app dependency
# leaking into the package.
set -e

# `fvm` pins the SDK on a developer's machine; CI installs the pinned version
# itself (see .github/workflows/ci.yml) and has no fvm. One script either way —
# a CI job that retyped these commands would drift from the one people run.
FLUTTER="fvm flutter"
command -v fvm >/dev/null 2>&1 || FLUTTER="flutter"

echo "→ analyze system_design (standalone)"
(cd packages/system_design && $FLUTTER analyze --fatal-infos)

echo "→ analyze app"
$FLUTTER analyze --fatal-infos

echo "✓ analyze clean"
