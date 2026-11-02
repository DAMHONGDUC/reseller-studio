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
| Design system | `packages/flutter-system-design-kit` v3 submodule |
| Launch markets | United States and United Kingdom |

## Setup

Needs [FVM](https://fvm.app) and `make`. Commands come from the `packages/script-tools` submodule; `make` lists them.

```sh
git submodule update --init
fvm install
make setup
```

Firebase and store accounts are not in the repo. Read [`docs/release/RELEASE_ACTIONS.md`](docs/release/RELEASE_ACTIONS.md) before connecting a real backend.

## Daily commands

| Task | Command |
|---|---|
| Run the app | `make run-dev` |
| Generate localization | `make gen` |
| Analyze | `make analyze` |
| Test one file | `make test TEST=<path>` |
| Build checks | `make pre-build` |

Every command in detail: [`docs/rules/COMMANDS.md`](docs/rules/COMMANDS.md).

### Combo commands

Dev first, then prod. `&&` stops at the first step that fails.

Backend and iOS:

```sh
make deploy-be-dev && make release-ios-dev && make deploy-be-prod && make release-ios-prod
```

Android:

```sh
make release-android-dev && make release-android-prod
```

## App identifiers

| Platform | Identifier | Source |
|---|---|---|
| iOS | `app.dd.reseller.studio` | `ios/Runner.xcodeproj/project.pbxproj` |
| Android | `com.dd.reseller.studio` | `android/app/build.gradle.kts` |

## Documentation

| Need | Read |
|---|---|
| Documentation index | [`docs/README.md`](docs/README.md) |
| Product authority | [`docs/plans/SELLER_OS_FINAL_MASTER_PLAN.md`](docs/plans/SELLER_OS_FINAL_MASTER_PLAN.md) |
| Engineering rules | [`AGENTS.md`](AGENTS.md) |
| Stored data contract | [`docs/architecture/DATA_MODEL.md`](docs/architecture/DATA_MODEL.md) |
| Built and pending work | [`docs/status/DONE_WORK.md`](docs/status/DONE_WORK.md), [`docs/status/REMAINING_WORK.md`](docs/status/REMAINING_WORK.md) |
| Release checklist | [`docs/release/RELEASE_ACTIONS.md`](docs/release/RELEASE_ACTIONS.md) |

## Release

Three parts; each deploy and release installs the flavor's config first, by itself.

```sh
make deploy-be-prod
```

```sh
make release-ios-prod NOTE="what changed"
```

```sh
make release-android-prod
```

`deploy-be` ships the backend (Firebase rules, indexes, functions), `release-ios` the IPA to TestFlight, `release-android` the APK and AAB into `Release/`. A build that needs new rules goes after `deploy-be`. Use `dev` for the dev environment.

Never archive from Xcode: only the release lane supplies the build-time config Firebase needs.