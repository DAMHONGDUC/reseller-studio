# CLAUDE.md — Reseller Studio

Read `SELLER_OS_FINAL_MASTER_PLAN.md` for the full product spec before making
any architectural decision. It is the product authority; this file is the
engineering one. `docs/DATA_MODEL.md` is the authority on what is stored.

**Every rule the owner states goes into the rulebook, in the same turn it is
stated.** A rule that lives only in a chat is gone by the next session — write
it with its reason, before doing the work it governs. Which file it goes in
depends on how wide it is:

| The rule applies to | It goes in |
|---|---|
| every change in the repo | this file |
| one topic — tests, commands, the design system | `docs/rules/<TOPIC>.md` |
| one feature | `lib/features/<feature>/CLAUDE.md` |

**Any edit to this file or to anything under `docs/rules/` gets its own
commit, immediately** — never folded into the change it governs. A rule that
arrives inside a 40-file feature commit is a rule nobody reviewed.
Message: `docs: update docs - detail is <what changed>`.

**A hard rule is cited by number, never restated.** Write "hard rule 9", not
the rule again in your own words. One list, one number, referenced from
everywhere — that is what stops the same constraint living in four files and
drifting in three of them. A file that repeats one says why it is repeating it,
the way `docs/rules/PRIVACY_AND_SECURITY.md` does.

**Numbers live in code; a document points at the field and never repeats the
value.** Write `` `listItemGap` ``, never `` `listItemGap` (12) ``, anywhere
outside the class that defines it. A number copied into a sentence goes stale
silently — the sibling app's prose still claims a gap the code stopped using,
and nobody noticed because prose does not fail to compile.

**A document created by hand gets a sample in `sample_data/`, in the same turn
it gains a field.** Owner's rule. `app_config` is typed into the Firebase
console, so the only record of what a correct one looks like was a code block
in a doc that nobody diffs — `sample_data/<collection>/<documentId>.json` is
that record, with every field present including the optional ones.
`docs/DATA_MODEL.md` stays the authority on what a field *means* and which way
it fails; the sample only says what a filled-in document looks like. Nothing
reads these files, and nothing may start to: a fixture a test depends on is a
file that stops being a reference the first time a test needs it to be
something else.

**Every document in this repo is written in English, in full.** `CLAUDE.md`,
everything under `docs/`, every `README.md`. No mixed-language paragraphs and
no untranslated quotes. The app's user-facing strings are the exception and
the opposite: those live in ARB files and ship in both locales (hard rule 7).

**Explaining a change means showing before and after — of the behaviour, not
of the code.** Owner's rule. The two halves are what the app did and what it
will do: the rule that was in force, the number the seller saw, the screen
that was blocked. A patch is not an explanation — the owner is deciding
whether the new behaviour is right, and a diff makes them compile it in their
head first. Name a symbol or a file only as the address of the change, never
as the body of it.

**And the pair is a table.** Owner's rule: two columns, before and after, one
behaviour per cell, the effect on the line below. Side by side is what makes
the halves comparable — stacked prose makes the reader carry the first half in
their head while reading the second.

**An explanation goes straight to the point.** Answer the question that was
asked, then stop. Don't re-establish what the owner already knows, don't pad
with background they did not ask for, and don't narrate the options that were
not taken. Two labelled rows and a sentence each beat three paragraphs saying
the same thing.

**`env/` is off limits, with exactly one exception: `env/env.example.json`.**
Owner's rule. Never read, write, move or rename anything else in there —
`dev.json` and `prod.json` are the owner's filled-in config, and no session
needs to see them to change what the app reads. The template is the opposite
case: it holds no value anyone filled in, it *is* the list of keys a build
takes, and it is what goes stale the moment `AppEnv` grows a getter — so it is
maintained like any other source file in this repo.
The tool permissions are the wider boundary, and a denied path is a decision
rather than an obstacle to route around — `git mv`, `git show` and a shell
heredoc all reach a file the deny rule covers, and reaching for one of them
because the file tool refused is the same act with an extra step. If a change
needs something in there, say exactly what is needed and stop. The owner
makes it.

## Where the rest of the rules live

This file holds only what applies to every change. Everything else loads when
it is relevant. Read the file in the right-hand column *before* doing the work
in the left.

| Working on | Read |
|---|---|
| `packages/system_design/`, or any screen or widget rendering `Sd*` v3 components | `docs/rules/DESIGN_SYSTEM.md` |
| a screen's app bar, status bar, scrolling list, empty state or search mode | `docs/rules/SCREENS.md` |
| a layout that has to survive a window wider than a phone — the shell, a body's width, a list's column count | `docs/rules/RESPONSIVE.md` |
| `firestore.rules`, `firestore.indexes.json`, `functions/`, or a `data/` method that queries or calls out | `docs/rules/BACKEND.md` |
| a build-time key, `lib/core/config/app_env.dart`, `lib/core/config/dev_flags.dart` | `docs/rules/ENV.md` |
| `env_assets/`, `packages/system_design/tool/prepare-env.sh`, `packages/system_design/tool/build-ipa.sh`, `ios/fastlane/`, the release workflow | `docs/rules/RELEASE.md` |
| running, building, generating or deploying | `docs/rules/COMMANDS.md` |
| writing or fixing a test | `docs/rules/TESTING.md` |
| anything that reads a key, logs, exports or uploads | `docs/rules/PRIVACY_AND_SECURITY.md` |
| anything that looks like missing infrastructure — Firebase, signing, icons | `docs/rules/SETUP.md` |
| asking *why* a rule exists before changing it | `docs/rules/DECISIONS.md` |
| asking what is already built, or what is left and why | `docs/DONE_WORK.md`, `docs/REMAINING_WORK.md` |
| a document created by hand in the Firebase console | `sample_data/README.md` |
| anything in `lib/features/seed_data/` | `lib/features/seed_data/CLAUDE.md` (loads on its own) |
| anything in `lib/features/workspace/` | `lib/features/workspace/CLAUDE.md` (loads on its own) |

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

