# The shape of a release

What runs, in what order, and where each thing can fail. The *rules* behind
every step are in `docs/rules/RELEASE.md` and are not repeated here.

## A run

```text
workflow_dispatch(flavor, bump, notes)
        │
        ├── checkout + submodule → design system's main
        ├── git identity → github-actions[bot]
        ├── Xcode, Flutter (from .fvmrc), Ruby 3.3 → bundle install
        │
        ├── env/<flavor>.json          ← ENV_<FLAVOR>_JSON secret, verbatim
        ├── GoogleService-Info.plist   ← base64 secret, then plutil -lint
        ├── Info.plist URL scheme      ← derived from the plist above
        ├── pub get (app + design system), gen-l10n
        │
        └── fastlane beta
              1. verify_flavor_config      ~5s    ← the last catch
              2. build number              ~30s   ← TestFlight says what is taken
              3. setup_ci → match → entitlements → manual signing → ExportOptions
              4. tool/build-ipa.sh         ~20m   ← the only archive
              5. upload_to_testflight      ~2m
              6. dSYMs                     best effort
              7. commit the build number
        │
        ├── git push          (only when bump)
        └── upload the .ipa as an artifact
```

## Where a run dies, and what it means

| Step | Failure | What it actually is |
|---|---|---|
| 1 | `GoogleService-Info.plist is project X, but prod is Y` | The two config halves disagree — the whole reason this step exists. |
| 1 | `no .firebaserc` | Nothing says which Firebase project a flavour is. See `RELEASE_ACTIONS.md`. |
| 2 | `build … is already on TestFlight` | Re-run with `bump: true`. |
| 3 | `Duplicate header: "Authorization"` | Both match auth secrets are set in Actions; one is empty and must leave `ENV`. |
| 3 | `profile doesn't include the … entitlement` | A capability was enabled after the profile was minted. `bundle exec fastlane certificates force:true`, from a Mac. |
| 4 | `No Firebase App '[DEFAULT]' has been created`, at runtime | Something archived without `--dart-define-from-file`. Nothing but `tool/build-ipa.sh` may build. |
| 4 | `codesign` prompting during `exportArchive` | `setup_ci` ran on a laptop. It is gated on `GITHUB_ACTIONS`, not on `is_ci`. |

## Rehearsing without burning macOS minutes

```bash
bundle exec fastlane preflight
```

Then the half most likely to break, which is the CI half:

```bash
CI=true bundle exec fastlane preflight
```

Both from `ios/`. Three minutes each, and between them they exercise every
credential a real run needs except the build itself.
