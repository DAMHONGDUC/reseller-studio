# Store privacy — what the app actually collects

Audited from the code on 16 August 2026, so the two store questionnaires can
be answered from evidence rather than from memory. Every claim below names the
file it came from.

`docs/rules/PRIVACY_AND_SECURITY.md` is the *engineering* rule file — what the
code may log and upload. This one is the *disclosure*: what to tell Apple,
Google and the seller. They are different jobs and both have to be right.

**This is a draft for a lawyer to review, not legal advice.** The UK is a
launch market, so UK GDPR applies: a controller has to be named, a lawful
basis stated and a retention period committed to, and none of those can be
read out of a codebase.

## 1. What is collected

### From the seller, because they typed it

| Data | Where it goes | Source |
|---|---|---|
| Display name, email, avatar URL | `users/{uid}`, denormalised into `workspaces/{id}/members/{uid}` | `docs/DATA_MODEL.md` |
| Business records — items, purchases, orders, listings, expenses, sources | `workspaces/{id}/…` | `docs/DATA_MODEL.md` |
| Item photos, receipt images, workspace logo | Firebase Storage | `lib/core/storage/file_uploader.dart` |
| Addresses of the seller's own storage locations and sourcing sources | `locations/`, `sources/` | `lib/features/inventory/domain/entities/storage_location.dart` |
| `buyerName` — optional, about the seller's customer | `orders/{id}` | `lib/features/orders/domain/entities/order.dart` |

`buyerName` is the only third-party personal data in the app, it is optional,
and it is the buyer's **name only**.

**No buyer address is stored anywhere.** Confirmed by grep across `lib/`: the
only address fields belong to the seller's own locations and sources. Worth
stating explicitly on both questionnaires, because a reseller app is exactly
where a reviewer expects to find shipping addresses.

### Automatically, by the SDKs

| Data | Collector | Note |
|---|---|---|
| Crash traces, device model, OS version | Firebase Crashlytics | `SdCrashReporter.setUserId` sends the Firebase UID **and nothing else** (hard rule 9) |
| Product-interaction events | Firebase Analytics | the full list is `lib/core/analytics/app_analytics.dart`, one typed method per event |
| App instance id, device and OS, coarse region from IP | Firebase Analytics | the SDK's own baseline, not something the app sends |
| Subscription and purchase state | RevenueCat | plan tier only |

**No analytics event carries personal data.** Every parameter is a boolean, a
count, or a fixed vocabulary word — `via_quick_add`, `marketplace`, `count`,
`plan`. No item title, no buyer name, no email, no amount of money. That is
enforced by the file being the single inventory of what is sent, and it is
worth re-reading before each release.

### What is NOT collected

Each of these is a question on one of the forms, and the answer is no:

- **No precise or coarse location.** There is no location plugin in
  `pubspec.yaml`.
- **No contacts, calendar, health, or browsing history.**
- **No advertising SDK, no third-party tracker, no data broker.** The only
  third parties are Google (Firebase) and RevenueCat, both processors.
- **No marketplace OAuth tokens in the app.** They live in Secret Manager and
  are read only by Cloud Functions (hard rule 10). Not deployed yet, so today
  the app holds none at all.
- **No password.** Sign-in is Apple and Google only (hard rule 1), so there is
  no credential for this app to store or lose.

## 2. App Store Connect — App Privacy answers

For each type: what it is, whether it is linked to the user, and why.

| Data type | Collected | Linked | Purpose |
|---|---|---|---|
| Contact Info → Name, Email | yes | yes | App Functionality |
| User Content → Photos | yes | yes | App Functionality |
| User Content → Other | yes | yes | App Functionality |
| Identifiers → User ID | yes | yes | App Functionality, Analytics |
| Identifiers → Device ID | yes | yes | Analytics |
| Usage Data → Product Interaction | yes | yes | Analytics |
| Diagnostics → Crash Data | yes | yes | App Functionality |
| Purchases → Purchase History | yes | yes | App Functionality |

**"Used for tracking" is NO for every row.** Apple defines tracking as linking
this data with third-party data for targeted advertising or sharing it with a
data broker. The app does neither, which is why it needs **no App Tracking
Transparency prompt**. Answering yes here would force one.

**Account deletion is already built** (`docs/DONE_WORK.md`, auth flows), which
is what guideline 5.1.1(v) requires — an app offering account creation must
offer in-app deletion. Point the reviewer at Settings.

## 3. Google Play — Data Safety answers

Same facts, Google's vocabulary. All of it is encrypted in transit (Firebase
is HTTPS throughout) and the seller can request deletion in-app.

| Category | Type | Collected | Purpose |
|---|---|---|---|
| Personal info | Name, Email address | yes | Account management, App functionality |
| Photos and videos | Photos | yes | App functionality |
| Financial info | Purchase history | yes | App functionality |
| App activity | App interactions | yes | Analytics |
| App info and performance | Crash logs, Diagnostics | yes | App functionality |
| Device or other IDs | Device or other IDs | yes | Analytics |

Declare: **data is encrypted in transit — yes**; **users can request data
deletion — yes**; **committed to Play Families policy — not applicable**, the
app is not aimed at children.

## 4. Privacy policy — a draft to host

Both stores need a **public URL** before the listing is accepted. Fill the
bracketed parts and have it reviewed.

---

### Privacy Policy — Seller OS

_Last updated: [date]_

**Who we are.** [Legal entity name] ("we") provides the Seller OS app. For UK
and EU data protection law we are the data controller. Contact:
[support email].

**What we collect.**

- *Your account*: the name, email address and avatar your Apple or Google
  account gives us when you sign in. If you use Sign in with Apple's Hide My
  Email, we only ever see the relay address.
- *Your business records*: the inventory, purchases, orders, listings,
  expenses and sourcing information you enter, including photographs of items
  and receipts.
- *Your customers*: if you choose to record a buyer's name against an order,
  we store that name. We do not ask for or store buyers' addresses.
- *Diagnostics and usage*: crash reports, and anonymous events describing
  which features are used. These never include your business data.

**Why we use it.** To run the service you signed up for, to keep your data
synchronised across your devices and team, to manage your subscription, and to
find and fix faults. Our lawful basis is performance of our contract with you,
and our legitimate interest in a working, secure product.

**We do not sell your data, and we do not use it for advertising.**

**Who processes it for us.** Google (Firebase — authentication, database,
file storage, crash reporting, analytics, notifications) and RevenueCat
(subscription management). Data is stored in [region]. Where data leaves the
UK or EEA, it is transferred under [safeguard].

**How long we keep it.** For as long as your account exists. Delete your
account in Settings and we remove your personal data and your workspace's
records within [n] days, except anything we must keep by law.

**Your rights.** You can access, correct, export or delete your data. The app
exports your records as CSV, and Settings deletes your account. To exercise
any other right, or to complain, write to [support email]. In the UK you may
also complain to the Information Commissioner's Office.

**Children.** Seller OS is for business use and is not directed at anyone
under 18.

**Changes.** We will post any change here and update the date above.

---

## 5. What is still yours to do

- Fill the brackets and have a lawyer read it — particularly the retention
  period and the transfer safeguard.
- Host it at a stable URL and put that URL in both listings.
- Re-read `lib/core/analytics/app_analytics.dart` before each release. It is
  the single inventory of what leaves the device, and this document is only
  true for as long as that file is.
