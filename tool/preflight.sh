#!/bin/sh
# Everything that must be true before a build is worth uploading.
#
# The release blockers live in RELEASE_ACTIONS.md, but a document does not
# fail. This does: each check is one line of output, and the exit code is
# non-zero if any BLOCKER is unmet. Run it after the Firebase and signing
# setup, before `flutter build ipa`.
#
# Checks are ordered the way the blockers are, so the first ✗ is the first
# thing to go and fix.

FAILED=0

blocker() {
  if [ "$2" = "0" ]; then
    echo "  ✓ $1"
  else
    echo "  ✗ $1"
    FAILED=$((FAILED + 1))
  fi
}

warn() {
  if [ "$2" = "0" ]; then
    echo "  ✓ $1"
  else
    echo "  ! $1"
  fi
}

exists() {
  [ -f "$1" ] && echo 0 || echo 1
}

echo "→ 1-3  Firebase and sign-in configuration"
blocker "lib/firebase_options.dart written by flutterfire configure" \
  "$(exists lib/firebase_options.dart)"
blocker "ios/Runner/GoogleService-Info.plist" \
  "$(exists ios/Runner/GoogleService-Info.plist)"
blocker "android/app/google-services.json" \
  "$(exists android/app/google-services.json)"
warn ".firebaserc — needed by melos run deploy-firebase" "$(exists .firebaserc)"

# The reversed iOS client id has to be a URL scheme or Google sign-in returns
# to nothing. flutterfire configure does not add it.
if [ -f ios/Runner/GoogleService-Info.plist ]; then
  REVERSED=$(/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" \
    ios/Runner/GoogleService-Info.plist 2>/dev/null)
  if [ -n "$REVERSED" ]; then
    grep -q "$REVERSED" ios/Runner/Info.plist
    blocker "the reversed client id is a URL scheme in Info.plist" "$?"
  fi
fi

echo "→ 4    Auth is real, not bypassed"
# Hard rule 1: the bypass is scaffolding and a release must not want it.
grep -q '"BYPASS_AUTH": *false' env/prod.json 2>/dev/null
blocker "env/prod.json has BYPASS_AUTH false" "$?"
warn "env/dev.json has BYPASS_AUTH false — the bypass is deletable" \
  "$(grep -q '"BYPASS_AUTH": *false' env/dev.json 2>/dev/null && echo 0 || echo 1)"

echo "→ 5    Store assets and brand marks"
# Checksum, not file size: the icon can be redesigned to any size, but there
# is exactly one byte sequence that means "nobody replaced the template".
FLUTTER_DEFAULT_ICON=7770183009e914112de7d8ef1d235a6a30c5834424858e0d2f8253f6b8d31926
ICON=ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
if [ -f "$ICON" ]; then
  [ "$(shasum -a 256 "$ICON" | cut -d' ' -f1)" != "$FLUTTER_DEFAULT_ICON" ]
  blocker "the app icon is not Flutter's default" "$?"
else
  blocker "the 1024 app icon exists" 1
fi

grep -q "Symbols.person_rounded\|Symbols.g_mobiledata_rounded" \
  lib/features/auth/presentation/screens/login_screen/login_screen.dart
[ $? -eq 0 ] && MARKS=1 || MARKS=0
blocker "the login buttons carry real Apple and Google marks" "$MARKS"

echo "→ 6    iOS build settings"
grep -q "NSCameraUsageDescription" ios/Runner/Info.plist
blocker "NSCameraUsageDescription — the scanner crashes without it" "$?"
grep -q "NSPhotoLibraryUsageDescription" ios/Runner/Info.plist
blocker "NSPhotoLibraryUsageDescription" "$?"

echo "→ 7    Listing"
warn "docs/STORE_PRIVACY.md still has [brackets] to fill" \
  "$(grep -q '\[date\]\|\[support email\]\|\[region\]' docs/STORE_PRIVACY.md \
    2>/dev/null && echo 1 || echo 0)"

echo "→      Definition of done"
sh tool/analyze.sh > /dev/null 2>&1
blocker "melos run analyze is clean" "$?"

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "✓ preflight clean — nothing here blocks an upload"
else
  echo "✗ $FAILED blocker(s) unmet — see RELEASE_ACTIONS.md"
  exit 1
fi
