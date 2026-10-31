# Decisions — the history behind the rules

Rationale that justifies a rule but is not itself actionable. Nothing here is needed to write correct code; it is here so the reasoning survives and the rules it explains stay short.

## Deep links hard-crash until Firebase is configured

Explains the `selleros://` deep-link entry under "Tech stack" in root `CLAUDE.md`.

**Until Firebase is configured, any deep link hard-crashes the app**: `firebase_auth`'s iOS plugin intercepts `openURL` and constructs `Auth.auth()`, which fatals with *"The default FirebaseApp instance must be configured"*. A native crash, so `bootstrap`'s guarded zone cannot catch it. Nothing to fix here — it disappears once `flutterfire configure` has run. Don't spend an afternoon on it.

## The app bar stays opaque

Explains the opaque-app-bar rule in `DESIGN_SYSTEM.md`.

A blur there costs a shader pass on every scroll frame of a list that can run to thousands of rows; the tab bar is a fixed strip whose cost does not grow with content.

## Reseller Studio pays for v2's dependencies, and one warns on every Android build

Explains why the `Compiled to invalid SkSL` warning is not to be fixed. Referenced from `DESIGN_SYSTEM.md`.

The package declares `liquid_glass_renderer`, `fl_chart` and `auto_size_text` for the whole package, not per generation, so this app resolves them though **no file under `lib/` imports liquid glass** — it belongs to v2's frosted chrome, which v3 deliberately lacks.

- The visible cost: `flutter build apk` prints `Compiled to invalid SkSL` for `liquid_glass_geometry_blended.frag`. **Non-fatal — the APK builds** — and not a bug in this app.
- Do not fix it by dropping the dependency from the package's `pubspec.yaml`: that breaks BaroEase, which renders those widgets.
- The real fix, if the noise ever justifies it, is splitting dependencies per generation, which pub cannot do in one package — it would take a second package. Not worth it for a warning. Revisit only if it becomes a build failure.

## v3 keeps its own chrome — two v2 patterns are deliberately not ported

Owner's call. Explains "What v3 deliberately does NOT have" in `DESIGN_SYSTEM.md`, so the next session does not read the gap as an oversight and "finish the port".

The spacing rulebook (`SdContentPaddingV2`) **was** ported in full. Two neighbouring v2 patterns were not; this is the standing answer:

- **`SdCollapsingFilterScaffoldV2` + `SdPinnedFilterBarV2`.** v2 lifts the whole filter row *into the app bar* as the list scrolls. v3 does not — the recorded owner's rule: a filter strip is never part of the app bar; it is its own body widget with the body's background. **Since then:** the strip *pins* below the chrome instead of scrolling away, because chips a seller cannot reach 300 rows down are chips they scroll back up for. Pinned below is not lifted inside — v2's component is still not what v3 wants, and v3 pins with a plain `SliverPersistentHeader` it owns.
- **`SdContentPaddingV3.belowPinnedFilterBar`.** Follows from the above: it is `appBarInset` plus the strip's height, the first term is zero under an opaque bar, and nothing pins a strip over a list anyway.
- **`SdFloatingBarScopeV2`.** This one *was* ported — the exception that proves the rest are deliberate. See below.
- **Two kinds of search entry, on purpose.** Inventory and Orders use `SdSearchHeaderV3`, whose field docks into the title row on scroll. The Search screen builds a plain `autofocus` field with no collapse: that screen exists to be typed into at once, and collapsing chrome buys nothing when the list starts empty.

## The floating-bar scope was ported, and v3 asks a different question

Owner approved the new component. `SdFloatingBarScopeV3` exists because lacking it cost a real bug: a snackbar draws into the root overlay, above the whole app, so nothing in its build can tell the glass nav bar is below. On all five tab screens the card sat at `detailBottom`, its lower edge well inside `floatingBarInset` — the bar's band.

