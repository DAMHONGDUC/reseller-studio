#!/bin/sh
# Everything a fresh clone needs, in order. Idempotent — re-run any time.
#
# The wipe is unconditional on purpose: this is the one answer to "it built
# yesterday and not today", and a clean that has to be decided is one nobody
# runs. Reach for `melos run gen` when a string or a table is all that changed.
set -eu
. "$(dirname "$0")/_common.sh"

sh tool/_clean.sh

step "submodules"
git submodule sync --recursive >/dev/null
git submodule update --init --recursive

# Put each submodule on the branch `.gitmodules` names and fast-forward it,
# rather than leaving it detached at the recorded gitlink — so it stays
# editable in place.
#
# The price, and it is a real one: **what you build is whatever is on that
# branch, not what the parent commit pins**, so a past parent commit no longer
# rebuilds byte for byte.
#
# A submodule that will not move is reported and skipped, never fatal: a
# developer mid-edit in one of them should still get a working set-up.
SUBMODULES=$(git config --file .gitmodules --name-only \
  --get-regexp '^submodule\..*\.path$' 2>/dev/null |
  sed 's/^submodule\.//; s/\.path$//' || true)

for NAME in $SUBMODULES; do
  SUB_PATH=$(git config --file .gitmodules --get "submodule.$NAME.path" || true)
  BRANCH=$(git config --file .gitmodules --get "submodule.$NAME.branch" || true)

  [ -n "$SUB_PATH" ] || continue

  if [ -z "$BRANCH" ]; then
    warn "$NAME: no branch in .gitmodules — left at the pinned commit"
    continue
  fi

  if (cd "$SUB_PATH" && git checkout "$BRANCH" >/dev/null 2>&1); then
    if ! (cd "$SUB_PATH" && git pull --ff-only >/dev/null 2>&1); then
      warn "$NAME: on $BRANCH, could not fast-forward"
    fi
  else
    warn "$NAME: could not check out $BRANCH — left detached"
  fi
done

for PACKAGE in packages/*/; do
  if [ -f "$PACKAGE/pubspec.yaml" ]; then
    step "pub get ($(basename "$PACKAGE"))"
    (cd "$PACKAGE" && $FL pub get)
  fi
done

step "pub get (app)"
$FL pub get

sh tool/gen.sh

step "env files"
# Seed the real env files from their templates. **Never overwrite**: a
# developer's dev.json holds the ids they filled in, and clobbering it on every
# set-up is how those get lost. The real values arrive from `env_assets/` —
# see `melos run prepare-env-dev`.
CREATED=""

# One template serves both flavours: the two files only ever differed by the
# values a developer fills in, and a second checked-in copy is a key list that
# goes stale in one place and not the other.
for FLAVOUR in dev prod; do
  if [ ! -f "env/$FLAVOUR.json" ]; then
    cp "env/env.example.json" "env/$FLAVOUR.json"
    CREATED="$CREATED env/$FLAVOUR.json"
  fi
done

if [ -f functions/package.json ]; then
  step "npm ci (functions)"
  (cd functions && npm ci)
fi

if [ "$(uname)" = "Darwin" ] && [ -f ios/Podfile ]; then
  step "pod install"
  # - LANG is FORCED, not defaulted: Ruby without a UTF-8 locale reads the
  #   Podfile as ASCII-8BIT and dies inside its own error reporter, and
  #   `LANG=C` breaks identically while satisfying a `:-` default.
  # - stderr is folded into stdout because melos labels every stderr line
  #   `ERROR:`, so an otherwise clean run reads as a failed one. `set -e` still
  #   stops on a real failure.
  (cd ios && LANG=en_US.UTF-8 pod install 2>&1)
fi

# Loudly, and at the end, where it is still on screen.
if [ -n "$CREATED" ]; then
  warn "created from templates and still placeholders:$CREATED"
  warn "fill them in, or run 'melos run prepare-env-dev' with env_assets/ in place"
fi

done_msg "set-up complete"
