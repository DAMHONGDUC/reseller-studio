# CLAUDE.md — Seller OS

Read `SELLER_OS_FINAL_MASTER_PLAN.md` for the full product spec before making
any architectural decision. It is the product authority; this file is the
engineering one. `docs/DATA_MODEL.md` is the authority on what is stored.

**Every rule the owner states goes into this file, in the same turn it is
stated.** A rule that lives only in a chat is gone by the next session — write
it into the section it belongs to, with the reason, before doing the work it
governs.

**Every document in this repo is written in English, in full.** `CLAUDE.md`,
everything under `docs/`, every `README.md`. No mixed-language paragraphs and
no untranslated quotes. The app's user-facing strings are the exception and
the opposite: those live in ARB files and ship in both locales (hard rule 7).

**Explaining a change means showing before and after.** Not prose about what
changed — the old code and the new one, side by side, then what the difference
does. A description of a diff is the reader taking your word for it; the diff
is the reader checking.

**An explanation goes straight to the point.** Answer the question that was
asked, then stop. Don't re-establish what the owner already knows, don't pad
with background they did not ask for, and don't narrate the options that were
not taken. Two labelled rows and a sentence each beat three paragraphs saying
the same thing.

## What this project is

A seller operating system for resellers — not an inventory tracker. The
lifecycle it exists to serve, and the sentence every feature is judged
against:

```text
SOURCE → PURCHASE → INVENTORY → LIST → SELL → SHIP → PROFIT → ANALYZE → SOURCE BETTER
```

The core UX principle, from the plan:

> The app should tell the seller what needs attention today, then make the
> action fast.

**Do not build Seller OS as a collection of screens.** Build connected
workflows. A screen that shows data but does not lead to the next step in that
chain is a screen that will be redesigned.

## Tech stack

- **Flutter** 3.44.5, pinned in `.fvmrc`. Always run through `fvm` —
  `fvm flutter analyze`, never bare `flutter`. Dart 3.12.2.
- **State**: Riverpod (`hooks_riverpod` 3.x), hand-written providers. **No
  `riverpod_generator`** — the sibling app (BaroEase) does it this way, and a
  codegen step that must run before the analyzer is honest is a cost paid on
  every provider edit.
- **Navigation**: `go_router`, one `StatefulShellRoute.indexedStack` for the
  five tabs. Every path lives in `lib/core/router/app_routes.dart`.
- **Backend**: Firebase — Firestore, Storage, Cloud Functions (TypeScript,
  Node 20), Auth, FCM, Crashlytics, Analytics.
- **No local database.** Firestore's own offline persistence is the offline
  story. This is the deliberate difference from BaroEase, which is local-first
  with Drift: health data must survive with no account, whereas a seller's
  inventory is inherently a synced business record shared with a team. Do not
  add Drift here.
- **Design system**: `packages/system_design`, a **submodule**, on its **v3**
  generation. See below.
- **Charts**: `fl_chart`. **Scanning**: `mobile_scanner`. **Photos**:
  `image_picker`.
- **iOS minimum is 15.0**, raised from Flutter's template default of 13.0.
  Not a preference — the Firebase Swift packages refuse to link below it
  (`the package product 'cloud-firestore' requires minimum platform version
  15.0`). Lowering it back breaks the iOS build outright.
- Prefer boring, well-maintained pub.dev packages (>1k likes, recent commits)
  over clever ones. **Ask before adding any new third-party service, SDK or
  analytics tool.**

## Repo layout

Feature-first clean architecture. Layers inside every feature use fixed
subfolder names:

```text
lib/
  core/                    # cross-cutting only, NO business logic
    bootstrap/             # guarded zone + Firebase init
    error/                 # AppFailure, FailureMapper
    extensions/            # context.l10n
    logging/               # AppLogger, CrashReporter
    router/                # AppRoutes, app_router.dart
    theme/                 # AppColors, AppTheme — the app owns the palette
    widgets/               # AppShell, SplashScreen
  l10n/                    # ARB files (+ generated gen/, gitignored)
  features/
    <feature>/
      domain/              # pure Dart, no Flutter imports
        entities/          # immutable models / value objects
        enums/
        repositories/      # abstract interfaces
        services/          # real domain logic (profit, ROI, pricing)
      data/
        repositories/      # Firestore/Storage/Functions implementations
        datasources/
        dtos/              # Firestore <-> entity mapping
      presentation/
        controllers/       # Riverpod Notifiers: view state + orchestration
        screens/
          <name>_screen/   # <name>_screen.dart + its part files, together
        widgets/
      providers.dart       # Riverpod wiring for the feature
functions/                 # Cloud Functions (TypeScript)
packages/system_design/    # the design system, its own git repo (submodule)
test/features/             # mirrors lib/features
tool/                      # melos script bodies
docs/
```

