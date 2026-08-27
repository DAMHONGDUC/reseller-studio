# Commands

Read this when running, building, generating or deploying. **This file is the
authority on the command set, and the only place it is explained.** The README
may list the names; it never gets a second explanation.

## The set

Fourteen commands. Every one is `melos run <name>`, and every body is a file in
`tool/`.

| Command | Script | Promise |
|---|---|---|
| `set-up` | `set-up.sh` | Wipe, then everything a fresh clone needs. Idempotent. |
| `deep-set-up` | `deep-set-up.sh` | `set-up` plus Xcode's derived data. Costs a cold build. |
| `prepare-env-dev` | `prepare-env.sh dev` | Install dev's config — env files + native files. |
| `prepare-env-prod` | `prepare-env.sh prod` | The same, prod's native files. |
| `run` | `run.sh` | The app, against a flavour's env config. |
| `gen` | `gen.sh` | Localizations and codegen, nothing else. |
| `analyze` | `analyze.sh` | Zero findings, or fail. What CI runs. |
| `test` | `test.sh` | The test suite. |
| `test-rules` | `test-rules.sh` | `firestore.rules` against the emulator. |
| `preflight` | `preflight.sh` | Everything that must be true before a build is worth uploading. |
| `build-ipa-dev` | `build-ipa.sh dev` | The IPA, dev config attached. |
| `build-ipa-prod` | `build-ipa.sh prod` | The IPA, prod config attached. |
| `deploy-firebase-dev` | `deploy-firebase.sh dev` | Rules, indexes and functions to the dev alias. |
| `deploy-firebase-prod` | `deploy-firebase.sh prod` | The same, prod alias. |

Three shapes recur, and they are the pattern to copy:

- **A flavour is a separate command, never a flag on a shared one.** `-dev` and
  `-prod` are typed on purpose; a prod deploy inherited from whatever the CLI
  was last pointed at is the failure this prevents.
- **One script serves both flavours, taking the flavour as `$1`.** The
  `melos.yaml` entry is the only thing that is duplicated.
- **Underscore-prefixed files are not commands.** `_common.sh`, `_clean.sh`,
  `_url-scheme.sh` — sourced or called by others, never named in `melos.yaml`.

## What each one actually does

### `set-up` — the one answer to "it built yesterday and not today"

Ordered, and the order is the contract:

1. **Wipe, unconditionally** (`_clean.sh`). A clean that has to be decided is
   one nobody runs.
2. **Submodules onto their branch, not the pinned commit** — read
   `submodule.<name>.branch` out of `.gitmodules`, check out, `pull --ff-only`,
   and **report per submodule when either step fails instead of dying**: a
   developer mid-edit in one of them should still get a working set-up.
3. Dependencies, each package then the app.
4. Localizations and codegen (`gen.sh`).
5. **Env templates** — copy `env/<flavour>.example.json` for each missing one,
   collect the names, and warn loudly at the end where it is still on screen.
   Never overwrite: a developer's `dev.json` holds ids they filled in.
6. `npm ci` in `functions/` when it exists.
7. `pod install`, macOS only, when a `Podfile` exists.

Two details in step 7 that are not cosmetic:

- **`LANG` is forced, not defaulted.** Ruby without a UTF-8 locale reads the
  Podfile as ASCII-8BIT and dies inside its own error reporter, on a trace
  naming the encoding and never the missing locale. `LANG=C` breaks
  identically, and only an *unset* one would be caught by a `:-` default.
- **`pod install 2>&1`.** Melos labels every stderr line `ERROR:`, so an
  otherwise clean run reads as a failed one. `set -e` still stops on a real
  failure.

**The submodule choice has a price, and it is stated where people read it:**
after this, what you build is whatever is on the design system's branch, not
what the parent commit pins — so a past parent commit no longer rebuilds byte
for byte. It is also why CI runs `git submodule update --remote`, and why the
submodule must be **pushed** for CI to see it. When CI and a laptop disagree,
check that gap first.

### `deep-set-up` — the second entry point, and the last one

Sets one variable and calls `set-up`; `_clean.sh` reads it and additionally
clears Xcode's derived data.