- **v3's scope returns a bool where v2's returns a double.** `insetOf` fit v2, whose snackbar host does its own bottom arithmetic from `safe.bottom`. v3 already has `SdContentPaddingV3.bottom(floatingNav: …)` — the call every tab screen makes for its last row — so the host asks `hasBarBelow` and passes the answer there, and a message rests exactly where its content does. One rulebook, no second copy of the arithmetic to drift.
- Both generations read the **caller's** context, not the entry's builder — not a style choice: the root overlay sits above the shell, so a scope inside it is invisible from there and every message would read "no bar".

## Two sibling-app rules Reseller Studio deliberately inverts

These files were ported from BaroEase's rulebook. Most of it transfers unchanged. Two rules do not, and both would look like bugs to anyone reading that rulebook beside this code — so the answer is recorded here, not re-argued.

- **"No FAB on a screen with the floating nav" — inverted.** There, the pill overlays content and eats the tap, so each tab puts its primary action in the app bar. Here the opposite is an owner's rule: **every screen that creates something uses the same `+` `SdFabV3`**, tab screens included, and `AppAddFabScaffold` lifts it clear by `floatingBarInset` so the glass never covers it. The reason is the product's, not the layout's — a seller adds inventory dozens of times a day, and a create action hidden behind a 24pt corner glyph is one they stop using. BaroEase's screens create occasionally; Inventory exists to.
- **"Local-first, account optional" — did not apply when written.** Hard rule 1 then made login mandatory with no guest mode: health data must survive with no account, whereas a seller's inventory was taken to be a synced business record shared with a team — hence no local database. **Since reversed**: the app now works with no account on a local store (hard rule 1, `docs/rules/GUEST_MODE.md`, and "Why the app stopped requiring an account" below).

## Why "now" is a provider, not a parameter

Explains the `clockProvider` rule in root `CLAUDE.md`.

The alternative — threading a `DateTime now` down from each screen's root — was rejected twice over:

- Most of the drift lives in *providers* — `staleItemsProvider`, `inventoryCountsProvider`, `visibleOffersProvider` — and a provider has no parent to take a parameter from. They would need a family keyed on an instant, recomputing for every distinct value ever passed.
- A parameter is opt-in: nothing stops the next screen calling `DateTime.now()` again. An override in `pump_app.dart` covers every screen that reads the clock, including ones not yet written.

The cost, recorded so it is not rediscovered as a bug: the clock is read at build time, so a screen left open does not re-derive "overdue" as the deadline passes. It already behaved so — this changed where the instant comes from, not when it is read.

## Three route constants were deleted rather than wired

`AppRoutes.notifications`, `AppRoutes.activity` and `AppRoutes.returns` had zero usages and no route serving their paths. Notifications (§22) and the activity log (§23) waited on Cloud Functions; returns folded into order detail (§16), so its screen was never built.

Deleted, not left, because a constant resolving to nothing reads as a working destination to the next caller and fails as a deep link without saying why. A comment sat where each was, so the gap read as a decision. **Two have since returned with their screens** — `activity` and `notifications` — the rule working as intended. `returns` stays deleted: order detail is where a return opens and closes.

## The notification is the Firestore row; the push is a copy

Plan §22 says "use FCM" — a delivery mechanism, not a design. The design: `users/{uid}/notifications/{id}` is written first, and the push is sent afterwards, best effort.

A push cannot be the notification: permission may be off, the token stale, the phone in a field with no signal, the push swiped away half-read. All four are ordinary, and in a push-only design each is a notification that never existed. Writing the row first means a seller who never grants permission still has a working notification centre — and is why `PushMessaging` answers rather than throws everywhere.

Three consequences worth keeping:

- **The inbox lives under the user, not the workspace.** A notification addresses a reader; two members of one business each get their own row and mark their own read. A shared document with a `readBy` array has every reader writing a document every other reader watches.
- **The row's words are rendered in the app, not read from the document.** A Cloud Function cannot know the reader's locale, so the stored `title` and `body` are the English push text, and the inbox builds its own line from `type` and `count` through ARB (hard rule 7). Reading the stored strings would keep the inbox English whatever the translation pass does.
- **Reminders are a digest, one per workspace per day.** Forty stale listings are one line. A seller getting forty notifications turns notifications off, leaving only the durable half working.

