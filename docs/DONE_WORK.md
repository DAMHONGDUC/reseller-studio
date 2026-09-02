# Built

“Built” means implemented and covered by the mock or Firestore repository. It
does not mean production-verified; see [`../RELEASE_ACTIONS.md`](../RELEASE_ACTIONS.md).

| Area | Included | External dependency |
|---|---|---|
| Onboarding and auth | One-time intro, Apple/Google sign-in, signed-out shell, sign-out, account deletion | Firebase and provider setup |
| Home | Attention queue, overview, recent activity, Quick Access, Premium banner | Functions for live notifications |
| Inventory | Add/edit/detail, Quick Add, intake session, scanner, photos, categories, locations, bulk actions including bulk listing | Firebase Storage for uploads |
| Orders | Record sale with an optional platform fee, detail, shipping queue, settlement, returns, refunds, overdue payout chasing | None for manual records |
| Sourcing | Sources, purchases, ROI ranking, buy calculator | None |
| Listings | Marketplace prices, cross-listing records, bulk reprice/pause/end | No marketplace publishing by decision |
| Marketplaces | Seller-owned records, fee estimate, defaults, soft delete | None |
| Carriers | Business-owned records, defaults, soft delete | None |
| Analytics | Sales, profit, inventory, marketplace, category and source views | None |
| Expenses and receipts | Add/list/delete, category totals, file upload | Firebase Storage for uploads |
| Reports and tax | CSV exports, US and UK summaries and mileage, Close the books, one-action tax pack | Rates require seasonal review |
| Search | Items, orders, listings and sources | None |
| Workspace and team | Create, switch, delete, invite, role and member management | Team actions require deployed Functions |
| Notifications | Inbox, unread state, FCM registration, event pushes, per-workspace-timezone digest, twelve types with a switch each | Functions, APNs and Scheduler |
| Subscription | Free/Premium gates, monthly/yearly paywall, restore, management screen, server-enforced item and order ceilings | RevenueCat and webhook setup |
| Settings | Account, workspace, theme, debug mock-data switch | None |

## Platform foundations

| Foundation | State |
|---|---|
| Money | Integer minor units; derived profit, margin and ROI; an unreported platform fee is estimated and labelled, never zeroed |
| Missing values | Render as `—`, never `0` |
| Errors | Mapped to `AppFailure`; technical messages stay out of UI |
| Localization | English ARB complete; Vietnamese pass deferred to release |
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
