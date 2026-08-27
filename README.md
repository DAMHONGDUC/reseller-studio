# Reseller Studio

A seller operating system for resellers — not an inventory tracker.

```text
SOURCE → PURCHASE → INVENTORY → LIST → SELL → SHIP → PROFIT → ANALYZE → SOURCE BETTER
```

Flutter · Firebase · Riverpod · design system v3.

## Getting started

Requires [fvm](https://fvm.app) and Melos 6.3.3:

```sh
dart pub global activate melos 6.3.3
fvm install                 # installs Flutter 3.44.5, per .fvmrc
melos run set-up            # submodules, deps, l10n, functions, pods
```

Then, before the app can reach a backend, run `flutterfire configure` — there
is no Firebase project checked in and none can be. See **Pending setup** in
`CLAUDE.md`.

`melos run analyze` must pass with zero findings before any change is done.

## App identifiers

What `flutterfire configure`, App Store Connect and the Play Console all ask
for. **The two platforms differ — iOS is `app.`, Android is `com.`** — so
register each store listing against its own row rather than assuming one id
covers both. The right-hand column owns the value; change it there, never here.

| | | |
| --- | --- | --- |
| iOS bundle id | `app.dd.reseller.studio` | `ios/Runner.xcodeproj/project.pbxproj` |
| Android applicationId | `com.dd.reseller.studio` | `android/app/build.gradle.kts` |

The iOS test target is `app.dd.reseller.studio.RunnerTests`. The Kotlin package
under `android/app/src/main/kotlin/` tracks the applicationId and moves with it.

## Commands

Names only. **`docs/rules/COMMANDS.md` is the one place they are explained** —
what each promises, and why the set is shaped this way.

| | |
| --- | --- |
| Setting up | `set-up`, `deep-set-up` |
| Config | `prepare-env-dev`, `prepare-env-prod` |
| Developing | `run`, `gen` |
| Gates | `analyze`, `test`, `test-rules`, `preflight` |
| Shipping | `build-ipa-dev`, `build-ipa-prod`, `deploy-firebase-dev`, `deploy-firebase-prod` |

## Where things are

| | |
| --- | --- |
| Product spec, the authority | `SELLER_OS_FINAL_MASTER_PLAN.md` |
| Engineering rules | `CLAUDE.md` |
| Firestore collections and field contracts | `docs/DATA_MODEL.md` |
| What may go in the design system | `packages/system_design/WIDGET_RULES.md` |

## The design system is a submodule

`packages/system_design` is [its own repo](https://github.com/DAMHONGDUC/system_design),
shared with BaroEase. It carries two widget generations: `v2/` renders
BaroEase, `v3/` renders Reseller Studio. **Never modify `v2/`, and never import it
from `v3/`.**