## Cross-listing has its own transition check

`ItemTransition.check(item, listed)` refuses an item already `listed` — right for the action it guards, exactly wrong for cross-listing: the item is on eBay and the seller wants it on Depop too.

- So `crossListCheck` is a second, narrower question — has this item left inventory, is any of it left — not a widening of the first.
- It does **not** require a price: the cross-list screen is where the price is entered, so requiring one beforehand blocks the screen that collects it — hard rule 2 backwards.
- The write moves the item's status only if it has not moved, and never touches `listedAt` on an item already live: staleness runs from the first time anything went live anywhere, so adding a marketplace must not reset that clock.

## RevenueCat is approved, and the app never sees a receipt

Owner's call, recorded because `CLAUDE.md` requires a written reason for any third-party SDK. Plan §27 allows "RevenueCat or equivalent"; this picks one. The owner holds the RevenueCat account and the App Store / Play products — none of that is in this repo.

Why not StoreKit and Billing directly: the stores disagree on almost everything a subscription needs — proration, grace periods, restore, a mid-period plan change — and the code reconciling them is where subscription billing goes wrong. That reconciliation is what is being bought.

Two constraints follow — hard rules 9 and 10 applied, not new rules:

- **The app asks RevenueCat what the seller is entitled to; it never validates or logs a receipt itself.** A receipt is a credential.
- **A Cloud Function mirrors entitlement into Firestore** from RevenueCat's webhook, because `firestore.rules` cannot ask an SDK anything. The client copy is a render cache; the server copy is what a rule reads. A client that could write its own plan is a paywall with a free bypass.

## Tax ships for two jurisdictions; the third is data

Owner's rule: the launch markets are the US and the UK (`CLAUDE.md`). Plan §20 says tax must stay country-specific and configurable — the same thing from the other side.

- A jurisdiction is a **value**, never a branch: `TaxJurisdiction` names one, and everything that differs — category list, tax-year boundary, mileage rate and tiers, the year-end summary's name — hangs off it.
- The US tax year is the calendar year; the UK's starts 6 April. A lone `DateTime(year, 1, 1)` anywhere in this feature is the bug.
- Mileage rates change yearly, set by the IRS and HMRC, so they are dated data with an effective-from date, not constants. A rate typed into a widget is a wrong deduction next April.

## Why a caught error must still be logged

Explains "Every `catch` logs, wherever it sits" in root `CLAUDE.md`. Inherited from the sibling app (BaroEase), where the rule was written after the fact — the reasoning transfers; the incident is not Reseller Studio's.

It was written after three features failed silently at once: WeatherKit answered every call `401` and the app said "no weather", the backend refused `sendTestPush`, and neither left a line anywhere. A caught error is invisible by construction — that is why it must be logged.

## A recurring expense is proposed, never posted on its own

`Expense.isRecurring` was written to Firestore and read by nothing, so the form's switch ("Happens every month") changed no behaviour. Two ways to give it meaning; the app takes the second:

1. **Post it automatically** each month — a scheduled Cloud Function, or the client writing missing occurrences next time it opens.
2. **Show it as due and let the seller confirm** — what ships.

- An expense is a tax record. Storage rent cancelled in March keeps posting in April under option 1, unnoticed until the inflated figure is on a return. A wrong number a seller must find is worse than a right one they had to tap — and it is one tap, on a row the app already filled in.
- It is also the cheaper half: option 1 needs a deploy before the feature exists at all (`functions/` is not deployed), and a client writing the backfill on open writes it twice from two devices.
- **A series is a field, not an inference.** `recurringSeriesId` points every occurrence at the first, because "the same cost as last month" cannot be derived from category and vendor — the vendor is optional and the amount moves. A row older than the field falls back to its own id, so nothing migrates.
- **Monthly is the only cadence; adding one is a data change.** The form says "every month" and offers no weekly, because a cadence nobody asked for is a picker on a create flow (hard rule 2). A second cadence becomes a field on the series, never an `if` at the call site.

