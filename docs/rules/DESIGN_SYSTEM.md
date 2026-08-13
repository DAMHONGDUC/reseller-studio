# Design system — `system_design` v3

Read this when touching `packages/system_design/`, or when building any screen
or widget that renders `Sd*` v3 components.

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
| App bar | frosted glass, body scrolls behind | opaque, takes layout space |
| Tab bar | floating glass pill | floating **liquid glass** pill |
| Context getters | `context.sdTheme` | `context.sdTheme3` |

### The tab bar is liquid glass and that makes its geometry layout

`SdGlassNavBarV3` floats over the content in the iOS 26 idiom — a detached
superellipse pill the body scrolls behind and refracts through. Three things
follow, and missing any one of them looks like a bug:

1. **`SdScaffoldV3` must be given `extendBody: true`** wherever that bar is
   used, or the scaffold reserves its height and the glass refracts a blank
   strip of page.
2. **Every tab screen pads by `floatingNav: true`** —
   `SdContentPaddingV3.screen(context, floatingNav: true)` or `.fullBleed(…)`.
   That number is `floatingBarInset`, and it lives in one place because a bar
   and the padding beneath it drifting apart is exactly what happens
   otherwise. Pushed detail routes have nothing floating over them and must
   *not* pass it.
3. **A FAB needs lifting by `floatingBarInset` itself.** `extendBody` keeps
   the FAB in the body's coordinate space rather than stacking it above the
   bottom slot, so without the lift it renders *behind* the glass.

`navBarOffset` uses the same clamped rule as `SdContentPaddingV2` — owner's
call, so both apps' floating bars sit identically. `maxNavBarOffset` lands
short of a portrait iPhone's home-indicator inset, which trades system
clearance for a tighter bar; that trade is documented on the getter.

### The chrome is minimal, and its numbers live in the design system

Owner's rules, all of them read from one place so no screen types them:

- **The gap from the app bar down to the content under it is
  `SdContentPaddingV3.topGap`.** Owner's rule. The bar already carries a band
  of empty space at its own bottom edge, the more so now it is a full
  `kToolbarHeight` — anything more under it reads as a hole between the chrome
  and the page.
- **`topGap` is a `SizedBox` the screen places, never padding and never added
  to a bar's height.** Owner's rule. `screen()` and `fullBleed()` therefore
  carry **no top inset**, and `SdAppBarV3.toolbarHeight + topGap` is a sum
  that must not appear anywhere. A gap folded into an `EdgeInsets` is
  invisible at the call site; a gap added to the toolbar height makes the bar
  *measure* taller than it *draws*, which is how a docked control ends up
  mis-set in a row whose height nobody can point at. A box in the tree can be
  seen, moved and skipped. `SdSearchHeaderV3` keeps its own internal spacing
  on `SdSearchHeaderMetricsV3` for the same reason — the distance between two
  things the header draws is not the screen's `topGap`, even at the same
  value.
- **A filter strip is never part of the app bar.** Owner's rule. It is its own
  widget in the body, `topGap` below the chrome, and it scrolls away with the
  content. `SdSearchHeaderV3` holds the title, the search field and the
  actions — there is no `bottom` slot on it, deliberately. What stays pinned
  300 rows down is search and the actions; a filter row is content, and
  content scrolls.
- **The app bar follows the system, `kToolbarHeight`** —
  `SdAppBarV3.toolbarHeight`. Owner's rule. It was shorter for a while, on the
  reasoning that every point of chrome on every route is a row of inventory;
  the bar reading as *this app's* bar rather than the platform's was the
  higher cost. Taken through the spacing scale, not as the raw constant —
  everything the bar contains is scaled, and a raw dimension next to a scaled
  child drifts apart on any device whose aspect differs from the design
  canvas. **The title stays `titleMedium`**: a screen title is a
  label, not a headline, and the screen's own content is what should be
  loud.
- **A screen whose search box is the point uses `SdSearchHeaderV3`, not an
  app bar with a field under it.** The field docks into the title's row as
  the list scrolls and the filter strip pins under it, so scrolled chrome
  costs one bar instead of three. Inventory is the reference implementation.
