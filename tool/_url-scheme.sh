#!/bin/sh
# Write the Google sign-in callback scheme into ios/Runner/Info.plist.
# Called by prepare-env.sh and by the release workflow, never named in
# melos.yaml.
#
# The scheme is the reversed client id of THIS flavour's Firebase project, and
# `flutterfire configure` does not add it. **Derived from the installed
# GoogleService-Info.plist, never carried as a file of its own** — two copies
# of derived data is what makes them drift.
#
# `ios/Runner/Info.plist` is tracked, so this leaves the working tree dirty on
# purpose. **Never commit the entry**: it pins one flavour into git.
set -eu
. "$(dirname "$0")/_common.sh"

PLIST=ios/Runner/Info.plist
SOURCE=ios/Runner/GoogleService-Info.plist

if [ "$(uname)" != "Darwin" ]; then
  warn "not macOS — skipping the URL scheme"
  exit 0
fi

REVERSED=$(/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" "$SOURCE" \
  2>/dev/null || true)

if [ -z "$REVERSED" ]; then
  warn "no REVERSED_CLIENT_ID in $SOURCE — Google sign-in will not return"
  exit 0
fi

# Find the derived entry by name and delete it, so a re-run replaces it rather
# than appending a second one. The loop exits with INDEX holding the count of
# the entries that stayed, which is where the new one goes.
INDEX=0

while /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:$INDEX:CFBundleURLName" \
  "$PLIST" >/dev/null 2>&1; do
  NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:$INDEX:CFBundleURLName" "$PLIST")

  if [ "$NAME" = "google-sign-in" ]; then
    /usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes:$INDEX" "$PLIST"
  else
    INDEX=$((INDEX + 1))
  fi
done

/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes: dict" "$PLIST" >/dev/null
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$INDEX:CFBundleTypeRole string Editor" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$INDEX:CFBundleURLName string google-sign-in" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$INDEX:CFBundleURLSchemes array" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$INDEX:CFBundleURLSchemes: string $REVERSED" "$PLIST"

step "  $PLIST (google-sign-in URL scheme)"