## The tab bar's selected indicator came back, as glass

The earlier rule was "nothing behind the current glyph — an indicator pill is Material's idiom and reads as a foreign control in iOS chrome". It is reversed, and recorded here because the old reasoning still reads as right on its own terms.

- What was tried and removed was a **flat filled shape**: a solid or tinted rounded rect behind the icon. That really is Material's `NavigationBar` indicator, and beside real iOS chrome it reads as one.
- But the iOS 26 system tab bar does mark its current tab — with a second piece of Liquid Glass, brighter than the bar, refracting the same page, sliding between tabs. The old rule rejected the *material* and generalised too far, to the mark itself. Owner's call: the bar follows the system bar 100%, so the mark returns in the system's material.
- The glyph still fills on the `FILL` axis. Colour alone was never allowed to be the signal and still is not; the capsule is a third signal, not a replacement for the second.

The mechanism is in `docs/rules/DESIGN_SYSTEM.md` — above all why the capsule gets its own `LiquidGlassLayer` instead of joining the bar's blend group: the one thing that looks like a free simplification and silently deletes the capsule.

## Mock data was deleted; seeding a real workspace replaced it

The app used to carry two backends and pick at runtime — a persisted `DataMode`, an in-memory repository behind every provider, a switch in Settings. Owner's rule removed it, and two facts made that a gain, not a loss:

- **The app a developer saw was not the app a seller runs.** Nothing exercised a write path, so `data/` could be broken for weeks with every screen still looking right.
- **A fake business was one stale preference from being real.** The mode was persisted, and dev mode is granted by email in `app_config` — a release-build grant by definition — so the branch survived compilation. Two booleans stood between a seller and someone else's invented inventory.

What replaced it is `SeedDataSeeder`: three rows of everything, written into the open workspace through the same repositories every screen reads. It is the one thing driving every live write path in one run, so a failure in it is a real `data/` bug found before a seller finds it.

- **The fakes were moved, not deleted.** They live in `test/support/fakes/`, where fakes belong, and `FakeOverrides` alone says which provider gets which. The app has one backend.
- `DevFlags.verboseLogging` keeps its `const` guard. A *default* that turns itself on in a shipped build is not what an email list was asked to buy.

## The block list is a UI gate, deliberately not a permission

`blocked_emails` sends an account to `/blocked` with nothing but a sign-out button. It revokes **nothing**: the account still holds a valid Firebase token, and `firestore.rules` does not know the list.

- A real permission means either putting the list where rules can read it — a document every client must then be allowed to read, the leak below — or disabling the account in the Firebase console: the actual answer, ten seconds' work.
- The list is for the non-emergency case: an account that should stop using the app, told so plainly, without the confusing half-broken session a mid-flight token revocation produces.
- **Every signed-in account can read the three lists — a known cost.** `app_config/current` allows any signed-in read, a rule cannot filter fields, and the client must check its own address — so a seller reading the document sees the owner's testers and, more awkwardly, who was blocked. Owner's call, over storing SHA-256 hashes, because a document nobody can read in the console is one nobody maintains. Keep the lists short; use the Firebase console for anything that must stay private.

## The forced update is a sheet, and the block is one field per store

Two changes to one feature, both owner's rules, both reversing what was written a commit earlier.

**The ceiling is per platform.** `minimum_build` and `update_url` were one pair for the whole product. A build number means something only beside the store that issued it: `41` on the App Store and on Google Play are different binaries, reviewed at different times, released in whatever order the queues allowed. One ceiling for both stops a shipped build or lets an old one through, and the store link was always going to be two links.

- So `force_update.ios` and `force_update.android` each carry `enable_force_update`, `build_number`, `build_name` and `store_link`, and the app reads only its own.
- Nested under one field, not loose at the top: two platform names at the document root read as config about platforms, when they hold one feature configured per store.

**`enable_force_update` lets the numbers stay current without blocking anyone.** Without it `build_number` would be both the record of what shipped and the trigger, so routine upkeep would look like an emergency. The switch is checked first: raising the build alone forces nothing.

