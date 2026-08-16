# Commands

Read this when running, building, generating or deploying.

**Melos is the task runner** (`melos.yaml`). Installed once per machine at the
version `pubspec.yaml` pins — `dart pub global activate melos 6.3.3`. The
global and local versions must match exactly. **Melos 6, not 7/8** — 7+
requires `resolution: workspace` inside `packages/system_design`, which would
stop that package resolving in BaroEase, which is not a workspace. That
portability is the whole reason the design system is a submodule.

- `melos run set-up` — **always wipes first**, then everything a clone needs:
  submodules, `pub get` for both packages, `gen-l10n`, `npm ci` in
  `functions/`, `pod install` on macOS. Idempotent. The wipe is unconditional
  on purpose: this is the one answer to "it built yesterday and not today".
  Don't reach for it when `melos run gen` would do.
  It also puts the submodule on `main` and fast-forwards it, so the design
  system is editable in place — **what you build is whatever is on that
  branch, not what the parent commit pins.**
- `melos run gen` — after editing any ARB file.
- `melos run analyze` — always-apply; see the root `CLAUDE.md` under
  "Definition of done". Not repeated here.
- `melos run test` — the Flutter test suite. **Exclude `*_tmp_test.dart`** —
  the scratch harnesses hang the runner by design, and `flutter test` with no
  arguments picks them up.
- `melos run preflight` — everything that must be true before a build is
  worth uploading: the Firebase and sign-in files, the bypass being off, the
  icon not being Flutter's, the iOS usage strings, and a clean analyze. Exits
  non-zero on an unmet blocker, so it is the check `RELEASE_ACTIONS.md` cannot
  be. Run it after the account setup, before `flutter build ipa`.
- `melos run deploy-firebase` — firestore rules, indexes, **storage rules**
  and functions. Confirms the project first; this reaches real users.
  **The script is the one place that list is written.** Never copy the
  `firebase deploy` line into a document: `storage` went missing from the
  script while `RELEASE_ACTIONS.md` still named it, and the bucket the app
  uploads photos and receipts to was the one nobody was deploying rules for.

**Every script body lives in `tool/`, and is POSIX `sh`.** The runner config
only names it. `[[ ]]`, `local` and `set -o pipefail` are syntax errors under
dash, and macOS will not catch it because its `/bin/sh` is bash wearing
another name — so a script that works here fails on CI. Check before
committing:

```bash
dash -n tool/<script>.sh
```

**The version and build number are edited in `pubspec.yaml`, never passed as
a `--build-name`/`--build-number` flag.** A build whose version exists nowhere
in git is one the repo cannot account for afterwards.

Running the app before Firebase exists — sign-in cannot succeed yet, so
`env/dev.json` carries `BYPASS_AUTH` to get past it:

```sh
melos run run
```

**Mock data does not come on with it** — owner's rule. `MOCK_DATA_DEFAULT` is
off unless the env file sets it, so a dev run opens the app a new seller would
see: five tabs with nothing in them. Turn the fake business on in
More → Settings when you want it, or set the key.

VS Code users: the **"Seller OS (dev)"** launch configuration does the same.
**Never run the app bare** — with no `--dart-define-from-file` every `AppEnv`
getter falls back to its default, which is a silently different app from the
one CI builds.
