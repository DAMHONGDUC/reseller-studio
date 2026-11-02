# `env/` — build-time configuration

Read when adding or changing a build-time key, or touching `lib/core/config/app_env.dart` or `lib/core/config/dev_flags.dart`.

One JSON file per flavour, passed with `--dart-define-from-file`, read through **`lib/core/config/app_env.dart` — the only file allowed to name an env key.** A `String.fromEnvironment('FIREBASE_…')` in a feature is a magic string nobody can audit, and a typo that silently returns `''`.

```sh
fvm flutter run --dart-define-from-file=env/dev.json
fvm flutter run --dart-define-from-file=env/prod.json
```

**A build's config has a second half, and nothing ties it to this one.** `env/<flavour>.json` is the Dart-visible half; the native SDK half is `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json` and the sign-in URL scheme in `ios/Runner/Info.plist`. A prod env file beside a dev plist compiles, installs, launches and writes into the wrong Firestore. `make env-<flavour>` keeps them in step and `env_assets/` holds your copies — **`docs/rules/RELEASE.md` is the authority on both**; not repeated here.

- **`env/env.example.json` is the one checked-in template, and it is the key list**; `env/dev.json` and `env/prod.json` are gitignored. `make setup` copies it into each missing flavour file and **never overwrites** one. One template, not one per flavour: the two only ever differed by filled-in values, so the key list lived twice and went stale in one copy — how the RevenueCat keys ended up misspelled in the template while `AppEnv` read the right names.
- **It also tells the build there is config to attach.** `packages/script-tools/flutter/build_ipa.sh` passes `--dart-define-from-file=env/<flavour>.json` only when a template exists — the shared tooling serves apps that compile every value in, and the template says this app is not one. **Deleting or renaming it fails no build; it ships an IPA with empty config** that dies at launch on `[core/no-app]`, naming nothing about the missing flag. Both names are accepted, `env/<flavour>.example.json` first, this one after.
- **It is the one file under `env/` a session may read or write** — root `CLAUDE.md` has the rule and the reason.
- **Adding a key means adding it to the template and to `AppEnv`.** `test/core/config/app_env_test.dart` pins one against the other and fails loudly when they disagree.
- **The templates carry exactly the keys `AppEnv` reads — no more, no less.** Owner's rule. A key nothing reads costs someone an afternoon filling a value that changes nothing; a key `AppEnv` reads but the template omits silently defaults to `''` — how `REVENUECAT_*` sat missing from both templates while `hasBillingConfig` answered false. The same test pins the list by hand, because Dart cannot reflect over `AppEnv`.
- **Every getter has a default**, so a build with no `--dart-define-from-file` still compiles. That keeps `make test` working without a flavour.

**So at startup the app checks the two halves against each other and refuses to open when they disagree.** The Firebase step compares `AppEnv.firebaseProjectId` with `Firebase.app().options.projectId` — the project the native SDK actually came up on — and throws `FlavorConfigMismatch` when they differ. `StartupFailurePolicy` treats it as fatal: the seller gets `StartupErrorScreen`, not five tabs onto the wrong Firestore.

- **Only a mismatch, never a missing half.** An empty project id means `hasFirebaseConfig` is false — an offline build, a supported state; a plist the SDK could not reach is a seller with no signal. Only two filled-in halves naming different projects are the bug.
- **Checked before Crashlytics attaches**, so a build pointed at the wrong project does not send its crashes there too.
- **The detail row names both projects and the command to run, in debug only** (hard rule 6). This only happens on a developer's machine — exactly where the sentence is worth reading.
- **The release lane asks the same question earlier, from the files** (`sd_verify_flavor_config`, against `.firebaserc`). Neither replaces the other: the lane catches it before a build exists; this catches the `fvm flutter run` that skipped the lane.

**A platform-specific key ends in `_IOS` or `_ANDROID`, suffix last.** Owner's rule. `REVENUECAT_API_KEY_IOS`, never `REVENUECAT_IOS_API_KEY`. The platform varies last, so the two stores' keys sit together in every file listing them, and a missing half reads as a gap, not two unrelated lines — the shape `hasBillingConfig` answers about.

