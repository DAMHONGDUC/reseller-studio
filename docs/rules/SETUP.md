# Pending setup — the owner does this by hand, don't assume it exists

Read this when something Firebase-, signing- or asset-related appears missing,
or before assuming a piece of infrastructure exists.

- **There is no Firebase project yet.** `lib/firebase_options.dart`,
  `google-services.json` and `GoogleService-Info.plist` are all gitignored and
  absent. Run `flutterfire configure` once the project exists. Until then
  `bootstrap` catches the init failure and the app runs without a backend —
  deliberately, so a missing config is a warning line rather than a white
  screen. `melos run run` gets past login meanwhile (hard rule 1), and
  **delete the bypass when real sign-in works.**
  The `FIREBASE_*` keys in `env/*.json` are empty until then; `bootstrap` logs
  one clean warning rather than a Firebase stack trace when it sees that.
- **`.firebaserc` does not exist**, so `melos run deploy-firebase` cannot run.
- **The v3 design-system commit is local to this machine.** It is committed in
  `packages/system_design` on `main` but **not pushed**. Push it before anyone
  else clones this repo, or their `melos run set-up` will fast-forward the
  submodule to an upstream `main` that has no `v3/` and nothing will compile.
- **Sign in with Apple and Google Sign-In are not configured** — no Services
  ID, no OAuth client, no entitlement. The login screen's buttons are inert
  and carry placeholder glyphs; both platforms require their own brand mark
  and forbid a substitute, so the real assets must land before release.
- **`functions/` has no deployed function.** `npm ci` has not been run there.
- **App icons and launch screens are Flutter's defaults.**
- **No `firebase_options.dart` means no FCM, no Crashlytics data, no
  Analytics.** Everything is wired; nothing is reporting.
