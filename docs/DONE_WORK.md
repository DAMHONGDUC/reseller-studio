# Done work — what is built

What exists and works, against both the mock dataset and Firestore. Written
against the master plan's section numbers so it can be read beside it.

**Nothing here is signed off as shipped.** None of it has run against a real
Firebase project, because there is not one yet — see `RELEASE_ACTIONS.md`.
"Built" means the screens, the domain logic and the repository implementations
are there and the mock backend drives them end to end.

## By plan section

| § | Feature | State |
|---|---|---|
| — | Onboarding — a three-page intro, once per install, before the gate | built |
| 5 | Navigation — five tabs, `StatefulShellRoute.indexedStack` | built |
| 6 | Home — needs-attention, overview figures, recent activity | built |
| 7 | Inventory — list, item detail, add/edit, Quick Add, scanner, locations, categories | built |
| 8 | Orders — list, detail, shipping queue, offers | built |
| 9 | Analytics — overview plus all six drill-downs | built |
| 10 | More | built |
| 11 | Sourcing — sources ranked by ROI, purchases, purchase detail, buy calculator | built |
| 12 | Listings — filtered by status, platform rejection messages surfaced, bulk reprice / pause / end from a selection | built; templates are the one §12 feature left |
| 13 | Cross-listing — one item onto several marketplaces, with the fee estimate per platform | built; publishes drafts, since nothing is integrated |
| 14 | Marketplaces — add, detail, edit, soft-delete, and four defaults per new business | built; seller-owned records, no integration |
| 15 | Pricing — profit, margin, ROI, maximum buy price | built, unit-tested |
| 16 | Returns / refunds — open a return, close it, optional restock | built, no separate screen |
| 17 | Expenses — add, list, totals by category, delete | built |
| 18 | Receipts — attach to a purchase or expense, with upload | built |
| 19 | Reports — CSV export of sales, inventory and expenses via the share sheet | built |
| 20 | Tax — year-end summary by form line, mileage at the published rate | built for US and UK, rates verified 16 Aug 2026 |
| 21 | Search — items, orders, listings and sources in one list | built |
| 22 | Notifications — the inbox, the bell on Home, FCM registration, the sends, and a digest for what is due, stale or running low | built; silent until the functions are deployed |
| 23 | Activity — the audit log, read-only, under More | screen built; empty until the triggers are deployed |
| 24 | Workspace — create, switch between several from Home's title, delete one, and set when it counts stock as low | built |
| 24 | Team — invite by email, accept from the workspace switcher, change a role, remove a member | built; every action is a callable, so it is silent until they are deployed |
| 25 | Settings — account, workspace, theme, mock-data switch (debug only) | built |
| 26 | Authentication — Apple and Google, sign out, delete account, signed-out shell | built, unconfigured |
| 27 | Monetization — Free / Pro / Business, limits, paywall, Subscription screen | built, unconfigured |
| 27 | Entitlement mirrored server-side — the RevenueCat webhook, and the uid it needs | written, not deployed |

## What the flows actually cover

- **First run**: onboarding (three pages, skippable, once per install) → the
  five tabs, empty → sign-in → workspace setup → Home.
- **Signed out**: the shell renders. Home, Inventory, Orders and Analytics all
  show one `SignedOutView` with a sign-in button rather than their own empty
  states; More stays itself and offers Settings alone, because theme and
  language belong to the device rather than to an account.
- **Auth**: Apple + Google sign-in, sign out, delete account, profile document
  written on first sign-in, workspace setup before Home. No email/password
  anywhere, and **no dev bypass** — it was deleted once the signed-out shell
  made it unnecessary. A build with no Firebase resolves to signed out rather
  than throwing.
- **Workspaces**: several per seller, switched from Home's title through a
  Slack-style sheet. Switching is a write to `lastWorkspaceId`, never local
  state, so a teammate's change cannot contradict it. Creating an additional
  business is its own pushed route and creates eBay, Etsy, Depop and Poshmark
  before the workspace pointer becomes visible.