Why it is separate: Xcode caches precompiled modules against the modulemap it
saw at the time, so bumping a native plugin leaves a `.pcm` no `flutter clean`
can reach — *has been modified since the module file was built*. Clearing it
fixes that and costs a full cold build, which is exactly the trade that must
stay opt-in.

**The cache is matched on the workspace path Xcode recorded, never the folder
name.** Every Flutter app builds a target called Runner, so a `Runner-*` glob
deletes other projects' caches.

**Do not add a third clean-shaped command.** Two entry points, and `gen` for
"all I changed is a table or a string".

### `gen` — the cheap one

Localizations and codegen, and nothing else. It exists so `set-up` never
becomes the reflex for a one-line change. No `build_runner` step here: this
repo writes its Riverpod providers by hand.

### `analyze` — the gate

`flutter analyze --fatal-infos`, every package, the design system standalone
first. Zero findings before any task is done, and **byte for byte what CI
runs** — a gate that differs from CI is a gate that passes and then fails.

### `test`

The suite, **for CI and for the rare full sweep**. Locally, never run the whole
thing to verify a change: scope to the file that changed. `*_tmp_test.dart` is
gitignored because the scratch harnesses hang the runner by design and
`flutter test` with no arguments picks them up.

### `test-rules`

`firestore.rules` against the emulator, plus the pure function tests. Starts
and stops the emulator itself and needs **Java**. Uses the `firebase` CLI from
`functions/node_modules`, deliberately not whatever is on PATH: a globally
installed CLI is a `pkg` bundle carrying its own node, and the child process it
spawns resolves `node` to that bundle, which does not understand `--test`.
**It builds `functions/` first** — the suite runs under plain node and imports
the compiled `functions/lib/`, so a stale `lib/` would quietly test last week's
code.

### `preflight`

Everything that must be true before a build is worth uploading: the Firebase
and sign-in files, no auth bypass in `lib/`, the icon not being Flutter's, the
iOS usage strings, the legal URLs, the release credentials, and a clean
analyze. Exits non-zero on an unmet blocker, so it is the check
`RELEASE_ACTIONS.md` cannot be.

### `prepare-env-*` and `build-ipa-*`

`docs/rules/RELEASE.md`. In one line each: nothing else ties
`env/<flavour>.json` to the installed `GoogleService-Info.plist`, and
`build-ipa` is **the only place an archive is made** — not `gym`, and never
Xcode's Product > Archive, both of which skip `--dart-define-from-file` and
produce a binary that dies on
`[core/no-app] No Firebase App '[DEFAULT]' has been created`.

### `deploy-firebase-*` — the one that reaches real users

**The environment is a CLI alias in `.firebaserc`, not an `env/*.json` file**:
the alias resolves to a project id, and the project id is what picks the
functions' own config and secrets. Naming the environment is the whole of the
switch.

Its contract, in order:

1. Validate the flavour, and an optional target (`rules` | `functions` |
   `both`).
2. **Resolve the alias to a project id itself**, so the prompt can name the
   project before anything is sent, and so a missing alias fails with the
   command that creates it rather than a CLI error naming neither.
3. **Warn when dev and prod resolve to the same project.** Until they are
   split, `deploy-firebase-dev` is a production deploy wearing another name —
   the one thing an alias in the prompt would otherwise hide.
4. **Confirm interactively, reading from `/dev/tty`.** Melos pipes stdout but
   leaves stdin alone, and `/dev/tty` is the descriptor that survives a
   redirected invocation. No terminal at all is a refusal, never a silent yes.
5. **Build and test the functions before deploying them.** Deploying a build
   that fails its own tests costs a second deploy to undo.
6. **`--project` on every deploy; never `firebase use` first.** `use` leaves
   the developer's shell pointed at whatever the script deployed last, so their
   next bare `firebase deploy` goes there silently.
7. **Rules and indexes deploy together** — a missing composite index fails at
   runtime, not at build. Storage goes with them: the app uploads item photos,
   receipts and the workspace logo.

**The script is the one place that list is written.** Never copy the
`firebase deploy` line into a document: `storage` once went missing from the
script while `RELEASE_ACTIONS.md` still named it, and the bucket the app
uploads to was the one nobody was deploying rules for.

