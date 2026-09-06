# `env/` — build-time configuration

Read this when adding or changing a build-time key, or touching
`lib/core/config/app_env.dart` or `lib/core/config/dev_flags.dart`.

One JSON file per flavour, passed with `--dart-define-from-file`, read through
**`lib/core/config/app_env.dart` — the only file allowed to name an env key.**
A `String.fromEnvironment('FIREBASE_…')` in a feature is a magic string nobody
can audit and a typo that silently returns `''`.

```sh
fvm flutter run --dart-define-from-file=env/dev.json
fvm flutter run --dart-define-from-file=env/prod.json
```

**There is a second half to a build's configuration, and nothing ties it to
this one.** `env/<flavour>.json` is the Dart-visible half; the native SDK half
is `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`
and the sign-in URL scheme in `ios/Runner/Info.plist`. A prod env file beside a
dev plist compiles, installs, launches and writes into the wrong Firestore.
`melos run prepare-env-<flavour>` is what keeps them in step and
`env_assets/` is where your copies live — **`docs/rules/RELEASE.md` is the
authority on both**, and this file does not repeat it.

- **`env/env.example.json` is the one checked-in template and it is the key
  list**; `env/dev.json` and `env/prod.json` are gitignored. `melos run set-up`
  copies it into each missing flavour file and **never overwrites** an existing
  one. One template rather than one per flavour: the two only ever differed by
  the values a developer fills in, so the key list lived twice and went stale
  in one copy — which is exactly how the RevenueCat keys ended up misspelled in
  the template while `AppEnv` read the right names.
- **It is also the one file under `env/` a session may read or write** — root
  `CLAUDE.md` carries that rule and the reason.
- **Adding a key means adding it to the template and to `AppEnv`.**
  `test/core/config/app_env_test.dart` pins the two against each other and
  fails loudly when they disagree.
- **The templates carry exactly the keys `AppEnv` reads — no more, no less.**
  Owner's rule. A key nothing reads is an afternoon somebody spends filling in
  a value that changes nothing, and a key `AppEnv` reads and the template omits
  defaults silently to `''` — which is how `REVENUECAT_*` sat missing from both
  templates while `hasBillingConfig` answered false. The same test pins the
  list, by hand, because Dart cannot reflect over `AppEnv`.
- **Every getter has a default**, so a build with no `--dart-define-from-file`
  still compiles. That is what keeps `melos run test` working without a
  flavour.

**A key that belongs to one platform ends in `_IOS` or `_ANDROID`, and the
suffix goes last.** Owner's rule. `REVENUECAT_API_KEY_IOS`, never
`REVENUECAT_IOS_API_KEY`. The platform is the last thing that varies, so the
two stores' keys land next to each other in every file that lists them and a
missing half reads as a gap rather than as two unrelated lines — which is
exactly the shape `hasBillingConfig` answers questions about.

- A key no platform owns carries no suffix: `FIREBASE_PROJECT_ID`,
  `GOOGLE_SIGN_IN_SERVER_CLIENT_ID`, `FUNCTIONS_REGION`.
- **The `AppEnv` getter mirrors the key exactly** — `REVENUECAT_API_KEY_IOS`
  is `revenueCatApiKeyIos` — so a grep for either name finds both. That is
  what stops a rename landing in the JSON and not in the Dart, where the
  getter would silently start returning `''`.
- The rule reaches every name for the same value, not just the JSON one: the
  Fastfile's `ENV[...]`, the workflow's `env:` block and the Actions secret it
  reads. A secret whose name disagrees with the variable it fills is one
  nobody can grep for.

**`REVENUECAT_API_KEY_IOS` and `REVENUECAT_API_KEY_ANDROID` are public SDK
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
- `FIREBASE_APP_ID_IOS`, because `verify_flavor_config` in the beta lane
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

**`MOCK_DATA_DEFAULT` is gone, and no flag replaces it** — owner's rule. The
app has one backend. A dev run opens on **what a new seller sees** — five tabs
with nothing in them (hard rule 1) — and what puts rows in them is
More → Settings → Developer → Seed demo data, which writes real documents
into the open workspace.

