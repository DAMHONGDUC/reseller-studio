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

### v3 keeps its own chrome

`SdCollapsingFilterScaffoldV2`, `SdPinnedFilterBarV2` and
`belowPinnedFilterBar` are deliberately **not** ported — v2 lifts the filter
row into the app bar on scroll, and v3's recorded rule is the opposite. The
two search entry points (Inventory's docking header, the Search screen's plain
autofocused field) also differ on purpose. `docs/rules/DECISIONS.md` has the
reasoning; do not "finish the port". `SdFloatingBarScopeV3` is the one that
*was* ported — it is what keeps a snackbar off the glass bar.

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
| 22 | Notifications — the in-app inbox | nothing. Its route constant was deleted rather than left resolving to no screen — `docs/rules/DECISIONS.md` |
| 23 | Activity / audit log — the screen | Home has a recent-activity block reading order and item timestamps; there is no `activity/` collection and no screen. Its route constant was deleted with §22's |

## 4. Loose ends found in the code

- **`team` and `marketplaces` are read-only screens.** Both render and both
  explain why they cannot do more yet; neither is a stub that fails.
- **`lib/features/mock_data/` ships in the binary.** It is gated behind
  `DevFlags`, but it is a whole fake backend inside the app. Worth deciding
  before release whether it is compiled out.
- **The plan limits are a first proposal, not a priced decision.**
  `PlanLimits.byPlan` holds every ceiling; changing one is a one-line edit and
  the paywall copy follows, because it reads the table rather than repeating
  it. Nobody has priced these against what a reseller will pay.
- **Apple's brand mark is the one asset still missing.** The code is done —
  `SdButtonV3` has its `leading` slot and Google's own file ships in
  `assets/brand/` — but Apple's logo can only come from Apple, and the login
  screen throws until `assets/brand/apple_logo.svg` exists. The Apple button
  also renders in the app's indigo, which Apple's guidelines do not allow.
  `RELEASE_ACTIONS.md` blocker 5 has both.
- **`selleros://` deep links work on iOS only.** `Info.plist` declares the
  scheme and `FlutterDeepLinkingEnabled`; `AndroidManifest.xml` has neither,
  so the notification taps the plan calls for (§22) will not open a record on
  Android. Not on the TestFlight path, which is iOS.
- **Entitlement is not mirrored into Firestore yet.** The client reads
  RevenueCat, which is a cache for rendering. `firestore.rules` cannot ask an
  SDK a question, so the server-side half — a Cloud Function on RevenueCat's
  webhook — is blocked with the rest of `functions/` above. Until it exists,
  the gates are a UI decision and not a security boundary.
