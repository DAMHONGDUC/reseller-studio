#!/bin/sh
# The suite.
#
# **For CI and for the rare full sweep, not a per-change habit.** Verifying one
# change by running everything costs minutes to learn what one file would have
# said in seconds — scope to the file that changed instead:
#
#   fvm flutter test test/features/<feature>/<name>_test.dart
set -eu
. "$(dirname "$0")/_common.sh"

$FL test "$@"
