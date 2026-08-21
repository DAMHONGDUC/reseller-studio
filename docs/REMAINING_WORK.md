# Remaining work — what is not built, and why

Grouped by *what is stopping it*, because that is what decides the order.
`DONE_WORK.md` is the other half.

Anything needing an account, a key or a card is not here — that is
`RELEASE_ACTIONS.md`, and it blocks more than this file does.

## Where to start

Ordered by what unblocks the most, not by size:

1. **Deploy `functions/`** (owner). Seven are written and idle; one of them is
   the only thing that keeps `users/{uid}.workspaceIds` correct.
2. **FCM sends and their triggers**, then the notifications inbox — in that
   order, because an inbox with no writer is a permanently empty screen.
3. **Cross-listing**, last: it needs marketplace OAuth, which needs a
   developer account per platform.

**`firebase_messaging` is a dependency nothing in `lib/` imports.** It is
there for §22 and reads as dead weight until the FCM work above lands — worth
either building or removing before submission, so the store questionnaire has
one fewer thing to explain.

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
| 22 | FCM sends and their triggers | not written |
| 27 | RevenueCat webhook | not written. It is what makes a plan gate a boundary rather than a UI decision |
| — | `deleteAccount` | **Written.** Guideline 5.1.1(v) — deletes the workspaces the seller solely owns, their Storage objects and the Auth user; refuses a sign-in older than five minutes |
| — | `deleteWorkspace` | not written. `deleteAccount` walks the subcollections already; what is missing is deleting **one** business without deleting the account with it |
| 14 | Marketplace OAuth and sync | not written, and blocked on a developer account per marketplace |
| 13 | Cross-listing push | not written. Every call carrying a token runs server-side (hard rule 10) |

Marketplace OAuth secrets go in **Secret Manager**, never `env/*.json`.

## 3. Not built at all

| Plan § | Feature | What is there today |
|---|---|---|
| 22 | Notifications — the in-app inbox | nothing writes a notification, so an inbox would be permanently empty. Its route constant is deliberately absent: a constant no route serves is a deep link that fails silently |
| 13 | Cross-listing | the `listings` feature and the `Listing` entity exist; there is no flow that pushes one item to several marketplaces |

## 4. Loose ends found in the code

- **Apple's brand mark is the one asset still missing.** Google's own file now
  draws through `SdButtonV3.leading`, and both buttons wear
  `SdButtonVariantV3.vendor` — black on light, white on dark, never the app's
  indigo. Apple's logo can only come from Apple, so that button keeps a
  `SimpleIcons` glyph: a redrawn trademark that renders, rather than a missing
  asset that throws while the login screen builds. `RELEASE_ACTIONS.md`
  blocker 5 is the one-line swap.
- **Entitlement is not mirrored into Firestore.** The client reads RevenueCat,
  which is a cache for rendering. `firestore.rules` cannot ask an SDK a
  question, so until the webhook function exists the plan gates are a UI
  decision and not a security boundary.
- **`NavigationUtils.requireSignIn` is unreachable today**, and that is
  recorded rather than removed. Every screen with a create action sits behind
  `AuthedTab` or outside `_previewRoutes`, which
  `test/core/router/signed_out_shell_test.dart` proves. It stays as the
  backstop for the day a tab is unwrapped.
- **`lib/features/mock_data/` ships in the binary.** Gated behind `DevFlags`
  and tree-shaken from release, but it is still a whole fake backend inside
  the repo's binary. Worth an explicit decision before submission.
- **The plan limits are a first proposal, not a priced decision.**
  `PlanLimits.byPlan` holds every ceiling, and `seatsByPlan` in
  `functions/src/lib/firestore.ts` is its **one deliberate duplicate** — rules
  cannot count a collection, so the seat number has to exist somewhere a
  modified client cannot reach. Changing one means changing the other.
- **`selleros://` deep links are declared on both platforms but untested end
  to end.** That needs a device and a real notification.
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

## 5. `DONE_WORK.md` is behind

It does not yet mention onboarding, the signed-out shell, multi-workspace
switching, the Activity screen, theme switching, the ARB backfill or CI.
Bring it up to date before using it to judge what exists.
