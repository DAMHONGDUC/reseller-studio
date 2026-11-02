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

```sh
make release-dev
```

```sh
make release-prod
```

Runs config, Firebase, then TestFlight, and stops at the first failure. Add a TestFlight note with `make release-prod NOTE="what changed"`.

Never archive from Xcode: only the release lane supplies the build-time config Firebase needs.
