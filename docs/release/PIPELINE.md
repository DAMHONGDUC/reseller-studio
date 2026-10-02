# Release pipeline

## Flow

| Order | Stage | Output |
|---|---|---|
| 1 | Checkout app and design-system submodule | Source tree |
| 2 | Install pinned Flutter, Ruby and dependencies | Build tools |
| 3 | Restore flavor configuration from Actions secrets | Env JSON and Firebase plist |
| 4 | Generate the iOS URL scheme and localization | Prepared source |
| 5 | Verify flavor/Firebase pairing | Safe release configuration |
| 6 | Resolve TestFlight build number | Unique build |
| 7 | Load signing through Match | Certificate and profile |
| 8 | Build only through `packages/script-tools/flutter/build_ipa.sh` | IPA and dSYMs |
| 9 | Upload to TestFlight | Processing build |
| 10 | Commit/push build number when requested | Traceable version |
| 11 | Upload the IPA workflow artifact | Downloadable artifact |

## Failure lookup

| Failure | Meaning | Fix |
|---|---|---|
| Firebase project mismatch | Flavor JSON and plist belong to different projects | Replace the incorrect flavor asset |
| Missing `.firebaserc` | Flavor has no project alias | Add `dev`/`prod` aliases |
| Build already exists | TestFlight has the same build number | Re-run with build bump enabled |
| Duplicate Authorization header | Multiple Match auth methods are set | Keep one authorization secret |
| Profile lacks entitlement | Capability changed after profile creation | Regenerate the profile |
| Firebase default app missing at runtime | Archive skipped build-time configuration | Build only through the repository script |
| Codesign prompts in CI | CI signing setup did not run | Check the GitHub Actions environment and Match values |

## Rehearsal

Run both from `ios/`:

```sh
bundle exec fastlane preflight
CI=true bundle exec fastlane preflight
```

The first checks the local path; the second checks CI-only behavior without
uploading a build.
