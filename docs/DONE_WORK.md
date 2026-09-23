# Built

“Built” means implemented and covered by the mock or Firestore repository. It
does not mean production-verified; see [`../RELEASE_ACTIONS.md`](../RELEASE_ACTIONS.md).

| Area | Included | External dependency |
|---|---|---|
| Onboarding and auth | One-time intro, Apple/Google sign-in, guest mode with a local store, sign-out, account deletion | Firebase and provider setup |
| Home | Attention queue, overview, recent activity, Quick Access, Premium banner | Functions for live notifications |
| Inventory | Add/edit/detail, Quick Add, intake session, scanner, photos, categories and locations created inline, buying-trip link, bulk actions including bulk listing and filing under a trip | Firebase Storage for uploads |
| Orders | Record sale with the platform's order number and an optional payout, bundles, detail, shipping queue, settlement, returns, refunds, overdue payout chasing, payout report import | None for manual records |
| Sourcing | Sources, purchases, items filed under a purchase, receipt apportioned across them, ROI ranking, buy calculator | None |
| Listings | Marketplace prices, cross-listing onto the business's own marketplaces, bulk mark-live/reprice/pause/end | No marketplace publishing by decision |
| Marketplaces | Seller-owned records, fee estimate, defaults, soft delete | None |
| Carriers | Business-owned records, defaults, soft delete | None |
| Analytics | Sales, profit, inventory, marketplace, category and source views | None |
| Expenses and receipts | Add/list/delete, category totals, file upload | Firebase Storage for uploads |
| Reports and tax | CSV exports and the one-action tax pack, both Premium; US and UK summaries and mileage; Close the books | Rates require seasonal review |
| Search | Items, orders, listings and sources | None |
| Workspace and team | Create, switch, delete, invite, role and member management | Team actions require deployed Functions |
| Notifications | Inbox, unread state, FCM registration, event pushes, per-workspace-timezone digest, twelve types with a switch each | Functions, APNs and Scheduler |
| Subscription | Free ceilings — items for the life of the business, orders over a rolling 30 days, one business — plus two gated capabilities (tax pack, payout chasing), monthly/yearly paywall, restore, management screen | RevenueCat and webhook setup |
| Settings | Account, workspace, theme, developer block: mock-data switch, seed demo data, delete all data | None |

## Platform foundations

| Foundation | State |
|---|---|
| Money | Integer minor units; derived profit, margin and ROI; an unreported platform fee leaves the order's profit blank — never estimated, never zeroed (hard rule 3) |
| Missing values | Render as `—`, never `0` |
| Errors | Mapped to `AppFailure`; technical messages stay out of UI |
| Localization | Seven locales ship — en, es, fr, de, pt, zh, vi — every ARB complete and pinned by a test |
| Design system | v3, light/dark themes, shared spacing and chrome |
| Backend | Firestore repositories, rules, indexes and Cloud Functions written |
| Deep links | `selleros://` registered on iOS and Android |
| CI | App analysis/tests plus Functions lint/build/rules tests |
| Store assets | App icons, launch screen and iOS permission descriptions |

## Manual release checks

| Check | Device/environment |
|---|---|
| Apple and Google sign-in | Store-signed real devices |
| Fresh workspace creation | Real Firebase project |
| Invite, role change and removal | Two real accounts after Functions deploy |
| Push delivery and deep-link tap | Real iOS and Android devices |
| Offline write behavior | Airplane mode |
| Missing-cost financial display | Any build |
| Bulk actions with 20+ records | Any build |
| Dark cold start | Real device in dark mode |