Features, from the plan's navigation tree (§38): `auth`, `workspace`, `home`,
`inventory`, `orders`, `analytics`, `more`, and later `sourcing`, `listings`,
`expenses`, `reports`, `search`, `notifications`, `team`, `settings`,
`marketplaces`, `subscription`.

**Create a layer folder only when it gets its first file** — no empty
placeholder folders.

**Dependency rule**: `presentation → domain ← data` inside a feature. Across
features, import only another feature's `domain/` or its `providers.dart`,
never its `data/` or `presentation/`.

## `system_design` — the design system is a separate package

Tokens and string-free widgets live in `packages/system_design`, a **separate
git repo checked out here as a submodule** (`DAMHONGDUC/system_design`), wired
in as a path dependency. There is exactly one import, and it is the index:

```dart
import 'package:system_design/index.dart';
```

**The package holds two generations and Seller OS renders on v3.**

| | `v2/` | `v3/` |
| --- | --- | --- |
| Renders | BaroEase | **Seller OS** |
| Palette | dark only | light + dark |
| Chrome | frosted glass, body scrolls behind | opaque, takes layout space |
| Context getters | `context.sdTheme` | `context.sdTheme3` |

`packages/system_design/WIDGET_RULES.md` is the authority on what may go in
the package and how it must be written. **Read it before adding to the
package.** The short version:

1. A widget belongs there only if it takes **every user-facing string as a
   parameter** and **imports nothing from this app** — no `context.l10n`, no
   provider, no repository, no router, no domain entity. Failing either test is
   not a reason to weaken the rule; it is the answer, and the widget stays in
   `lib/features/…/presentation/widgets/`.
2. One folder per widget, one `export` line in `v3/index.dart`, nothing else
   changes.
3. Nothing in the package hardcodes a colour, a font size or a dimension.

**Never touch `v2/`.** It is what a shipped app renders. If a v3 widget wants
something a v2 widget already does, copy the idea into v3 — never import it,
and never edit v2 to suit this product.

**The palette is NOT in the package — this app owns it.** `AppColors` and
`AppTheme` stay in `lib/core/theme/`. `AppTheme.light`/`.dark` hand the design
system its colours by registering an `SdThemeV3` on `ThemeData.extensions`;
package widgets read `context.colorScheme3`, `context.textTheme3` and
`context.sdTheme3` and never name a colour.

**A widget test that pumps a bare `MaterialApp` will assert** — `sdTheme3`
requires the extension. Pass `theme: AppTheme.light`, and install
`ScreenUtilInit` too, or the first `SdSpacingConstant.w16` throws.

**The submodule is a shared repo, and a v3 commit lands in the repo BaroEase
also pulls.** That is harmless — BaroEase never imports v3 — but it means a
change there is not local to this project. Commit the gitlink deliberately.

### Seller OS pays for v2's dependencies, and one of them warns on every Android build

The package declares `liquid_glass_renderer`, `fl_chart` and `auto_size_text`
for the whole package, not per generation, so this app resolves them even
though **no file under `lib/` imports liquid glass** — it belongs to v2's
frosted chrome, which v3 deliberately does not have.

The visible cost: `flutter build apk` prints
`Compiled to invalid SkSL` for `liquid_glass_geometry_blended.frag`. **It is
non-fatal — the APK builds** — and it is not a bug in this app. Do not try to
fix it by editing the package's `pubspec.yaml` to drop the dependency; that
breaks BaroEase, which actually renders those widgets.

The real fix, if the noise ever justifies it, is splitting the package's
dependencies per generation, which pub does not support in one package —
meaning it would take a second package. Not worth it for a warning. Revisit
only if it becomes a build failure.

## Commands

**Melos is the task runner** (`melos.yaml`). Installed once per machine at the
version `pubspec.yaml` pins — `dart pub global activate melos 6.3.3`. The
global and local versions must match exactly. **Melos 6, not 7/8** — 7+
requires `resolution: workspace` inside `packages/system_design`, which would
stop that package resolving in BaroEase, which is not a workspace. That
portability is the whole reason the design system is a submodule.

- `melos run set-up` — **always wipes first**, then everything a clone needs:
  submodules, `pub get` for both packages, `gen-l10n`, `npm ci` in
  `functions/`, `pod install` on macOS. Idempotent. The wipe is unconditional
  on purpose: this is the one answer to "it built yesterday and not today".
  Don't reach for it when `melos run gen` would do.
  It also puts the submodule on `main` and fast-forwards it, so the design
  system is editable in place — **what you build is whatever is on that
  branch, not what the parent commit pins.**
