# Commands

Read when running, building, generating or deploying. **This file is the authority on the command set and the only place it is explained.** The README may list the names; it never explains them a second time.

**Never create or edit a command script in `packages/script-tools/` from this app repo.** Owner's rule. Those files belong to the script-tools submodule and stay exactly as it supplies them. When the app's command config names a missing or incompatible script, fix the app-side config, or update the submodule in its own repo — never patch the script locally.

**Command scripts live in `packages/script-tools/flutter/`, never in the app's `tool/`.** Owner's rule. One setup, analysis, test and release pipeline serves every app using the submodule; a second copy in the app lets fixes land in one pipeline while the other silently goes stale.

**An app-specific check is not a shared script.** Owner's rule, stated when the design system deleted `tool/pre-build.sh`: a gate full of one app's bundle ids, entitlements and store rules cannot live in a folder every app shares — it arrived as another app's checks and would drift again. It belongs in this app's fastlane lane and, if it needs a short name, a target in this app's `Makefile` — never a second local script tree.

## The set

**Every platform answers to one command list, and this app uses it unchanged.** Owner's rule: the owner works across many projects on several platforms, and a command named one way here and another way in the next project is one that gets forgotten. The list, what each command means on each platform and the old names that still work live in `packages/script-tools/common/COMMANDS.md`; this file only says what each does in this app.