- **The search field shrinks as it docks:
  `SdSearchFieldV3.expandedHeight` in its own row,
  `SdSearchFieldV3.dockedHeight` once it is in the bar.** Owner's rule. The
  docked height equals `SdAppBarActionV3.slot` — the pill and the action share
  that row, so they share a height and read as one piece of chrome rather than
  two things centred near each other. The field used to equal the full bar
  height, which left it running edge to edge with no air above or below while
  the action beside it floated; one control bursting out of the row reads as a
  misalignment even when both are centred. The leftover splits evenly top and
  bottom. **A control docking into the bar pads itself; it does not fill the
  bar.**
- **The FAB is `SdFabV3`, never Material's.** It is shorter than Material's
  and sheds its label while the list is moving — but it never hides. A create
  action a seller has to hunt for is one they stop using.
- **Every screen that creates something uses that same button, in that same
  place.** Owner's rule. Not an `IconButton` in the app bar, not a row at the
  bottom of a list — the labelled FAB Inventory has. `AppAddFabScaffold`
  (`lib/core/widgets/app_add_fab_scaffold.dart`) is the one implementation:
  it owns the scroll notifier, installs the `NotificationListener` around the
  body, and lifts the button clear of the floating tab bar when the screen is
  a tab. Screens pass a label and a callback and get the behaviour.
  - **`floatingNav` is true on the five tab screens and false everywhere
    else.** A pushed route has no glass bar under it, so the inset would leave
    the button hovering above nothing.
  - A screen whose create action needs more than a tap — one that opens a
    sheet or a form — still uses this button. What the tap *does* is the
    screen's business; where the seller looks for it is not.

**The effect degrades by itself.** `SdGlassV3.isSupported` is false on
Android's Skia fallback and in widget tests, where the bar renders `FakeGlass`
— same geometry, flat fill, nothing reflows. Do not branch on it at a call
site.

why: see DECISIONS.md § The app bar stays opaque

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

why: see DECISIONS.md § Seller OS pays for v2's dependencies

## Spacing — one class owns it, and nothing else does

Ported from BaroEase's `SdContentPaddingV2`, which v3 was copied from. Read
this before adding any inset, gap or padding anywhere.

### The one law

**No widget and no screen holds spacing logic — `SdContentPaddingV3` does.**
Not the scaffold, not the app bar, not a screen. Any inset another widget pads
by is a static on that one class.

The only thing a widget keeps is its **own intrinsic size** — a bar's height,
a badge's max count, a card's radius, a divider's thickness. That is what the
widget *is*, not configuration about it.

Under it sits `SdSpacingConstant` in the package's generation-neutral `core/`:
every screenutil dimension, one home, **no version suffix**, because a raw
dimension belongs to no generation. Naming is unit prefix + design-size value.
Getters, not consts — screenutil resolves at runtime, after `ScreenUtilInit`.

**No raw `16.w` / `12.h` / `20.r` in any widget, ever.** A mockup measuring 13
becomes 12: snap to the ladder rather than adding a rung.

### The fields

Names only — the values live on the class, and see "two rules about the rules"
below for why they are not repeated here.

**The screen frame**

| Field | What it is |
|---|---|
| `horizontal` | the gutter, either side of all content |
| `topGap` | app bar to first item — a separate field from the bottom on purpose, because breathing room under chrome and thumb room above the home indicator are different problems and each must move without dragging the other |
| `bottomGap` | last item to whatever is below it |
| `screen(context, {floatingNav})` | gutter + bottom, the whole thing |
| `fullBleed(context, {floatingNav})` | same vertical insets, no gutter, for rows that inset themselves |

**Rhythm inside the content**

| Field | What it is |
|---|---|
| `listItemGap` | between two items of the same list — **one number for every list in the app**, and the gap from a filter row down to its list is also this, because a filter sits above the list like one more item above the first |
| `sectionGap` | between two whole cards or sections stacked on a screen — a distinct section, not a repeated row, so it gets the roomier number |
| `sectionHeader({first})` | a heading's own insets; `first` drops the top gap because `topGap` already placed it. Its gutter is the *list's*, so the heading lines up with the left edge of the rows under it |
| `button` | the one padding every button variant wears, so filled, outlined and text buttons never come out different sizes next to each other |
| `card`, `row` | the inside of a card, and of a list row that is not one |
| `filterStrip`, `filterStripGap` | the chip strip's height and its internal air |
| `pinnedActionsGap` | above a pinned bottom action. Its own field, not `bottomGap`: that one is the air *below* the last item, and pinning created a second edge on the side the content arrives from |

**Chrome the content has to clear**

