# Pending setup

Read before treating missing Firebase, signing or store setup as a code defect. The owner does every row; each needs external access.

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

Without Firebase the app resolves to signed out and runs as a guest; More → General → Seed demo data fills it. No auth bypass exists (hard rule 1).

Full owner checklist: [`RELEASE_ACTIONS.md`](../release/RELEASE_ACTIONS.md).
