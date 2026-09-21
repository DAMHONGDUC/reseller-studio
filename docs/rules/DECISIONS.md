# Decisions — the history behind the rules

Rationale that justifies a rule but is not itself actionable. Nothing here
needs to be in context to write correct code; it is here so the reasoning
survives, and so the rules it explains can stay short.

## Deep links hard-crash until Firebase is configured

Explains the `selleros://` deep-link entry under "Tech stack" in the root
`CLAUDE.md`.

  **Until Firebase is configured, any deep link hard-crashes the app**:
  `firebase_auth`'s iOS plugin intercepts `openURL` and constructs
  `Auth.auth()`, which fatals with *"The default FirebaseApp instance must be
  configured"*. It is a native crash, so `bootstrap`'s guarded zone cannot
  catch it. Nothing to fix in this app — it disappears the moment
  `flutterfire configure` has run. Don't spend an afternoon on it.

## The app bar stays opaque

Explains the opaque-app-bar rule in `DESIGN_SYSTEM.md`.

The app bar deliberately stays opaque: a blur there costs a shader pass on
every scroll frame of a list that can run to thousands of rows, whereas the
tab bar is a fixed strip whose cost does not grow with the content.

## Reseller Studio pays for v2's dependencies, and one of them warns on every Android build

Explains why the `Compiled to invalid SkSL` warning is not to be fixed.
Referenced from `DESIGN_SYSTEM.md`.

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

## v3 keeps its own chrome — two v2 patterns are deliberately not ported

Owner's call. Explains the "What v3 deliberately does NOT have" section in
`DESIGN_SYSTEM.md`, and exists so the next session does not read the gap as an
oversight and "finish the port".

The spacing rulebook (`SdContentPaddingV2`) **was** ported in full. Two
neighbouring v2 patterns were not, and this is the standing answer:

- **`SdCollapsingFilterScaffoldV2` + `SdPinnedFilterBarV2`.** v2 lifts the
  whole filter row *into the app bar* as the list scrolls. v3 does not, and
  that is the recorded owner's rule: a filter strip is never part of the app
  bar, it is its own widget in the body with the body's background.
  **What changed since:** the strip now *pins* below the chrome rather than
  scrolling away, because chips a seller cannot reach 300 rows down are chips
  they scroll back up for. Pinned below is not the same as lifted inside —
  v2's component is still not what v3 wants, and v3 pins with a plain
  `SliverPersistentHeader` it owns.
- **`SdContentPaddingV3.belowPinnedFilterBar`.** Follows from the above: it is
  `appBarInset` plus the strip's height, the first term is zero under an
  opaque bar, and nothing pins a strip over a list anyway.
- **`SdFloatingBarScopeV2`.** This one *was* ported, and is the exception that
  proves the rest are deliberate. See below.
- **Two search entry points on purpose.** Inventory uses `SdSearchHeaderV3`,
  whose field docks into the title row as the list scrolls. The Search screen
  builds a plain field with `autofocus` and no collapse, because that screen
  exists to be typed into immediately and collapsing chrome buys nothing when
  the list starts empty.

## The floating-bar scope was ported, and v3 asks a different question

Owner approved the new component. `SdFloatingBarScopeV3` exists because not
having it cost a real bug: a snackbar draws into the root overlay, above the
whole app, so nothing in its own build can tell the glass nav bar is under it.
On all five tab screens the card sat at `detailBottom` and its lower edge
landed well inside `floatingBarInset` — the band the bar occupies.

**v3's scope returns a bool where v2's returns a double.** `insetOf` was the
right shape in v2, whose snackbar host does its own bottom arithmetic from
`safe.bottom`. v3 already has `SdContentPaddingV3.bottom(floatingNav: …)` —
the exact call every tab screen makes for its own last row — so the host asks
`hasBarBelow` and hands the answer to that, and a message rests exactly where
the content it is about does. One rulebook, no second copy of the arithmetic
to drift.

Both generations read from the **caller's** context rather than the entry's
builder, and that part is not a style choice: the root overlay sits above the
shell, so a scope inside it is invisible from down there and every message
would read "no bar".

