# Reseller Studio

Seller operations for the full resale lifecycle:

```text
SOURCE → PURCHASE → INVENTORY → LIST → SELL → SHIP → PROFIT → ANALYZE
```

| Area | Choice |
|---|---|
| App | Flutter 3.44.5 / Dart 3.12.2 |
| State | Riverpod |
| Backend | Firebase |
| Navigation | `go_router`, five-tab shell |
| Design system | `packages/system_design` v3 submodule |
| Launch markets | United States and United Kingdom |

## Setup

Requirements: [FVM](https://fvm.app) and Melos 6.3.3.

```sh
dart pub global activate melos 6.3.3
fvm install
melos run set-up
```

Firebase and store accounts are not included in the repository. See
[`RELEASE_ACTIONS.md`](RELEASE_ACTIONS.md) before connecting a real backend.

## Daily commands

| Task | Command |
|---|---|
| Run | `melos run run` |
| Generate localization | `melos run gen` |
| Analyze | `melos run analyze` |
| Test | `melos run test` |
| Test Firestore rules | `melos run test-rules` |
| Release checks | `melos run preflight` |

Full command behavior: [`docs/rules/COMMANDS.md`](docs/rules/COMMANDS.md).

## App identifiers

| Platform | Identifier | Source |
|---|---|---|
| iOS | `app.dd.reseller.studio` | `ios/Runner.xcodeproj/project.pbxproj` |
| Android | `com.dd.reseller.studio` | `android/app/build.gradle.kts` |

## Documentation

| Need | Read |
|---|---|
| Documentation index | [`docs/README.md`](docs/README.md) |
| Product authority | [`SELLER_OS_FINAL_MASTER_PLAN.md`](SELLER_OS_FINAL_MASTER_PLAN.md) |
| Engineering rules | [`AGENTS.md`](AGENTS.md) |
| Stored data contract | [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) |
| Built and pending work | [`docs/DONE_WORK.md`](docs/DONE_WORK.md), [`docs/REMAINING_WORK.md`](docs/REMAINING_WORK.md) |
| Release checklist | [`RELEASE_ACTIONS.md`](RELEASE_ACTIONS.md) |

## Release

```sh
melos run prepare-env-prod
cd ios && bundle exec fastlane beta flavor:prod bump:true notes:"release notes"
```

Do not archive from Xcode. The release lane supplies the build-time
configuration required by Firebase.
