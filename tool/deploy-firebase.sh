#!/bin/sh
# Deploy rules, indexes and functions. Confirms first — this reaches real
# users, and there is no staging project.
set -e

PROJECT=$(firebase use 2>/dev/null | head -1)
echo "About to deploy to: $PROJECT"
printf 'Type the project id to confirm: '
read -r CONFIRM

case "$PROJECT" in
  *"$CONFIRM"*) ;;
  *) echo "✗ mismatch — aborted"; exit 1 ;;
esac

# Storage belongs in this list: the app uploads item photos, receipts and the
# workspace logo, and storage.rules is never applied if it ships separately.
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