**Do not build Reseller Studio as a collection of screens.** Build connected
workflows. A screen that shows data but does not lead to the next step in that
chain is a screen that will be redesigned.

**The launch markets are the United States and the United Kingdom.** Owner's
rule, and it is the answer to every "which country?" question the plan leaves
open — most of all §20, whose tax rules it says must stay country-specific.
Two jurisdictions ship: `us` and `uk`. The point of the rule is not that
others are forbidden; it is that a third one is **added as data behind the
same interface**, never by widening an `if` at a call site. Anything that
hardcodes one country's category names, its tax year boundary or its mileage
rate is the bug this rule exists to stop.

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
  generation. See `docs/rules/DESIGN_SYSTEM.md`.
- **Charts**: `fl_chart`. **Scanning**: `mobile_scanner`. **Photos**:
  `image_picker`.
- **Typography is Inter, bundled in `assets/fonts/`** — not `google_fonts`,
  which downloads on first launch and would show a seller with no signal a
  fallback face. Two families: `Inter` for text, `Inter Display` for the
  headline styles only, because a text face set at 28sp reads loose and a
  display face at 12sp reads cramped. The scale, its optical tracking and its
  line heights are in `AppTheme._textTheme`.
- **Deep links use the `selleros://` scheme**, declared on both platforms —
  `ios/Runner/Info.plist` (`FlutterDeepLinkingEnabled`) and
  `android/app/src/main/AndroidManifest.xml`
  (`flutter_deeplinking_enabled` plus a `VIEW` intent filter). `selleros:///orders/ord-4` opens that order —
  what the plan's notification taps (§22) need.
  why: see `docs/rules/DECISIONS.md` § Deep links hard-crash until Firebase
  is configured
- **iOS minimum is 15.0**, raised from Flutter's template default of 13.0.
  Not a preference — the Firebase Swift packages refuse to link below it
  (`the package product 'cloud-firestore' requires minimum platform version
  15.0`). Lowering it back breaks the iOS build outright.
- Prefer boring, well-maintained pub.dev packages (>1k likes, recent commits)
  over clever ones. **Ask before adding any new third-party service, SDK or
  analytics tool.** An exception to that bar is fine and gets its reason
  written into `docs/rules/DECISIONS.md` in the same turn — otherwise the next
  session reads an odd dependency as an accident and swaps it.

## Repo layout

Feature-first clean architecture. Layers inside every feature use fixed
subfolder names:

```text
lib/
  core/                    # cross-cutting only, NO business logic
    bootstrap/             # guarded zone + Firebase init
    error/                 # AppFailure, FailureMapper
    extensions/            # context.l10n
    logging/               # FirebaseCrashReporter — the logger is shared
    router/                # AppRoutes, app_router.dart
    theme/                 # AppColors, AppTheme — the app owns the palette
    widgets/               # AppShell, SplashScreen
  l10n/                    # ARB files (+ generated gen/, gitignored)
  features/
    <feature>/
      domain/              # pure Dart, no Flutter imports (one exception below)
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
packages/system_design/tool/ # shared melos script bodies (submodule)
sample_data/               # one JSON file per hand-created Firestore document
docs/
```

`onboarding` is the one feature the plan does not name — it is the pre-auth
intro flow, added by the owner, and hard rule 1 governs it. The rest come from
the plan's navigation tree (§38): `auth`, `workspace`, `home`,
`inventory`, `orders`, `analytics`, `more`, and later `sourcing`, `listings`,
`expenses`, `reports`, `search`, `notifications`, `team`, `settings`,
`marketplaces`, `subscription`.

**Create a layer folder only when it gets its first file** — no empty
placeholder folders.

**How an enum is displayed lives on that enum, in its own file.** Owner's
rule, and the one place `domain/` is allowed to import Flutter.
`ItemStatusDisplay` and `ItemConditionDisplay` in
`inventory/domain/enums/item_status.dart` carry **both** halves —
`String label(BuildContext)` and `Color color(BuildContext)` — so a value is
asked and there is exactly one answer, and adding a case breaks the switches
that hand them out. A presenter class holding the same switches is what this
replaced, and it is the shape that let a badge and a tag drift apart.

- **Display only.** No widget, no repository, no provider: an extension that
  says what a value *looks like* and *reads as*, and nothing else. Everything
  else in `domain/` stays pure Dart.
- **The strings still come from ARB through `context.l10n`** (hard rule 7).
  What moved is where the switch lives, not where the words are written.
- The palette comes from `AppColors` through `AppTagHue`, because the app owns
  it (`docs/rules/DESIGN_SYSTEM.md`, which carries the rest of this rule).

**Never index a palette by number.** Owner's rule. `ItemStatus.draft => 7` said
nothing about what 7 was and made the reader count list entries to find out;
`AppTagHue.grey` says it. Any set of colours a switch chooses from is a named
enum, never a list plus an index.

**Dependency rule**: `presentation → domain ← data` inside a feature. Across
features, import only another feature's `domain/` or its `providers.dart`,
never its `data/` or `presentation/`.

## Configuration and secrets

**Nothing in `env/` is secret.** `--dart-define-from-file` compiles the JSON
into the binary; anyone with the `.ipa` can read it. Firebase api keys and app
ids are fine — they are public identifiers protected by `firestore.rules`, not
credentials. **Marketplace OAuth secrets are not** (hard rule 10): they live in
Secret Manager and are read only by Cloud Functions. A test rejects any key
whose name contains `SECRET` or `PRIVATE`.

**`AppEnv` says what was asked for; `DevFlags` says what is allowed.** The
dev switches are read from the env file but every one is ANDed with
`!kReleaseMode` in `DevFlags`, so a `prod.json` with a switch turned on still
ships an app without it. Read the guarded flag, never the raw `AppEnv` value
behind it.

## Hard rules

