# Remaining work — what is not built, and why

Grouped by *what is stopping it*, because that is what decides the order.
`DONE_WORK.md` is the other half.

Anything needing an account, a key or a card is not here — that is
`RELEASE_ACTIONS.md`, and it blocks more than this file does.

## Where to start

Ordered by what unblocks the most, not by size:

1. **Deploy `functions/`** (owner). Fourteen are written and idle, and three
   of them are the only thing making a whole feature real: `onMemberWritten`
   keeps `users/{uid}.workspaceIds` correct, the notification triggers are the
   only writers of the inbox, and `revenueCatWebhook` is what turns a plan
   gate from a UI decision into a boundary. Deploying needs the Firebase
   project — `RELEASE_ACTIONS.md` blocker 1.
2. **Marketplace OAuth and sync**, which is what is left of §13 and §14 and is
   blocked on a developer account per platform. Cross-listing itself is built;
   what it writes is a draft, because nothing can publish to eBay yet.

**Everything the app carries is now used.** `firebase_messaging` was a
dependency nothing imported; it is wired through `PushMessaging` and the
notifications feature. Nothing in `pubspec.yaml` is dead weight for the store
questionnaire to explain.

## 1. Deferred by decision

Owner has ruled on each of these. They are not oversights.

### Language switching waits for the Vietnamese pass

Theme is built and works (Settings → Appearance, light/dark/system,
device-local). **Language is listed with a "Soon" badge and no picker.**

The English side is finished: every plain user-facing string in
`presentation/` goes through ARB, and the interpolated ones carry placeholders
with real `plural` forms where a count is shown (`analyticsOrderCount`,
`listingViewCount`) — "1 orders" is the kind of thing nobody fixes after
launch.

**Three literals are left on purpose**, and each should stay:

- `'$count'` on Home's attention row — a bare number, no text to translate.
- `'${context.l10n.orderProfitPrefix} '` — already an ARB key; the trailing
  space is layout, not language.
- The mock-data summary in Settings — developer-only, behind `DevFlags`, and
  absent from a release build.

**The backfill widened the en/vi gap on purpose.** English is complete;
`app_vi.arb` is filled in once, at release, and the 388 keys already there
were written without a native speaker and need reviewing with the rest. The
product vocabulary is what needs arguing about, not the buttons:
`Offers → "Đề nghị giá"`, `Counter → "Trả giá"`,
`Sell-through → "Tỷ lệ bán hết"`. Turning the picker on before that ships a
half-Vietnamese app, which is worse than an English one — so do not advertise
`vi` in the store listing either.

### v3 keeps its own chrome

`SdCollapsingFilterScaffoldV2`, `SdPinnedFilterBarV2` and
`belowPinnedFilterBar` are deliberately **not** ported — v2 lifts the filter
row into the app bar on scroll, and v3's recorded rule is the opposite. The
two search entry points (Inventory's docking header, the Search screen's plain
autofocused field) also differ on purpose. `docs/rules/DECISIONS.md` has the
reasoning; do not "finish the port". `SdFloatingBarScopeV3` is the one that
*was* ported — it is what keeps a snackbar off the glass bar.

## 2. Cloud Functions

`functions/` builds, lints and typechecks in CI. **Nothing is deployed** —
that needs the Firebase project, which is `RELEASE_ACTIONS.md` blocker 1.

| Plan § | Function | State |
|---|---|---|
| — | `onMemberWritten` | **Written.** Keeps `users/{uid}.workspaceIds` in step. Until deployed, a seller sees only businesses they created — never one they were invited to |
| 24 | `inviteMember`, `acceptInvite`, `removeMember` | **Written.** The seat limit and the last-owner check each need a count, and rules read one document |
| 23 | `onItemWritten`, `onOrderWritten`, `onListingWritten` | **Written.** `actorId` is read from the document, never from a client (hard rule 12) |
| 22 | `onOrderCreated`, `onOfferCreated`, `onMemberJoined` | **Written.** Each writes an inbox row per member — the actor excluded — and sends a push as a copy of it |
| 22 | `dailyDigest` | **Written.** One scheduled run: orders past their ship-by date and stale listings, one line per workspace per day. Needs Cloud Scheduler enabled |
| 27 | `revenueCatWebhook` | **Written.** Needs `REVENUECAT_WEBHOOK_TOKEN` in Secret Manager and the URL in the RevenueCat dashboard. Until it runs, `planFor` reads every workspace as Free however much the seller paid |
| — | `deleteAccount` | **Written.** Guideline 5.1.1(v) — deletes the workspaces the seller solely owns, their Storage objects and the Auth user; refuses a sign-in older than five minutes |
| — | `deleteWorkspace` | **Written.** Owner only, recent sign-in required, and it shares its teardown with `deleteAccount` so neither can forget the Storage objects |
| 14 | Marketplace OAuth and sync | not written, and blocked on a developer account per marketplace |
| 13 | Cross-listing push | not written. Every call carrying a token runs server-side (hard rule 10) |