| Field | What it is |
|---|---|
| `bottom(context, {floatingNav})` | where the last item ends. `floatingNav: true` on the five tab screens only |
| `detailBottom(context)` | the plain rule for everything else: the device's safe area **floored** at `minDetailBottom`, and **deliberately not `bottomGap` on top of it** — a device reporting a deep inset already gives more room than the floor asks for, and stacking a gap on it makes a detail screen look like it ends early |
| `floatingBarHeight` / `floatingBarRadius` | the glass bar's height, and its radius **derived** as half of it |
| `floatingBarHorizontal` | side margin shared by every floating bar |
| `navBarOffset(context)` | the device's bottom inset **clamped** between `minNavBarOffset` and `maxNavBarOffset` |
| `floatingBarInset(context)` | offset + height — the bar's whole footprint, what content and overlays must clear |
| `statusBarInset(context)` | the status bar, for the one thing that draws chrome from the top of the window itself |
| `keyboardInset(context)` | how far the keyboard covers the window |

### What v3 deliberately does NOT have

`v3` is a copy of `v2`, not a binding. Two fields were dropped because this
product's chrome differs, and **an unused inset is one more number that can
disagree with reality** — do not port them back "for later":

- **`appBarInset` — deleted.** v3's app bar is opaque, so `Scaffold` has
  already subtracted it by the time a body builds. `top` is `topGap` alone.
  `statusBarInset` is not a replacement: it exists only for
  `SdSearchHeaderV3`, whose `maxExtent` has no context to read from.
- **`belowPinnedFilterBar` — not ported.** It is `appBarInset` plus the
  strip's height, and with an opaque bar the first term is zero. Nothing here
  pins a filter strip over a scrolling list either: a filter strip is its own
  widget in the body and takes real layout space, so nothing has to clear it.

The same call covers `SdCollapsingFilterScaffoldV2`, `SdPinnedFilterBarV2` and
`SdFloatingBarScopeV2`, none of which v3 has. **v3's chrome is its own design,
not an unfinished copy of v2's** — `DECISIONS.md` has the reasoning and one
known open item. Read it before "finishing the port".

### The traps — each one cost a real bug

- **Insets come off the view, not the ambient `MediaQuery`.** `Scaffold` wraps
  its body in `removePadding(removeTop)` when there is an app bar and
  `removeBottom` when there is a bottom bar, so the same read returns different
  numbers above vs inside the body — 0 for the home indicator where the
  screen's own build got the real inset, and the last row of every tab screen
  ends up *behind* the nav pill. Read `MediaQueryData.fromView(View.of(
  context))`; the inset is a property of the window, so the view is the one
  place with a stable answer. `SdContentPaddingV3` does this in one private
  helper and **feature code never reads `MediaQuery` for spacing at all**.
  - The one exception is `keyboardInset`, which reads the ambient
    `MediaQuery` on purpose: the keyboard is transient, and a route animating
    one open needs the value that changes with it rather than the window's
    resting state.
- **Never re-add an inset the class already applied.** `SdScaffoldV3` adds no
  padding — no `SafeArea`, no insets — and every screen pads its own
  scrollable *inside* the scrollable, so content still scrolls behind the
  chrome. A scaffold-level `SafeArea` plus a body clearing the floating bar is
  how insets double up. `SdBottomSheetV3` lifts itself over the keyboard, so a
  caller that also wraps it in a `Padding` applies the same inset twice.
- **Two things that must line up get the value measured ONCE and handed to
  both.** `SdSearchHeaderV3` passes `topPadding` down to its delegate rather
  than letting the delegate read it, because a read inside the `Scaffold` body
  differs from the read at the site that pads the list — and then the strip
  and the gap never agree.
- **A floating bar's height is one field, never typed twice.** It drifted once
  in the sibling app and the difference was silently eaten out of `bottomGap`.
  Same for the radius: derive it from the height rather than typing a literal
  that only looks right because the shape clamps it.
- **A divider occupies exactly the line it draws.** Material's reserves height
  around a 0-thickness rule, so a "1px line" costs real vertical space and two
  rows drift apart for reasons nothing at the call site explains. Pass
  `height` equal to `thickness`; the gap around a divider belongs to whoever
  places it.
- **The default test view has no notch**, so every one of these bugs costs
  exactly 0 pixels in a widget test. `pumpScreen` gives the view the device's
  real top and bottom insets, and pins it to the design size — screenutil's
  `.sp` on the default surface scales fonts about double and breaks layout.

