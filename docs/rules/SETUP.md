# Pending setup

Read this before treating missing Firebase, signing or store infrastructure as
a code defect. The owner completes every row with external access.

| Area | Repository state | Owner action |
|---|---|---|
| Firebase apps | Integration code exists; generated configs are gitignored | Create projects/apps and run `flutterfire configure` |
| Firebase aliases | `.firebaserc` is not committed | Add `dev` and `prod` aliases |
| Authentication | Apple and Google flows exist | Configure both providers and store-approved artwork |
| Cloud Functions | Code builds and tests locally; nothing is deployed | Deploy, then configure APNs and Scheduler |
| RevenueCat | Client, paywall, gates and webhook exist | Create one Premium entitlement/offering with monthly/yearly products |
| Legal links | App reads build-time URLs | Host Privacy Policy and Terms of Use |
| iOS release | Fastlane workflow exists | Add App Store Connect and Match credentials |
| Android release | App configuration exists | Add Play listing and release signing |

Without Firebase, the app resolves to signed out and remains usable only with
seed a workspace from More → General → Seed demo data. There is no auth bypass
(hard rule 1).

The full owner checklist is [`../../RELEASE_ACTIONS.md`](../../RELEASE_ACTIONS.md).
