# Release actions — what only you can do

Everything in this file needs an account, a card, a private key or a decision.
None of it can be written in code, and the app **cannot ship** until the
blockers are done.

Ordered by what blocks what. Work top to bottom.

---

## 0. Blockers — nothing ships without these

| # | Thing | Why it blocks | Rough time |
|---|---|---|---|
| 1 | Firebase project + `flutterfire configure` | No backend at all. Every screen reads from Firestore. | 30 min |
| 2 | Google Sign-In OAuth clients | One of only two ways into the app. | 30 min |
| 3 | Sign in with Apple (Services ID + key) | The other way in, and **App Store review rejects** an app offering Google without it. | 45 min |
| 4 | Deploy `firestore.rules`, `firestore.indexes.json`, `storage.rules` | Without rules, Firestore is either locked shut or wide open. | 10 min |
| 5 | The vendors' own artwork on the sign-in buttons | The buttons currently draw `SimpleIcons` glyphs (owner's rule), which is a **redrawn trademark** — Beta App Review rejects that, and Google's guidelines require their four-colour "G". Nothing is blocked from running; this blocks external TestFlight and submission only. | 30 min |
| 6 | Bundle id, signing, App Store / Play listings | No build can be uploaded. | 2–3 h |
| 7 | Privacy policy + terms URLs, hosted, then in `env/*.json` | Both stores refuse the listing without them, and guideline 3.1.2 wants both links **inside** the app — the paywall and About read `PRIVACY_POLICY_URL` and `TERMS_OF_SERVICE_URL` and draw nothing when they are empty. | 1 h |

App icons, the launch screen, the iOS permission strings, the **Sign in with
Apple entitlement** and **account deletion with its data** are done and are no
longer on this list. `melos run preflight` checks every row above and exits
non-zero on the ones still unmet — run it rather than reading this table.

### TestFlight: internal and external are not the same gate

Internal testing — up to 100 people on your App Store Connect team — needs no
review at all, so a build can go out as soon as rows 1–4 and 6 are done.
**External testing, which is what "customers" means, goes through Beta App
Review**, and that is the reviewer who rejects a placeholder logo. Row 5 only
blocks the external half.

---

## 1. Firebase

1. Create the project (one per environment if you want `dev` and `prod`
   separate; one is fine for launch).
2. Add an **iOS app** with bundle id `com.dd.seller.os` and an **Android app**
   with the matching application id.
3. Run `flutterfire configure` from the repo root. It writes
   `lib/firebase_options.dart`, `ios/Runner/GoogleService-Info.plist` and
   `android/app/google-services.json` — all three are gitignored and all three
   are currently **absent**.
4. Fill the `FIREBASE_*` keys in `env/dev.json` and `env/prod.json` with the
   same values. They are not secrets (see `docs/rules/ENV.md`); they are read
   by tooling and by the diagnostics line in the log.
5. Enable in the console: **Authentication** (Apple + Google providers only),
   **Firestore**, **Storage**, **Crashlytics**, **Analytics**, **Cloud
   Messaging**.
6. Create `.firebaserc` (`firebase use --add`) — it does not exist, so
   `melos run deploy-firebase` cannot run today.
7. Deploy the rules and indexes:
   ```sh
   melos run deploy-firebase
   ```
   Use the script rather than a hand-typed `firebase deploy`: it confirms the
   project first, and it is the one place the list of what ships is written
   down. A command copied into a document is a command that drifts from the
   one people actually run — that is how `storage` came to be missing from
   the script while this page still named it.

**The dev bypass is already gone** — deleted, not switched off, along with the
`AUTH OFF` banner. Nothing enters the app without an account. Two consequences
while Firebase is still missing:

- the app opens on the **signed-out shell** — onboarding, then five empty tabs
  — and sign-in fails with the one message hard rule 6 allows;
- to develop against data, turn **mock data on in More → Settings**, which is
  reachable without signing in.

`BYPASS_AUTH` may still sit in `env/*.json`; nothing reads it, and the key can
be deleted from both files and both templates whenever you are next in there.

