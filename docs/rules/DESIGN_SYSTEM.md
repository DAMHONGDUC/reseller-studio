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
call, so both apps' floating bars sit identically. It caps at 20 against a
portrait iPhone's 34pt home-indicator inset; that trade is documented on the
getter.

### The chrome is minimal, and its numbers live in the design system

Owner's rules, all of them read from one place so no screen types them:

- **The gap from the app bar down to the content under it is 8** —
  `SdContentPaddingV3.topGap`. Owner's rule. The bar already carries a band of
  empty space at its own bottom edge, the more so now it is a full 56 —
  anything more under it reads as a hole between the chrome and the page.
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
- **The app bar follows the system: 56, `kToolbarHeight`** —
  `SdAppBarV3.toolbarHeight`. Owner's rule. It was 48 for a while, on the
  reasoning that eight points of chrome on every route is a row of inventory;
  the bar reading as *this app's* bar rather than the platform's was the
  higher cost. Taken through the spacing scale (`h56`), not as the raw
  constant — everything the bar contains is scaled, and a raw 56 next to a
  scaled child drifts apart on any device whose aspect differs from the
  design canvas. **The title stays `titleMedium`**: a screen title is a
  label, not a headline, and the screen's own content is what should be
  loud.
- **A screen whose search box is the point uses `SdSearchHeaderV3`, not an
  app bar with a field under it.** The field docks into the title's row as
  the list scrolls and the filter strip pins under it, so scrolled chrome
  costs one bar instead of three. Inventory is the reference implementation.
- **The search field shrinks as it docks: 48 in its own row,
  `SdSearchFieldV3.dockedHeight` (44) once it is in the bar.** Owner's rule.
  44 is `SdAppBarActionV3.slot` — the pill and the action share that row, so
  they share a height and read as one piece of chrome rather than two things
  centred near each other. The field used to equal the full bar height, which
  left it running edge to edge with no air above or below while the action
  beside it floated; one control bursting out of the row reads as a
  misalignment even when both are centred. The leftover splits evenly, ~6pt
  top and bottom. **A control docking into the bar pads itself; it does not
  fill the bar.**
- **The FAB is `SdFabV3`, never Material's.** It is 48 tall against
  Material's 56 and sheds its label while the list is moving — but it never
  hides. A create action a seller has to hunt for is one they stop using.

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

## Snackbars, dialogs and sheets — the v3 primitives do not exist yet

These four rules are inherited from the sibling app and are written against
the v3 names they will have. **None of them is built in `v3/` today**, and no
screen in `lib/` currently needs one — there is not a single raw
`showDialog`, `showModalBottomSheet` or `ScaffoldMessenger` call in the app.
So this section is a specification for the first person who needs one, not a
description of what is there.

**Build the v3 widget first, then use it. Never reach into `v2/` for these**
(hard rule 17), and never call the raw Flutter API as a stopgap — a stopgap is
how the app ends up with two snackbar looks. `WIDGET_RULES.md` governs how to
build them.

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