- **Marketplaces**: a business owns its marketplace records. The list adds and
  opens detail; detail changes the name and estimated fee or soft-deletes the
  row, with no published-rate toggle and no OAuth state.
- **Inventory**: Quick Add takes a title and nothing else. Full add/edit form
  with photos, item detail, list on a marketplace, mark sold (which creates
  the order), reprice, move, archive, restore, soft delete, **bulk reprice /
  move / archive**, barcode scanner, categories, locations as
  warehouse → shelf → bin.
- **Orders**: detail with the full profit statement, ship with carrier,
  tracking and cost, mark delivered, open and close a return with optional
  restock, record fees and payout, shipping queue sorted by deadline.
- **Offers**: `Pending | Accepted | Declined | Expired`, accept (creates the
  order), decline, record a counter, and the discount off the asking price
  spelled out on the card.
- **Cross-listing**: from the item's action sheet — pick the marketplaces it
  is not already on, confirm one price inherited from the item, and see what
  each platform's fee would take before publishing. One write for all of
  them; the ones it is already on are shown and disabled rather than hidden.
- **Notifications**: the bell on Home carries an unread dot and opens an
  inbox. A new order, a new offer and a new teammate each write a row and send
  a push; a daily digest carries the orders past their ship-by date, the
  listings that have gone stale and stock that is running low — one line each
  rather than one push per row. Tapping a row switches to the business it is
  about and opens the record. The inbox trims itself: rows past the retention
  window are dropped a batch at a time while a delivery is already writing to
  that inbox.
- **Team**: invite by email with a role, and the invitation appears in the
  invitee's workspace switcher — the only surface it can appear on, since the
  rules scope `invites/` to the address it names. Accepting joins the business
  and opens it. An admin changes a role or removes somebody from the row's own
  sheet; your own row opens nothing, because nobody edits their own
  membership. The last owner is refused by the callable, which is the only
  place that can count the owners.
- **Listings in bulk**: long-press starts a selection, the bar reprices,
  pauses or ends every ticked row in one write. Nothing there can mark a
  listing sold — a sale is an order, and profit is derived from orders.
- **Analytics**: the overview, the profit statement, the marketplace
  breakdown, and drill-downs for sales, profit, inventory, marketplace,
  categories and sources.

## Cross-cutting things that are done

- **Money** is integer minor units through a `Money` value type that refuses
  to mix currencies. Zero-decimal currencies (VND, JPY) handled by
  `CurrencyDecimals`, not assumed to be two.
- **Every financial figure is derived at read time.** Nothing computed is
  stored, except `orders.payoutMinor`, which is a reported fact.
- **Missing data renders `—`, never `0`.**
- **Failures** map to `AppFailure` at the `data/` boundary; no raw exception
  reaches a widget.
- **Logging** through `SdLogger` — every call tagged with a flow from
  `LogTagConstant` and carrying its data — and analytics through
  `AppAnalytics`, a typed method per event. No credential, FCM token or buyer
  detail is ever a parameter.
- **Localization**: **733 ARB keys in `en`** — every plain user-facing string
  in `presentation/` goes through ARB, and the interpolated ones carry
  placeholders with real `plural` forms where a count is shown. `app_vi.arb`
  is still at 388 and is filled in once, at release, by rule — so the language
  picker is deliberately not offered yet. `REMAINING_WORK.md` has the three
  literals that stay hardcoded and why.
- **Theme**: light, dark or system from Settings, stored device-local. A
  business is shared; a phone's brightness is not.
- **Design system**: v3 on its own generation, spacing owned entirely by
  `SdContentPaddingV3`, no `MediaQuery` read for spacing anywhere in `lib/`.
  `SdFloatingBarScopeV3` wraps the shell body so a snackbar — which draws into
  the root overlay and cannot see the glass nav bar — rests above it instead
  of inside it.