1. **Login is mandatory to _use_ the app. There is no guest mode.** Plan
   principle 1. While auth state is still resolving the app shows the splash,
   never the login form: flashing a login screen at a returning user is the
   most common way this gets it wrong.

   **The shell renders before sign-in, and four of the five tabs show one
   shared view** — owner's rule, and the one place this hard rule has been
   rewritten rather than extended:
   - **Home, Inventory, Orders and Analytics are wrapped in `AuthedTab`** and
     show `SignedOutView` — a single centred sign-in prompt. **Never let one
     of them render its own empty state instead.** "You have no orders" is a
     claim about the seller's business; the truth is that nobody has said
     whose business to show. Same idea as hard rule 5, one level up.
   - **More is deliberately not wrapped**, and signed out it lists **Settings
     alone** — every other destination is a view onto a business that has not
     been named. Settings is in `_previewRoutes` because theme and language
     belong to the device, not to an account.
   - **`NavigationUtils.requireSignIn` is a backstop, not the gate.** Nothing
     reaches it today: every screen with a create action is behind `AuthedTab`
     or outside `_previewRoutes`, which
     `test/core/router/signed_out_shell_test.dart` proves. It stays because
     the day a tab is unwrapped or a signed-out action is added, one guard is
     what stops that becoming a hole. **Never write `if (isSignedIn)` at a
     call site** — the old rule's point holds: no screen decides for itself.
   - **The router refuses anything that names a record.** A detail route,
     search and workspace setup all need an account, so a signed-out visitor
     is bounced to Home.
   - **No business data is readable, and that is enforced below the UI.**
     `WorkspaceGuard` keeps every business stream empty without a workspace,
     so nothing depends on a widget having remembered to hide something.
   - **`firestore.rules` is unchanged and is still the real boundary.** The
     signed-out shell is a UI state, never a permission.

   `test/core/router/signed_out_shell_test.dart` pins which tabs are wrapped
   and what More offers.

   `test/core/router/onboarding_precedes_login_test.dart` pins the order.

   **One screen comes before the gate: the intro flow.** Owner's rule.
   `/onboarding` runs once per install and then hands over to `/login` — it
   describes the product and reads nothing, so it is not a way in and does not
   soften this rule. Three things keep it that way, and a change to any of
   them is a change to the gate:
   - it is only ever shown to someone **not signed in**, so a returning seller
     is never re-introduced to a product they already pay for;
   - it navigates nowhere itself — finishing flips
     `onboardingStatusProvider` and the same `redirect` decides what happens
     next, so there is still exactly one place that knows where a person lands;
   - **skipping counts as finishing.** A seller who does not want the tour is
     not asked twice, and the flag is device-local
     (`PrefsKeyConstant.onboardingSeen`) because it is about this install, not
     this account.

   Until preferences resolve the status is `loading` and the app shows the
   splash — the same reason as auth above, in the other direction: defaulting
   to "not seen" would flash the intro on every cold start.
   `test/core/router/onboarding_precedes_login_test.dart` pins the order.

   **The development bypass is gone, and nothing replaces it.** It entered
   the app as a fake signed-in user because the login screen was otherwise a
   dead end before Firebase existed. The five tabs now render empty without an
   account, so that reason expired and the flag went with it — `bypassAuth`,
   `bypassUid`, `BYPASS_AUTH` and the `AUTH OFF` banner are all deleted. **Do
   not reintroduce one.** To put rows on screen, sign in and seed a workspace
   from More → Settings → Developer.

   **A build with no Firebase resolves to signed OUT, never signed in.**
   `firebaseReadyProvider` is checked before anything touches
   `FirebaseAuth.instance`, which throws `[core/no-app]` when
   `Firebase.initializeApp` has not run — and `AppBootstrap` skips that when
   the build carries no config. Without the guard the first read of auth state
   takes the app down before its first frame; with it, an unconfigured build is
   simply a signed-out one. `test/core/config/dev_flags_test.dart` holds both
   halves: no fake uid anywhere, and no path that answers "signed in" without
   an account.

   **There are exactly two ways in: Sign in with Apple and Google Sign-In.**
   Owner's rule, and it narrows plan §26. There is **no email/password**, no
   sign-up form, no password reset and no email verification — so there is no
   password for this app to store, no reset flow to secure, and no "forgot
   password" support load. It also removes the two screens (sign-up, reset)
   that the plan's §28 field lists were written for; those lists no longer
   apply to authentication.
   - Both providers ship, and Apple is not optional: App Store guideline 4.8
     requires Sign in with Apple wherever a third-party sign-in is offered.
     Shipping Google alone is a review rejection.
   - **Neither works until the owner configures it** — an OAuth client for
     Google, a Services ID and key for Apple. Until then the buttons are the
     only way in and no account can be created; the app opens on the
     signed-out shell. See `RELEASE_ACTIONS.md`.
   - **Both marks are `SimpleIcons` glyphs, passed as `SdButtonV3.icon`** —
     owner's rule, restated after Google's own SVG was wired in and taken back
     out. A font cannot fail to load, and that is the point: the buttons once
     drew vendor SVGs from `assets/brand/`, Apple's file has never existed,
     and `SvgPicture.asset` threw *while the login screen built*, costing the
     seller Google as well — the whole gate, over one missing asset. Neither
     button is an exception, including the one whose artwork does ship:
     **two buttons drawn two different ways is the state where only one of
     them can break.** `test/features/auth/login_screen_test.dart` pins that
     both render and nothing throws.
     **A glyph is a redrawn trademark and does not pass Beta App Review**, so
     the vendors' own artwork goes back before an external build — both at
     once. `RELEASE_ACTIONS.md` blocker 5 holds both links, and
     `SdButtonV3.leading` is the slot that takes them.
   - **Both buttons wear `SdButtonVariantV3.vendor`, never `primary`.** Apple
     allows its sign-in button in black, white, or white with an outline and
     nothing else, so the app's indigo was a rejection sitting on the first
     screen a reviewer opens. The variant's colours are literal black and
     white and the app's palette cannot reach them — that is what stops a
     theme change quietly re-tinting somebody else's trademark.
   - A cancelled sign-in is **not** an error: the seller closed a sheet. It is
     logged as info and shows no message.

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

   **And never estimate one either.** Owner's rule, and the half this app is
   built on: a platform's fee is measured, never guessed from a published
   rate. What the seller records is what the platform actually paid —
   `orders.payoutMinor` — and the fee falls out of it as
   `salePrice - refund - payout - shippingCost`, the same statement read
   backwards. A rate table tops out near 95% on the one platform that already
   shows the seller the true number, and it goes stale every time a
   marketplace reprices; an order with no payout renders `—` (hard rule 5)
   rather than a plausible figure nobody can tell apart from a fact.
   - **A rate survives in exactly one place: before a sale exists.** Sourcing
     has nothing to measure — the item is still in the shop — so
     `Workspace.planningFeeRate` carries a single planning assumption for
     `PurchaseEvaluation` and the cross-list comparison. It never reaches an
     `Order`, and there is never a second one per marketplace.
   - **An order with no payout is work, not a blank.** Payouts gathers them
     and takes them in bulk (hard rule 16): the app says what needs attention
     today, and "the platform paid you and nobody wrote it down" is exactly
     that.

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

   **Until release, write English only, and do not hand-translate.** Owner's
   rule. New keys go into `app_en.arb`; `app_vi.arb` is filled in **once, in
   one pass, at release**, and every other locale with it. The reason is that
   translating a screen that is about to be redesigned pays for the same
   string twice, and a half-translated app reads worse than an English one.
   - **The ARB indirection still applies to every new string** — the rule
     above is unchanged. What is deferred is the *translation*, never the key.
     A string hardcoded in a widget now is a string nobody finds at release.
   - The keys already in `app_vi.arb` stay. Do not delete them and do not add
     more by hand.
   - `vi` translations written before this rule are unreviewed machine work.
     They are on the release checklist in `RELEASE_ACTIONS.md`, not trusted.
   - **A build offers `ResellerStudioApp.shippingLocales`, never
     `AppLocalizations.supportedLocales`.** The generator fills a missing key
     from the template, so a partial `app_vi.arb` does not fail to build — it
     ships a device set to Vietnamese an app that is two thirds English, out
     of the very translations the line above says are not trusted. The
     shipping list is English alone and grows again in the one translation
     pass at release. `test/core/shipping_locales_test.dart` pins both halves:
     what ships, and that the vi keys are still there.

