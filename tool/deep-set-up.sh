#!/bin/sh
# `set-up`, plus Xcode's derived data.
#
# One variable, then the same script — a separate entry point rather than a
# flag because it costs a full cold build every time, and that is a price to
# ask for rather than one to charge by default.
#
# **Do not add a third clean-shaped command.** Two entry points, and `gen` for
# "all I changed is a string".
set -eu

DEEP_CLEAN=1
export DEEP_CLEAN

sh "$(dirname "$0")/set-up.sh"
