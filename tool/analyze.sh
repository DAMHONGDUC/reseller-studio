#!/bin/sh
# Exactly what CI runs. Must pass with zero findings before any task is done —
# a gate that differs from CI is a gate that passes and then fails.
#
# The design system is analyzed on its own first: it must compile without the
# host app, and running it from inside the app would hide an app dependency
# leaking into the package.
set -eu
. "$(dirname "$0")/_common.sh"

for PACKAGE in packages/*/; do
  if [ -f "$PACKAGE/pubspec.yaml" ]; then
    step "analyze $(basename "$PACKAGE") (standalone)"
    (cd "$PACKAGE" && $FL analyze --fatal-infos)
  fi
done

step "analyze app"
$FL analyze --fatal-infos

done_msg "analyze clean"
