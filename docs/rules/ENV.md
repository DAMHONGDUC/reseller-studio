# `env/` — build-time configuration

Read this when adding or changing a build-time key, or touching
`lib/core/config/app_env.dart` or `lib/core/config/dev_flags.dart`.

One JSON file per flavour, passed with `--dart-define-from-file`, read through
**`lib/core/config/app_env.dart` — the only file allowed to name an env key.**
A `String.fromEnvironment('FIREBASE_…')` in a feature is a magic string nobody
can audit and a typo that silently returns `''`.

```sh
melos run run            # env/dev.json
melos run run -- prod    # env/prod.json
```

- `env/*.example.json` is checked in and is the key list; `env/dev.json` and
  `env/prod.json` are gitignored. `melos run set-up` copies the templates when
  the real files are missing and **never overwrites** an existing one.
- **Adding a key means adding it to both templates and to `AppEnv`.**
  `test/core/config/app_env_test.dart` fails if the two flavours' key sets
  diverge — a key in one and not the other is a build that works locally and
  fails in CI.
- **Every getter has a default**, so a build with no `--dart-define-from-file`
  still compiles. That is what keeps `melos run test` working without a
  flavour.

**`REVENUECAT_IOS_API_KEY` and `REVENUECAT_ANDROID_API_KEY` are public SDK
keys and belong here**, the same category as the Firebase ids: they identify
the app to RevenueCat and are protected by the store's receipt verification,
not by being unreadable. The **webhook auth header is the secret half** and
must never appear in `env/` — it is read only by the Cloud Function that
mirrors entitlement into Firestore (hard rule 10). An empty key is a
supported state: `AppEnv.hasBillingConfig` is false, billing is skipped at
bootstrap, and every seller reads as Free.

The two secret-handling rules for `env/` — that nothing in it is secret, and
that `AppEnv` states the request while `DevFlags` states the permission — are
always-apply and live in the root `CLAUDE.md` under "Configuration and
secrets". They are not repeated here.

**Design tokens and domain policy deliberately stay out of `env/`** —
`AppColors`, `SdRadiusV3`, `PurchaseEvaluation.defaultTargetRoi`,
`Marketplace.estimatedFeeRate`. They do not vary per build, and they must be
readable from a unit test without a build flag. The stale threshold especially:
it is per-workspace data in Firestore (`Workspace.staleThresholdDays`), so
freezing it into a build file would contradict `docs/DATA_MODEL.md`.
`env/README.md` has the full list and the reasoning.
