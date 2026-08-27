#!/bin/sh
# The real security rules, run against the emulator.
#
# `docs/rules/BACKEND.md`: a rules test that mocks the evaluation proves
# nothing, because the thing being tested IS the evaluator. The emulator runs
# the same engine production does, so this is the only kind of rules test
# worth having.
#
# `emulators:exec` starts Firestore, runs the command, and tears down — so the
# suite leaves nothing running and its exit code is the command's.
set -eu
. "$(dirname "$0")/_common.sh"

# **The npm copy, not whatever `firebase` is on PATH.** A globally installed
# CLI is a `pkg` bundle carrying its own node, and the child process it spawns
# resolves `node` to that bundle — which does not understand `--test`, so the
# suite dies before it runs. The devDependency runs under the real node.
# The suite imports the COMPILED functions (`functions/lib/`) as well as the
# rules — plain node cannot read TypeScript. Building first is what stops a
# stale `lib/` quietly testing last week's code.
(cd functions && npm run build)

FIREBASE="functions/node_modules/.bin/firebase"
[ -x "$FIREBASE" ] || FIREBASE="npx --yes firebase-tools"

# A `demo-` project id keeps the emulator fully offline: it never asks for
# credentials and never reaches a real Firebase project.
$FIREBASE emulators:exec \
  --only firestore \
  --project demo-seller-os \
  "node --test functions/test/*.test.mjs"