## The conventions

### Every body is a file; `melos.yaml` only names it

Melos echoes the whole `run:` block before **and** after every run, with no
flag to turn it off, so a multi-line body buries the output it introduces. A
file is also the only version that can be linted and run directly. Adding a
command is a `tool/*.sh` plus one line in `melos.yaml` — **a `run:` longer than
one line is the smell.** Every command also carries a real `description:`; that
is what `melos run` prints.

### POSIX `sh`, not bash

Melos runs scripts through `/bin/sh`, which is dash on Linux: `set -o pipefail`,
`[[ ]]` and `local` are syntax errors there. macOS will not catch it — its
`/bin/sh` is bash under another name. Check before committing:

```bash
dash -n tool/<name>.sh
```

### Every script opens the same way

```sh
#!/bin/sh
set -eu
. "$(dirname "$0")/_common.sh"
```

`tool/_common.sh` holds what they share:

- `cd "${MELOS_ROOT_PATH:-.}"` — every path in every script is repo-relative.
- **SDK resolution**, exported as `$FL` / `$DT`: `fvm flutter` when `.fvmrc`
  and `fvm` are both present, plain `flutter` otherwise. A shell alias does not
  exist inside a script, so without this a machine using a version manager
  silently runs the wrong SDK — and it is the only difference between a runner
  and a laptop.
- `step` / `warn` / `done_msg` / `fail`, colour-coded.
- **Colour is emitted unconditionally unless `NO_COLOR` is set.** Melos hands
  every script a piped stdout and `TERM=dumb` even on a real terminal, so
  `[ -t 1 ]` and a `TERM` check both mean "never colour at all". Melos passes
  ANSI through and CI renders it.

`preflight.sh` is the one script without `set -e`, and it says why: every check
must run so the output is the whole list rather than the first failure.

### Pin the runner exactly, and know why you are on that major

`dart pub global activate melos 6.3.3` — **exact, not caret**, and the global
and local versions must match. This repo stays on 6 deliberately: 7+ moves to
pub workspaces, which requires `resolution: workspace` inside
`packages/system_design` — and that stops the package resolving in any project
that is not itself a workspace, which is exactly the portability the submodule
exists for. BaroEase consumes the same submodule and is not a workspace.

A version pin with no recorded reason is one the next session "upgrades", so
the reason lives in `melos.yaml` next to the pin as well as here.
`ide: intellij: false` is there for the same kind of reason: 6.3.3 ships
without the run-configuration templates it tries to write, and nothing here
uses them.

## Two rules that are not about any one command

**The version and build number are edited in `pubspec.yaml`, never passed as a
`--build-name`/`--build-number` flag.** A build whose version exists nowhere in
git is one the repo cannot account for afterwards. The release lane obeys this
too: it *writes* the settled number into `pubspec.yaml` and commits it after
the upload.

**Never run the app bare.** With no `--dart-define-from-file` every `AppEnv`
getter falls back to its default, which is a silently different app from the
one CI builds. `melos run run` and the **"Seller OS (dev)"** VS Code launch
configuration both pass it.

Running before Firebase exists: sign-in cannot succeed, and **there is no
bypass** (hard rule 1). The app opens on the signed-out shell. **Mock data does
not come on with it** — `MOCK_DATA_DEFAULT` is off unless the env file sets it,
so a dev run opens the app a new seller would see. Turn the fake business on in
More → Settings.

## Releasing

Three fastlane lanes, run from `ios/`. `docs/rules/RELEASE.md` is the authority
on what each does and why the order matters.

```bash
bundle exec fastlane preflight
```

- `preflight` — everything a release depends on except the build. Three minutes
  instead of twenty-eight. Run `CI=true bundle exec fastlane preflight` after
  it: the CI half is the one most likely to break.
- `certificates` — **local only**, and refuses to run on a runner.
  `force:true` regenerates the profiles after enabling a capability.
- `beta flavor:prod bump:true notes:"…"` — the real thing. **Normally run from
  the `Release` workflow, not by hand**: `workflow_dispatch` on GitHub, because
  a release is an act and not a side effect of a push.