### ⚠️ Read this before you deploy the rules

`firestore.rules` changed in this session. Creating a workspace needs the owner
to write their own `members/{uid}` document, and `canAdmin()` cannot authorise
that — it reads the very document being created, so the first member of a new
workspace could never be written and the workspace would be unreadable by
anyone, forever.

The new clause is narrow: **only** the uid the workspace itself names as
`ownerId`, **only** with `role == 'owner'`, **only** on create. It cannot be
used to promote anyone later. Read it and satisfy yourself before deploying —
this is the one rule in the file that lets somebody write their own membership.

---

## 2. Sign-in — Google and Apple are now the only ways in

You changed the auth model this session: **no email/password, no sign-up form,
no password reset.** That is recorded in `CLAUDE.md` hard rule 1 and in the
master plan §26. It removes a lot of surface, and it makes both providers
blocking rather than nice-to-have.

### Google Sign-In

1. In Google Cloud (the Firebase project's own GCP project), create OAuth 2.0
   client IDs: one **iOS**, one **Android** (needs your signing SHA-1 **and**
   SHA-256 — both debug and release), one **Web** (this is the
   `serverClientId`).
2. Add the iOS client's reversed client id to `ios/Runner/Info.plist` as a URL
   scheme. `flutterfire configure` does not do this for you.
3. Put the values in `env/*.json` as `GOOGLE_SIGN_IN_IOS_CLIENT_ID` and
   `GOOGLE_SIGN_IN_SERVER_CLIENT_ID` **only if** the bundle id differs from the
   Firebase app's — otherwise leave them empty and the plugin reads the config
   file, which is the normal path.
4. Test on a **real Android device with a release-signed build**. Google
   Sign-In failing only in release, because the release SHA-1 was never
   registered, is the single most common launch-day bug in this flow.

### Sign in with Apple

1. Apple Developer → Identifiers → enable **Sign in with Apple** on the app id.
2. Create a **Services ID** for the Android/web flow, and a **Key** (`.p8`) for
   Sign in with Apple. Note the Key ID and Team ID.
3. Paste all of it into Firebase Console → Authentication → Apple.
4. In Xcode, add the **Sign in with Apple** capability to the Runner target.
   **The repo half is done** — `ios/Runner/Runner.entitlements` declares
   `com.apple.developer.applesignin` and `CODE_SIGN_ENTITLEMENTS` names it on
   Debug, Release and Profile. What is left is enabling the capability on the
   app id in the developer portal so the provisioning profile carries it.
5. `APPLE_SIGN_IN_SERVICE_ID` in `env/*.json` is for reference; the app itself
   goes through `FirebaseAuth.signInWithProvider`, which handles the nonce.

### Brand marks — blocker 5, deferred to submission

**Both buttons draw a `SimpleIcons` glyph today** (owner's rule), passed as
`SdButtonV3.icon` so the button sizes and tints them like any other icon
button. That is what unblocked the demo: the previous version loaded vendor
SVGs from `assets/brand/`, Apple's file has never existed, and
`SvgPicture.asset` threw *while the login screen built* — which cost the
seller Google as well, and with it the only way into the app.

**It is still a redrawn trademark, and that is a review risk, not a style
preference.** Two things have to happen before an external build:

| Mark | What submission needs |
|---|---|
| Apple | Apple's own logo from the Sign in with Apple design resources. A substitute fails Beta App Review. |
| Google | Google's four-colour "G", untinted. `assets/brand/google_g.svg` is already in the repo — their own `logo_googleg_48dp` file, byte-for-byte. |

Swapping back is a small change: `SdButtonV3` still has its `leading` slot for
artwork that cannot be an `IconData`, which is the slot both buttons used
before.

- Apple: <https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple>
- Google: <https://developers.google.com/identity/branding-guidelines>

Neither mark may be redrawn — an approximated trademark is worse than an
obvious placeholder, because it looks finished. That is why Apple's is a gap
rather than a best guess.

### The Apple button's colour is fixed

**Was:** `SdButtonVariantV3.primary`, which is the app's indigo. Apple allows
three styles and no others — black, white, or white with an outline — so an
indigo one was a rejection risk sitting on the first screen a reviewer opens.

**Now:** both buttons wear `SdButtonVariantV3.vendor`, a variant whose colours
the app's palette cannot reach: black on a light theme, white on a dark one.
Google's neutral button is the same shape, so the two match without either
being tinted. The one place the design system hardcodes a colour, and
`WIDGET_RULES.md` §4 says why.

**Both marks stay `SimpleIcons` glyphs** — owner's rule, restated after
Google's own SVG was wired in and taken back out. Google's file ships in
`assets/brand/` and is deliberately unused: two buttons drawn two different
ways is the state where only one of them can break, and the one that breaks
takes the whole gate with it.

**Apple's logo is the asset still missing**, and it is what unblocks the swap
— both buttons move to `SdButtonV3.leading` in the same change, once
`assets/brand/apple_logo.svg` exists. Until then blocker 5 stands and the
glyphs render.

### I removed a dependency

`sign_in_with_apple` is gone from `pubspec.yaml`. Apple sign-in now runs
through `FirebaseAuth.signInWithProvider`, which is native on iOS, works on
Android, and generates and verifies its own nonce — three fewer things to get
wrong. If you would rather keep the package, say so and I will switch it back.

---

## 3. Store and platform

- **App icons and launch screens are done** on iOS. Confirm the Android
  adaptive icon before uploading a Play build.
- **Bundle id / application id**: iOS is `com.dd.seller.os`. Confirm the
  Android one matches what you registered.
- **Signing**: an iOS distribution certificate and provisioning profile; an
  Android upload keystore. Keep the keystore and its password somewhere you
  will still have them in two years — losing it means you cannot update the app.
- **iOS deployment target is 15.0** and must stay there: the Firebase Swift
  packages refuse to link below it.
- **Permission strings.** The app uses the camera (scanner), the photo library
  (item photos) and Storage. `Info.plist` needs `NSCameraUsageDescription` and
  `NSPhotoLibraryUsageDescription` in wording a reviewer will accept — "to scan
  barcodes on your inventory", not "for camera access".
- **Privacy policy URL** and both stores' data-safety questionnaires.
  **`docs/STORE_PRIVACY.md` has the answers already worked out** — the app was
  audited against its own code, so every row is filled in for both forms,
  along with a policy draft to host. Two findings that save an argument with a
  reviewer: no buyer address is stored anywhere, and nothing is "used for
  tracking" in Apple's sense, so the app needs no ATT prompt. What is left is
  filling the brackets, a legal read, and hosting it.
- **App Store**: screenshots at every required size, description, keywords,
  support URL, age rating.
- **TestFlight / internal testing** before submitting. Both sign-in flows must
  be tested on a real device from a store-signed build.

---

## 4. Cloud Functions — not deployed, and some features wait on them

Nothing is deployed. Several things in the app are deliberately switched off
until it is, and each says so on screen rather than failing:

| Feature | What it needs |
|---|---|
| Marketplace sync (eBay, Etsy, Depop, Poshmark, Mercari, Shopify) | OAuth per platform, secrets in Secret Manager, sync + webhook functions. **The app never sees a token** (hard rule 10). Not written. |
| Team invites, roles and removal | The three team callables — `invites/` is `allow write: if false` because a callable is what enforces the seat limit and stops the last owner being removed. Written, **and the app now calls them**: the Team screen has an invite button and a role sheet, so before the deploy a seller taps them and gets the generic failure. That is the same bet delete-account already makes, and it is worth knowing before a demo. |
| Activity / audit log | Firestore triggers. `activity/` is append-only and client-writable-never, so a client-written log would be worthless as an audit trail. Written. |
| Notifications and pushes | Three triggers plus a scheduled digest. The inbox renders without them and stays empty, because nothing else may write a notification. Written. |
| The plan being a real limit | `revenueCatWebhook`, below. Written. |
| Deleting one business | `deleteWorkspace`. Settings offers it to an owner; the delete itself is server-side because Firestore does not cascade. Written. |

### What deploying the notifications needs beyond the deploy

1. **An APNs key in the Firebase console** (Project settings → Cloud
   Messaging). Without it iOS pushes silently never arrive — the app
   registers, the send reports success, and no phone rings.
2. **Cloud Scheduler enabled** on the project. `dailyDigest` is an
   `onSchedule` function and the first deploy creates the job; the API has to
   be on for that to succeed.
3. **Test on a real device.** A simulator has no APNs token, so nothing about
   push can be checked before you have hardware in your hand.

Marketplace OAuth secrets go in **Secret Manager**, never in `env/*.json` — a
test in this repo fails any key whose name contains `SECRET` or `PRIVATE`.

---

## 4b. Billing — RevenueCat, which you said you would handle

The app is built against it and runs without it: with no key, every seller
reads as Free and the Subscription screen says billing is not set up. Nothing
below can be done from this repo.

1. **RevenueCat project**, one app per store.
2. **Entitlements named `pro` and `business`** — the identifiers are in
   `SubscriptionProductConstant.planByEntitlement`. If they do not match the
   dashboard, every paying seller reads as Free and nothing throws, so this is
   the first thing to check when an account looks wrong.
3. **Products whose identifiers contain the plan name** — `pro_monthly`,
   `pro_yearly`, `business_monthly`, `business_yearly`. The app reads the tier
   off the identifier and **drops any product it cannot place**, rather than
   selling it as the wrong tier.
4. **App Store Connect and Play Console subscriptions**, attached to those
   products, with a subscription group per tier.
5. **Two keys into `env/dev.json` and `env/prod.json`** — I could not edit
   `env/`, so these are yours to add to both files and both templates:
   `REVENUECAT_IOS_API_KEY` and `REVENUECAT_ANDROID_API_KEY`. They are public
   SDK keys and belong there (`docs/rules/ENV.md`).
6. **The webhook secret is NOT an env key.** It goes in Secret Manager as
   `REVENUECAT_WEBHOOK_TOKEN`, and only `revenueCatWebhook` reads it:

   ```sh
   printf '%s' '<the value you set in RevenueCat>' | \
     gcloud secrets create REVENUECAT_WEBHOOK_TOKEN --data-file=-
   ```

   Then in the RevenueCat dashboard, point the webhook at the deployed
   function's URL and set the **Authorization header** to that same value. The
   function answers 401 to anything else and never logs what was sent.

   Until both halves are done, `planFor` reads every workspace as Free
   however much the seller paid — that is what makes a plan gate a UI
   decision rather than a boundary.

7. **The entitlement follows the person and lands on the businesses they
   own.** RevenueCat knows an `app_user_id`, which the app sets to the
   Firebase uid at sign-in; the webhook grants the plan to every workspace
   where that uid is `owner`. A business somebody else owns is somebody
   else's to pay for.
8. **Price the tiers.** `PlanLimits.byPlan` holds the ceilings and
   `InMemorySubscriptionRepository.catalogue` holds the demo prices; both are
   a first proposal nobody has priced.

**Restore purchases is already wired** and App Store review requires it, so do
not remove that row from the Subscription screen.

## 4c. Tax — the mileage rates are now verified

**Done, 16 August 2026.** `MileageRateConstant.published` was two years out of
date and has been checked against irs.gov and gov.uk. Four figures were
missing: the IRS set 72.5¢ for the first half of 2026 and 76¢ from 1 July, and
HMRC raised its first band from 45p to 55p on 6 April 2026 — its first change
since 2011.

Nothing here needs an account, so it is only listed to record that it was
done. What is left for you: **re-check both tables before each filing season**,
and add a new dated entry rather than editing an old one — a past year must
keep deducting at the rate that applied to it.

The jurisdiction comes from the workspace's country, and only `US` and `GB`
are recognised; anything else falls back to the US. That matches the launch
markets in `CLAUDE.md`.

## 4d. Account deletion — done, and it needs the functions deployed

**App Store guideline 5.1.1(v) wants the account *and its data* gone.** The
old delete removed the login with `user.delete()` and left every document
where it was, which is the reading Apple rejects.

- `functions/src/account/deleteAccount.ts` is the callable. It deletes the
  workspaces the seller **solely owns** — subcollections and Storage objects
  with them — removes only the membership from a business somebody else owns,
  clears their pending invites, then deletes the Auth user last.
- **It refuses a stale session.** The Admin SDK does not enforce Firebase's
  `requires-recent-login`, so the function reads `auth_time` off the token and
  wants a sign-in inside five minutes. Same guard as before, made explicit.
- **Until `functions/` is deployed, the Delete account row fails** with the
  one message hard rule 6 allows. That is section 1 blocker 4's deploy, not a
  separate task.

## 4e. Legal URLs — two env keys only you can fill

`env/` is not editable from this repo, so both keys are yours to add to
`env/dev.json`, `env/prod.json` **and both `.example.json` templates** — a key
in one flavour and not the other fails `test/core/config/app_env_test.dart`:

```json
"PRIVACY_POLICY_URL": "https://…/privacy",
"TERMS_OF_SERVICE_URL": "https://…/terms"
```

- Both are on `AppEnv.missingReleaseKeys`, so a release build without them
  says so by name in the bootstrap log, and `melos run preflight` blocks.
- **Empty draws nothing** — no row, no dead link. A reviewer clicking through
  to a 404 is a worse outcome than an app with no link.
- `docs/STORE_PRIVACY.md` holds the policy draft to host. Filling its
  brackets and hosting it is what produces the first URL.

## 5. Decisions I need from you

Nothing is open. Everything that was here is under **Resolved** below.

### Resolved since the first draft

- **Launch markets are the US and the UK**, and **RevenueCat is approved** —
  owner's calls. Both are recorded in `CLAUDE.md` and
  `docs/rules/DECISIONS.md`. §20 Tax and §27 Monetization are built against
  them; what only you can do is in sections 4b and 4c above.

- **Localization — English only until release.** Owner's call. New strings
  still go through ARB keys (hard rule 7 is unchanged), but `app_vi.arb` and
  every other locale are filled in **once, in one pass, at release**. The
  reason: translating a screen that is about to be redesigned pays for the
  same string twice. The remaining work and its size are in section 7.
- **Offers** (plan §8) are built — list with `Pending | Accepted | Declined |
  Expired`, accept, decline, record a counter, and the discount off the asking
  price spelled out on each card.
- **Receipts** (plan §18) are built, with upload.
- **Analytics drill-downs** (plan §9) are built.
- **Analytics events** — `AppAnalytics` now exists with a typed method per
  event, wired beside each `SdLogger.action` in the controllers. It is a
  no-op until Firebase is configured. **No item title, buyer name or
  credential is ever a parameter** (hard rule 9). The one number worth
  watching is `item_created.via_quick_add`: hard rule 2 says the product's
  speed rests on Quick Add, and that flag is how anyone finds out whether
  sellers actually use it.
- **Zero-decimal currencies** — fixed rather than dodged. `CurrencyDecimals`
  knows which ISO codes have no minor unit, `Money` parses and formats through
  it, and every hardcoded `/100` in the app is gone. VND is safe to leave in
  the picker; `test/core/money/currency_decimals_test.dart` is what stops the
  2-decimal assumption creeping back.

---

## 6. What is built, and what is left

Both moved out of this file, which is only for what needs an account, a key or
a card:

- **`docs/DONE_WORK.md`** — what exists and works, by plan section, plus the
  flows worth testing by hand before you trust a build.
- **`docs/REMAINING_WORK.md`** — what is not built, grouped by what is
  stopping it: deferred by decision, blocked on Cloud Functions, or not
  started.

The Cloud Functions table in section 4 above is the overlap: those features
are blocked on the deploy that section describes.