8. **Every `catch` logs — handling an error is not the same as knowing it
   happened.** Call
   `SdLogger.error(LogTagConstant.<flow>, '<what failed>', error: error,
   stackTrace: stackTrace)`.
   A block that turns a failure into `null` or `false` is holding the only
   copy of what actually went wrong. Catch `catch (error, stackTrace)`, not
   `on Exception` — `Error` subtypes (a `TypeError` from a malformed document,
   a `StateError`) are not `Exception`s, so `on Exception` lets exactly the
   unexpected failures through unlogged. Never `print(...)`.
   Notable successes are logged too (`SdLogger.info` / `.action`), so an
   empty console means nothing ran rather than everything worked.

9. **Never log a credential.** No password, OAuth token, API key, or buyer
   address. `SdLogger.error` reports to Crashlytics in release, so a log line
   is the easiest way for a secret to reach a third-party dashboard. Log the
   *shape* of a failure ('marketplace token refresh failed'), never its
   contents. `SdCrashReporter.setUserId` takes a Firebase UID and nothing else.

10. **No secret ships in the Flutter binary.** Plan §14 and §32. Any call that
    uses a token happens in a Cloud Function — the app asks the backend, the
    backend asks the platform. Nothing in the app reads or stores one.
    **Marketplace connection is not a feature of this app** (owner's rule):
    there is no OAuth, no sync, and no client that talks to a platform.
    Reinstating one is a product decision, and this rule is what it would have
    to be built under.
    - **A file the seller exports is not a connection.** `PayoutCsvImport`
      reads a payout report the seller downloaded and handed over — no token,
      no account, nothing leaving the device. It is the honest way to collect
      the figures this app measures rather than guesses (hard rule 3), and it
      is the only import there is.
    - **An importer reads the columns it needs and no others.** A marketplace
      export carries buyer names and addresses; two values are taken from each
      row and the rest is never held or logged (hard rule 9).

11. **Workspace membership is the only ACL, and nobody edits their own
    membership document.** `firestore.rules` decides everything from
    `workspaces/{id}/members/{uid}.role`. Without that self-edit clause a
    member could promote themselves to owner, and every other rule is decided
    by that document.

11b. **A seller can belong to several businesses, and switching is a write —
    never local state.** Owner's rule. `setLastWorkspace` writes
    `lastWorkspaceId` on the user's own document; the profile stream carries it
    back and `resolvedWorkspaceId` picks it up, which every business provider
    is already watching. A "currently selected workspace" held in a controller
    would be a second answer to the same question, and a teammate removing you
    from a business could contradict it.
    - **`UserProfile.workspaceIds` is the list, and it is not queryable.**
      `firestore.rules` scopes member reads to one workspace at a time on
      purpose, so "which businesses am I in?" has no server-side answer a
      client may ask. A Cloud Function keeps the list in step.
    - A pointer at a business the seller has left **falls back to the first
      they still belong to** rather than stranding them on one every rule
      denies. `test/features/workspace/resolved_workspace_test.dart`.
    - The switcher is Home's title (`SdAppBarV3.onTitleTap`) opening
      `WorkspaceSwitcherSheet`. Creating an additional business is
      `AppRoutes.workspaceCreate`, a **pushed** route — deliberately not
      `workspaceSetup`, which the redirect forces new accounts through and
      then bounces them off.

12. **The audit log is append-only and written only by Cloud Functions.** Plan
    §23. An entry a client can write can name any actor it likes, which makes
    it worthless as an audit log. `allow create, update, delete: if false`.

13. **Five bottom tabs, and the list is closed**: Home, Inventory, Orders,
    Analytics, More. Plan §5 is explicit that Sourcing, Listings, Finance,
    Shipping and Offers are **not** tabs — they live under More. The More
    screen growing is fine; the bottom bar growing is a product decision, not
    a layout one.

14. **Every table is flat and top-level, modelled the way SQL would model
    it.** Owner's rule, and it **reverses "business records are nested under
    their workspace, never flat"**. One collection per entity, keyed by its
    id, with `workspaceId` and every other relationship stored as a **field**
    — never as a path segment, never as a subcollection. The reason is the
    move off Firestore: a document tree has no relational equivalent and has
    to be reshaped, while a flat collection with a `workspaceId` column
    already *is* a table, so migrating becomes an export.

    The old rule's argument was not wrong and is now a cost this one accepts
    knowingly:
    - **`workspaceId` is the whole security boundary.** A rule cannot inspect
      the result set of a query, so it must be proven from the query's own
      filters: every client query carries the filter and `firestore.rules`
      *requires* it. One forgotten `where` is a leak between two sellers, and
      nothing structural stops it any more — `WorkspaceCollections` is what
      does, so no read reaches Firestore around it.
    - **Every composite index gains `workspaceId` as its first field.** All of
      them, not some.
    - **Deleting a workspace becomes a query per table**, written once and
      enumerating every table it sweeps.
    - **A child list is a table with a foreign key.** Embed only what SQL
      would keep in a column: a value object with no identity, or a snapshot
      frozen at write time (a price as sold, a marketplace name as printed).

    **Every table is migrated.** `docs/DATA_MODEL.md` is the authority on the
    shape and on where each half of the boundary is enforced;
    `functions/src/scripts/flattenTables.ts` moves data written before the
    change.

15. **Soft-delete anything another record points at** — items, sources,
    purchases, categories, locations carry `deletedAt`. Hard-deleting a source
    orphans its purchases and destroys the ROI history the Sourcing feature
    exists to show.

16. **Bulk actions are a first-class requirement, not a later nicety.** Plan
    §7. Reprice, relist and archive are things a seller does to forty rows at
    once. A screen that only edits one item at a time is why people keep using
    spreadsheets.

17. **`system_design/v2` is never modified, and v3 never imports it.** Plan
    principles 17–19. See `docs/rules/DESIGN_SYSTEM.md`.

## Code style

How Dart in this repo is written. UI primitives live in
`docs/rules/DESIGN_SYSTEM.md`; anything feature-specific lives in that
feature's own `CLAUDE.md`.

### Structure

- Small widgets, **extract at ~80 lines**. Prefer composition over config
  flags: two booleans selecting three looks should be one enum prop.
- **No `_buildX()` methods for UI.** Do not split `build()` into helper
  methods like `Widget _buildHeader()` / `Widget _buildList()` inside a
  `State`. Extract UI into a separate widget class
  (`StatelessWidget`/`StatefulWidget`) so Flutter can scope rebuilds (const,
  keys) instead of rebuilding the whole parent — a method split is a fake
  split.
- **Split big presentation files with `part of`.** When a screen under
  `presentation/` accumulates many private child widgets, move them into
  sibling files joined via `part of` (not one giant file; `main.dart` is
  exempt). Name child files `<main_file>_<widget>.dart` — e.g.
  `home_screen.dart` + `home_screen_needs_attention.dart` with
  `part of 'home_screen.dart';`.
- **Every screen with a create action uses the same button Inventory does.**
  Owner's rule. That is `SdFabV3` in the floating-action slot — a labelled
  button that sheds its label while the list is moving and brings it back the
  moment it stops — via `AppAddFabScaffold` (`core/widgets/`), never an
  `IconButton` in the app bar. An add hidden behind a 24pt glyph in the corner
  is one a seller has to hunt for, and a create action that is hard to find is
  one they stop using. Same button, same place, every screen: Inventory,
  Categories, Locations, Sources, Purchases, Expenses.
  - `floatingNav: true` **only on the five tab screens** — a pushed route has
    nothing floating over it, and adding the inset there leaves the button
    hovering in dead space (`docs/rules/DESIGN_SYSTEM.md`).
- **One folder per screen under `presentation/screens/`.** Each screen gets
  its own subfolder named after the screen file:
  `presentation/screens/<name>_screen/` holds `<name>_screen.dart` and all of
  its `part` files. Screens never sit loose directly in `screens/`.
- **No standalone top-level functions.** Every function lives inside a class —
  a widget method, or a static/instance method on a utility class
  (`DateTimeUtils`, `MoneyFormatUtils`, `ValidatorUtils`). Never a floating
  `void doSomething() {}` at file scope. The sanctioned exceptions are
  `main()` in `main.dart`, a Riverpod provider declaration in a feature's
  `providers.dart`, and a widget's `.show()` extension.
- **No `abstract final class` — plain `final class`.** Static-only holders
  (`AppColors`, `AppTheme`, `AppEnv`, `AppRoutes`, `DevFlags`,
  `FailureMapper`, `SdSpacingConstant`, …) are declared `final class`.
  `abstract` is reserved for contracts that are actually implemented: every
  `domain/repositories/` and `domain/services/` interface stays
  `abstract interface class`.
- **`main.dart` holds `main()` and nothing else.** Startup work lives in
  `AppBootstrap` (`core/bootstrap/app_bootstrap.dart`), so the entry point
  stays a list of what happens rather than how. Anything new that must run
  before `runApp` goes there, not back into `main.dart`.
- **`AppBootstrap` is a list of `SdBootstrapStep`s and nothing else.**
  `SdBootstrap` (design system) owns the guarded zone, the ordering, the
  per-step `try`, the logging and the three framework error hooks; this app
  supplies only what comes up. A step therefore does **not** write its own
  `try`/`catch` — that is the one place in the repo where the catch rule is
  satisfied by the caller, and it is why the step list reads as a list.
  **Firebase goes first** so Crashlytics is up before anything else can fail.
- **Nothing slow goes in that list.** Every step runs **before `runApp`**,
  where the only thing on screen is the platform launch image — so work a
  seller could be shown a splash for belongs behind `SplashScreen`, the way the
  fresh-install wipe does it, not in the steps.
- **Preferences are the one exception, and the reason is the first frame.**
  `SharedPreferences` is loaded as a bootstrap step and handed to the
  `ProviderScope` as `AppBootstrap.overrides`, so `sharedPreferencesProvider`
  is `AsyncData` on its very first read. Anything that decides how the app
  *looks* is read above the splash — `themeMode` is set on `MaterialApp` — so
  there is no screen that could be shown while it loads: the app paints a
  guess and corrects it a frame later. A seller who chose dark on a light
  phone saw white first. Local plugin call, milliseconds; a network round trip
  would still not belong here.
- **A provider that decides where the app lands says "loading" while it is
  loading, retained value or not.** Riverpod carries the previous value
  forward across a rebuild, so `isLoading && !hasValue` reads as "resolved" at
  exactly the moment a dependency changed — which is how sign-in sent every
  returning seller to the create-business form for a frame.
  `workspaceStatusProvider` is the one this was found in;
  `test/features/workspace/workspace_status_test.dart` pins the transition.

### Extraction and placement

- **Specialised logic gets its own `*Utils` or helper class, on its FIRST use
  — not its second.** Owner's rule, and it sharpens the extraction rule below
  rather than repeating it: a widget's job is layout and a controller's is
  orchestration, so a calculation sitting inside either is in the wrong place
  whether or not anything else needs it yet. Date and duration math, string
  parsing and formatting, axis/grid arithmetic, filename building: all of it
  moves out. `core/utils/` when more than one feature could want it, the
  feature's own `domain/services/` when it is really domain logic. What
  legitimately stays in a widget is reading providers, wiring callbacks and
  choosing what to build; in a controller, the call sequence and its error
  handling.
- **Anything shared gets extracted — a widget, or a `*Utils` class.** The
  second copy is the trigger, not a later cleanup: duplicated UI becomes a
  widget in `core/widgets/` (or the feature's `presentation/widgets/` if only
  that feature uses it), duplicated logic becomes a static method on a
  `*Utils` class. Same in `test/` — shared setup and pump helpers live in
  `test/support/`, never re-declared per file.
- **A widget used by more than one feature lives in `core/widgets/`, always —
  and that is the only `widgets/` folder in `core/`.** The moment a second
  feature needs it, it moves: `presentation/widgets/` is for widgets that
  feature alone builds. Otherwise the importer reaches into another feature's
  `presentation/` and breaks the dependency rule. A shared widget may import a
  feature's `domain/` or `providers.dart` — core → feature is fine, feature →
  feature `presentation/` is not. Never open a `widgets/` folder elsewhere
  under `core/`.
- **Constants live in their own class, never on a model, entity, controller or
  widget.** Owner's rule. A number a class does not itself use is not that
  class's business. Reach for `core/constants/` for anything cross-cutting, a
  feature-local `*Constant` class otherwise — but never a `static const`
  bolted onto the entity or the widget that happens to be nearby.
  `PrefsKeyConstant` holds every `shared_preferences` key, so a collision
  between two features is visible rather than silent.
  - **The one exception is a widget's own intrinsic size**
    (`SdAppBarV3.toolbarHeight`, `SdBadgeV3.maxCount`) — that is what the
    widget *is*, not configuration about it. Spacing likewise stays on
    `SdContentPaddingV3`, which is itself the constants class for that job.
  - **Constants inside `domain/services/` and `data/` stay where they are**
    (`PurchaseEvaluation.defaultTargetRoi`, `StaleInventoryPolicy.defaultThreshold`):
    those classes ARE the algorithm the number belongs to, and the rule names
    models, entities, controllers and widgets. Raise it with the owner before
    widening that.
  - **A canonical empty instance** (`AnalyticsSummary.empty`) is a value of the
    type, not configuration about it — the same shape as `Duration.zero`. It
    stays.
  - **`packages/system_design` is out of scope** — it is a separate repo with
    its own `WIDGET_RULES.md`, and its statics are widget-intrinsic.
- **Read-time "now" comes from `clockProvider`, never `DateTime.now()`**
  (`core/time/app_clock.dart`). Anything a screen or a provider *derives* —
  what is overdue, what is stale, whether an offer has expired, how many days
  are left — reads the clock, so a test pins it with `FixedClock` and the same
  assertion cannot pass in June and fail in August. That is exactly how
  `test/features/screens_with_fake_backend_test.dart` broke: the seed was
  placed
  against a fixed instant and Home read the wall clock.
  - **A recorded timestamp is the opposite and stays `DateTime.now()`**:
    `createdAt`, `deletedAt`, the instant an order shipped, the default date
    on a form. Those are facts about when something happened, not figures
    computed from it, and pinning them in a test would prove nothing.
- **All date and time arithmetic goes in `DateTimeUtils`, never a second
  date-shaped utils class.** Owner's rule: clock formatting, month arithmetic
  and the time axis of a chart are one subject, and two classes is how the
  same call site ends up computing midnight two different ways.
- Repositories: interface in `domain/`, impl in `data/`; return domain
  entities, never a Firestore `DocumentSnapshot`, `Map` or DTO. The DTO is how
  `data/` talks to Firestore and it stops at that boundary.
- **Profit, margin, ROI and pricing stay pure Dart with unit tests**
  (`features/pricing/domain/services/`). This is the "insight" the product is
  judged on — test the edge cases: no cost recorded, a sale under cost, two
  currencies, a fee corrected after the fact.
- **Shared navigation lives in `NavigationUtils`** (`core/router/`). A plain
  "push this route" belongs at its call site; a move with a *rule* attached —
  an order of screens, or a condition deciding where the user lands — goes in
  `NavigationUtils` so the second caller cannot reimplement it without the
  rule.

### Controllers, logging and errors

- **No business logic in widgets.** View state and orchestration (state
  machines, save/delete/export flows, filtering) live in a
  `presentation/controllers/` Notifier or a `Ref`-backed controller; screens
  are `ConsumerWidget`s that watch state and call controller methods. Dialogs
  and snackbars stay in the widget.
- **Controllers log their own failures: process first, print the error if one
  lands.** Every `presentation/controllers/` method that touches a repository,
  service or platform plugin wraps its work in `try` /
  `catch (error, stackTrace)`, calls
  `SdLogger.error(LogTagConstant.<flow>, '<what failed>', error: error,
  stackTrace: stackTrace)`, then `rethrow`s — the log is an extra pair
  of eyes, never a replacement for the caller's error handling. Plain
  `try`/`catch` inline, always: no closure-taking wrapper (an
  `SdLogger.guard(action)`-style combinator hides the flow), and never
  `print(...)`. Cancellation is not a failure. Controllers that only hold
  state have nothing to catch and stay bare.
- **The logger is `SdLogger`, it comes from the design system, and every call
  names its flow first.** Owner's rule. It lives in
  `packages/system_design/lib/core/common/` and is imported from
  `package:system_design/common.dart` — a pure-Dart entrypoint, so a
  `domain/` file can log without pulling Flutter in. The app owns no logger of
  its own; what it owns is the vendor half (`FirebaseCrashReporter`) and the
  flow list.
  - **The first argument is a required tag from `LogTagConstant`**
    (`core/constants/log_tag_constant.dart`), printed ahead of the message:
    `Login - Signed in — {uid: 3f9…}`. A console interleaves every flow at
    once, and the tag is what lets one be read back on its own.
  - **A tag names the flow, never the verb.** The message already says what
    happened ('Delete item'); `Item - Delete item` is the pair that makes
    filtering on `Item - ` return the whole story.
  - **Never type a tag at a call site.** 'Login' and 'login' are one flow to a
    reader and two to a text filter. A new flow gets a constant first.
- **Every action in the app logs, and it logs the DATA with it.** Owner's
  rule, and it is the widest of the logging rules — the ones below sharpen it
  rather than compete with it. Every API call, every user tap, every submit: a
  line on the way in with what was sent, and a line on the way out with what
  came back.
  - **A log without its data is a log that cannot answer anything.** "Sync
    failed" tells you a sync failed; "Sync failed — {collection: orders,
    pushed: 12}" tells you which one and how far it got. So
    `SdLogger.action('…', data)` and `SdLogger.info('…', data)` always carry
    the payload, the id, the count — whatever the next person would have to
    reproduce the run to find out. **Never the value of a credential or a
    buyer address** (hard rule 9): log the shape, the key name, the count.
  - **An error logs the FULL error and the response**, not a message about it.
    `SdLogger.error(message, error: …, stackTrace: …, data: …)` — `data` is
    what the call was doing (the arguments, the collection, the record id) and
    `error` is the thing that was thrown, unmodified. A
    `FirebaseFunctionsException`'s `code`/`details` and an
    `HttpsCallableResult`'s body are exactly what is needed and exactly what a
    `toString()` of a hand-written string throws away.
  - **Success is logged too, not only failure.** An empty console must mean
    nothing ran, never "everything worked".
- **Every `catch` logs, wherever it sits — handling an error is not the same
  as knowing it happened.** Owner's rule, and it widens the one above from
  controllers to everything that catches: data sources, repositories,
  `domain/services/`, launchers, deep-link listeners. A block that turns a
  failure into `null`, `false` or a domain enum is holding the only copy of
  what actually went wrong, so it calls
  `SdLogger.error('<what failed>', error: error, stackTrace: stackTrace)`
  before returning the substitute.
  - Catch `catch (error, stackTrace)`, not `on Exception` — `Error` subtypes
    (`StateError`, `TypeError`, a failed cast) are not `Exception`s, so
    `on Exception` lets exactly the unexpected ones through untouched *and*
    unlogged.
  - Two exemptions, both narrow: a widget re-catching what its controller
    already logged (say so in the comment), and a cancellation, which is not a
    failure.
  - why: see `docs/rules/DECISIONS.md` § Why a caught error must still be
    logged
- **Crash reporting goes through `SdCrashReporter`**
  (from `package:system_design/common.dart`, wired to Crashlytics by
  `core/logging/firebase_crash_reporter.dart`): `recordError` for a caught
  failure worth seeing in production, alongside the `SdLogger.error` that
  serves the debug console. **The vendor half is the app's, and it is the only
  file that imports the Crashlytics SDK** — swapping reporters is that file
  and the one `SdCrashReporter.attach` call in `AppBootstrap`. `domain/` stays
  pure Dart — report from the presentation or data layer that catches it.
- **Analytics: every event goes through `AppAnalytics`**
  (`core/analytics/app_analytics.dart`) — a typed method per event, so the
  full inventory of what we send is one file. Never call `FirebaseAnalytics`
  directly and never type an event name at a call site. Events live next to
  the matching `SdLogger.action` in a `presentation/controllers/` Notifier,
  never in a widget's build. A credential, a buyer address or a marketplace
  token never becomes a parameter (hard rule 9).

### Syntax

- **Never use `var`.** Always declare explicit types
  (`final String name = ...`, `int count = 0`, `List<Item> items = []`).
  Prefer `final`/`const` with an explicit type. Explicit types keep reviews
  clear and prevent silent type-inference bugs. `prefer_final_locals` and
  `type_annotate_public_apis` are on.
- **Every `Text` carries an explicit `style:`.** Never lean on the ambient
  `textTheme` implicitly; read it and pass it.
- **Declarations first, blank line, then logic.** Group all
  variable/constant declarations at the top of a method with no blank lines
  between them, then one blank line before the logic block (conditions, loops,
  calls, `return`). Don't interleave — never declare, run logic, then declare
  again lower down.
- **Comments: short and plain.** One or two lines. Say *why*, not what the
  code already says — and say it in the fewest words that still land. No
  paragraphs, no essays, no restating the diff.
- **Multi-point comments are bullet lists, one `//` line per point, each
  starting with `-`.** The moment a comment needs more than one point, it
  stops being a sentence with a conjunction and becomes a list — no run-on
  `// does X, and also Y, but watch out for Z`. Each bullet stays short and
  plain per the rule above; a single-point comment stays a single plain line,
  no dash.
- **A comment is never more than 3 lines**, bulleted or not. If it needs a
  4th, the comment is doing too much — cut to the one reason that matters, or
  split it: a "why" for the line it sits on stays here, a longer "how"/design
  rationale moves into the doc comment (`///`) of the function or class it
  belongs to.

Visual and design-system rules — colour, hierarchy, depth, thumbnails,
tabular figures, motion, spacing, snackbars, dialogs and sheets — are in
`docs/rules/DESIGN_SYSTEM.md`.

## Git

- **Conventional commits, and the scope goes inline — never in parentheses.**
  Owner's rule. `feat: inventory - bulk reprice on the selection bar`, never
  `feat(inventory): …`. The scope names the part of the app that changed, and
  it never names the tool that changed it.
  - Types: `feat:`, `fix:`, `chore:`, `docs:`.
  - Commits before this rule use `feat(scope):`. History is not rewritten;
    everything from here follows the form above.
- **Commit freely; never push.** Owner's rule. Committing costs nothing and is
  local; pushing is the irreversible half and it is the owner's to call. That
  includes the `packages/system_design` submodule — commit there too, and
  leave it unpushed unless told otherwise.
- **Never add a `Co-Authored-By` trailer to a commit.** Owner's rule. The
  commit message describes the change, not who or what typed it.
- **No tool, agent or model is ever named in a commit message or a PR.**
  Owner's rule, and it is the same reason as the trailer above: no attribution
  footer, no "Generated with", no tool name anywhere in the title, the body or
  a comment. A PR describes the change; who typed it is not a fact about the
  change.
- **A PR title and description are short, plain and written as bullets.**
  Owner's rule. No prose paragraphs, no essay: a one-line title and a body
  that is a list. Anything a reviewer has to read twice is a cost, and a wall
  of text is how the line that mattered gets skipped.
  - One line per point, each starting with `-`. Group under short `##`
    headings only when the list is long enough to need them.
  - Say what changed and what it affects. Cut the reasoning that already
    lives in the commit messages or in `docs/rules/`.
- **"Prepare for PR" is a fixed sequence.** Owner's rule, and it is three
  steps in order, each reported: run the **full** test suite, not the part
  that was touched; re-read the whole branch diff and fix what it turns up —
  dead code, a stale comment, a boundary that disagrees with its mirror — and
  only then hand over a title and description. A branch is reviewed whole, so
  it is checked whole first.
- **A PR description lists the features that branch built, and nothing else.**
  Owner's rule, and it **replaces "blockers go at the top"**. No deploy steps,
  no migration order, no caveats, no test counts, no diff stats, no
  attribution footer — a reviewer opens a PR to find out what the branch does,
  and every other line is one they read past to get there. What is cut still
  has a home: `RELEASE_ACTIONS.md` holds what must happen before a build
  ships, and the commit that made a change holds why it was made.

## Definition of done

- `melos run analyze` — `--fatal-infos`, exactly what CI runs. **Must pass
  with zero findings before considering any task done.** It analyzes the
  design system standalone first, on purpose: the package must compile without
  the host app, and running it from inside the app would hide an app
  dependency leaking in.

## When unsure

- Product questions → `SELLER_OS_FINAL_MASTER_PLAN.md` first.
- What is stored, and what a field may mean → `docs/DATA_MODEL.md`.
- What may go in the design system → `packages/system_design/WIDGET_RULES.md`.
- Ask before adding a required field to any create flow (hard rule 2), before
  adding a bottom tab (hard rule 13), and before adding any third-party
  service.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **reseller_studio** (6841 symbols, 17158 relationships, 283 execution flows).

> Index stale? Run `node .gitnexus/run.cjs analyze --index-only` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? Bootstrap with `npx`, `bunx`, or `pnpm dlx` — e.g. `bunx gitnexus@latest analyze` (npm 11 npx crash; #1939).

## Always Do

- **MUST run impact analysis before editing.** Use `impact({target: "symbolName", direction: "upstream"})` (MCP) or `node .gitnexus/run.cjs impact "symbolName" --direction upstream --repo .` (CLI fallback); report callers, processes, and risk. Never substitute grep for graph analysis.
- **MUST analyze graph changes before committing.** Use `detect_changes({scope: "all"})` (MCP) or `node .gitnexus/run.cjs detect-changes --scope all --repo .` (CLI fallback). `partial: true` or `truncated: true` is not a clean check — a zero means unseen, not unaffected; re-run it. For regression review: `detect_changes({scope: "compare", base_ref: "master"})` or `node .gitnexus/run.cjs detect-changes --scope compare --base-ref "master" --repo .`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- **MUST treat `risk: UNKNOWN` as unresolved, not as low.** An empty caller set is not evidence the symbol is unused — it can also mean the callers are not resolvable by the index (plain-object property access, dynamic dispatch, cross-language calls). `impact` pairs `UNKNOWN` with a `riskNote` saying so. Confirm with a text search before treating the symbol as safe to change or delete; do not proceed on the strength of a zero.
- When exploring unfamiliar code, use `query({search_query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method before MCP/CLI impact analysis.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis, and never read `UNKNOWN` as an all-clear — it means the walk could not answer, which is the one verdict that requires confirming by other means.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit before MCP/CLI graph change analysis.

## Resources

| Resource | Use for |
| --- | --- |
| `gitnexus://repo/reseller_studio/context` | Codebase overview, check index freshness |
| `gitnexus://repo/reseller_studio/clusters` | All functional areas |
| `gitnexus://repo/reseller_studio/processes` | All execution flows |
| `gitnexus://repo/reseller_studio/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
| --- | --- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