**The UI is an undismissable bottom sheet, and `/update-required` is deleted.**

- The screen was a route the redirect sent every location to, above every other gate. It guaranteed nothing could be behind it; it cost a route, a redirect branch, a `refreshListenable` subscription, and a dead end to unwind once config was fixed.
- The sheet gets the same guarantee from `SdBottomSheetExitV3.blocked` — no close button, grab handle, barrier tap or back gesture — and `ForceUpdateGate` raises it from above the router, covering signed-out screens, deep links and mid-form states without any of them knowing.
- The gate closes it too: a build number typed one digit too high is fixed in the console, and the seller is released with no release.

**It is drawn, never pushed.** The first build of the sheet used `showSdBottomSheetV3`, and a modal sheet is a pageless route hanging off the page route below — so the block raised over the splash left with the splash on the first redirect, and nothing brought it back because config had not changed. `ForceUpdateGate` renders `ForceUpdateBlock` as its own child instead: barrier, bottom alignment and entry animation sit in the tree the gate owns, out of navigation's reach, and the block rises and falls on the provider alone. That is also why `SdBottomSheetExitScopeV3` is public — a blocked sheet **is** the app's state, not something shown over it, so a route is not the only place to present one.

## Materials a seller turns into stock are a purchase, not an expense category

Owner's decision, taken while walking the app through as a handmade-goods seller rather than a reseller of finished items.

A maker buys $80 of clay and glaze and makes twelve mugs. Two ways to record it; only one is right:

- **A — the materials are a buying trip.** The $80 is a purchase, the twelve mugs are filed under it, and *Spread this receipt across the items* writes each its share. Three mugs sold in March cost $20.01 of goods; the other $60 stays in inventory value until those mugs sell.
- **B — the materials are an expense.** The $80 is an `ExpenseCategory` deduction in March. March's profit absorbs it all, the nine unsold mugs carry zero cost, and every later sale reads as pure profit.

**A was chosen.** Per-item profit and inventory value both come out right, and it matches both launch jurisdictions: unsold stock is not yet a deduction. B also breaks the tax summary, claiming the same $80 in the year bought *and* again as cost of goods when the mug sells.

The consequence: **no materials expense category exists, and adding one would be a second way to record the same money.** A maker uses the same Sourcing flow as a reseller — only the "buying trip" wording reads oddly, and renaming it is a copy change, not a model one.

## Only mismatched config stops the launch

Explains `StartupFailurePolicy` in `lib/core/bootstrap/app_startup_failure.dart`, and why it names one failure instead of "the Firebase step threw".

`SdBootstrap` guards every step and always calls `runApp`: an app that will not open is worse than almost anything it could lack. That holds for everything this app brings up — no Firebase config is an offline build, a broken Google Sign-In leaves Apple working, a missing RevenueCat key reads every seller as Free, an unreachable Firebase is a seller in a shop with no signal. All of those open the app.

- `FlavorConfigMismatch` is the one that does not, because of its shape: **nothing is unreachable.** The build's two config halves name different Firebase projects, so the app would come up, sign in and work — against a database this build was never meant to touch. Every failure above announces itself; this one looks like a normal launch, which is why the app refuses it. `docs/rules/ENV.md` has the check.
- **`[core/duplicate-app]` was on this list and is not any more** — owner's call. It guarded against `initializeApp` running twice, which one call site in `AppBootstrap` cannot do; and the project-id comparison answers the failure it imagined directly, asking what the SDK actually came up on instead of how. The cost: a throw from `initializeApp` now returns to the router and the comparison below it does not run — the same outcome as any unreachable backend, the rule above.
- **The seller sees the two localized lines and nothing else.** The failure itself is a debug affordance (hard rule 6), gated on `DevFlags.isDebugOrProfile`, which is `const` — so the release binary carries `null` there and the detail row is absent. Outside release it names both projects and the command that re-aligns them.

## A cache miss is not an answer the router may act on

