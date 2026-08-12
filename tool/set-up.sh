#!/bin/sh
# Everything a fresh clone needs, in order. Idempotent — re-run any time.
#
# The wipe is unconditional on purpose: this is the one answer to "it built
# yesterday and not today". Reach for `melos run gen` when that is all you
# need.
set -e

sh tool/_clean.sh

echo "→ submodules"
git submodule sync --recursive
git submodule update --init --recursive
# Put the design system on the branch named in .gitmodules and fast-forward
# it, rather than leaving it detached at the recorded gitlink — so it stays
# editable in place. What you build is whatever is on that branch, NOT what
# the parent commit pins.
(cd packages/system_design && git checkout main && git pull --ff-only || true)

echo "→ pub get (system_design)"
(cd packages/system_design && fvm flutter pub get)

echo "→ pub get (app)"
fvm flutter pub get

echo "→ env files"
# Seed the real env files from their templates. Never overwrite: a developer's
# dev.json holds the ids they filled in, and clobbering it on every set-up is
# how those get lost.
for flavour in dev prod; do
  if [ ! -f "env/$flavour.json" ]; then
    cp "env/$flavour.example.json" "env/$flavour.json"
    echo "  created env/$flavour.json from the template — fill it in"
  fi
done

echo "→ gen-l10n"
fvm flutter gen-l10n

if [ -d functions ] && [ -f functions/package.json ]; then
  echo "→ npm ci (functions)"
  (cd functions && npm ci)
fi

if [ "$(uname)" = "Darwin" ] && [ -f ios/Podfile ]; then
  echo "→ pod install"
  (cd ios && pod install)
fi

echo "✓ set-up complete"
