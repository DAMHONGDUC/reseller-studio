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
- `melos run deploy-firebase` — rules, indexes and functions. Confirms the
  project first; this reaches real users.

Running the app before Firebase exists — the app is otherwise stuck on a
login screen that cannot succeed (hard rule 1). `env/dev.json` carries
`BYPASS_AUTH` and `MOCK_DATA_DEFAULT`, so this is all it takes:

```sh
melos run run
```

VS Code users: the **"Seller OS (dev)"** launch configuration does the same.
**Never run the app bare** — with no `--dart-define-from-file` every `AppEnv`
getter falls back to its default, which is a silently different app from the
one CI builds.