## Two rules from the sibling app that Reseller Studio deliberately inverts

The rulebook these files were ported from is BaroEase's. Most of it transfers
unchanged. Two rules do not, and both would look like bugs to anyone reading
that rulebook next to this code — so the answer is recorded here rather than
re-argued.

- **"No FAB on a screen with the floating nav" — inverted.** There, the pill
  overlays the content and eats the tap, so every tab puts its primary action
  in the app bar. Here the opposite is an owner's rule: **every screen that
  creates something uses the same labelled `SdFabV3`**, tab screens included,
  and `AppAddFabScaffold` lifts it clear by `floatingBarInset` so the glass
  never covers it. The reasoning is the product's, not the layout's — a seller
  adds inventory dozens of times a day, and a create action hidden behind a
  24pt glyph in a corner is one they stop using. BaroEase's screens create
  something occasionally; Inventory exists to.
- **"Local-first, account optional" — does not apply.** Hard rule 1: login is
  mandatory and there is no guest mode. Health data must survive with no
  account, whereas a seller's inventory is a synced business record shared with
  a team, which is also why there is no local database here. Anything in the
  ported rules about an account being optional, or about the device being the
  source of truth, belongs to that app.

## Why "now" is a provider and not a parameter

Explains the `clockProvider` rule in the root `CLAUDE.md`.

The alternative was threading a `DateTime now` down from each screen's root.
It was rejected for two reasons. Most of the drift lives in *providers* —
`staleItemsProvider`, `inventoryCountsProvider`, `visibleOffersProvider` — and
a provider has no parent to take a parameter from, so those would have needed
a family keyed on an instant, which recomputes on every distinct value it is
ever passed. And a parameter is opt-in: nothing stops the next screen calling
`DateTime.now()` again, whereas an override in `pump_app.dart` covers every
screen that reads the clock, including ones not written yet.

The cost, recorded so it is not rediscovered as a bug: the clock is read at
build time, so a screen left open does not re-derive "overdue" as the deadline
passes. It already behaved that way — this changed where the instant comes
from, not when it is read.

## Three route constants were deleted rather than wired

`AppRoutes.notifications`, `AppRoutes.activity` and `AppRoutes.returns` had
zero usages and no route serving their paths. Notifications (§22) and the
activity log (§23) were blocked on Cloud Functions; returns folded into order
detail (§16), so its screen was never built.

Deleted rather than left in place, because a constant that resolves to nothing
reads as a working destination to the next caller and fails as a deep link
without saying why. A comment sat where each was, so the gap read as a
decision. **Two have since come back with their screens** — `activity` and
`notifications` — which is the rule working as intended. `returns` stays
deleted: order detail is where a return is opened and closed.

## The notification is the Firestore row; the push is a copy of it

Plan §22 says "use FCM", which is a delivery mechanism and not a design. The
design is that `users/{uid}/notifications/{id}` is written first and the push
is sent afterwards, best-effort.

A push cannot be the notification: permission may be off, the token may be
stale, the phone may be in a field with no signal, and the seller may swipe it
away half-read. All four are ordinary, and in a push-only design each one is a
notification that never existed. Writing the row first means a seller who
never grants permission still has a working notification centre, and it is why
`PushMessaging` answers rather than throws everywhere.

Three consequences worth keeping:

- **The inbox lives under the user, not the workspace.** A notification is
  addressed to a reader; two members of one business each get their own row
  and each marks their own read. A shared document with a `readBy` array would
  have every reader writing to a document every other reader is watching.
- **The row's words are rendered in the app, not read from the document.** A
  Cloud Function cannot know the reader's locale, so the stored `title` and
  `body` are the English push text and the inbox builds its own line from
  `type` and `count` through ARB (hard rule 7). Reading the stored strings
  would make the inbox permanently English whatever the translation pass does.
- **The reminders are a digest, one per workspace per day.** Forty stale
  listings is one line. A seller who gets forty notifications turns
  notifications off, and then the durable half is all that is left working.

## Cross-listing has its own transition check

