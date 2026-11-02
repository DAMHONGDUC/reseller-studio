# Release checklist

Tasks that need an external account, credential, private key or production decision. Do them in order. Run `make pre-build` before a release — `release-dev` and `release-prod` do not run it.

## Blocking setup

| # | Task | Done when |
|---|---|---|
| 1 | Create Firebase projects/apps | iOS and Android configs exist for each flavor |
| 2 | Configure Google Sign-In | iOS, Android and web OAuth clients work on store-signed devices |
| 3 | Configure Sign in with Apple | App ID capability, Services ID and key are active in Firebase |
| 4 | Create `.firebaserc` aliases | `dev` and `prod` resolve to the intended projects |
| 5 | Deploy backend | Rules, indexes, Storage rules and Functions live — including `refreshUsageDaily`; without it a workspace at the order ceiling stays blocked after its 30-day window empties |
| 6 | Configure APNs and Scheduler | Push delivery and `dailyDigest` work |
| 7 | Configure RevenueCat | One Premium entitlement and offering expose monthly/yearly products |
| 8 | Host legal pages | Privacy and Terms URLs open from Paywall and About. **Re-host after the guest-mode rewrite** — the live text still says the app cannot be used without an account |
| 9 | Replace sign-in glyphs | Approved Apple and Google artwork passes external review; both at once, into `SdVendorButtonV3.leading` |
| 10 | Configure signing and stores | TestFlight/Play upload succeeds |
| 11 | Configure CI release credentials | Manual release workflow completes without local files |

Internal TestFlight can start before external Beta App Review; production auth, backend rules and signing must already work.

## Firebase and authentication

| Area | Required action |
|---|---|
| App registration | iOS: `app.dd.reseller.studio`; Android: `com.dd.reseller.studio` |
| Firebase services | Enable Auth, Firestore, Storage, Crashlytics, Analytics and Messaging |
| Google | Register debug/release SHA-1 and SHA-256; test a release-signed Android build |
| Apple | Enable Sign in with Apple on the App ID and configure Firebase's Apple provider |
| Deploy | Use `make deploy-be-dev` or `make deploy-be-prod` |

No auth bypass exists. Until Firebase is configured, use More → General → Seed demo data.

## RevenueCat

The paid product is Premium; monthly and yearly are billing periods of one entitlement.

| Dashboard item | Requirement |
|---|---|
| Apps | One RevenueCat app per store |
| Entitlement | Must match `AppEnv.revenueCatEntitlement` |
| Offering | Must match `AppEnv.revenueCatOffering` |
| Products | Monthly and yearly subscriptions attached to the offering |
| Client keys | Use the four `REVENUECAT_*` build-time fields read by `AppEnv` |
| Secret Manager | Enable `secretmanager.googleapis.com` on the Firebase project before deploying — `revenueCatWebhook` declares a secret, so the whole Functions deploy fails without it |
| Webhook | Token in Secret Manager; RevenueCat points at `revenueCatWebhook` |
| Identity | Pass the Firebase UID to RevenueCat after sign-in |

`PlanLimits.free` owns the Free limits; never copy their values here. A downgrade keeps existing records and blocks only new creates.

## Release pipeline setup

| Step | Action |
|---|---|
| Local flavor files | Prepare the gitignored `env_assets/` source files |
| App Store Connect | Create an App Manager API key and keep the `.p8` outside the repo |
| Signing | Create a private certificates repo and a read-only fine-grained PAT |
| Local Fastlane | Fill `ios/fastlane/.env`, then run `bundle exec fastlane certificates` |
| GitHub Actions | Add the secrets in [`CREDENTIALS.md`](CREDENTIALS.md) |
| Rehearsal | From `ios/`, run `bundle exec fastlane preflight`, then `CI=true bundle exec fastlane preflight` |
| First upload | Use `bump:false` with a known-free build number |

Never archive from Xcode: it skips `--dart-define-from-file` and can ship a binary with no Firebase config.

## Store submission

| Area | Required action |
|---|---|
| Legal | Review and host [`docs/store/STORE_PRIVACY.md`](../store/STORE_PRIVACY.md); host Terms of Use |
| Privacy forms | Submit the App Store and Play answers from the privacy document |
| Listing | Paste every field from [`docs/store/MARKETING_INFO.md`](../store/MARKETING_INFO.md), top to bottom, and close its `TODO(owner)` list |
| Hardware checks | Auth, push, camera, photo picker, deep links and dark cold start |
| Billing checks | Monthly purchase, yearly purchase, lifetime purchase, cancellation state and restore |
| Translations | Native read-through of `es`, `fr`, `de`, `pt`, `zh`, `vi` — all unreviewed machine work (hard rule 7) |
| Data checks | Workspace creation, invite flow, deletion, offline writes and exports |

## Release command

Backend first when the build needs new rules, then the app:

```sh
make deploy-be-prod
```

```sh
make release-ios-prod NOTE="release notes"
```

Pipeline details: [`PIPELINE.md`](PIPELINE.md).