Explains `ConfirmedStream` and why only `watchProfile` uses `FirestoreStream.confirmedDocument`.

Firestore serves a listener from cache first. On a device that never held the signed-in person's profile — fresh install, new phone, first sign-in after a reinstall — the first snapshot says `exists: false`, and nothing in it tells "this account has no profile" from "this device has not been told yet". `workspaceStatusProvider` could only read it as *no business*, so the router sent a returning seller to the create-business form and corrected itself a round trip later. After every sign-in the seller saw a form they had already filled, for about half a second.

The fix has hard rule 5's shape: **unknown is not zero.** The profile stream now carries a server-confirmed answer first, and until it arrives the status stays `loading` — the screen that already exists for it.

Two things are deliberately narrow:

- **Only the profile.** Every other document keeps cache-first behaviour: a list showing an empty state for one frame is a screen correcting itself, not an app sending someone where they did not ask to go.
- **Only the first answer.** Once a confirmed one arrives the gate stays open for the stream's life — later unconfirmed snapshots are the app's own writes echoing back, and holding those would make every edit feel like a network wait.

The cost is offline: nothing is ever confirmed there, so `ConfirmedStream.grace` bounds the wait and the held answer is released when it expires.

## The page loader is a newton's cradle, and it costs a dependency

Explains `loading_animation_widget` in `packages/flutter-system-design-kit/pubspec.yaml`, approved by the owner, who named both package and animation.

- The v3 loading indicator was a `CircularProgressIndicator` at both sizes. A ring filling an empty screen reads as *stuck* — the same picture at second one and second ten — and the screen it fills most is the one a seller waits on after signing in.
- So the two sizes now draw differently, still as one look: a wait the seller watches is the cradle; a wait inside something they already look at (a button, a row) stays the ring. The cradle scales everything off its box, so at inline size its dots would be under two points — a smudge, not an animation.
- The package is a drawing library: no service, account or network, nothing it can log. So it is a design-system dependency, not the app's — it has a look, so it belongs to a generation.

## The splash route has no transition — a bug fix

Explains the `NoTransitionPage` on `AppRoutes.splash` in `app_router.dart`.

A guest renders at `/home` (hard rule 1), so signing in *leaves* the tab shell for the splash and returns a moment later. go_router gives `StatefulShellRoute` **one `GlobalKey` for the router's life** — the same key on every `StatefulNavigationShell` it builds.

An animated page keeps the outgoing route mounted until its transition ends. So the old shell was still on screen when the next was built — two widgets holding one global key:

```text
Duplicate GlobalKey detected in widget tree.
- [LabeledGlobalKey<StatefulNavigationShellState>]
```

It fired on Home's first frame and truncated the losing tab. A splash is a state, not a destination, so dropping its transition costs nothing and closes the window: the shell page is gone in the frame it is left.

**`SplashHoldController.minimum` hides this; it does not fix it.** Two seconds far exceeds any page transition, so the hold alone makes the overlap impossible — exactly why the transition fix must stand on its own. Shorten the hold one day and the error returns; `test/core/router/sign_in_lands_once_test.dart` pins the transition with the hold overridden away, so it cannot.

## Why the app stopped requiring an account, and took a local database with it

Owner's call. Explains current hard rule 1 in root `CLAUDE.md`, the "Two stores, one live at a time" Tech stack entry, and all of `docs/rules/GUEST_MODE.md`. Recorded because two long-standing rules were reversed at once, and a reversal read as an accident gets quietly undone.