`ItemTransition.check(item, listed)` refuses an item that is already `listed`,
which is correct for the action it guards and exactly wrong for cross-listing:
the item is on eBay and the seller wants it on Depop as well.

So `crossListCheck` is a second, narrower question — has this item left
inventory, and is there any of it left — rather than a widening of the first.
It also does **not** require a price, because the cross-list screen is itself
where the price is entered; requiring one beforehand would block the screen
that collects it, which is hard rule 2 backwards.

The write moves the item's status only when it has not already moved, and
never touches `listedAt` on an item that was already live: staleness is
measured from the first time something went live anywhere, so adding a
marketplace must not reset that clock.

## RevenueCat is approved, and the app never sees a receipt

Owner's call, recorded because `CLAUDE.md` requires a reason in writing for
any third-party SDK. The plan (§27) allows "RevenueCat or equivalent"; this
picks one. The owner owns the RevenueCat account and the App Store / Play
products — none of that is in this repo.

Why not StoreKit and Billing directly: the two stores disagree about almost
everything a subscription needs — proration, grace periods, restore, a plan
change mid-period — and the code that reconciles them is the part that gets
subscription billing wrong. That reconciliation is what is being bought.

Two constraints that follow, and they are hard rules 9 and 10 applied rather
than new ones:

- **The app asks RevenueCat what the seller is entitled to; it never validates
  a receipt itself and never logs one.** A receipt is a credential.
- **Entitlement is mirrored into Firestore by a Cloud Function**, from
  RevenueCat's webhook, because `firestore.rules` cannot ask an SDK a
  question. The client copy is a cache for rendering; the server copy is what
  a rule reads. A client that could write its own plan is a paywall with a
  free bypass.

## Tax ships for two jurisdictions, and the third is data

Owner's rule: launch markets are the US and the UK (`CLAUDE.md`). Plan §20
says tax must stay country-specific and configurable, which is the same thing
said from the other side.

So a jurisdiction is a **value**, never a branch: `TaxJurisdiction` names one,
and everything that differs — the category list, the tax-year boundary, the
mileage rate and its tiers, what the year-end summary is called — hangs off
that value. The US tax year is the calendar year and the UK's starts on 6
April; a single `DateTime(year, 1, 1)` anywhere in this feature is the bug.

Mileage rates change every year and are set by the IRS and HMRC, so they are
dated data with an effective-from date, not a constant. A rate typed into a
widget is a wrong deduction the following April.

## Why a caught error must still be logged

Explains "Every `catch` logs, wherever it sits" in the root `CLAUDE.md`.
Inherited from the sibling app (BaroEase), where the rule was written after
the fact — the reasoning transfers, the incident is not Reseller Studio's.

The rule was written after three features failed silently at once: WeatherKit
answered every call `401` and the app said "no weather", `sendTestPush` was
refused by the backend, and neither left a line anywhere. The reason to log a
caught error is that a caught error is invisible by construction.

## A recurring expense is proposed, never posted on its own

`Expense.isRecurring` was written to Firestore and read by nothing, so the
switch on the form ("Happens every month") changed no behaviour at all. Two
ways to make it mean something, and the app takes the second:

1. **Post it automatically** each month — a scheduled Cloud Function, or the
   client writing the missing occurrences the next time it opens.
2. **Show it as due and let the seller confirm**, which is what ships.

The reason is that an expense is a tax record. Storage rent that was
cancelled in March keeps posting in April under option 1, and nobody notices
until the figure it inflated is on a return. A wrong number a seller has to
find is worse than a right one they had to tap — and the tap is one tap, on a
row the app has already filled in.

It is also the cheaper half of the same decision: option 1 needs a deploy
before the feature exists at all (`functions/` is not deployed), and a client
that writes the backfill on open makes the same write twice from two devices.

**A series is a field, not an inference.** `recurringSeriesId` points every
occurrence at the first one, because "the same cost as last month" cannot be
derived from category and vendor — the vendor is optional and the amount
moves. A row written before the field existed falls back to its own id, so
nothing needs migrating.

**Monthly is the only cadence, and adding another is a data change.** The form
says "every month" and nothing offers weekly, because a cadence nobody asked
for is a picker on a create flow (hard rule 2). A second cadence becomes a
field on the series, never an `if` at the call site.

