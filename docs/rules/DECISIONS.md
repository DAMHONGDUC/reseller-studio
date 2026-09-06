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

## Dev mode is granted by email, so the mock branch stops being tree-shaken

The earlier rule is in `lib/features/mock_data/CLAUDE.md`: every repository
provider tests `DevFlags.isDebugOrProfile` **first**, which is `const` false in
release, so the mock branch folds away at compile time and the in-memory
repositories and their seed leave the shipped binary rather than merely going
unreachable inside it. That is a stronger property than a runtime check, and
nothing about the argument for it was wrong.

Owner's rule adds `dev_mode_emails` to `app_config`, and a list of email
addresses is a **release-build** grant by definition — a debug build already
has dev mode, so a list that only worked there would grant nothing. The branch
therefore has to survive compilation, and the seed now ships.

What replaces the compiler as the guard is `devModeEnabledProvider`: true in
every debug and profile build, and in a release build only when the config
names the signed-in account. `DataModeController` still refuses to return
`mock` without it, and the mock-data card in Settings still hides itself — two
checks rather than one, because the thing on the other side is a fake business
shown to a real seller.

`DevFlags.mockDataDefault` and `DevFlags.verboseLogging` keep their `const`
guards. A *default* that turns itself on in a shipped build is not what an
email list was asked to buy.

**The config repository is the one thing mock mode no longer swaps.** Dev mode
is now read out of `app_config`, so mocking the repository that supplies it
would make the config depend on the switch the config decides, and Riverpod
answers a circular dependency by throwing. Nothing is lost: the in-memory
implementation returned `AppConfig.fallback`, which is exactly what a build
with no Firebase already gets.

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
So `ios` and `android` each carry `enable_force_update`, `build_number`,
`build_name` and `store_link`, and the app reads only its own.

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