- `melos run gen` — after editing any ARB file.
- `melos run analyze` — `--fatal-infos`, exactly what CI runs. **Must pass
  with zero findings before considering any task done.** It analyzes the
  design system standalone first, on purpose: the package must compile without
  the host app, and running it from inside the app would hide an app
  dependency leaking in.
- `melos run test` — the Flutter test suite.
- `melos run deploy-firebase` — rules, indexes and functions. Confirms the
  project first; this reaches real users.

Running the app before Firebase exists — the app is otherwise stuck on a
login screen that cannot succeed (hard rule 1):

```sh
fvm flutter run --dart-define=BYPASS_AUTH=true
```

VS Code users: the **"Seller OS (auth bypassed)"** launch configuration in
`.vscode/launch.json` does the same thing.

## Mock data — the app runs fully before Firebase exists

**More → Settings → Mock data** swaps every repository for an in-memory one
seeded with a coherent demo business (`features/mock_data/`). It is on by
default whenever auth is bypassed, because the two go together: a bypassed
session has no project and no user, so live mode would show an empty app and
a stream of permission errors.

- `DataMode` is **persisted** (unlike the auth bypass, which is a build flag),
  because it is a setting a developer toggles from inside the running app. It
  therefore carries its own guard: `DataModeController` refuses to return
  `mock` in a release build whatever is stored, and the Settings card is
  tree-shaken out entirely. Showing a user a fake business as if it were
  theirs is worse than any crash.
- **The seed is coherent, not random.** Every item traces to a purchase, every
  purchase to a source, every order to items that existed, and the totals add
  up by hand — `test/features/screens_with_mock_data_test.dart` asserts the
  arithmetic. Random rows would fill the screens and prove nothing.
- Three properties of the seed are deliberate and must survive edits to it:
  **some items have no cost** (so `—` appears and hard rule 5 is exercised),
  **some listings are stale and one failed to publish** (so Needs Attention
  has something in it), and **one order sold under cost** (so the loss colour
  renders somewhere).
- **Nothing is persisted.** A restart re-seeds, so the dataset stays the
  known-good one the tests are written against.
- Live mode throws `UnimplementedError` from any repository provider — the
  Firestore implementations do not exist yet. That is a named, explanatory
  failure rather than a null-check crash three frames later.

Delete this feature when the real data layer is done, the same way the auth
bypass goes.

## Hard rules

1. **Login is mandatory. There is no guest mode.** Plan principle 1. The
   router's `redirect` is the entire gate — no screen checks auth for itself.
   While auth state is still resolving the app shows the splash, never the
   login form: flashing a login screen at a returning user is the most common
   way this gets it wrong.

   **The development bypass is not a guest mode and must never become one.**
   `DevFlags.bypassAuth` (`--dart-define=BYPASS_AUTH=true`) enters the app as
   a fake user. It exists because there is no Firebase project yet, so the
   login screen is otherwise a dead end and none of the app can be looked at.
   Three properties keep it honest, and a change that weakens any of them is
   a change that ships a guest mode:
   - it is `const` and ANDed with `!kReleaseMode`, so a release build contains
     `if (false)` and the tree-shaker deletes the branch — the bypass is
     *absent* from a shipped binary, not disabled in it;
   - passing the define to a release build does nothing, so the guarantee does
     not depend on who typed the build command;
   - the app wears an `AUTH OFF` banner on every route while it is on.

   `test/core/config/dev_flags_test.dart` asserts the flag is off by default.
   **Delete this bypass once real sign-in works** — it is scaffolding, and its
   reason to exist expires with "Pending setup".

2. **Create takes the minimum; a state transition takes the rest.** Plan §28
   and §29, and it is the rule the whole product's speed rests on. Quick Add
   requires **only a title**. An item does not need a price, a photo, a
   category or a source to exist. The extra requirements attach when the item
   *moves*: listing it needs a price and a marketplace, selling it needs sale
   information, shipping it needs shipment information.
   **Any new required field on a create flow needs explicit approval.** Adding
   one is the single easiest way to make this app feel like the spreadsheet it
   replaces.

3. **Never store a computed financial value.** Profit, margin and ROI are
   derived at read time from cost, sale price, fees, shipping and expenses. A
   stored profit is a number that goes silently wrong the moment a fee is
   corrected, and it will be corrected. `orders.payoutMinor` is the one
   exception because it is a fact the marketplace reported, not a derivation.

