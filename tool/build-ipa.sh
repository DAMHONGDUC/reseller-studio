#!/bin/sh
# Build a signed .ipa for one flavour. The only place an archive is made.
#
#   melos run build-ipa-dev
#   melos run build-ipa-prod
#   sh tool/build-ipa.sh prod ios/fastlane/ExportOptions.plist
#
# **Nobody archives from Xcode, and fastlane does not archive either** — its
# lane shells out to this same script. The app's whole configuration arrives
# through `--dart-define-from-file`, a flag `xcodebuild`, `gym` and
# Product > Archive all know nothing about. An archive made by any of them
# carries empty config and dies at runtime on
# `[core/no-app] No Firebase App '[DEFAULT]' has been created` — a crash that
# names nothing to do with the missing flag.
set -eu
. "$(dirname "$0")/_common.sh"

FLAVOUR=${1:-}
EXPORT_OPTIONS=${2:-}

case "$FLAVOUR" in
  dev | prod) ;;
  *) fail "usage: sh tool/build-ipa.sh <dev|prod> [export-options.plist]" ;;
esac

# Existence only, never contents. A missing file here costs twenty-five minutes
# to discover from the build itself.
[ -f "env/$FLAVOUR.json" ] ||
  fail "env/$FLAVOUR.json does not exist — run 'melos run prepare-env-$FLAVOUR'"
[ -f ios/Runner/GoogleService-Info.plist ] ||
  fail "ios/Runner/GoogleService-Info.plist does not exist — run 'melos run prepare-env-$FLAVOUR'"

# The version is read out of pubspec.yaml and never passed as a flag: a build
# whose version exists nowhere in git is one the repo cannot account for
# afterwards. The release lane writes the settled number there and commits it.
VERSION=$(grep '^version:' pubspec.yaml | cut -d' ' -f2)
step "$FLAVOUR $VERSION"

# Wipe first so the glob afterwards matches exactly one file and it is the one
# just built.
rm -rf build/ios/ipa

if [ -n "$EXPORT_OPTIONS" ]; then
  # A caller-supplied plist REPLACES --export-method rather than joining it:
  # `flutter build ipa` generates its own from --export-method and maps the
  # main bundle id only, which is wrong the moment the app has an extension.
  $FL build ipa \
    --dart-define-from-file="env/$FLAVOUR.json" \
    --export-options-plist="$EXPORT_OPTIONS"
else
  $FL build ipa \
    --dart-define-from-file="env/$FLAVOUR.json" \
    --export-method app-store
fi

done_msg "$(ls build/ios/ipa/*.ipa)"
