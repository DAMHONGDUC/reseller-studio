# Remaining work — what is not built, and why

Grouped by *what is stopping it*, because that is what decides the order.
`DONE_WORK.md` is the other half.

Anything needing an account, a key or a card is not here — that is
`RELEASE_ACTIONS.md`, and it blocks more than this file does.

## 1. Deferred by decision

Owner has ruled on each of these. They are not oversights.

### Localization — English only until release

New strings still go through ARB keys; only the *translation* is deferred, and
it happens in one pass at release. See hard rule 7.

| Feature | Strings still inline |
|---|---|
| Analytics | ~51 |
| Sourcing | ~46 |
| Expenses | ~13 |
| Home | ~11 |
| Reports | ~9 |
| Receipts, Search, Settings, Listings, Inventory | ~21 combined |

Roughly **150 user-facing strings**, counted over `presentation/screens/` and
`presentation/widgets/` only — log lines in `presentation/controllers/` stay
English forever (hard rule 8).

At release, in this order: backfill the ~150 into `app_en.arb`, then translate
`app_vi.arb` in one pass **and review the 388 keys already there**, which were
written without a native speaker. The product vocabulary is what needs
arguing about, not the buttons: `Offers → "Đề nghị giá"`,
`Counter → "Trả giá"`, `Sell-through → "Tỷ lệ bán hết"`. A half-translated
`vi` is worse than an English one, so do not advertise `vi` in the store
listing until that is done.

### A snackbar renders over the floating nav bar

Visible on all five tab screens. `SdSnackBarV3` draws into the root overlay
and sets its bottom from `SdContentPaddingV3.detailBottom`, which knows
nothing about the glass bar — so the snackbar's bottom edge lands inside the
band the bar occupies (`navBarOffset` up to `floatingBarInset`).

Nothing in `v3` can detect it: a root-overlay presenter sits above the whole
app, and `floatingBarInset` is only ever read by screens padding themselves.

**The fix is a port.** `SdFloatingBarScopeV2` is an `InheritedWidget` wrapped
once around the shell body; `insetOf(context)` returns the footprint inside it
and 0 outside, so a pushed route — which covers the bar anyway — correctly
reads zero. Port it as `SdFloatingBarScopeV3`, wrap `AppShell`, add it to the
snackbar host's bottom. It needs a **new component in
`packages/system_design`**, which `CLAUDE.md` says to ask about first.

### v3 keeps its own chrome

`SdCollapsingFilterScaffoldV2`, `SdPinnedFilterBarV2` and
`belowPinnedFilterBar` are deliberately **not** ported — v2 lifts the filter
row into the app bar on scroll, and v3's recorded rule is the opposite. The
two search entry points (Inventory's docking header, the Search screen's plain
autofocused field) also differ on purpose. `docs/rules/DECISIONS.md` has the
reasoning; do not "finish the port".

### Known-failing test

`test/features/screens_with_mock_data_test.dart` — *Home shows the workspace
and its real figures*. `testNow` in `test/support/pump_app.dart` is a fixed
date but `HomeScreen` reads the real `DateTime.now()`, so the seeded
`shipByDate` values drift past it as the calendar moves and the overdue count
changes. The real fix is injecting a clock into the widgets that read
`DateTime.now()`.

## 2. Blocked on Cloud Functions

`functions/` has never had `npm ci` run in it and nothing is deployed. Each of
these says so on screen rather than failing.

| Plan § | Feature | What it needs |
|---|---|---|
| 13 | Cross-listing | one item pushed to several marketplaces — every call that carries a token runs server-side (hard rule 10) |
| 14 | Marketplace integrations | OAuth and sync. `marketplaces/{id}` holds status only and is `allow write: if false` |
| 22 | Notifications | FCM sends, and the triggers that decide when |
| 23 | Activity / audit log | Firestore triggers. `activity/` is append-only and never client-writable, so a client-written log would be worthless as an audit trail |
| 24 | Team invites | server-side, so a member cap cannot be bypassed and the last owner cannot be removed |

Marketplace OAuth secrets go in **Secret Manager**, never `env/*.json`.

## 3. Not built at all

Nothing started. Listed with what already exists to build on.

| Plan § | Feature | What is there today |
|---|---|---|
| 13 | Cross-listing | `listings` feature and the `Listing` entity exist; there is no cross-list flow |
| 20 | Tax — categories, deductible expenses, mileage, tax reports, year-end summary | nothing. Expenses and Receipts are the data it would read. **Country-specific and configurable** by the plan, so it is not a small feature |
| 22 | Notifications — the in-app inbox | route constant only, see below |
| 23 | Activity / audit log — the screen | Home has a recent-activity block reading order and item timestamps; there is no `activity/` collection and no screen |
| 27 | Monetization — Free / Pro / Business, and §25's Subscription settings | nothing. No paywall, no plan gating, no RevenueCat or equivalent. Adding one needs approval first |

## 4. Loose ends found in the code

- **Three route constants are declared and never wired**:
  `AppRoutes.notifications`, `AppRoutes.activity`, `AppRoutes.returns`
  (`lib/core/router/app_routes.dart`). Zero usages anywhere. They are
  placeholders for §22, §23 and a returns screen that folded into order
  detail. Either wire them or delete them — a route constant that resolves to
  nothing is a deep link that fails silently.
- **`team` and `marketplaces` are read-only screens.** Both render and both
  explain why they cannot do more yet; neither is a stub that fails.
- **`lib/features/mock_data/` ships in the binary.** It is gated behind
  `DevFlags`, but it is a whole fake backend inside the app. Worth deciding
  before release whether it is compiled out.
