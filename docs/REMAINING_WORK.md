# Remaining work — what is not built, and why

Grouped by *what is stopping it*, because that is what decides the order.
`DONE_WORK.md` is the other half.

Anything needing an account, a key or a card is not here — that is
`RELEASE_ACTIONS.md`, and it blocks more than this file does.

## 1. Deferred by decision

Owner has ruled on each of these. They are not oversights.

### Theme is built; language is not

Theme switching works (Settings → Appearance, light/dark/system, device-local).
**Language is listed with a "Soon" badge and no picker**, and that is the right
order: a picker offering a half-translated Vietnamese is worse than none. The
backfill below is the prerequisite.

### Localization — English only until release

New strings still go through ARB keys; only the *translation* is deferred, and
it happens in one pass at release. See hard rule 7.

**The backfill is done.** Every plain user-facing string in
`presentation/` now goes through ARB — 142 keys were added across analytics,
sourcing, expenses, reports, tax, home, subscription, search, listings and
receipts, reusing an existing key wherever one already held the same English.

The interpolated ones are done too — 13 keys carrying placeholders, with real
`plural` forms where a count is shown (`analyticsOrderCount`,
`listingViewCount`), because "1 orders" is the kind of thing nobody fixes
after launch.

**Three literals are left on purpose**, and each should stay:

- `'$count'` on Home's attention row — a bare number, with no text to
  translate.
- `'${context.l10n.orderProfitPrefix} '` — already an ARB key; the trailing
  space is layout, not language.
- The mock-data summary in Settings — developer-only, behind `DevFlags`, and
  absent from a release build.

At release, translate `app_vi.arb` in one pass **and review the 388 keys
already there**, which were written without a native speaker. The backfill
widened the gap on purpose: English is complete, `vi` is filled in once. The
product vocabulary is what needs arguing about, not the buttons:
`Offers → "Đề nghị giá"`, `Counter → "Trả giá"`,
`Sell-through → "Tỷ lệ bán hết"`. A half-translated `vi` is worse than an
English one, so do not advertise `vi` in the store listing until that is done.
listing until that is done.

### v3 keeps its own chrome

`SdCollapsingFilterScaffoldV2`, `SdPinnedFilterBarV2` and
`belowPinnedFilterBar` are deliberately **not** ported — v2 lifts the filter
row into the app bar on scroll, and v3's recorded rule is the opposite. The
two search entry points (Inventory's docking header, the Search screen's plain
autofocused field) also differ on purpose. `docs/rules/DECISIONS.md` has the
reasoning; do not "finish the port". `SdFloatingBarScopeV3` is the one that
*was* ported — it is what keeps a snackbar off the glass bar.

## 2. Cloud Functions

**Written, not deployed.** `functions/` builds and lints in CI; nothing has
been pushed to a project because that needs the Firebase setup.

| Plan § | Feature | State |
|---|---|---|
| 24 | Team invites | **Written** — `inviteMember`, `acceptInvite`, `removeMember`. Seat limit and last-owner check both need a count rules cannot take |
| 23 | Activity / audit log | **Written** — triggers on items, orders and listings. `actorId` is read from the document, never from a client |
| — | `workspaceIds` upkeep | **Written** — `onMemberWritten`. Until it is deployed, a seller only sees businesses they created, never ones they were invited to |
| 22 | Notifications | not written. FCM sends and the triggers that decide when |
| 13 | Cross-listing | not written. Every call carrying a token runs server-side (hard rule 10) |
| 14 | Marketplace integrations | not written, and blocked on per-marketplace developer accounts |
| 27 | Entitlement mirror | not written. The RevenueCat webhook is what makes a plan gate a boundary rather than a UI decision |
| — | `deleteWorkspace` | not written. Firestore does not cascade |

Marketplace OAuth secrets go in **Secret Manager**, never `env/*.json`.

## 3. Not built at all

Nothing started. Listed with what already exists to build on.

| Plan § | Feature | What is there today |
|---|---|---|
| 13 | Cross-listing | `listings` feature and the `Listing` entity exist; there is no cross-list flow |

**Activity (§23) is built** — More → Activity, read-only, fed by the triggers
in `functions/`. It is empty in every environment until those are deployed,
and its empty state is written for the ordinary reason a workspace has no
history rather than for the missing backend.
| 22 | Notifications — the in-app inbox | nothing writes a notification yet, so an inbox would be permanently empty. Its route constant is still deliberately absent — `docs/rules/DECISIONS.md` |

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
- **`selleros://` deep links now work on both platforms.** `AndroidManifest.xml`
  declares the scheme in a `VIEW` intent filter and sets
  `flutter_deeplinking_enabled`, matching what `Info.plist` has always had.
  Untested end to end — that needs a device and a real notification.
- **Entitlement is not mirrored into Firestore yet.** The client reads
  RevenueCat, which is a cache for rendering. `firestore.rules` cannot ask an
  SDK a question, so the server-side half — a Cloud Function on RevenueCat's
  webhook — is blocked with the rest of `functions/` above. Until it exists,
  the gates are a UI decision and not a security boundary.
