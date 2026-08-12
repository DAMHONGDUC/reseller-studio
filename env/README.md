# `env/` — build-time configuration

One JSON file per flavour, passed to the build with
`--dart-define-from-file`. Every value becomes a compile-time constant read
through `lib/core/config/app_env.dart`, which is the only file that names an
env key.

```sh
fvm flutter run --dart-define-from-file=env/dev.json
```

## What is in here

| File | Checked in | What it is |
| --- | --- | --- |
| `dev.example.json` | yes | The template. The list of keys, with placeholders. |
| `prod.example.json` | yes | Same, for release builds. |
| `dev.json` | **no** | The real one. `melos run set-up` copies it from the example. |
| `prod.json` | **no** | The real one. |

`.gitignore` carries `env/*.json` and `!env/*.example.json`, so a real file
can never be committed by accident and the templates always can.

**Adding a key means adding it to both examples and to `AppEnv`.** A key that
exists in one flavour's file and not the other is a build that works on a
developer's machine and fails in CI.

## What must never go in here

> **Everything in these files is compiled into the app binary and is trivially
> extractable.** `--dart-define-from-file` is not a secret store — it is a
> way to vary constants per build. Anyone with the `.ipa` can read every value
> in it in a couple of minutes.

So, per `CLAUDE.md` hard rule 10:

- **No marketplace OAuth client secrets.** eBay, Etsy and Poshmark secrets
  live in Secret Manager and are only ever read by a Cloud Function.
- **No service-account keys, no private keys, no admin tokens.**
- **No database credentials.**

Firebase's `apiKey` and app ids *are* fine here, and that is not an
inconsistency: they are public identifiers, not credentials. What protects
Firestore is `firestore.rules` and Auth, not the obscurity of the key.

The rule of thumb: if leaking the value would let someone act as your
backend, it does not belong in this folder.

## What is deliberately NOT here

These are constants, but they are not *environment* constants, and moving
them here would make each one worse:

- **Design tokens** — `AppColors`, `SdSpacingConstant`, `SdRadiusV3`,
  `SdMotionV3`. They do not vary per build, and the design system's contract
  is that they are Dart values a widget can read from a theme.
- **Domain policy** — `PurchaseEvaluation.defaultTargetRoi`,
  `StaleInventoryPolicy.defaultThreshold`, `Marketplace.estimatedFeeRate`.
  These are product rules that belong with the logic they govern, and they
  need to be readable from a unit test without a build flag.
- **The stale threshold in particular is per-workspace data in Firestore**
  (`Workspace.staleThresholdDays`). Freezing it into a build file would
  contradict the data model — see `docs/DATA_MODEL.md`.
- **Route paths** — `AppRoutes`. Changing one is a code change, not a
  configuration change.