## The tab bar's selected indicator came back, as glass

The earlier rule was "nothing behind the current glyph — an indicator pill is
Material's idiom and reads as a foreign control inside iOS chrome". It is
reversed, and the reversal is recorded here because the old reasoning still
reads as correct on its own terms.

What was tried and removed was a **flat filled shape**: a solid or tinted
rounded rect painted behind the icon. That really is Material's `NavigationBar`
indicator, and next to real iOS chrome it reads as one.

But the iOS 26 system tab bar does mark its current tab, and the mark is a
second piece of Liquid Glass — brighter than the bar, refracting the same page
through it, sliding between tabs. The old rule was rejecting the *material*
and generalised too far, to the mark itself. Owner's call is that the bar
follows the system bar 100%, so the mark returns in the system's material.

The glyph still fills on the `FILL` axis. Colour alone was never allowed to be
the signal and still is not; the capsule is a third signal, not a replacement
for the second.

The mechanism is in `docs/rules/DESIGN_SYSTEM.md` — notably why the capsule
gets its own `LiquidGlassLayer` rather than joining the bar's blend group,
which is the one thing that looks like a free simplification and silently
deletes the capsule.

## Mock data was deleted; seeding a real workspace replaced it

The app used to carry two backends and choose between them at runtime — a
persisted `DataMode`, an in-memory repository behind every provider, and a
switch in Settings. Owner's rule removed it, and two things made that the
right way round rather than a loss:

- **The app a developer looked at was not the app a seller runs.** Nothing
  exercised a write path, so `data/` could be broken for weeks and every
  screen would still look right.
- **A fake business was one stale preference away from being real.** The mode
  was persisted and dev mode is granted by email in `app_config` — a
  release-build grant by definition — so the branch survived compilation. Two
  booleans stood between a seller and somebody else's invented inventory.

What replaced it is `SeedDataSeeder`: three rows of everything, written into
the open workspace through the same repositories every screen reads. It is the
only thing that drives every live write path in one run, so a failure in it is
a real bug in `data/` found before a seller finds it.

**The fakes were moved, not deleted.** They live in `test/support/fakes/`,
where a fake belongs, and `FakeOverrides` is the single place that says which
provider gets which. The app has one backend.

`DevFlags.verboseLogging` keeps its `const` guard. A *default* that turns
itself on in a shipped build is not what an email list was asked to buy.

## The block list is a UI gate, and it is deliberately not a permission

`blocked_emails` sends an account to `/blocked` and gives it nothing but a
sign-out button. It does **not** revoke anything: the account still holds a
valid Firebase token, and `firestore.rules` does not know the list exists.

Making it a real permission means either putting the list where the rules can
read it — a document every client would then have to be allowed to read to
enforce it, which is the leak below — or disabling the account in the Firebase
console, which is the actual answer and takes ten seconds. The list is for the
case that is not an emergency: an account that should stop using the app, told
so plainly, without the confusing half-broken session that revoking a token
mid-flight produces.

**The three lists are readable by every signed-in account, and that is a known
cost.** `app_config/current` allows any signed-in read, a rule cannot filter
fields, and the client has to be able to check its own address — so a seller
who reads the document sees the owner's testers and, more awkwardly, who has
been blocked. Owner's call, taken over storing SHA-256 hashes instead, because
a document nobody can read in the console is a document nobody maintains. Keep
the lists short, and use the Firebase console for anything that must not be
public.

## The forced update is a sheet, and the block is one field per store

Two changes to the same feature, both owner's rules, and both reverse what was
written a commit earlier.

**The ceiling is per platform.** `minimum_build` and `update_url` were one
pair for the whole product. A build number is only meaningful next to the
store that issued it: `41` on the App Store and `41` on Google Play are
different binaries, reviewed at different times, released in whichever order
the queues allowed. One ceiling for both either stops a build that shipped or
lets an old one through, and the store link was always going to be two links.
So `force_update.ios` and `force_update.android` each carry
`enable_force_update`, `build_number`, `build_name` and `store_link`, and the
app reads only its own. They are nested under one field rather than loose at
the top level: two platform names in the root of the document read as a config
about platforms, when what they hold is one feature configured per store.