**Three parts, and the first is part of the other two** (owner's rule): `env-*` installs a flavour's config, and `deploy-be-*`, `release-ios-*` and `release-android-*` each run it first by themselves. The backend is its own command, never a step of a release.

Every command is `make <name>`; bare `make` lists them. The root `Makefile` includes `packages/script-tools/flutter/flutter.mk`, which maps each target to a script in `packages/script-tools/flutter/` — except `pre-build`, defined in the `Makefile` itself because its body is this app's fastlane lane.

| Command | Script | Promise |
|---|---|---|
| `setup` | `set_up.sh` | Wipe, then everything a fresh clone needs. Idempotent. |
| `setup-deep` | `set_up.sh --deep` | `setup` plus Xcode's derived data. Costs a cold build. |
| `env-dev` / `env-prod` | `prepare_env.sh <flavour>` | Install that flavour's config — env files + native files. |
| `gen` | `generate_code.sh` | Localizations and codegen, nothing else. Off the shared list, still runs. |
| `analyze` | `analyze_code.sh` | Zero findings, or fail. What CI runs. Off the shared list, still runs — the definition of done types it. |
| `test` | `run_tests.sh` | `TEST=<path>` scopes it to one file or folder. |
| `run-dev` / `run-prod` | `run_app.sh <flavour>` | `flutter run` in debug, with that flavour's config. |
| `pre-build` | fastlane `preflight` | The app's own gate — config, signing, build number. |
| `deploy-be-dev` / `deploy-be-prod` | `deploy_backend.sh <flavour>` | Install that flavour's config, then rules, indexes and functions to its alias — only with `.firebaserc`. `ONLY=rules\|functions` narrows it. |
| `release-ios-dev` / `release-ios-prod` | `release_ios.sh <flavour>` | Install that flavour's config, then the IPA to TestFlight. Deploys no backend. `NOTE="…"` for What to Test. |
| `release-android-dev` / `release-android-prod` | `release_android.sh <flavour>` | Install that flavour's config, then the release APK and AAB into `Release/`. Signed with the debug key until a release `signingConfig` exists — the script warns. |
| `icon` / `icon-strip` | `generate_app_icon.sh` / `strip_icon_marker.sh` | Launcher and launch icons from the artwork; erase its watermark. |

Recurring shapes, and the pattern to copy:

- **A flavour is part of the target name, never a defaulted flag.** `-dev` and `-prod` are typed on purpose; a prod deploy inherited from wherever the CLI last pointed is the failure this prevents. A flavour not in `FLAVORS` (default `dev prod`) is refused with the usage line.
- **One script serves every flavour, taking it as `$1`.** `flutter.mk` has one pattern rule per command; nothing is duplicated per flavour.
- **A chaining command calls the other scripts, never their steps.** `release_ios.sh` runs `prepare_env.sh`, `deploy_firebase.sh` and the beta lane in order, re-implementing none — so the confirm prompt and every check are the ones each step gets alone.

**The shared list stays minimal** (owner's rule), so `gen` and `analyze` are off it and out of `make help`, and still run; `clean` is gone. The old names (`set-up`, `build-ipa-*`, `upload-ipa-*`, `deploy-*`, `release-*`, `app-icon`, …) still run and stay out of `make help` — `release-*` as it always did, the backend then TestFlight.

**`run-*` is back, with the shared list** — it was deleted here once, and returned when every platform took the same commands. **No `test-rules` or `_url-scheme` command exists, and no `pre-build` script.** Both were deleted. `pre-build` is the one command whose body is not a shared script: a gate naming this app's bundle ids, entitlements and store rules cannot live in a folder every app shares, so it is the `preflight` lane, reached through this app's `Makefile`. **`release-ios-*` does not run it** — `release_ios.sh` names no app — so run `pre-build` before a release; the release does not run it for you.

## What each one actually does

### `setup` — the one answer to "it built yesterday and not today"

Ordered; the order is the contract:

1. **Wipe, unconditionally** (top of `set_up.sh`). A clean that must be decided is one nobody runs.
2. **Submodules onto their branch, not the pinned commit** — read `submodule.<name>.branch` from `.gitmodules`, check out, `pull --ff-only`, and **report per submodule when a step fails instead of dying**: a developer mid-edit in one still gets a working setup.
3. Dependencies: the app, every `packages/*/pubspec.yaml`, and script-tools' own Dart tools.
4. Localizations and codegen (`generate_code.sh`).
5. **Env templates** — copy `env/env.example.json` into each missing flavour file, collect the names, and warn loudly at the end, where it is still on screen. One template serves both flavours: they only differed by filled-in values, and a second checked-in copy is a key list that goes stale in one place. Never overwrite: a developer's `dev.json` holds ids they filled in.
6. `npm ci` in `functions/` when it exists.

No `pod install`: every iOS plugin resolves as a Swift Package, which Xcode handles on the first build.

**The submodule choice has a price, stated where people read it:** after this, you build whatever is on each submodule's branch, not what the parent commit pins — so an old parent commit no longer rebuilds byte for byte. It is also why CI runs `git submodule update --remote`, and why a submodule must be **pushed** for CI to see it. When CI and a laptop disagree, check that gap first.

### `setup-deep` — the second entry point, and the last

`set_up.sh --deep`: the same run, and the wipe also clears Xcode's derived data.

- Why separate: Xcode caches precompiled modules against the modulemap it saw, so bumping a native plugin leaves a `.pcm` no `flutter clean` reaches — *has been modified since the module file was built*. Clearing it fixes that at the cost of a full cold build — exactly the trade that must stay opt-in.
- **The cache is matched on the workspace path Xcode recorded, never the folder name.** Every Flutter app builds a target called Runner, so a `Runner-*` glob deletes other projects' caches.
- **Add no third clean-shaped command.** Two entry points, plus `gen` for "all I changed is a table or a string".

### `gen` — the cheap one

Localizations and codegen, nothing else. It exists so `setup` never becomes the reflex for a one-line change.

- **There is one `build_runner` step, and it is Drift's.** Riverpod providers are still hand-written — that rule has not moved — but the guest database is generated (`docs/rules/GUEST_MODE.md` has the exception and why it is safe). `generate_code.sh` runs it only when `build_runner` is in `pubspec.yaml`, so the script matches the sibling app's.
- **Run it after a schema change, never before reading the repo.** The generated file is committed, so `analyze` and `test` need no build step — the clause that keeps the original objection answered.

### `analyze` — the gate

`flutter analyze --fatal-infos`, every package, the design system standalone first. Zero findings before any task is done, and **byte for byte what CI runs** — a gate differing from CI passes, then fails.

### `test`

The suite, **for CI and the rare full sweep**. Locally, never run it all to verify a change: scope to the changed file. `*_tmp_test.dart` is gitignored because scratch harnesses hang the runner by design, and argument-free `flutter test` picks them up.

### `pre-build`

Everything a release needs but the build, owned by the app: the installed config matches the flavour, the App Store Connect key is accepted, the build number settles against TestFlight, and on CI the profiles resolve and carry the entitlements. It fails loudly — the check `docs/release/RELEASE_ACTIONS.md` cannot be.

**`flavor:` is optional and skipped, not defaulted** — defaulting to prod would fail a dev-machine rehearsal over the one question it was not asked.

### `env-*` and the IPA

See `docs/rules/RELEASE.md`. One line each: nothing else ties `env/<flavour>.json` to the installed `GoogleService-Info.plist`; and `build_ipa.sh` — reached through `release-ios-*` — is **the only place an archive is made** — not `gym`, never Xcode's Product > Archive, both of which skip `--dart-define-from-file` and produce a binary that dies on `[core/no-app] No Firebase App '[DEFAULT]' has been created`.

### `deploy-be-*` — the one that reaches real users

**The environment is a CLI alias in `.firebaserc`, not an `env/*.json` file**: the alias resolves to a project id, which picks the functions' own config and secrets. Naming the environment is the whole switch.

Its contract, in order:

1. Validate the flavour and an optional target (`ONLY=rules` | `ONLY=functions`; both when unset).
2. **Resolve the alias to a project id itself**, so the prompt names the project before anything is sent, and a missing alias fails with the command that creates it, not a CLI error naming neither.
3. **Warn when dev and prod resolve to one project.** Until split, `deploy-be-dev` is a production deploy under another name — exactly what an alias in the prompt would hide.
4. **Confirm interactively, reading `/dev/tty`.** A caller may pipe stdout or stdin; `/dev/tty` survives a redirected call. No terminal means refusal, never a silent yes.
5. **Build and test the functions before deploying.** Deploying a build that fails its own tests costs a second deploy to undo.
6. **`--project` on every deploy; never `firebase use` first.** `use` leaves the developer's shell pointed at whatever the script deployed last, so their next bare `firebase deploy` silently goes there.
7. **Set the Artifact Registry cleanup policy before deploying, keeping retention at what the script passes to `--days`.** Owner's rule, fixed for every project and region — never raised for one.
   - With no policy, the CLI asks for one *after* a successful deploy, so a run with no terminal exits non-zero with the functions already live.
   - With per-project retention, one command means different things by target.
   - The step may fail: a project's first-ever deploy has no repository to set it on yet.
   - **Never pass `--force` to `firebase deploy` to silence that prompt** — on `deploy` it also deletes functions missing from the source without asking, far larger than the warning it hides.
8. **Rules and indexes deploy together** — a missing composite index fails at runtime, not build. Storage goes with them: the app uploads item photos, receipts and the workspace logo.

**The script is the one place that list is written.** Never copy the `firebase deploy` line into a document: `storage` once went missing from the script while `docs/release/RELEASE_ACTIONS.md` still named it, and the app's upload bucket was the one nobody deployed rules for.

### `release-ios-*` and `release-android-*` — the app, never the backend

Each installs the flavour's config, then builds: `release-ios-*` runs the `beta` lane, which builds through `build_ipa.sh` and uploads to TestFlight; `release-android-*` builds the release APK and AAB into `Release/`. Neither runs `set_up.sh` — they build the tree as it stands — and **neither deploys the backend** (owner's rule).

- **The order is still a rule, now the one running it keeps it.** A build that needs new rules or indexes goes after them: `make deploy-be-prod`, then `make release-ios-prod`. A build reaching a tester ahead of the rules it needs fails on a query nobody can fix from the App Store.
- **`set -e`, so each is a chain, not a list.** A failed config step is never followed by a build.

The TestFlight note is the `NOTE` variable (`make release-ios-prod NOTE="what changed"`), quoted so spaces never split it. `make release-prod` still runs both halves in the old order, for a note that still types it.

## The conventions

### `make` names a script; the script is the body

`flutter.mk` gives every target one line calling one script, so the body is always a file that can be linted and run directly — `bash packages/script-tools/flutter/<name>.sh` is the same command without `make`, and it is what CI calls. **A target longer than one line is the smell.** Every target has a `## description`; `make` prints it.

The root `Makefile` stays the include plus this app's targets, and an app target exists only for what no shared script can do (`pre-build`). A change every app needs goes to script-tools first, then the gitlink is bumped — never a fork of a shared script here.

### Settings come from `script-tools.properties`; this app needs none

Every script finds the project from `PROJECT_ROOT` (the Makefile exports it) or the nearest `pubspec.yaml`, and reads optional keys from `script-tools.properties` at the root. This app's flavours are the default `dev prod`, so the file does not exist; a third flavour adds it with `FLAVORS=…` and the same list in `sd_ios_app(flavors:)`.

### What the shared helpers guarantee

`packages/script-tools/flutter/lib/common.sh`, sourced by every script:

- **SDK resolution**, as `$FL` / `$DT`: `fvm flutter` when `.fvmrc` and `fvm` both exist, plain `flutter` otherwise. A shell alias does not exist inside a script, so without this a version-manager machine silently runs the wrong SDK — the only difference between a runner and a laptop.
- **A flavour outside `FLAVORS` is refused** with the usage line, before anything is read or written.
- **Fastlane always gets a UTF-8 locale** (`ensure_utf8_locale`): under `LANG=C` Ruby reads the shared Fastfile as ASCII and the lane dies on its first em dash.

## Two rules beyond any one command

**Edit the version and build number in `pubspec.yaml`, never pass `--build-name`/`--build-number`.** A build whose version exists nowhere in git is one the repo cannot account for. The release lane obeys this too: it *writes* the settled number into `pubspec.yaml` and commits it after the upload.

**Never run the app bare.** With no `--dart-define-from-file`, every `AppEnv` getter falls back to its default — a silently different app from the one CI builds. The **"Reseller Studio (dev)"** VS Code launch configuration passes it.

Running before Firebase exists: sign-in cannot succeed and **there is no bypass** (hard rule 1). The app opens as a guest and all of it works against the local store. **No fake backend exists to fall back on** — the switch that swapped one in is gone — so a dev run opens what a new seller sees. More → General → Seed demo data fills the workspace with the fake business.

## Releasing

Four fastlane lanes, imported from `packages/script-tools/flutter/fastlane/Fastfile` and run from `ios/`. `docs/rules/RELEASE.md` is the authority on what each does and why the order matters.

```bash
bundle exec fastlane preflight
```

- `preflight` (`make pre-build`) — everything a release needs but the build. Three minutes instead of twenty-eight. Then run `CI=true bundle exec fastlane preflight`: the CI half breaks most often.
- `upload flavor:prod` (`make upload-ipa-prod`) — the already-built IPA that did not reach TestFlight.
- `certificates` — **local only**; refuses to run on a runner. `force:true` regenerates the profiles after enabling a capability.
- `beta flavor:prod bump:true notes:"…"` — the real thing. **Normally run from the `Release` workflow, not by hand**: `workflow_dispatch` on GitHub, because a release is an act, not a side effect of a push.
