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
| 7 | Privacy policy URL + data-safety answers | Both stores refuse the listing without them. | 1 h |

App icons, the launch screen and the iOS permission strings **are done** and
are no longer on this list.

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

### ⚠️ The Apple button is the wrong colour for Apple's guidelines

Separate from the missing file, and it will be read at review. "Continue with
Apple" renders as `SdButtonVariantV3.primary`, which is the app's indigo
(`AppColors.brand`). **Apple allows three button styles and no others: black,
white, or white with an outline.** An indigo one is a rejection risk.

It is a design decision, not a bug, so it has been left alone — **and the
login redesign made it more visible, not less**: the two buttons now sit
pinned together at the bottom, so an indigo Apple button beside an outlined
Google one is the first thing a reviewer looks at. The two ways out: give the
Apple button the `outlined` variant, so both match and both are
white-with-outline; or add a black variant for it alone. Say which and it is a
few minutes.

### I removed a dependency

`sign_in_with_apple` is gone from `pubspec.yaml`. Apple sign-in now runs
through `FirebaseAuth.signInWithProvider`, which is native on iOS, works on
Android, and generates and verifies its own nonce — three fewer things to get
wrong. If you would rather keep the package, say so and I will switch it back.

---

## 3. Store and platform

- **App icons and launch screens are still Flutter's defaults.** Every size,
  both platforms, plus the adaptive icon on Android.
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

`functions/` has never had `npm ci` run in it and nothing is deployed. Three
things in the app are deliberately switched off until it is, and each says so
on screen rather than failing:

| Feature | What it needs |
|---|---|
| Marketplace sync (eBay, Etsy, Depop, Poshmark, Mercari, Shopify) | OAuth per platform, secrets in Secret Manager, sync + webhook functions. **The app never sees a token** (hard rule 10). |
| Team invites | An `inviteMember` callable — `invites/` is `allow write: if false` because the callable is what enforces the seat limit and stops the last owner being removed. |
| Activity / audit log | Firestore triggers. `activity/` is append-only and client-writable-never, so a client-written log would be worthless as an audit trail. |

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
6. **The webhook secret is NOT an env key.** It goes in Secret Manager and is
   read only by the Cloud Function that mirrors entitlement into Firestore —
   which is not written yet, and is why the plan gates are a UI decision and
   not yet a security boundary.
7. **Price the tiers.** `PlanLimits.byPlan` holds the ceilings and
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
  event, wired beside each `AppLogger.action` in the controllers. It is a
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