### Two rules about the rules

- **Numbers live in the class; docs point at the field rather than repeating
  the value.** Write `` `listItemGap` ``, never `` `listItemGap` (12) ``,
  anywhere outside the class itself. A number copied into a sentence is a
  number that goes stale silently — the sibling app's prose still claims a gap
  the code stopped using.
- **A new spacing need is a new field on the class, on its first use** — not a
  literal now and a cleanup later. If two call sites would want the same
  indent, that is the moment it becomes a field, never a number typed twice.

## Visual rules for screens that use it

- **Colour is never the only signal.** A state told by colour is also told by
  an icon, a label or a shape. `SdBadgeV3` always carries a label for exactly
  this reason — Seller OS draws a dozen states across items, listings, orders
  and offers, and a colour-only marker is a memory test.
- **One loud element per screen.** `SdHeroStatV3` is a filled, gradient card
  and a screen gets at most one; everything else is an `SdStatTileV3`. Four
  equal tiles say four things matter equally, which on a dashboard means none
  of them does. Same rule for `SdCardV3(elevated: true)` and
  `SdIconTileV3(filled: true)`.
- **Depth is border-first, shadow-second.** The hairline separates a card in
  every palette; `SdElevationV3` only adds a shadow where there is a lighter
  page behind it to darken, and dark mode sets `SdThemeV3.shadow` transparent
  so it vanishes. That is the intended look, not a degradation.
- **A list of physical things gets a thumbnail, not an icon.** Sellers
  recognise a row by the picture. Icons in tinted `SdIconTileV3` squares are
  for categories and status rows, where there is no picture to show.
- **Every price, cost and total uses `.tabular3`.** Proportional digits are
  why a column of money appears to shuffle sideways as it updates, and this
  app is mostly columns of money.
- Motion: `SdMotionV3` only. No widget writes a `Duration(milliseconds:)`.
  Animations must be calm — fade/scale/slide, short, gentle curves. Never
  flashing or strobing.

## Dimensions and colour

- **Responsive sizing via `flutter_screenutil`** (design size 390×844,
  `minTextAdapt: true` — `SellerOsApp.designSize`), but NEVER as raw literals
  in widgets: every dimension goes through `SdSpacingConstant` —
  `w*` horizontal, `h*` vertical, `r*` square/radius, `sp*` font.
  `SdSpacingConstant` lives in the package's generation-neutral `core/`, so it
  is the same class v2 uses; there is no `V3` suffix and none is coming.
- **Colour comes from `AppColors` (`lib/core/theme/`), never from the
  package.** This is where Seller OS differs from BaroEase, whose palette
  ships inside `system_design`: here the app owns the palette and hands it to
  the design system as an `SdThemeV3` theme extension. So a *screen* reads
  `context.colorScheme3` / `context.sdTheme3` or names an `AppColors` constant;
  a *package widget* reads the extension and never names a colour at all.

## Snackbars, dialogs and sheets

All three are built in `v3/` and in use across the app. **Never reach into
`v2/` for them** (hard rule 17), and never call the raw Flutter API as a
stopgap — a stopgap is how the app ends up with two snackbar looks.
`WIDGET_RULES.md` governs how to build a new one.

- Snackbars: always `SdSnackBarUtilsV3.success/error/info` — never raw
  `ScaffoldMessenger.showSnackBar`. It draws the app's own card and shows one
  message at a time. Pass a finished localized string; the kind picks the icon
  and accent, and the icon always differs so colour is never the only signal.
  **It must draw into the root `Overlay`, not a `ScaffoldMessenger`** — a
  messenger renders into the nearest registered `Scaffold`, so a route without
  one sends its messages to the screen *underneath*, where the very sheet that
  raised them covers them up. Widget tests do not catch it: `find.text`
  matches a widget the user cannot see. Placement is a second prop —
  `SdSnackBarPlacementV3.bottom` is the default and what every screen wants,
  `top` is for a route that owns the bottom of the screen. Assert on
  `SdSnackBarCardV3`, the only public handle on what a static presenter drew.
- Dialogs: always `showSdDialogV3` + `SdDialogV3`/`SdDialogOptionV3` — never
  raw `showDialog`.
- Sheets: always `showSdBottomSheetV3` — it must use the root navigator so
  sheets cover the floating glass tab bar; raw `showModalBottomSheet` slides
  under it.
- Use `SdPressableScaleV3` for tactile button feedback.