- **Plans are enforced by one gate.** `PlanGate` decides every limit and
  every locked feature from the plan plus a count; `PlanLimits` is the single
  table of ceilings, and the sales copy reads it rather than repeating it.
  `PlanBlockSheet` names the ceiling that was hit before offering the upgrade.
  Billing is RevenueCat behind a repository — with no key configured the app
  hands out `UnconfiguredSubscriptionRepository` and everyone is on Free.
  The in-memory backend lets a purchase succeed, so the whole gating path is
  walkable before the store exists.
- **Tax is two jurisdictions and no branches.** `TaxJurisdiction` carries the
  year boundary (US calendar, UK 6 April), the form's line names (Schedule C,
  SA103) and the mileage rate; adding a third country is a case in two files.
  Mileage is banded over the year's total — the UK's 10,000-mile threshold —
  and each journey is rated by its own date, never by today's table and never
  by one figure for the year: the IRS changed its 2026 rate on 1 July, and a
  band holds hundredths of a minor unit because 72.5¢ is not an integer.
- **Read-time "now" is injected**, not read from the wall clock. `AppClock`
  and `clockProvider` (`core/time/`) are what every derived figure — overdue,
  stale, expired, days left — asks, so a test pins the instant with
  `FixedClock`. Recorded timestamps (`createdAt`, `deletedAt`, when an order
  shipped) deliberately still call `DateTime.now()`.
- **Cloud Functions**: fourteen written and idle — membership upkeep, the
  three team callables, account and workspace deletion, the three audit-log
  triggers, the three notification triggers, the daily digest and the
  RevenueCat webhook. They build, lint and typecheck in CI; none is deployed.
  `REMAINING_WORK.md` has what is not written.
- **CI**: `.github/workflows/ci.yml` analyzes and tests the app on every pull
  request and builds `functions/` in a separate job. It calls `tool/analyze.sh`
  and `tool/test.sh` rather than retyping them, and reads the SDK version out
  of `.fvmrc`.
- **Tests**: 278 Dart tests passing and 27 under `functions/` — the security
  rules against the emulator, plus the entitlement mapping as plain node.
  Profit/margin/ROI including the plan §11 worked example, and screen-level
  tests asserting rendered figures against the mock seed.
  `test/features/shot_tmp_test.dart` is the gitignored scratch harness and is
  excluded — it hangs by design.
- **Store assets exist.** The app icon is a price tag on the brand indigo, at
  every size iOS and Android ask for, with an Android adaptive foreground; the
  iOS launch screen carries the same mark and follows the theme, so it does
  not flash white into a dark-mode app. `NSCameraUsageDescription` and
  `NSPhotoLibraryUsageDescription` are set — without them iOS hard-crashes the
  first time the scanner or the photo picker opens.

## Things worth testing by hand first

- Sign in on a **release-signed Android build** — Google Sign-In failing only
  in release, because the release SHA-1 was never registered, is the most
  common launch-day bug in this flow.
- Creating a workspace on a fresh account: that is the sequential write the
  `firestore.rules` note in `RELEASE_ACTIONS.md` is about.
- An item with **no cost** — profit, margin and ROI must all read `—`.
- A bulk action on 20+ items.
- Airplane mode: Firestore queues the write and the app says so.
- **A `selleros://` deep link on Android.** The scheme is declared on both
  platforms now but has never been opened end to end.
- **The invite flow, once the functions are deployed** — invite, accept from a
  second account, and check the new business appears in the switcher. That
  last step is `onMemberWritten` doing its job.
- **A push, on a real device.** The simulator has no APNs token, so
  registration, the notification itself and the tap that deep-links into an
  order have never run end to end. Check the inbox row appears even with
  permission denied — that is the design, not a fallback.
- **Deleting a business you own** while belonging to a second one: the app
  should land on the other business rather than on workspace setup.
- **Theme on a device set to dark**, from a cold start: the launch screen
  should not flash light before the app resolves the stored preference.
