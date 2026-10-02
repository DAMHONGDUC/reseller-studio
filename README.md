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

Requirements: [FVM](https://fvm.app) and `make`. Commands come from the
`packages/script-tools` submodule; `make` lists them.

```sh
git submodule update --init
fvm install
make set-up
```

Firebase and store accounts are not included in the repository. See
[`RELEASE_ACTIONS.md`](RELEASE_ACTIONS.md) before connecting a real backend.

## Daily commands

| Task | Command |
|---|---|
| Generate localization | `make gen` |
| Analyze | `make analyze` |
| Test one file | `make test TEST=<path>` |
| Build checks | `make pre-build` |

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
make release-dev
```

```sh
make release-prod
```

Config, Firebase and TestFlight in that order, and it stops at the first
failure. Add a TestFlight note with `make release-prod NOTE="what changed"`.

Do not archive from Xcode. The release lane supplies the build-time
configuration required by Firebase.