- **There is no build-time way to fake a business any more.** The switch was
  persisted and dev mode is granted by email in `app_config`, so a fake
  business was two booleans away from being shown to a seller as if it were
  theirs. Deleting the mode deleted the failure — see
  `lib/features/seed_data/CLAUDE.md`.
- `VERBOSE_LOGGING` is the only development switch left in the template, and
  the release guard on it is unchanged: `DevFlags` ANDs it with
  `!kReleaseMode`. `test/core/config/app_env_test.dart` holds that the
  template and `AppEnv` still name exactly the same keys.

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

## Switching flavour on one device wipes it first

Two flavours that share a bundle id share a sandbox, so installing one over
the other leaves the new binary reading the old one's signed-in session,
preferences and cached Firestore documents — a dev account writing into the
real project, or the reverse. Owner's rule: **an environment change is treated
as a fresh install.**

- **`SdFreshInstall` is the whole check, and it is one class** (design system,
  `core/common/`, pure Dart). It compares a stamp on the device against
  `AppEnv.flavor.name` and wipes when they differ. It was three classes — a
  reinstall guard, an environment guard and a widget — until the owner merged
  them: both were asking whether the state on this device belongs to the app
  now running. `packages/system_design/WIDGET_RULES.md` holds the decision
  table.
- **`SplashScreen` runs it, and it is deliberately not a bootstrap step.**
  Owner's rule: the seller should see the splash loading *while* the wipe
  happens. Before `runApp` the only thing on screen is the platform launch
  image, so a wipe that takes a second looks like a hang; here the app is up
  and themed and shows the same screen a returning seller already sees while
  auth resolves. One screen covers both reasons the app is not ready yet.
- **That is why the screen takes a `child`.** It is mounted twice: once around
  the whole app, where it holds the child back until the check returns, and
  once as the router's `/splash` route with no child, already inside the tree
  the first one gated.
- **The outer one sits above `ForceUpdateGate`, and that ordering is the
  point.** `clearPersistence` throws `failed-precondition` once the Firestore
  client is running, and `ForceUpdateGate`'s `app_config` read is what starts
  it on the first frame — so nothing below may build until the check returns.
  Letting the first screen build alongside would also race the sign-out against
  the screens reading that session.
  `test/core/widgets/splash_screen_test.dart` pins all three states.
- **`AppFreshInstall` is the half that touches the device**, and it is an
  `SdFreshInstallHost`: `isBackendReady`, `signOut` (Google then Firebase), and
  `clearCache` (`terminate` then `clearPersistence`). Nothing else — the order
  of a wipe and the names of its steps are `SdFreshInstall`'s. Emptying
  preferences is appended there and takes the onboarding flag with it, because
  that is what a fresh install is.
- **It passes `PrefsKeyConstant.lastEnv` as the stamp key**, which is what
  installs in the wild already hold — so the first launch after the merge reads
  a valid stamp and is a normal launch, with no migration branch and no wipe.
- **There is no device-scoped store here.** Nothing this app writes outlives a
  delete, so a reinstall is already a first install and that row cannot fire.
  That is the difference from the sibling app, whose iOS Keychain kept a
  session across one.
- **The stamp is written after the wipe, never before** — the wipe clears the
  store it lives in, so a wipe that halted is repeated on the next launch
  rather than skipped.

## The build tag is drawn from the flavour, never from `kDebugMode`

`SdDevWrapper` stamps `DEV · 1.0.0 (8)` down the right edge of everything
the app draws, hung from the top-right corner — env name from
`AppEnv.flavor.name`, version and build number from `packageInfoProvider`.
It wraps `MaterialApp` rather than sitting inside one, so it brings its own
`Directionality` and hardcodes its two colours: a tag drawn from the app's
palette disappears the moment that palette is the bug.

`visible: !AppEnv.flavor.isProd`. A TestFlight build of the dev flavour is a
release binary and is exactly the one nobody can otherwise tell apart from the
real app in a bug report.
