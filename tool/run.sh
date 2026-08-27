#!/bin/sh
# Run the app against a flavour's config. Defaults to dev.
#
#   melos run run            # env/dev.json
#   melos run run -- prod    # env/prod.json
#
# **Never run the app bare**: with no --dart-define-from-file every AppEnv
# getter falls back to its default, which is a silently different app from the
# one CI builds.
set -eu
. "$(dirname "$0")/_common.sh"

FLAVOUR=${1:-dev}
if [ $# -gt 0 ]; then shift; fi

if [ ! -f "env/$FLAVOUR.json" ]; then
  fail "env/$FLAVOUR.json does not exist — run 'melos run set-up' first"
fi

$FL run --dart-define-from-file="env/$FLAVOUR.json" "$@"