4. **Money is an integer of minor units, never a double.** Use the `Money`
   value type in `core/money/` — it stores minor units with a currency and
   refuses to combine two currencies. `19.99` is not representable in binary
   floating point and a few hundred summed rows drift visibly.
   - **`Money?` of null means "not known" and is never the same as
     `Money.zero`.** `totalOfKnown()` sums the known amounts and returns null
     when none are; it deliberately does not treat a null as zero, because
     that would claim the items with no cost were free.
   - Format through `context.money(...)`, which is the one place a nullable
     amount becomes a string and therefore where hard rule 5 is enforced.
     Compact form uses `compactSimpleCurrency`, never `compactCurrency` —
     the latter prints `USD439` instead of `$439`.

5. **Missing data renders as `—`, never as `0`.** Plan §15. A zero is a claim:
   it tells a seller they made nothing, when the truth is nobody has entered
   the cost yet. `SdStatTileV3` does this for a null value; anything computing
   its own figure must do the same.

6. **Never show the user a raw technical error.** Plan §31. Every `data/`
   method funnels through `FailureMapper.guard`, which turns any throw into an
   `AppFailure` — so `domain/` and `presentation/` are written as if
   `FirebaseException` does not exist. `AppFailure.technicalMessage` is for the
   log and Crashlytics only and must never reach a widget. The user sees
   "Something went wrong. Please try again."

7. **Every user-facing string goes through `intl` ARB files.** Two locales
   ship: `app_en.arb` (template, with `@` descriptions) and `app_vi.arb` —
   **every new key must be added to BOTH**. Access via `context.l10n`, never
   `AppLocalizations.of(context)` directly. Tooltips and semantics labels are
   user-facing strings too.

8. **Every `catch` logs — handling an error is not the same as knowing it
   happened.** Call
   `AppLogger.error('<what failed>', error: error, stackTrace: stackTrace)`.
   A block that turns a failure into `null` or `false` is holding the only
   copy of what actually went wrong. Catch `catch (error, stackTrace)`, not
   `on Exception` — `Error` subtypes (a `TypeError` from a malformed document,
   a `StateError`) are not `Exception`s, so `on Exception` lets exactly the
   unexpected failures through unlogged. Never `print(...)`.
   Notable successes are logged too (`AppLogger.info` / `.action`), so an
   empty console means nothing ran rather than everything worked.

9. **Never log a credential.** No password, OAuth token, API key, or buyer
   address. `AppLogger.error` reports to Crashlytics in release, so a log line
   is the easiest way for a secret to reach a third-party dashboard. Log the
   *shape* of a failure ('marketplace token refresh failed'), never its
   contents. `CrashReporter.setUserId` takes a Firebase UID and nothing else.

10. **No secret ships in the Flutter binary.** Plan §14 and §32. Marketplace
    OAuth, and every call that uses a token, happens in a Cloud Function.
    The app asks the backend; the backend asks eBay. `marketplaces/{id}` in
    Firestore holds connection *status* only and is `allow write: if false`.

11. **Workspace membership is the only ACL, and nobody edits their own
    membership document.** `firestore.rules` decides everything from
    `workspaces/{id}/members/{uid}.role`. Without that self-edit clause a
    member could promote themselves to owner, and every other rule is decided
    by that document.

12. **The audit log is append-only and written only by Cloud Functions.** Plan
    §23. An entry a client can write can name any actor it likes, which makes
    it worthless as an audit log. `allow create, update, delete: if false`.

13. **Five bottom tabs, and the list is closed**: Home, Inventory, Orders,
    Analytics, More. Plan §5 is explicit that Sourcing, Listings, Finance,
    Shipping and Offers are **not** tabs — they live under More. The More
    screen growing is fine; the bottom bar growing is a product decision, not
    a layout one.

14. **Business records are nested under their workspace, never flat.** See
    `docs/DATA_MODEL.md`. A flat collection makes every rule re-derive
    ownership from a field and every query carry a `where` clause; one
    forgotten clause is a leak between two sellers.

15. **Soft-delete anything another record points at** — items, sources,
    purchases, categories, locations carry `deletedAt`. Hard-deleting a source
    orphans its purchases and destroys the ROI history the Sourcing feature
    exists to show.

16. **Bulk actions are a first-class requirement, not a later nicety.** Plan
    §7. Reprice, relist and archive are things a seller does to forty rows at
    once. A screen that only edits one item at a time is why people keep using
    spreadsheets.

17. **`system_design/v2` is never modified, and v3 never imports it.** Plan
    principles 17–19. See the design system section above.

