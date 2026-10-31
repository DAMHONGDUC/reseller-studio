# Built

“Built” means implemented and backed by the mock or Firestore repository — not verified in production ([`RELEASE_ACTIONS.md`](../release/RELEASE_ACTIONS.md)).

| Area | Included | External dependency |
|---|---|---|
| Onboarding and auth | One-time intro, Apple/Google sign-in, guest mode on a local store, sign-out, account deletion | Firebase and provider setup |
| Home | Attention queue, overview, recent activity, Quick Access, Premium banner, info button to About | Functions for live notifications |
| Inventory | Add/edit/detail, Quick Add, intake session, scanner, photos, inline categories and locations, buying-trip link, bulk actions incl. bulk listing and filing under a trip | Firebase Storage for uploads |
| Orders | Record a sale with platform order number and optional payout; bundles, detail, shipping queue, settlement, returns, refunds, overdue payout chasing, payout report import; dropship supplier orders with tracking, refunds, days waiting, estimated arrival; search by item, buyer, order number, tracking or platform | None for manual records |
| Sourcing | Sources, purchases, items filed under a purchase, receipt split across them, ROI ranking, buy calculator, dropship suppliers and products, List it as a dropship item, primary and backup supplier per item | None |
| Listings | Marketplace prices, cross-listing onto the business's marketplaces, bulk mark-live/reprice/pause/end, bulk pricing rules, price history per item | No marketplace publishing yet (`docs/plans/DROPSHIPPING_PLAN.md`) |
| Marketplaces | Seller-owned records, fee estimate, defaults, soft delete | None |
| Carriers | Business-owned records, defaults, soft delete | None |
| Analytics | Sales, profit, inventory, marketplace, category and source views; dropship view (stocked vs dropshipped, product ranking, supplier timing); custom day range beside fixed periods | None |
| Expenses and receipts | Add/list/delete, category totals, file upload | Firebase Storage for uploads |
| Reports and tax | CSV exports and one-action tax pack, both Premium; US and UK summaries and mileage; Close the books | Rates need seasonal review |
| Search | Items, orders, listings, sources | None |
| Workspace and team | Create, switch, delete, invite, roles, members | Team actions need deployed Functions |
| Notifications | Inbox, unread state, FCM registration, event pushes, digest in the workspace's timezone, twelve types each with a switch | Functions, APNs, Scheduler |
| Subscription | All free except export (every CSV and the tax pack); ceiling machinery kept, Free set to unlimited; monthly/yearly/lifetime paywall, restore, management screen | RevenueCat and webhook setup |
| More → General | First section on More, replaces Settings: account / sign in, subscription, theme, language, notifications, about (reselling and dropshipping guides), support, sign out, delete account; dev mode adds seed demo data and delete all data | None |
| More → Sync status | Card at the top of More: synced, syncing (writes queued), or this device only for a guest | None |

## Platform foundations

| Foundation | State |
|---|---|
| Money | Integer minor units; profit, margin, ROI derived; an unreported platform fee leaves profit blank — never estimated, never zeroed (hard rule 3) |
| Missing values | Render as `—`, never `0` |
| Errors | Mapped to `AppFailure`; technical messages stay out of UI |
| Localization | Seven locales — en, es, fr, de, pt, zh, vi — every ARB complete, pinned by a test |
| Design system | v3, light/dark themes, shared spacing and chrome |
| Backend | Firestore repositories, rules, indexes, Cloud Functions written |
| Deep links | `selleros://` registered on iOS and Android |
| CI | App analyze/tests; Functions lint/build/rules tests |
| Store assets | App icons, launch screen, iOS permission strings |

## Manual release checks

| Check | Device/environment |
|---|---|
| Apple and Google sign-in | Store-signed real devices |
| Fresh workspace creation | Real Firebase project |
| Invite, role change, removal | Two real accounts after Functions deploy |
| Push delivery and deep-link tap | Real iOS and Android devices |
| Offline writes | Airplane mode |
| Missing-cost figures | Any build |
| Bulk actions on 20+ records | Any build |
| Dark cold start | Real device in dark mode |
