# Release checklist

These tasks require an external account, credential, private key or production
decision. Complete them in order. Run `melos run pre-build` before a
release — `release-dev` and `release-prod` do not run it for you.

## Blocking setup

| # | Task | Done when |
|---|---|---|
| 1 | Create Firebase projects/apps | iOS and Android configs exist for each flavor |
| 2 | Configure Google Sign-In | iOS, Android and web OAuth clients work on store-signed devices |
| 3 | Configure Sign in with Apple | App ID capability, Services ID and key are active in Firebase |
| 4 | Create `.firebaserc` aliases | `dev` and `prod` resolve to the intended projects |
| 5 | Deploy backend | Rules, indexes, Storage rules and Functions are live |
| 6 | Configure APNs and Scheduler | Push delivery and `dailyDigest` work |
| 7 | Configure RevenueCat | One Premium entitlement and offering expose monthly/yearly products |
| 8 | Host legal pages | Privacy and Terms URLs open from Paywall and About |
| 9 | Replace sign-in glyphs | Approved Apple and Google artwork passes external review |
| 10 | Configure signing and stores | TestFlight/Play upload succeeds |
| 11 | Configure CI release credentials | Manual release workflow completes without local files |

Internal TestFlight can start before external Beta App Review, but production
auth, backend rules and signing must already work.

## Firebase and authentication

| Area | Required action |
|---|---|
| App registration | iOS: `app.dd.reseller.studio`; Android: `com.dd.reseller.studio` |
| Firebase services | Enable Auth, Firestore, Storage, Crashlytics, Analytics and Messaging |
| Google | Register debug/release SHA-1 and SHA-256; test a release-signed Android build |
| Apple | Enable Sign in with Apple on the App ID and configure Firebase's Apple provider |
| Deploy | Use `melos run deploy-firebase-dev` or `melos run deploy-firebase-prod` |

The app has no auth bypass. Until Firebase is configured, use mock data from
More → Settings.

## RevenueCat

The paid product is Premium. Monthly and yearly are billing periods for the
same entitlement.

| Dashboard item | Requirement |
|---|---|
| Apps | One RevenueCat app per store |
| Entitlement | Must match `AppEnv.revenueCatEntitlement` |
| Offering | Must match `AppEnv.revenueCatOffering` |
| Products | Monthly and yearly subscriptions attached to the offering |
| Client keys | Use the four `REVENUECAT_*` build-time fields read by `AppEnv` |
| Webhook | Store its authorization token in Secret Manager and point RevenueCat to `revenueCatWebhook` |
| Identity | Firebase UID must be passed to RevenueCat after sign-in |

Free limits are owned by `PlanLimits.free`; do not duplicate their values in
this checklist. A downgrade keeps existing records and blocks only new creates.

## Release pipeline setup

| Step | Action |
|---|---|
| Local flavor files | Prepare the gitignored `env_assets/` source files |
| App Store Connect | Create an App Manager API key and keep the `.p8` outside the repo |
| Signing | Create a private certificates repo and a read-only fine-grained PAT |
| Local Fastlane | Fill `ios/fastlane/.env`, then run `bundle exec fastlane certificates` |
| GitHub Actions | Add the secrets listed in [`docs/release/CREDENTIALS.md`](docs/release/CREDENTIALS.md) |
| Rehearsal | From `ios/`, run `bundle exec fastlane pre_build`, then `CI=true bundle exec fastlane pre_build` |
| First upload | Use `bump:false` with a known-free build number |

Do not archive from Xcode. It omits `--dart-define-from-file` and can produce a
binary without Firebase configuration.

## Store submission

| Area | Required action |
|---|---|
| Legal | Review and host [`docs/STORE_PRIVACY.md`](docs/STORE_PRIVACY.md); host Terms of Use |
| Privacy forms | Submit the App Store and Play answers from the privacy document |
| Listing | Description, screenshots, keywords, support URL and age rating |
| Hardware checks | Auth, push, camera, photo picker, deep links and dark cold start |
| Billing checks | Monthly purchase, yearly purchase, cancellation state and restore |
| Data checks | Workspace creation, invite flow, deletion, offline writes and exports |

## Release command

```sh
melos run release-prod -- release notes
```

Detailed pipeline behavior: [`docs/release/PIPELINE.md`](docs/release/PIPELINE.md).