- A key no platform owns has no suffix: `FIREBASE_PROJECT_ID`, `GOOGLE_SIGN_IN_SERVER_CLIENT_ID`, `FUNCTIONS_REGION`.
- **The `AppEnv` getter mirrors the key exactly** — `REVENUECAT_API_KEY_IOS` is `revenueCatApiKeyIos` — so grepping either finds both. That stops a rename landing in the JSON but not the Dart, where the getter would silently return `''`.
- The rule covers every name for the value, not just the JSON one: the Fastfile's `ENV[...]`, the workflow's `env:` block, the Actions secret it reads. A secret named unlike the variable it fills is one nobody can grep for.

**`REVENUECAT_API_KEY_IOS` and `REVENUECAT_API_KEY_ANDROID` are public SDK keys and belong here**, like the Firebase ids: they identify the app to RevenueCat and are protected by the store's receipt verification, not by being unreadable. The **webhook auth header is the secret half** and never appears in `env/` — only the Cloud Function mirroring entitlement into Firestore reads it (hard rule 10). An empty key is supported: `AppEnv.hasBillingConfig` is false, bootstrap skips billing, every seller reads as Free.

**Two Firebase keys remain, and neither configures the SDK.** `Firebase.initializeApp` takes no options, so api keys, sender id and buckets come from `GoogleService-Info.plist` and `google-services.json` — carrying them in `env/` too was one fact written twice, the copy nothing read. What stayed:

- `FIREBASE_PROJECT_ID`: `AppEnv.hasFirebaseConfig` uses it to tell "no backend configured" from "configured and unreachable";
- `FIREBASE_APP_ID_IOS`: `verify_flavor_config` in the beta lane checks it against the installed plist — the same fact twice, on purpose; if they disagree, Crashlytics symbols land in another project's dashboard.

**`APPLE_SIGN_IN_SERVICE_ID` is not an env key.** Sign in with Apple needs nothing in the binary — on iOS the app shows Apple's sheet and hands the token to Firebase; elsewhere `FirebaseAuth.signInWithProvider` runs the web flow — and the Services ID lives in the Firebase console. See `docs/release/RELEASE_ACTIONS.md`.

**Theme is a preference, not a build flag.** `ThemeModeController` reads `PrefsKeyConstant.themeMode`, device-local on purpose: a seller on a bright shop floor and the same seller packing at 1am want opposite answers on two devices, so syncing it to the account makes one wrong. The intro flag lives in preferences for the same reason.

**`MOCK_DATA_DEFAULT` is gone, and no flag replaces it** — owner's rule. The app has one backend. A dev run opens on **what a new seller sees** — five empty tabs (hard rule 1) — and More → General → Seed demo data fills them with real documents in the open workspace.

- **No build-time way to fake a business remains.** The switch was persisted and dev mode is granted by email in `app_config`, so a fake business was two booleans from being shown to a seller as theirs. Deleting the mode deleted the failure — see `lib/features/seed_data/CLAUDE.md`.
- `VERBOSE_LOGGING` is the only dev switch left in the template; its release guard is unchanged: `DevFlags` ANDs it with `!kReleaseMode`. `test/core/config/app_env_test.dart` holds that the template and `AppEnv` still name exactly the same keys.

The two always-apply rules for `env/` — nothing in it is secret; `AppEnv` states the request, `DevFlags` the permission — live in root `CLAUDE.md` under "Configuration and secrets". Not repeated here.

**Design tokens and domain policy stay out of `env/`, on purpose** — `AppColors`, `SdRadiusV3`, `PurchaseEvaluation.defaultTargetRoi`, `Marketplace.estimatedFeeRate`. They do not vary per build and must be readable from a unit test without a build flag. Above all the stale threshold: it is per-workspace Firestore data (`Workspace.staleThresholdDays`), so freezing it into a build file would contradict `docs/architecture/DATA_MODEL.md`. `env/README.md` has the full list and reasoning.

