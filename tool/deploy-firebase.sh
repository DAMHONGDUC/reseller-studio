#!/bin/sh
# Deploy rules, indexes and functions. **This reaches real users.**
#
#   melos run deploy-firebase-dev
#   melos run deploy-firebase-prod
#   sh tool/deploy-firebase.sh prod rules
#
# The environment here is a CLI alias in `.firebaserc`, not an `env/*.json`
# file: the alias resolves to a project id, and the project id is what picks
# the functions' own config and secrets. **Naming the environment is the whole
# of the switch.**
set -eu
. "$(dirname "$0")/_common.sh"

FLAVOUR=${1:-}
TARGET=${2:-both}

case "$FLAVOUR" in
  dev | prod) ;;
  *) fail "usage: sh tool/deploy-firebase.sh <dev|prod> [rules|functions|both]" ;;
esac

case "$TARGET" in
  rules | functions | both) ;;
  *) fail "target must be rules, functions or both" ;;
esac

[ -f .firebaserc ] || fail ".firebaserc does not exist — run 'firebase use --add'"

# Resolved here rather than left to the CLI, for two reasons: the prompt below
# can then name the project before anything is sent, and a missing alias fails
# with the command that creates it instead of a CLI error naming neither.
alias_project() {
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg name "$1" '.projects[$name] // empty' .firebaserc
  else
    python3 -c 'import json,sys; print(json.load(open(".firebaserc"))["projects"].get(sys.argv[1], ""))' "$1"
  fi
}

PROJECT=$(alias_project "$FLAVOUR")
OTHER=$(alias_project "$([ "$FLAVOUR" = "prod" ] && echo dev || echo prod)")

[ -n "$PROJECT" ] ||
  fail "no '$FLAVOUR' alias in .firebaserc — run 'firebase use --add' and name it $FLAVOUR"

# Until the two are split, `deploy-firebase-dev` is a production deploy wearing
# another name — the one thing an alias in the prompt would otherwise hide.
if [ "$PROJECT" = "$OTHER" ]; then
  warn "dev and prod both resolve to $PROJECT — this IS the production project"
fi

step "about to deploy $TARGET to $FLAVOUR ($PROJECT)"

# Read from the terminal, not from stdin. Melos pipes stdout but leaves stdin
# alone, and /dev/tty is the descriptor that survives a redirected invocation.
# No tty at all (a CI job) is a refusal, never a silent yes.
if [ -r /dev/tty ]; then
  printf 'Type the project id to confirm: '
  read -r CONFIRM < /dev/tty
else
  fail "no terminal to confirm on — this script never deploys unattended"
fi

[ "$CONFIRM" = "$PROJECT" ] || fail "mismatch — aborted"

FIREBASE="functions/node_modules/.bin/firebase"
[ -x "$FIREBASE" ] || FIREBASE="npx --yes firebase-tools"

# Rules and indexes go together: a missing composite index fails at runtime,
# not at build, so shipping one without the other is a live outage on a query
# nobody ran locally. Storage belongs in the same breath — the app uploads item
# photos, receipts and the workspace logo.
if [ "$TARGET" != "functions" ]; then
  step "rules, indexes and storage"
  $FIREBASE deploy --project "$PROJECT" \
    --only firestore:rules,firestore:indexes,storage
fi

if [ "$TARGET" != "rules" ]; then
  # Built and tested first. Deploying a build that fails its own tests costs a
  # second deploy to undo.
  step "building and testing functions"
  (cd functions && npm run build && npm run lint)
  sh tool/test-rules.sh

  step "functions"
  $FIREBASE deploy --project "$PROJECT" --only functions
fi

# **--project on every deploy; never `firebase use` first.** `use` leaves the
# developer's shell pointed at whatever this script deployed last, so their
# next bare `firebase deploy` goes there silently.
done_msg "deployed $TARGET to $PROJECT"