**`enable_force_update` exists so the numbers can be kept current without
blocking anybody.** Without it, `build_number` would be both the record of
what shipped and the trigger, so routine maintenance would be indistinguishable
from an emergency. The switch is checked first: raising the build alone forces
nothing.

**The UI is a bottom sheet nothing dismisses, and `/update-required` is
deleted.** The screen was a route the redirect sent every location to, above
every other gate. What that bought was a guarantee nothing could be behind it;
what it cost was a route, a redirect branch, a `refreshListenable`
subscription, and a dead end to unwind when the config was corrected. The sheet
gets the same guarantee from `SdBottomSheetExitV3.blocked` — no close button,
no grab handle, no barrier tap, no back gesture — and `ForceUpdateGate` raises
it from above the router, so it covers signed-out screens, deep links and
mid-form states alike without any of them knowing.

The gate is what closes it too: a build number typed one digit too high is
corrected in the console, and the seller is released without a release.

**And it is drawn, never pushed.** The first build of the sheet used
`showSdBottomSheetV3`, and a modal sheet is a pageless route hanging off the
page route below it — so the block raised over the splash went away with the
splash on the very first redirect, and nothing brought it back because the
config had not changed. `ForceUpdateGate` renders `ForceUpdateBlock` as its
own child instead: the barrier, the bottom alignment and the entry animation
sit in the tree the gate owns, where no navigation can reach them, and the
block goes up and comes down from the provider alone. That is also why
`SdBottomSheetExitScopeV3` is public — a blocked sheet **is** the app's state
rather than something shown over it, so a route is not the only place one can
be presented from.

## Materials a seller turns into stock are a purchase, not an expense category

Owner's decision, taken when the app was walked through as a handmade-goods
seller rather than a reseller of finished items.

A maker buys $80 of clay and glaze and turns it into twelve mugs. Two ways to
record that, and only one of them can be right:

- **A — the materials are a buying trip.** The $80 is a purchase, the twelve
  mugs are filed under it, and *Spread this receipt across the items* writes
  each mug its share. Three mugs sold in March cost $20.01 of goods; the other
  $60 sits in inventory value until those mugs sell.
- **B — the materials are an expense.** The $80 is an `ExpenseCategory`
  deduction in March. March's profit absorbs all of it, the nine unsold mugs
  carry a cost of zero, and every later sale of one reads as pure profit.

**A was chosen.** Per-item profit and inventory value both come out right, and
it matches what both launch jurisdictions ask for: stock that has not sold yet
is not yet a deduction. B also breaks the tax summary, because the same $80
would be claimed in the year it was bought *and* again as cost of goods when
the mug sells.

The consequence worth stating: **there is no materials expense category, and
adding one would be a second way to record the same money.** A maker uses the
same Sourcing flow a reseller does — the "buying trip" wording is the only
thing that reads oddly, and renaming it is a copy change rather than a model
one.

## Only mismatched config stops the launch

Explains `StartupFailurePolicy` in `lib/core/bootstrap/app_startup_failure.dart`,
and why it names one failure rather than "the Firebase step threw".

`SdBootstrap` guards every step and always calls `runApp`, on the argument
that an app which will not open is worse than almost anything it could be
missing. That argument holds for everything this app brings up: no Firebase
config is an offline build, a broken Google Sign-In leaves Apple working, a
missing RevenueCat key reads every seller as Free, and a Firebase that could
not be reached is a seller standing in a store with no signal. All of those
open the app.

`FlavorConfigMismatch` is the one that does not, and the reason is the shape
of it: **nothing is unreachable.** The two halves of the build's config name
different Firebase projects, so the app would come up, sign in and work —
against a database this build was never meant to touch. Every failure above
announces itself; this one is indistinguishable from a normal launch, which is
why it is the one the app refuses. `docs/rules/ENV.md` carries the check.

