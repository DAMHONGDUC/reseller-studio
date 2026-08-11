#!/bin/sh
# Regenerate localizations. Run after editing any ARB file.
set -e

fvm flutter gen-l10n
echo "✓ gen complete"
