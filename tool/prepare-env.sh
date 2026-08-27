#!/bin/sh
# Put one flavour's configuration where the build reads it.
#
#   melos run prepare-env-dev
#   melos run prepare-env-prod
#
# Sources live in `env_assets/`, gitignored, one set per flavour. Destinations
# are the exact paths the tools read — the google-services gradle plugin, the
# Runner target, `--dart-define-from-file` — so they carry no dev-/prod-
# prefix. A prefixed copy beside them is a file nothing opens.
#
# Why it exists: nothing ties the Dart-visible config to the native SDK config.
# `env/prod.json` beside a dev `GoogleService-Info.plist` compiles, installs,
# launches and writes into the wrong Firestore. See `docs/rules/RELEASE.md`.
#
# It copies bytes and never reads them (hard rule 9). The one derived value is
# the sign-in URL scheme, and that lives in `tool/_url-scheme.sh` because the
# release workflow needs the same derivation.
set -eu
. "$(dirname "$0")/_common.sh"

FLAVOUR=${1:-}

case "$FLAVOUR" in
  dev | prod) ;;
  *) fail "usage: sh tool/prepare-env.sh <dev|prod>" ;;
esac

# Both env files every run; only the native pair is flavour-picked. Carrying
# both `env/*.json` costs nothing — `--dart-define-from-file` names the one it
# wants — and it means `melos run run -- prod` works straight afterwards.
PAIRS="env_assets/dev.json:env/dev.json
env_assets/prod.json:env/prod.json
env_assets/$FLAVOUR-google-services.json:android/app/google-services.json
env_assets/$FLAVOUR-GoogleService-Info.plist:ios/Runner/GoogleService-Info.plist"

# Check every source first, copy after. A run that dies on the third file
# leaves the tree half one environment and half the other, and nothing on disk
# says so.
MISSING=0

for PAIR in $PAIRS; do
  SRC=${PAIR%%:*}

  if [ ! -f "$SRC" ]; then
    warn "missing $SRC"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$MISSING" -ne 0 ]; then
  fail "$MISSING file(s) missing from env_assets/ — see docs/release/CREDENTIALS.md"
fi

step "$FLAVOUR config"

for PAIR in $PAIRS; do
  SRC=${PAIR%%:*}
  DST=${PAIR##*:}

  mkdir -p "$(dirname "$DST")"
  cp "$SRC" "$DST"
  step "  $DST"
done

# One implementation of the URL scheme, shared with the release workflow.
sh tool/_url-scheme.sh

done_msg "$FLAVOUR config in place — do not commit ios/Runner/Info.plist"
