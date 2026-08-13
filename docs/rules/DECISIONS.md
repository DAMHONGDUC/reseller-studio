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

## Seller OS pays for v2's dependencies, and one of them warns on every Android build

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
  whole filter row into the app bar as the list scrolls. v3 does the opposite
  and it is a recorded owner's rule: a filter strip is never part of the app
  bar, it is its own widget in the body, and it scrolls away with the content.
  What stays pinned is search and the actions. These are mutually exclusive
  designs, not two halves of one — v3's stands.
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

## Two rules from the sibling app that Seller OS deliberately inverts

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
activity log (§23) are blocked on Cloud Functions; returns folded into order
detail (§16), so its screen was never built.

Deleted rather than left in place, because a constant that resolves to nothing
reads as a working destination to the next caller and fails as a deep link
without saying why. A comment sits where each was, so the gap reads as a
decision. They come back with their screens.

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
the fact — the reasoning transfers, the incident is not Seller OS's.

The rule was written after three features failed silently at once: WeatherKit
answered every call `401` and the app said "no weather", `sendTestPush` was
refused by the backend, and neither left a line anywhere. The reason to log a
caught error is that a caught error is invisible by construction.
