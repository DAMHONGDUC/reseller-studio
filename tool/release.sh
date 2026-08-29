#!/bin/sh
# One flavour, all the way to TestFlight. **This reaches real users.**
#
#   melos run release-dev
#   melos run release-prod
#   melos run release-prod -- fixes the settlement sheet
#
# Three steps that were three commands, in the order they have to run:
#
#   1. prepare-env  — the env file and the native config, together.
#   2. deploy-firebase — rules, indexes and functions. Confirms interactively.
#   3. fastlane beta — the archive and the upload.
#
# The order is the point. Backend first: a build that reaches a tester before
# the rules it needs is a build that fails on a query nobody can fix from the
# App Store. And `set -e` is what makes this a chain rather than a list — a
# failed deploy must never be followed by an upload.
#
# **Not a shortcut past the confirm.** Step 2 still asks for the project id on
# /dev/tty and still refuses with no terminal, so an unattended run stops here
# rather than shipping.
set -eu
. "$(dirname "$0")/_common.sh"

FLAVOUR=${1:-}

case "$FLAVOUR" in
  dev | prod) ;;
  *) fail "usage: sh tool/release.sh <dev|prod> [testflight note]" ;;
esac

if [ $# -gt 0 ]; then shift; fi

# Everything after the flavour is the note, collected with $* rather than $2:
# melos joins its extra args into the command line before a shell sees them,
# so a three-word note arrives as three arguments.
NOTES=$*

[ -n "$NOTES" ] || NOTES=$FLAVOUR

# Checked before the twenty-five minute step, not inside it. `bundle exec` from
# a tree with no Gemfile.lock resolves whatever gems the machine happens to
# have, which is how a lane that passed last week fails on nothing that changed.
command -v bundle >/dev/null 2>&1 ||
  fail "no bundler — run 'gem install bundler' then 'bundle install' in ios/"
[ -f ios/Gemfile.lock ] || fail "no ios/Gemfile.lock — run 'bundle install' in ios/"

step "releasing $FLAVOUR — note: $NOTES"

step "1/3 config"
sh tool/prepare-env.sh "$FLAVOUR"

step "2/3 firebase"
sh tool/deploy-firebase.sh "$FLAVOUR"

# A subshell, so the working directory is this repo's root again afterwards
# whether the lane passed or failed.
step "3/3 testflight"
(cd ios && bundle exec fastlane beta flavor:"$FLAVOUR" bump:true notes:"$NOTES")

done_msg "$FLAVOUR released"