**`[core/duplicate-app]` used to be on this list and is not any more** —
owner's call. It was a guard against `initializeApp` running twice, which one
call site in `AppBootstrap` cannot do; and the failure it imagined is one the
project-id comparison answers directly, because a comparison asks what the SDK
actually came up on rather than how it got there. What it costs: a throw from
`initializeApp` now returns the app to the router, and the comparison below it
does not run. That is the same outcome as any other unreachable backend, which
is the rule above.

**What the seller sees is the two localized lines and nothing else.** The
failure itself is a debug affordance (hard rule 6), gated on
`DevFlags.isDebugOrProfile`, which is `const` — so the release binary carries
`null` there and the detail row is not in it at all. Outside release it names
both projects and the command that puts them back in step.

## A cache miss is not an answer the router may act on

Explains `ConfirmedStream` and why `watchProfile` alone uses
`FirestoreStream.confirmedDocument`.

Firestore serves a listener from its cache first. On a device that has never
held the signed-in person's profile — a fresh install, a new phone, the first
sign-in after a reinstall — that first snapshot says `exists: false`, and
nothing in it distinguishes "this account has no profile" from "this device
has not been told yet". `workspaceStatusProvider` could only read it as *no
business*, so the router sent a returning seller to the create-business form
and corrected itself a round trip later. The seller saw a form they had
already filled in, for about half a second, after every sign-in.

The fix is the same shape as hard rule 5: **unknown is not zero.** The profile
stream now carries a server-confirmed answer first, and until it arrives the
status stays `loading`, which is the screen that already exists for it.

Two things are deliberately narrow:

- **Only the profile.** Every other document keeps the cache-first behaviour,
  because a list that renders an empty state for one frame is a screen
  correcting itself, not an app sending someone somewhere they did not ask to
  go.
- **Only the first answer.** Once a confirmed one has arrived the gate is open
  for the life of the stream — later unconfirmed snapshots are the app's own
  writes echoing back, and holding those would make every edit feel like a
  network wait.

The cost is offline: nothing is ever confirmed there, so the wait is bounded
by `ConfirmedStream.grace` and the held answer is released when it expires.

## The page loader is a newton's cradle, and it costs a dependency

Explains `loading_animation_widget` in `packages/system_design/pubspec.yaml`,
approved by the owner, who named both the package and the animation.

The v3 loading indicator was a `CircularProgressIndicator` at both of its
sizes. A ring filling an empty screen reads as *stuck* — it is the same
picture at second one and second ten — and the screen it fills most often is
the one a seller waits on after signing in.

So the two sizes now draw differently, and it is still one look rather than
two: a wait the seller is watching is the cradle, a wait inside something they
are already looking at (a button, a row) stays the ring. The cradle scales
everything off its box, so at the inline size its dots would be under two
points — a smudge, not an animation.

The package is a drawing library: no service, no account, no network, and
nothing it can log. That is why it is a dependency of the design system rather
than of the app — it has a look, so it belongs to a generation.

## The splash route has no transition, and that is a bug fix

Explains the `NoTransitionPage` on `AppRoutes.splash` in `app_router.dart`.

The signed-out shell renders at `/home` (hard rule 1), so signing in *leaves*
the tab shell for the splash and comes back to it a moment later. go_router
gives `StatefulShellRoute` **one `GlobalKey` for the life of the router** — the
same key on every `StatefulNavigationShell` it builds.

An animated page keeps the outgoing route mounted until its transition
finishes. So the old shell was still on screen when the next one was built,
which is two widgets holding one global key:

```text
Duplicate GlobalKey detected in widget tree.
- [LabeledGlobalKey<StatefulNavigationShellState>]
```

It fired on the first frame of Home and truncated the tab that lost. A splash
is a state rather than a destination, so removing its transition costs nothing
and closes the window: the shell page is gone in the same frame it is left.

**`SplashHoldController.minimum` hides this rather than fixing it.** Two
seconds is far longer than any page transition, so the hold alone makes the
overlap impossible — which is exactly why the transition fix has to stand on
its own. Shorten the hold one day and the error comes back;
`test/core/router/sign_in_lands_once_test.dart` pins the transition with the
hold overridden away, so it cannot.
