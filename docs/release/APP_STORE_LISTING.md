# App Store submission sheet

Every field App Store Connect asks for, in the order it asks. A row marked
**[owner]** is a decision or an account action no source file can answer.
Privacy answers are not repeated here — they live in
[`../STORE_PRIVACY.md`](../STORE_PRIVACY.md), and the release order lives in
[`../../RELEASE_ACTIONS.md`](../../RELEASE_ACTIONS.md).

## App record

| Field | Value |
|---|---|
| Name | Reseller Studio |
| Bundle ID | `app.dd.reseller.studio` |
| SKU | **[owner]** — free text, suggestion `reseller-studio-ios` |
| Primary language | English (U.S.); six more locales ship (hard rule 7), and a locale with no listing of its own shows this one |
| Primary category | Business |
| Secondary category | Productivity |
| Age rating | 4+ — no user-generated sharing, no ads, no gambling |
| Content rights | Does not contain third-party content |
| Price | Free, with an in-app subscription |
| Availability | United States and United Kingdom |
| Device family | iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) — see below |
| Minimum iOS | 15.0 |
| Export compliance | Answered in the binary: `ITSAppUsesNonExemptEncryption` is false |

**iPad is currently claimed.** Keeping it means iPad screenshots and an iPad
pass in review; dropping it is `TARGETED_DEVICE_FAMILY = 1` in the Runner
target. **[owner]** decides which.

## Localizable listing

### Subtitle (30 characters)

```text
Inventory, orders, profit
```

### Promotional text (170 characters)

```text
Know what needs attention today: items to list, orders to ship, payouts a marketplace still owes you, and the profit each sale actually made.
```

### Keywords (100 characters)

```text
reselling,inventory,flipping,thrift,profit,sourcing,sales tracker,ROI,bookkeeping,consignment
```

Marketplace names are deliberately absent. A competitor's or a marketplace's
trademark in the keyword field is a metadata rejection, and this app does not
connect to any platform (hard rule 10).

### Description

```text
Reseller Studio is the operating system for your reselling business. It follows
one chain from end to end: source, purchase, inventory, list, sell, ship,
profit, analyze — then source better.

TELLS YOU WHAT NEEDS ATTENTION TODAY
Home opens on the work, not on a dashboard: items still unlisted, orders still
unshipped, sales a marketplace has not paid out yet, and inventory that has sat
too long.

FAST INTAKE
Add an item with nothing but a title. Scan a barcode, snap a photo, or run an
intake session for a whole haul. Prices, categories and locations attach when
you need them, not before.

REAL PROFIT, NEVER AN ESTIMATE
Profit, margin and ROI are worked out from what you actually paid and what the
platform actually paid you. Fees are measured from your payout, never guessed
from a published rate — and when a figure is unknown, it says so instead of
printing a zero.

ORDERS AND SHIPPING
Record a sale with the platform's order number, ship it, settle it, handle
returns and refunds, and chase the payouts that are late. Import a payout report
you downloaded from your marketplace and reconcile in bulk.

SOURCING THAT PAYS FOR ITSELF
Track sources, purchases and buying trips. Split a receipt across the items on
it, rank your sources by ROI, and use the buy calculator before you pay.

BULK BY DEFAULT
Reprice, relist, mark live, pause, end, archive and file forty rows at once.

ANALYTICS AND TAX
Sales, profit, inventory, marketplace, category and source views. US and UK tax
summaries, mileage, and a one-action tax pack for your accountant.

WORKS WITH YOUR TEAM
Several businesses under one account, invite teammates, set roles, and keep
everything in sync.

PREMIUM
Premium unlocks exports — every CSV and the tax pack — and payout
reconciliation broken down by marketplace and by order, and removes the free
plan's record ceilings.

Reseller Studio does not connect to marketplace accounts, does not sell your
data and does not use it for advertising.
```

### Subscription terms block

App Store guideline 3.1.2 wants the terms in the listing as well as in the app.
Append to the description, with the prices filled in for each storefront:

```text
Reseller Studio Premium is an auto-renewing subscription, billed monthly or
yearly at the price shown in the app. Payment is charged to your Apple Account
at confirmation. It renews automatically unless turned off at least 24 hours
before the period ends; manage or cancel it in your Apple Account settings.
Privacy Policy: [privacy URL]
Terms of Use: [terms URL]
```

| Field | Value |
|---|---|
| Support URL | **[owner]** — a page that answers a seller, not a repository |
| Marketing URL | Optional |
| Privacy Policy URL | **[owner]** — the same URL the build carries in `PRIVACY_POLICY_URL` |
| Terms of Use URL | **[owner]** — the same URL the build carries in `TERMS_OF_SERVICE_URL` |
| Copyright | `2026 Dam Hong Duc` |

Apple shows its own standard EULA unless a custom one is supplied, and the
paywall's Terms link must resolve to whichever one is used.

## Screenshots

Required sizes, portrait, with no device frame and no claim the app does not
make:

| Display | Size | Needed |
|---|---|---|
| iPhone 6.9" | 1320 × 2868 | Yes |
| iPhone 6.5" | 1242 × 2688 | Only if 6.9" is not supplied for every locale |
| iPad 13" | 2064 × 2752 | Only while iPad stays in the device family |

Suggested order, one job per shot: Home's attention queue, Inventory with a
bulk selection, an order with its real profit, Sourcing ROI by source,
Analytics, the tax pack.

A screenshot that shows seeded demo figures is fine; one that shows a
marketplace's logo or a real buyer's details is not.

## In-app purchases

| Field | Value |
|---|---|
| Product | Premium, one entitlement, two billing periods |
| Product IDs | **[owner]** — must match the RevenueCat offering (`RELEASE_ACTIONS.md` step 7) |
| Display name | Reseller Studio Premium |
| Free trial | Yearly only, and the app quotes what the store says |
| Review screenshot | The paywall sheet, one per product |
| Review notes | Name the screen the paywall opens from: More → Subscription, and the Premium banner on Home |

Both products must be attached to the version and submitted with it, or the
build ships with a paywall that has nothing to sell.

## App Review Information

| Field | Value |
|---|---|
| Sign-in required | Yes — there is no guest mode (hard rule 1) |
| Demo account | **[owner]** — a real Google account on the production project, signed in once, with a seeded workspace so the reviewer sees rows rather than empty states |
| Notes | State that the only ways in are Sign in with Apple and Google Sign-In, that account deletion is in More → Account, and that the app connects to no marketplace |
| Contact | **[owner]** — name, phone, email |
| Attachment | Optional |

Two guideline answers the app already carries: Sign in with Apple ships
alongside Google (4.8), and account deletion is reachable in-app (5.1.1(v)).

## Version

| Field | Value |
|---|---|
| Version | Read from `pubspec.yaml`; the build number is bumped by the release lane |
| What's New | First release — a one-line "Initial release" is enough |
| Release | Manually release after approval, so the backend is live first |

## Still blocking a submission

| # | Item | Where it is tracked |
|---|---|---|
| 1 | Apple and Google brand artwork replacing the glyph placeholders | `RELEASE_ACTIONS.md` step 9 |
| 2 | Hosted Privacy Policy and Terms URLs | `RELEASE_ACTIONS.md` step 8 |
| 3 | RevenueCat products, entitlement, offering and webhook | `RELEASE_ACTIONS.md` step 7 |
| 4 | Deployed rules, indexes and Functions | `RELEASE_ACTIONS.md` step 5 |
| 5 | Demo account with seeded data on production | This file |
| 6 | Screenshots at the sizes above | This file |
