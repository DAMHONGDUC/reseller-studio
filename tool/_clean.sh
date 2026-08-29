#!/bin/sh
# Wipe every build artefact. Called by set-up.sh, never named in melos.yaml.
#
# `DEEP_CLEAN=1` additionally clears Xcode's derived data — see deep-set-up.sh
# for why that is opt-in.
set -eu
. "$(dirname "$0")/_common.sh"

step "flutter clean (app)"
$FL clean >/dev/null

for PACKAGE in packages/*/; do
  if [ -f "$PACKAGE/pubspec.yaml" ]; then
    step "flutter clean ($(basename "$PACKAGE"))"
    (cd "$PACKAGE" && $FL clean >/dev/null)
  fi
done

step "removing build output"
rm -rf build android/.gradle android/app/build
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/Flutter/ephemeral

if [ "${DEEP_CLEAN:-}" != "1" ]; then
  exit 0
fi

# Xcode caches precompiled modules against the modulemap it saw at the time,
# so bumping a native plugin leaves a `.pcm` that no `flutter clean` can reach
# — "has been modified since the module file was built". Clearing it fixes
# that and costs a full cold build, which is why it is opt-in.
step "clearing Xcode derived data (this costs a cold build)"

DERIVED="$HOME/Library/Developer/Xcode/DerivedData"

if [ ! -d "$DERIVED" ]; then
  exit 0
fi

# Matched on the workspace path Xcode recorded, **never on the folder name**.
# Every Flutter app builds a target called Runner, so a `Runner-*` glob deletes
# other projects' caches.
for DIR in "$DERIVED"/*/; do
  [ -f "$DIR/info.plist" ] || continue

  WORKSPACE=$(/usr/libexec/PlistBuddy -c "Print :WorkspacePath" \
    "$DIR/info.plist" 2>/dev/null || true)

  case "$WORKSPACE" in
    "$PWD"/*)
      rm -rf "$DIR"
      step "  removed $(basename "$DIR")"
      ;;
  esac
done
