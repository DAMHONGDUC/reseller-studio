#!/bin/sh
set -e

# `fvm` pins the SDK on a developer's machine; CI installs the pinned version
# itself (see .github/workflows/ci.yml) and has no fvm. One script either way —
# a CI job that retyped these commands would drift from the one people run.
FLUTTER="fvm flutter"
command -v fvm >/dev/null 2>&1 || FLUTTER="flutter"

$FLUTTER test "$@"
