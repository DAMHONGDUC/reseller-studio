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

**There is a second half to a build's configuration, and nothing ties it to
this one.** `env/<flavour>.json` is the Dart-visible half; the native SDK half
is `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`
and the sign-in URL scheme in `ios/Runner/Info.plist`. A prod env file beside a
dev plist compiles, installs, launches and writes into the wrong Firestore.
`melos run prepare-env-<flavour>` is what keeps them in step and
`env_assets/` is where your copies live — **`docs/rules/RELEASE.md` is the
authority on both**, and this file does not repeat it.

- `env/*.example.json` is checked in and is the key list; `env/dev.json` and
  `env/prod.json` are gitignored. `melos run set-up` copies the templates when
  the real files are missing and **never overwrites** an existing one.
- **Adding a key means adding it to both templates and to `AppEnv`.**
  `test/core/config/app_env_test.dart` fails if the two flavours' key sets
  diverge — a key in one and not the other is a build that works locally and
  fails in CI.
- **The templates carry exactly the keys `AppEnv` reads — no more, no less.**
  Owner's rule. A key nothing reads is an afternoon somebody spends filling in
  a value that changes nothing, and a key `AppEnv` reads and the template omits
  defaults silently to `''` — which is how `REVENUECAT_*` sat missing from both
  templates while `hasBillingConfig` answered false. The same test pins the
  list, by hand, because Dart cannot reflect over `AppEnv`.
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

**The Firebase keys are down to two, and neither configures the SDK.**
`Firebase.initializeApp` is called with no options, so the api keys, the sender
id and the buckets are read from `GoogleService-Info.plist` and
`google-services.json` — carrying them in `env/` as well was one fact written
twice, and the copy nothing read. What stayed:

- `FIREBASE_PROJECT_ID`, because `AppEnv.hasFirebaseConfig` is how bootstrap
  tells "no backend configured" apart from "configured and unreachable";
- `FIREBASE_IOS_APP_ID`, because `verify_flavor_config` in the beta lane
  cross-checks it against the installed plist — the two are the same fact
  written twice on purpose, and disagreeing means Crashlytics symbols land in
  another project's dashboard.

**`APPLE_SIGN_IN_SERVICE_ID` is not an env key.** Sign in with Apple goes
through `FirebaseAuth.signInWithProvider`, which needs nothing in the binary;
the Services ID is configured in the Firebase console. See
`RELEASE_ACTIONS.md`.

**Theme is a preference, not a build flag.** `ThemeModeController` reads
`PrefsKeyConstant.themeMode` and is device-local on purpose: a seller on a
bright shop floor and the same seller packing at 1am want opposite answers on
two devices, so syncing it to the account would make one of them wrong. The
same reasoning puts the intro flag in preferences.

**`MOCK_DATA_DEFAULT` is off, and no other flag turns it on** — owner's rule.
It used to be ORed with the auth bypass in `DevFlags`, so any dev run opened
onto a fake business. It no longer is, and the two are independent:

- A dev run now opens on **what a new seller sees** — five tabs with nothing in
  them (hard rule 1). That is a real shipped state, and a default that replaced
  it with seeded data meant nobody was looking at it.
- Turning it on is deliberate: `"MOCK_DATA_DEFAULT": true` in the env file, or
  the switch in More → Settings, which is the path it is designed to be reached
  by — the stored preference is what `DataModeController` reads.
- The release guard is unchanged and is the part that matters:
  `DevFlags.mockDataDefault` is still ANDed with `!kReleaseMode`, and
  `DataModeController.build` refuses `mock` in release whatever is stored.
  `test/core/config/app_env_test.dart` holds both.

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

**The privacy policy and terms URLs are env keys, not constants** — owner's
rule. `PRIVACY_POLICY_URL` and `TERMS_OF_SERVICE_URL` are read through
`AppEnv`, the same as every other build-time value, because they differ per
flavour: a staging build points at a draft nobody has had a lawyer read, and
a hardcoded production URL in a `final class Constant` is one that ships to
staging too.

- **Both are on `AppEnv.missingReleaseKeys`.** Apple's guideline 3.1.2 wants
  a functional link to each from inside the binary, so a release build with
  either one empty is not shippable and the bootstrap log says so by name.
- **An empty value renders nothing at all** — no row, no dead link. A link to
  a 404 is a worse review outcome than an app with no link, because the
  reviewer clicks it.
- They are not secret and belong here for the same reason the Firebase ids
  do: they are public addresses, not credentials.