**Privacy policy and terms URLs are env keys, not constants** — owner's rule. `PRIVACY_POLICY_URL` and `TERMS_OF_SERVICE_URL` are read through `AppEnv` like every build-time value, because they differ per flavour: a staging build points at a draft no lawyer has read, and a hardcoded production URL in a `final class Constant` ships to staging too.

- **Both are on `AppEnv.missingReleaseKeys`.** Apple guideline 3.1.2 wants a working link to each inside the binary, so a release build with either empty is unshippable, and the bootstrap log names it.
- **An empty value renders nothing** — no row, no dead link. A link to a 404 reviews worse than no link: the reviewer clicks it.
- Not secret; they belong here for the same reason as the Firebase ids: public addresses, not credentials.

## Switching flavour on one device wipes it first

Two flavours sharing a bundle id share a sandbox, so installing one over the other leaves the new binary on the old one's signed-in session, preferences and cached Firestore documents — a dev account writing into the real project, or the reverse. Owner's rule: **an environment change is treated as a fresh install.**

- **`SdFreshInstall` is the whole check, in one class** (design system, `core/common/`, pure Dart). It compares a device stamp with `AppEnv.flavor.name` and wipes when they differ. It was three classes — reinstall guard, environment guard, widget — until the owner merged them: both asked whether this device's state belongs to the app now running. `packages/flutter-system-design-kit/WIDGET_RULES.md` holds the decision table.
- **`SplashScreen` runs it — deliberately not a bootstrap step.** Owner's rule: the seller sees the splash loading *while* the wipe runs. Before `runApp` only the platform launch image shows, so a one-second wipe looks like a hang; here the app is up and themed, showing the same screen a returning seller sees while auth resolves. One screen covers both reasons the app is not ready.
- **That is why the screen takes a `child`.** It is mounted twice: around the whole app, holding the child back until the check returns; and as the router's `/splash` route with no child, inside the tree the first one gated.
- **The outer one sits above `ForceUpdateGate` — that order is the point.** Building the first screen alongside the wipe would race its sign-out against screens reading that session.
- **The splash cannot stop every listener.** The router is built above it and listens to `app_config` and the user profile on frame one. So every Firestore listener goes through `FirestoreMaintenance` (`core/firestore/`): a reset detaches them, terminates, clears the cache, re-attaches them; a listener opened mid-reset waits. A listen reaching a terminating client is an uncatchable abort on iOS — TestFlight builds 45 and 46 crashed on launch exactly so, because the wipe's sign-out re-subscribes `app_config` just before `terminate`. `test/core/widgets/splash_screen_test.dart` pins all three states.
- **`AppFreshInstall` is the half that touches the device**, an `SdFreshInstallHost`: `isBackendReady`, `signOut` (Google, then Firebase), `clearCache` (`FirestoreMaintenance.reset`). Nothing else — a wipe's order and step names are `SdFreshInstall`'s. Emptying preferences is appended there and takes the onboarding flag with it, because that is what a fresh install is.
- **It passes `PrefsKeyConstant.lastEnv` as the stamp key** — what installs in the wild already hold — so the first launch after the merge reads a valid stamp: a normal launch, no migration branch, no wipe.
- **No device-scoped store exists here.** Nothing the app writes outlives a delete, so a reinstall is already a first install and that row cannot fire. That differs from the sibling app, whose iOS Keychain kept a session across one.
- **The stamp is written after the wipe, never before** — the wipe clears the store it lives in, so a halted wipe repeats next launch instead of being skipped.

## The build tag is drawn from the flavour, never from `kDebugMode`

`SdDevWrapper` stamps `DEV · 1.0.0 (8)` down the right edge of everything the app draws, hung from the top-right corner — env name from `AppEnv.flavor.name`, version and build from `packageInfoProvider`. It wraps `MaterialApp` rather than sitting inside it, so it brings its own `Directionality` and hardcodes its two colours: a tag drawn from the app's palette vanishes when that palette is the bug.

`visible: !AppEnv.flavor.isProd`. A TestFlight build of the dev flavour is a release binary — exactly the one nobody can otherwise tell from the real app in a bug report.
