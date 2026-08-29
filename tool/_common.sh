# Shared by every script in tool/. **Sourced, never run** — the leading
# underscore is what says so, and nothing underscore-prefixed is named in
# melos.yaml.
#
# Every script opens with the same three lines:
#
#   #!/bin/sh
#   set -eu
#   . "$(dirname "$0")/_common.sh"

# Every path in every script is repo-relative. Melos exports the root; a bare
# `sh tool/x.sh` from the root gets the same answer out of the fallback.
cd "${MELOS_ROOT_PATH:-.}"

# `fvm` pins the SDK on a developer's machine; CI installs the pinned version
# itself and has no fvm. A shell alias does not exist inside a script, so
# without this a machine using a version manager silently runs a different SDK
# from the one `.fvmrc` names.
if [ -f .fvmrc ] && command -v fvm >/dev/null 2>&1; then
  FL="fvm flutter"
  DT="fvm dart"
else
  FL="flutter"
  DT="dart"
fi

export FL DT

# Colour unconditionally unless NO_COLOR. Melos hands every script a piped
# stdout and TERM=dumb even on a real terminal, so `[ -t 1 ]` and a TERM check
# both evaluate to "never colour at all". Melos passes ANSI through and CI
# renders it.
if [ -n "${NO_COLOR:-}" ]; then
  C_STEP=''
  C_WARN=''
  C_DONE=''
  C_OFF=''
else
  C_STEP=$(printf '\033[36m')
  C_WARN=$(printf '\033[33m')
  C_DONE=$(printf '\033[32m')
  C_OFF=$(printf '\033[0m')
fi

step() {
  printf '%s→ %s%s\n' "$C_STEP" "$1" "$C_OFF"
}

warn() {
  printf '%s! %s%s\n' "$C_WARN" "$1" "$C_OFF"
}

# Not `done` — that is a shell keyword.
done_msg() {
  printf '%s✓ %s%s\n' "$C_DONE" "$1" "$C_OFF"
}

fail() {
  printf '%s✗ %s%s\n' "$C_WARN" "$1" "$C_OFF" >&2
  exit 1
}