## Code style

- Small widgets, **extract at ~80 lines**. Composition over config flags: two
  booleans selecting three looks should be one enum prop.
- **No `_buildX()` methods.** A `Widget _buildHeader()` inside a `State` is a
  fake split — Flutter cannot scope the rebuild. Extract a real widget class.
- **No business logic in widgets.** View state and orchestration (state
  machines, save/delete flows, filtering) live in a `presentation/controllers/`
  Notifier; screens are `ConsumerWidget`s that watch state and call controller
  methods. Dialogs and snackbars stay in the widget.
- **Controllers log their own failures**: `try` / `catch (error, stackTrace)`,
  `AppLogger.error(...)`, then `rethrow`. Plain inline try/catch always — no
  closure-taking wrapper, which hides the flow. Cancellation is not a failure.
- **Every `Text` carries an explicit `style:`.** Never lean on the ambient
  `textTheme` implicitly; read it and pass it.
- **Never `var`.** Explicit types everywhere, `final`/`const` where possible.
  `prefer_final_locals` and `type_annotate_public_apis` are on.
- **Declarations first, blank line, then logic.** No interleaving.
- **Colour is never the only signal.** A state told by colour is also told by
  an icon, a label or a shape. `SdBadgeV3` always carries a label for exactly
  this reason — Seller OS draws a dozen states across items, listings, orders
  and offers, and a colour-only marker is a memory test.
- **Every price, cost and total uses `.tabular3`.** Proportional digits are
  why a column of money appears to shuffle sideways as it updates, and this
  app is mostly columns of money.
- Motion: `SdMotionV3` only. No widget writes a `Duration(milliseconds:)`.

## Pending setup — the owner does this by hand, don't assume it exists

- **There is no Firebase project yet.** `lib/firebase_options.dart`,
  `google-services.json` and `GoogleService-Info.plist` are all gitignored and
  absent. Run `flutterfire configure` once the project exists. Until then
  `bootstrap` catches the init failure and the app runs without a backend —
  deliberately, so a missing config is a warning line rather than a white
  screen. Use `--dart-define=BYPASS_AUTH=true` to get past login meanwhile
  (hard rule 1), and **delete the bypass when real sign-in works.**
- **`.firebaserc` does not exist**, so `melos run deploy-firebase` cannot run.
- **The v3 design-system commit is local to this machine.** It is committed in
  `packages/system_design` on `main` but **not pushed**. Push it before anyone
  else clones this repo, or their `melos run set-up` will fast-forward the
  submodule to an upstream `main` that has no `v3/` and nothing will compile.
- **Sign in with Apple and Google Sign-In are not configured** — no Services
  ID, no OAuth client, no entitlement. The login screen's buttons are inert
  and carry placeholder glyphs; both platforms require their own brand mark
  and forbid a substitute, so the real assets must land before release.
- **`functions/` has no deployed function.** `npm ci` has not been run there.
- **App icons and launch screens are Flutter's defaults.**
- **No `firebase_options.dart` means no FCM, no Crashlytics data, no
  Analytics.** Everything is wired; nothing is reporting.

## Testing priorities

Done: **(1) profit, margin, ROI and max-buy-price**, including the plan §11
worked example, and screen-level tests that assert the figures rendered
against the mock seed rather than eyeballing a screenshot.

Still to do, in order:

2. **State transitions** (plan §29) — that listing an item without a price is
   refused, and that Quick Add with only a title is not.
3. **Permissions** — that a `viewer` cannot write and that nobody can edit
   their own membership document. Firestore rules tests against the emulator.
4. **Repository boundary** — that every `data/` method maps its failures to
   `AppFailure` rather than leaking a `FirebaseException`.
5. **Widget tests** for forms and error states.

Two things about widget tests here, both learned the hard way:

- **`pumpScreen` in `test/support/pump_app.dart` pins the surface to
  1179×2556.** The default 800×600 is wider and much shorter than any phone,
  so it hides real overflows behind fake ones.
- **Warm the streams with `warmUp(container)`, not `await
  container.read(p.future)`.** The mock repositories are backed by a broadcast
  controller that never closes, so awaiting their future hangs until the test
  times out.

## When unsure

- Product questions → `SELLER_OS_FINAL_MASTER_PLAN.md` first.
- What is stored, and what a field may mean → `docs/DATA_MODEL.md`.
- What may go in the design system → `packages/system_design/WIDGET_RULES.md`.
- Ask before adding a required field to any create flow (hard rule 2), before
  adding a bottom tab (hard rule 13), and before adding any third-party
  service.
