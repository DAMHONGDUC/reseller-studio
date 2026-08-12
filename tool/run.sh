#!/bin/sh
# Run the app against a flavour's config. Defaults to dev.
#
#   sh tool/run.sh          # env/dev.json
#   sh tool/run.sh prod     # env/prod.json
#
# Never run the app bare: without --dart-define-from-file every AppEnv getter
# falls back to its default, which means no Firebase config and a silently
# different app from the one CI builds.
set -e

FLAVOUR=${1:-dev}
shift 2>/dev/null || true

if [ ! -f "env/$FLAVOUR.json" ]; then
  echo "✗ env/$FLAVOUR.json does not exist — run 'melos run set-up' first"
  exit 1
fi

fvm flutter run --dart-define-from-file="env/$FLAVOUR.json" "$@"