Marketplace OAuth secrets go in **Secret Manager**, never `env/*.json`.

## 3. Not built at all

| Plan § | Feature | What is there today |
|---|---|---|
| 13, 14 | Publishing to a real marketplace | cross-listing writes a **draft** listing per platform, which is everything up to the API call. The call itself needs OAuth per marketplace, which needs a developer account per marketplace |

## 4. Loose ends found in the code

- **Apple's brand mark is the one asset still missing.** Both buttons draw
  `SimpleIcons` glyphs (hard rule 1) — redrawn trademarks that render, rather
  than a missing file that throws while the login screen builds. Google's own
  SVG ships in `assets/brand/` and stays unused until Apple's arrives, so the
  swap is one change and not two. The colour half is fixed:
  `SdButtonVariantV3.vendor` is black on light and white on dark, never the
  app's indigo. `RELEASE_ACTIONS.md` blocker 5.
- **Entitlement is mirrored by a function nobody has deployed.** The client
  still reads RevenueCat as a cache for rendering; `revenueCatWebhook` writes
  the server copy `planFor` reads. Until it is deployed *and* the dashboard
  points at it, the plan gates are still a UI decision. The webhook also needs
  the app to have identified the seller — `Purchases.logIn(uid)` at sign-in,
  without which every event arrives under an anonymous id no workspace
  matches.
- **`NavigationUtils.requireSignIn` is unreachable today**, and that is
  recorded rather than removed. Every screen with a create action sits behind
  `AuthedTab` or outside `_previewRoutes`, which
  `test/core/router/signed_out_shell_test.dart` proves. It stays as the
  backstop for the day a tab is unwrapped.
- **`lib/features/mock_data/` ships in the binary.** Gated behind `DevFlags`
  and tree-shaken from release, but it is still a whole fake backend inside
  the repo's binary. Worth an explicit decision before submission.
- **The plan limits are a first proposal, not a priced decision.**
  `PlanLimits.byPlan` holds every ceiling. **Two things are deliberately
  duplicated in `functions/`**, both for the same reason — the backend needs
  them where a modified client cannot reach: `seatsByPlan` in
  `lib/firestore.ts` (rules cannot count a collection) and
  `planByEntitlement` in `subscription/entitlement.ts`, which mirrors
  `SubscriptionProductConstant`. Changing either means changing its pair;
  there is no third place.
- **`selleros://` deep links are declared on both platforms but untested end
  to end.** There is now something that produces one — a push carries a
  `route` and `PushController` follows it — but it still needs a device and a
  real send.
- **Push has never run on hardware.** A simulator has no APNs token, so
  registration, delivery and the tap are all untested. The inbox does not
  depend on any of it: the Firestore row is written first and the push is a
  copy, so a seller who denies permission still has a notification centre.
- **The notification inbox never prunes.** It reads the most recent 50 and
  older rows simply sit there, which is the same call the audit log made.
  Worth a retention job before a workspace has two years of them.
- **CI follows the design system's `main`, not the pinned gitlink.** A green
  run proves the app builds against the tip, not against the commit this repo
  records — so CI and a laptop can disagree, and that gap is the first thing
  to check when they do.
- **`test/features/shot_tmp_test.dart` hangs the runner for 20 minutes.** It
  is gitignored and local-only; the cause is a font loader doing real file I/O
  inside a widget test's fake-async zone. Excluding `*_tmp_test.dart` takes the
  full suite from 20 minutes to 8 seconds.
- **`team` and `marketplaces` are read-only screens.** Both render and both
  explain why they cannot do more yet; neither is a stub that fails.

## 5. Keep `DONE_WORK.md` beside this file

The two are halves of one answer and they drift apart in one direction: work
lands, and only this file gets edited. It was last brought level on
23 August 2026, with notifications, cross-listing, workspace deletion and the
RevenueCat webhook.