- **What the old rules said.** Login was mandatory, no guest mode (plan principle 1); no local database, because a seller's inventory is "inherently a synced business record shared with a team", unlike the sibling app's health data, which must survive with no account.
- **Why that gave way.** The second half of that argument did work the first could not support. A business record *ends up* shared but does not start so — a seller evaluating the app has nothing to share and nobody to share with, and the sign-in wall stood between them and the one thing that would tell them whether an account is worth it. The app's core principle is telling the seller what needs attention today, then letting them act fast; a login form is neither.
- **Why not anonymous Firebase auth** — cheaper, and considered first. It would have left every repository, rule and the data model untouched, with sign-in as `linkWithCredential` on the same uid — no migration. Rejected because it puts a guest's records on the server, and the owner requires nothing to leave the device until there is an account to attach it to. The cost — a Drift schema and a second implementation of every business repository — is paid knowingly.
- **Why the engine is still small.** The sibling app's data-flow spec has revision counters, tombstones, a write-through watcher, two passes and a cursor per collection. None ports: they keep two stores live forever. Here one store *replaces* the other — the guest store never pulls, never merges, and is drained and dropped at sign-in. Porting those columns builds a sync engine for a problem this shape lacks, and `docs/rules/GUEST_MODE.md` says so where the next session will look.
- **What was accepted, not solved.** Deleting the app deletes a guest's business. No recovery exists; the owner chose that over putting records on a server. That is why the sign-in prompt and the local export in `GUEST_MODE.md` are not optional: the architecture may make the trade only if the product says so out loud.

## Sign in with Apple on iOS presents its own sheet

App Review rejected build 34 under guideline 2.1(a): on an iPad Air (iPadOS 27), Sign in with Apple loaded forever. Two things could hold that button forever; both are closed.

- **FlutterFire's Apple path can present from no window.** It searches connected scenes for a key window and, finding none, falls back to a deprecated `keyWindow` that is nil under the UIScene lifecycle. The sheet never appears and the call never answers; several delegate branches also return without answering. `ios/Runner/AppleSignInPlugin.swift` replaces it on iOS: the anchor is the Flutter view's own window, found before the request runs, and every path answers exactly once. The token reaches Firebase through `signInWithCredential`. Other platforms keep `signInWithProvider`, the web flow, which has no window to get wrong.
- **Sign-in awaited two unbounded calls.** The profile write waits for server acknowledgement, and RevenueCat's `logIn` is a network round trip; both were awaited before the button stopped spinning, on an already valid session. They now run unawaited and log their own failure. `test/features/auth/sign_in_test.dart` pins it.

**Why not the `sign_in_with_apple` package.** A new dependency for about a hundred lines of Swift, and the bug was in who owns the presentation — moving that to another package moves the question without answering it.

## A refused permission opens Settings through the app's own channel

A seller who refused the camera got "Something went wrong" on a photo, a blank error icon on the scanner, and nothing about notifications — with no way back but finding the app's page in Settings alone. `PermissionSettingsSheet` now says what is off and opens that page.

- **Shown only when the system will not ask again.** iOS asks once, so any refusal is final. Android asks twice: the first refusal is the seller changing their mind, treated like a cancel; the sheet comes once `shouldShowRequestPermissionRationale` says the dialog is gone for good.
- **The plugins still ask.** `image_picker`, `mobile_scanner` and FCM request their own permissions; `SystemPermissions` only answers what happens after a no.

**Why not `permission_handler`.** Two questions — "will it ask again?" and "open Settings" — take about sixty lines across `SystemPermissionsPlugin.swift` and `MainActivity.kt`, the same trade as the Apple sheet above. The package would also be a second requester of the permissions the plugins already request, and the two can disagree on what was asked.

## Marketplace connection came back, because dropshipping needs it

Owner's call. Explains the dropshipping paragraph under "What this project is" in root `CLAUDE.md` and hard rule 10's current form. Recorded because two decisions were taken together, and a reversal read as an accident gets quietly undone.

- **What the old rule said.** Marketplace connection was not a feature: no OAuth, no sync, no client talking to a platform. Listings were records the seller kept; `PayoutCsvImport` was the only import.
- **Why that gave way.** The owner widened the product from reselling to reselling plus dropshipping. A reseller can live with typing a sale in by hand; a dropshipper's whole margin is the minutes between a sale and the supplier order, and the supplier's price moving under a live listing. Hand-kept records serve neither, so connections returned with the scope.
- **What did not change.** No secret ships in the binary, and the backend is still the only thing talking to a platform. The rule kept its number and first sentence; only the clause forbidding the feature went.
