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

- **The gap from the app bar down to the content under it is 12** —
  `SdContentPaddingV3.topGap`. It is what `screen()`, `fullBleed()` and
  `sectionHeader()` are built on, so changing it is one edit.
- **The app bar is 48 tall, not `kToolbarHeight`'s 56, and its title is
  `titleMedium`** — `SdAppBarV3.toolbarHeight`. A screen title is a label,
  not a headline; the screen's own content is what should be loud.
- **A screen whose search box is the point uses `SdSearchHeaderV3`, not an
  app bar with a field under it.** The field docks into the title's row as
  the list scrolls and the filter strip pins under it, so scrolled chrome
  costs one bar instead of three. Inventory is the reference implementation.
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
