#!/bin/sh
# Localizations and codegen, and nothing else.
#
# It exists so that `set-up` never becomes the reflex for a one-line change:
# a new ARB key costs this, not a full wipe and a cold build.
set -eu
. "$(dirname "$0")/_common.sh"

step "gen-l10n"
$FL gen-l10n

# No build_runner step, deliberately: this repo writes its Riverpod providers
# by hand (`CLAUDE.md`, Tech stack). A codegen step added later goes here.

done_msg "gen complete"
