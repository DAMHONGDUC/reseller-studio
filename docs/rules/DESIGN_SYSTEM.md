# Design system — `system_design` v3

Read this when touching `packages/system_design/`, or when building any screen
or widget that renders `Sd*` v3 components.

## `system_design` — the design system is a separate package

Tokens and string-free widgets live in `packages/system_design`, a **separate
git repo checked out here as a submodule** (`DAMHONGDUC/system_design`), wired
in as a path dependency. There are two imports and no others — the index for
anything with a look, and `common.dart` for the shared app infrastructure that
has none:

```dart
import 'package:system_design/index.dart';   // tokens and widgets
import 'package:system_design/common.dart';  // SdLogger, SdCrashReporter
```

**`common.dart` is pure Dart on purpose** — it exports no widget, so a
feature's `domain/` can log without importing Flutter. `index.dart` re-exports
it, so a widget file that already imports the index has `SdLogger` and never
needs both lines.

**The package holds two generations and Reseller Studio renders on v3.**

| | `v2/` | `v3/` |
| --- | --- | --- |
| Renders | BaroEase | **Reseller Studio** |
| Palette | dark only | light + dark |
| App bar | frosted glass, body scrolls behind | opaque, takes layout space |
| Tab bar | floating glass pill | floating **liquid glass** pill |
| Context getters | `context.sdTheme` | `context.sdTheme3` |

### The tab bar is liquid glass and that makes its geometry layout

`SdBottomNavigationV3` is the complete tab frame: it owns the extended
scaffold, `SdFloatingBarScopeV3`, swipe handling and `SdGlassNavBarV3`.
`AppShell` supplies app routes and localized labels only; rebuilding the frame
there would leave swipe and glass clearance as app-specific behaviour.

Horizontal swipes move one adjacent tab. A horizontal scrollable inside a tab
wins Flutter's gesture arena, so filter strips and carousels keep their own
gesture; a swipe at either end does nothing. Taps and swipes call the same
`onSelected` callback, which keeps routing and analytics on one path.

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

**A detail screen has no bottom nav at all.** Owner's rule. A route nested in
a `StatefulShellBranch` is pushed onto that *branch's* navigator by default,
so the shell and its bar stay drawn over it — "pushed route" is not the same
as "no bar", and that is exactly why Expenses and Categories had rows sitting
under the glass. Every route under a tab therefore names
`parentNavigatorKey: AppNavigatorKey.root`, which pushes it above the shell.
Only the five branch roots keep the bar.
`test/core/router/detail_routes_leave_the_shell_test.dart` walks the route
tree and names any route that forgot.

**No content in this app is ever covered by the bottom nav — the screens with
the floating add button included.** Owner's rule, and it is the *outcome* the
three points above exist to produce, stated separately because they are the
mechanism and this is the promise. The clearance under the last row is
`bottomGap`, which is the same value `SdContentPaddingV2.bottomGap` uses so
the two generations end a list with identical air.

- A screen with the FAB clears the button **as well as** whatever is under it,
  through `AppAddFabScaffold.listPadding` — every such screen uses it rather
  than padding by hand, Inventory's sliver included.
  **`kFloatingActionButtonMargin` is a term in that sum, not a rounding
  error.** `Scaffold` adds its own margin under a FAB whatever the caller
  does, so a clearance of `inset + SdFabV3.size` is short by exactly 16 — that
  is what put the last row of Expenses behind the button while four sibling
  screens with shorter lists looked fine.
- **A centred widget has to be told too.** `SdEmptyStateV3` centres itself,
  and on a tab screen the body it centres in runs under the glass — so it
  reads `SdFloatingBarScopeV3` and pads its own bottom by `floatingBarInset`.
  Nothing centred in a tab body may skip this; centring against a height the
  seller cannot fully see puts the message low and its last line behind the
  bar.
- `test/core/widgets/content_clears_nav_bar_test.dart` scrolls all five tabs
  to the end and measures the last row. **It picks the *vertical* `Scrollable`
  on purpose** — Orders and Inventory put a horizontal chip row above the
  list, so `find.byType(Scrollable).first` is that strip, dragging it
  vertically scrolls nothing, and the assertion passes for the wrong reason.

**The bar follows the iOS system Liquid Glass tab bar** — owner's rule, and it
decides the arguments the look would otherwise keep re-opening:

- It wears `SdElevationV3.modal`, not `.raised`. It floats over every screen
  and never scrolls away, so it belongs in the same depth band as a sheet
  rather than at the height of the cards passing under it.
- **The current tab is marked by the glyph filling in *and* by a glass
  capsule behind it, and the capsule slides.** Owner's rule, and it **reverses
  the earlier "nothing behind the glyph"** — see below for what changed and
  why. `SdIconV3.fill` drives the font's `FILL` axis, so one glyph morphs
  rather than two swapping; weight stays a real second signal alongside
  colour, which colour alone must never be.
- The corner stays a `LiquidRoundedSuperellipse`, not a circular radius —
  the capsule's too, at the same family of corner as the bar it sits in.

`test/core/widgets/nav_bar_marks_the_current_tab_test.dart` holds all three.

#### The bar is glyphs only — no words on any tab

Owner's rule, given as the sibling app's own bar: **five equal segments, one
icon each, and nothing written under them.** It replaces the earlier "always
rendered — five glyphs with no words is a memory test", and the argument that
lost is that the bar is five destinations a seller opens every day, not a menu
they read. The words cost a line of type across the whole width of the chrome
to say what the seller learned on their second launch.

- **The label has not gone; it stopped being painted.**
  `SdNavDestinationV3.label` is still required and is still the `Semantics`
  label of every segment, with the segment marked `container: true` so a
  screen reader hears one node saying one name. Nothing about the bar is
  icon-only to somebody who cannot see it.
- **The segments stay equal, and the capsule keeps sliding at one width.**
  There is no expanding segment: an icon-only bar has nothing to expand for,
  and equal thirds are what make the row read as one control.
- **The glyph still fills in.** `SdIconV3.fill` on the font's `FILL` axis is
  now the *only* signal besides colour and the capsule, so it matters more
  rather than less — colour alone must never be the mark.

#### The selected capsule is a tinted thumb inside the glass bar

Owner's rule, taken from the reference switcher. The bar is the one Liquid
Glass surface; the selected segment is a **tinted `DecoratedBox`** sliding
inside it. A second Liquid Glass layer made the active segment too subtle over
light content, so it stopped reading as a switcher.

Two things follow:

- **The thumb uses the primary colour at `selectedThumbOpacity`.** It is clear
  enough to mark the selected icon without becoming a solid Material button.
  The filled glyph is the second signal, so colour is never the only one.
- **It slides; it does not fade in and out.** One thumb moving is what says the
  tabs are one control. `SdMotionV3.normal` on `SdMotionV3.emphasized` moves
  it from the current segment to the next, and a re-tap does nothing.
- **It slides; it does not fade in and out.** One capsule moving is what says
  the tabs are one row. `SdMotionV3.normal` on `SdMotionV3.emphasized` — the
  motion enters and leaves in one animation, so `standard` would land it
  abruptly. Tapping mid-flight redirects the capsule from where it *is*, not
  from the tab it was heading to.
- **It stays one segment wide while it slides.** The icon-only bar has no
  label to make room for, so a stretch is unrelated motion. `AnimatedAlign`
  moves the capsule; `FractionallySizedBox` keeps it at `1 / count` of the
  track and `selectedTabInset` separates it from neighbouring segments.

The geometry is `SdContentPaddingV3.selectedTabInset` inside the bar on every
side, and nothing types that number at a call site.

**The switcher stays compact and keeps its horizontal outer inset.** Owner's
rule, reversing the edge-to-edge variant: `floatingBarHorizontal` detaches the
visible pill from the screen edges while every equal segment remains a full
touch target. Compactness comes from the chrome's height, never from shrinking
the icon or its tappable region.

**The glass is tuned sheer and refractive, not frosted** — owner's rule, and
it is the one that decides how the bar is read at a glance. A high-alpha fill
with a heavy blur is a frosted panel: it says "surface", and the page under it
stops existing. The tuning is the other way — a low `glassColor` alpha, a
thick pane at a real `refractiveIndex`, and enough `lightIntensity` for the
specular rim to draw the shape's edge. What keeps the labels legible is the
blur plus that rim, never opacity.

**`chromaticAberration` stays 0 on this bar.** It sits over columns of money,
and colour fringing on small tabular figures is the fastest way to make a
number hard to read. Every other glass knob is tunable; this one is a rule.

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
  things **the header itself draws** is not the screen's `topGap`, even at the
  same value. Read the emphasis: it once carried a `stripGap` for the filter
  strip, which the header does *not* draw, and that gap was then placed twice.
- **A filter strip is never part of the app bar, and it stays put while the
  list scrolls.** Owner's rules, and they are not in tension: the strip is its
  own widget below the chrome with the body's background, and it is *pinned*
  there rather than lifted into the bar. `SdSearchHeaderV3` still holds only
  the title, the search field and the actions — there is no `bottom` slot on
  it, deliberately.
  - Orders gets this for free: its strip sits in a `Column` above an
    `Expanded` list, so it was never inside the scrollable.
  - Inventory's list *is* the scrollable — the search header has to live in it
    to dock — so its strip is a `SliverPersistentHeader(pinned: true)` whose
    extent is `topGap * 2 + AppFilterStrip.height`, plus
    `AppActiveFilterBar.height` and the gap above it while something is
    filtered. That band carries both outer gaps, so the screen places neither.
    **The delegate rebuilds when that row appears**: a pinned sliver states its
    extent before it lays anything out, so a row coming and going inside a
    fixed extent would be clipped.
  - **This reverses the earlier "a filter row is content, and content
    scrolls".** Chips a seller cannot reach 300 rows down are chips they
    scroll back up for, which is the cost the docking header exists to avoid.
- **A filter strip carries no gap of its own and fits its chips exactly, and
  the screen places `topGap` above it and the same below.** Owner's rule, and
  it is the one-owner rule applied to the one widget that kept breaking it.
  `AppFilterStrip` (`core/widgets/`) is that strip — every screen uses it,
  none builds its own. There is **no `filterStrip` height and no
  `filterStripGap`**: both were deleted, because a fixed-height box with an
  internal vertical inset means the daylight above a chip is built from two
  numbers owned by two files. A `Row` inside a horizontal scroll view has
  exactly the height of its chips and no opinion about what is above or below
  it. `test/core/widgets/filter_strip_gap_test.dart` measures the chip
  against the strip's own edges, so any padding creeping back in fails.
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
- **An icon-only app bar action is `SdAppBarActionButtonV3`, and no screen
  builds an `IconButton` in an app bar.** Owner's rule. The same control was
  drawn six ways: Home's search and the notification bell as raw `Icon`s at
  whatever `IconTheme` happened to set, Orders' two at `SdIconV3.defaultSize`,
  the marketplace and carrier deletes at `r24`, and the search header's own
  privately inside its delegate. Three sizes of one control, on bars a seller
  moves between all day. The widget owns the slot, the glyph size, the colour
  and the shrink-wrapped tap target; `SdSearchHeaderV3` renders its actions
  through it too, so a docked header and a plain bar cannot come out
  different.
  - **The glyph is `SdAppBarActionButtonV3.glyphSize`, which is larger than
    `SdIconV3.defaultSize`.** Owner's rule, and the same argument as the end
    glyph below: a control at the top of every screen that a seller has to
    look for is one they stop reaching for. It is the size the two delete
    actions had already drifted to on their own.
  - **An action whose state is on wears `isActive`, and it fills as well as
    tints.** Owner's rule, given for the filter glyph over a filtered list.
    The `FILL` axis of the variable font is how the nav bar already marks the
    current destination, so the state survives a palette a colour-blind seller
    cannot separate — colour is never the only signal. An explicit `tint`
    still wins the colour; the fill is the half that cannot be argued with.
  - **A header compares the actions it was handed, never how many.**
    `SdAppBarActionV3` carries value equality over what it draws — `onPressed`
    is left out, because a closure is new on every build and an action would
    never equal itself. A delegate comparing `actions.length` is why a lit
    glyph stayed unlit until something else rebuilt the header.
  - **An unread mark is `dotColor`, not a `Stack` at the call site.** The dot
    sits on the glyph's corner, and only the button knows where the glyph is —
    `NotificationBell` used to pin one to a raw `Icon` whose size it did not
    control.
  - **`onPressed` is nullable**, because a disabled action is a real state: a
    delete is refused while a save is in flight, and hiding the row instead
    would move everything beside it.
- **A labelled action in a detail screen's app bar uses the medium button
  proportions.** Owner's rule. The small button keeps `labelLarge` text while
  scaling down its glyph and gap, so the word outweighs the icon and the pair
  reads as two unrelated sizes. `AppDetailActionButton` is the shared app-side
  wrapper; detail screens do not rebuild its padding or button size.
- **A screen whose search box is the point uses `SdSearchHeaderV3`, not an
  app bar with a field under it.** The field docks into the title's row as
  the list scrolls and the filter strip pins under it, so scrolled chrome
  costs one bar instead of three. Inventory is the reference implementation.
- **`SdSearchFieldV3` draws its own pill; the fill, border and radius are not
  an `InputDecoration`.** They were, and `InputDecorator` sizes its content to
  itself: stretched from outside by a `SizedBox` it painted the full height
  but laid the text and the magnifier out at the *top*, ten points above the
  middle of a docked field — which is what made the bar look mis-set against
  the actions beside it. `textAlignVertical` cannot fix that; with
  `isCollapsed` there is no spare space for it to centre within. A plain `Row`
  in a box the widget owns centres its children and needs no persuading.
  The glyph sits `height / 2` from the edge, so it lands in the middle of the
  stadium's round cap and mirrors the clear button on the right at whatever
  height the field is currently drawn at.
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
- **A row in a sheet that can be the chosen one is `AppSelectableRow`**
  (`core/widgets/`). It owns the ground, the corner and the hit target, and
  nothing else — what "chosen" looks like inside stays the sheet's, because
  the picker ticks the row while the workspace switcher fills its icon tile.
  Two things it settles that a hand-rolled `InkWell` kept getting wrong: a
  one-line row is otherwise only as tall as its text, which is under the 44pt
  Apple asks for; and the chosen row said so only with a tick at the far right,
  which is a long way from the label somebody is actually reading. **Colour is
  never the only signal** — the ground comes with a weight change and a glyph.
  Rows separated by a gap rather than a hairline: each carries its own rounded
  ground, and a rule cutting through that reads as two competing shapes.
- **The rule between two rows is `SdDividerV3`, never Material's `Divider`.**
  Material reserves a whole `height` around a rule only `thickness` tall, and
  defaults that height to 16 — so a call site asking for a hairline silently
  pays 16 of vertical space that nothing nearby explains, and the gap cannot
  be reconciled with the spacing ladder. `SdDividerV3` occupies exactly the
  line it draws, takes its breathing room as an explicit `gap`, and resolves
  its own colour. **Between items only** — a rule on a container's own edge
  reads as a border it does not have.
- **A message is `SdSnackBarUtilsV3`, never `ScaffoldMessenger`.**
  `ScaffoldMessenger` renders into the nearest `Scaffold`, so a message
  raised from a pushed route or a sheet cannot see `SdFloatingBarScopeV3` and
  lands inside the glass tab bar instead of above it. The presenter draws
  into the root overlay, which is also what lets a message outlive the route
  that raised it — pop first, then call it.
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

why: see DECISIONS.md § Reseller Studio pays for v2's dependencies

## A card that is a row is info at the start and an affordance at the end

Owner's rule. **Every row-shaped card lays out `space-between`: the information
at the start, and at the end one glyph telling the seller something happens
when they tap it** — a chevron for a row that opens something, `more_vert` for
one that opens a sheet of verbs.

- **A tappable row without an end glyph is the bug this rule exists for.** The
  whole card is a tap target and nothing on it says so, so the seller learns
  the screen by poking at it. `AppListRow` has always drawn the chevron by
  default; the violations were rows that passed `showChevron: false` while
  still passing an `onTap`.
- **The converse still holds, and it is the older rule**: an inert row draws
  no chevron. "An affordance that leads nowhere is worse than none" —
  `AppListRow.showChevron`. So `showChevron: false` is correct **only** on a
  row with no `onTap`, or one whose `trailing` widget is itself the
  interaction (a switch, a delete button).
- **A card built by hand rather than from `AppListRow` obeys it too.** The
  order card, the offer card and the receipt row are `SdCardV3`s with their
  own layout; each wraps its content in a `Row` with the glyph as the last
  child, rather than growing a private idea of what a tappable card looks
  like.
- **The end glyph is `AppRowChevron`, and nothing draws one inline.** Owner's
  rule. Five call sites had grown their own — three at `smallSize` in
  `textTertiary`, one a raw `Icon` at Material's default in `textSecondary` —
  so a seller scrolling Home met three sizes of the same promise. The widget
  owns the glyph, the size and the colour; a call site passes nothing.
- **It is `textSecondary` at `SdIconV3.defaultSize`.** Owner's rule, and it
  **reverses `textTertiary` at `SdIconV3.smallSize`**. The old pair was
  argued as "a hint, not content", and the hint lost: at 16 points in the
  faintest grey the app has, the one mark saying a card opens something was
  the thing sellers did not see. An affordance is not decoration — it is the
  instruction, and it is read before the content it sits beside. It still
  never outweighs the title: the title is `semiBold3` text, the glyph is a
  grey the tier above faint.
- **A tappable end glyph keeps a 44pt target, and the target overhangs the
  padding rather than pushing the glyph inward.** Owner's rule, and it
  **reverses "the whole target stays inside the card's padding"**. Centring a
  20pt glyph in a 44pt box that stops at the content edge sets the glyph 12
  points short of every plain chevron in the app, so the item card's dots and
  arrow sat out of line with the column of chevrons on Orders and Offers —
  which `row_affordance_test.dart` had been failing on. The overhang is
  invisible: it is ink over the card's own inset. The misalignment was not.
  `AppRowIconButton` (`core/widgets/`) is that control — the actions dots, a
  row's delete — and it lays out at the glyph's width while its `InkResponse`
  overflows to the target.
- **Cards that are not rows are out of scope.** Home's three shortcut cards
  are columns — a glyph over a label, three across — and a chevron on each
  would be three arrows pointing at nothing. So are the stat tiles and the
  hero card, which are figures rather than rows.
- `test/core/widgets/row_affordance_test.dart` reads the source and fails on a
  tappable `AppListRow` that hides its chevron and offers no trailing widget.

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
| `floatingBarHorizontal` | the outer horizontal inset that detaches the floating bar from the screen edges |
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

The same call covers `SdCollapsingFilterScaffoldV2` and `SdPinnedFilterBarV2`,
neither of which v3 has. **v3's chrome is its own design, not an unfinished
copy of v2's** — `DECISIONS.md` has the reasoning. Read it before "finishing
the port".

`SdFloatingBarScopeV3` is the one that *was* ported, because leaving it out
cost a real bug: see the snackbar entry under "Snackbars, dialogs and sheets".

### Every spacing refers to one value, and exactly one owner places it

Owner's rule, and the widest of the spacing rules — the ones below sharpen it
rather than compete with it. **No gap is ever built by adding two numbers
that both mean "the space here".** A distance with two owners is a distance
that drifts, and it drifts invisibly: each file looks right on its own.

- **A boundary belongs to one side of it.** The filter strip sits in the
  body, so the *screen* places `topGap` in front of it.
  `SdSearchHeaderV3` used to reserve a second gap of its own for the same
  boundary, and Inventory's chips sat 8 points below every other screen's
  while both files read correctly. The header now reserves the field and
  nothing under it.
- **Reach for the token, never the literal that equals it.** `h8` in two
  places is one value; `h8` in one and `8` in the other is two, and only one
  of them moves when the scale does.
- `test/core/widgets/filter_strip_gap_test.dart` holds two screens against
  each other, because "looks about right" is exactly the judgement that let
  this through.

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
  this reason — Reseller Studio draws a dozen states across items, listings, orders
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
  `minTextAdapt: true` — `ResellerStudioApp.designSize`), but NEVER as raw literals
  in widgets: every dimension goes through `SdSpacingConstant` —
  `w*` horizontal, `h*` vertical, `r*` square/radius, `sp*` font.
  `SdSpacingConstant` lives in the package's generation-neutral `core/`, so it
  is the same class v2 uses; there is no `V3` suffix and none is coming.
- **Colour comes from `AppColors` (`lib/core/theme/`), never from the
  package.** This is where Reseller Studio differs from BaroEase, whose palette
  ships inside `system_design`: here the app owns the palette and hands it to
  the design system as an `SdThemeV3` theme extension. So a *screen* reads
  `context.colorScheme3` / `context.sdTheme3` or names an `AppColors` constant;
  a *package widget* reads the extension and never names a colour at all.

## Forms and input

Owner's rules. Every one of them is something a seller read wrong, so each is
fixed in a single owner rather than at the call sites that got it wrong.

- **Every field that accepts money formats grouping separators while the
  seller types.** `MoneyField` owns that behavior for the whole app: call
  sites provide the currency and parse its normalized text with `Money`, but
  never implement their own formatter. Existing values are formatted when
  loaded as well, so an edit form and a create form do not display the same
  amount differently. The formatter preserves the currency's decimal limit,
  cursor position and the distinction between an empty value and zero.

- **Anywhere a keyboard can open, a tap outside the field closes it.** Wired
  once in `SdKeyboardDismissV3`, which `SdScaffoldV3` and `SdBottomSheetV3`
  both wrap their content in — no screen writes its own `GestureDetector`, and
  no form leaves the platform's own gesture as the only way out. The hit test
  is translucent, so it is reached only when nothing nearer claims the tap, and
  a scroll drag defeats a tap, so scrolling is untouched.
  - **A sheet needs it as much as a screen does.** A sheet is a route of its
    own and is not inside the scaffold underneath it, so it inherits nothing
    from that wrapper — and a sheet is where most of this app's typing happens.
  - A field that owns its own trough and is not in either container
    (`SdSearchFieldV3` docked in an app bar) is the exception the wrapper
    cannot reach; the screen holding it dismisses on scroll instead.

- **A placeholder is fainter than any real text, and it has its own colour
  slot.** `SdThemeV3.textPlaceholder`, read through `.placeholder3(context)`.
  It sits a step below `textTertiary` on purpose: tertiary is the faintest
  colour still meant to be *read* — a caption, a timestamp, a disabled label —
  and a hint drawn in it was being taken for a value the field already held.
  Anything standing in for a value the seller has not given yet takes this: a
  text field's hint, a search field's hint, `PickerField`'s "not set". Helper
  and error text keep their own colours — those are text to read, not text
  standing in for something absent.

- **A required field is marked with an asterisk, and the widget draws it.**
  `isRequired: true` on `SdTextFieldV3`, `MoneyField` or `PickerField` appends
  it after the label in `SdThemeV3.danger`. No call site concatenates a
  `*` into a string, or the marker ends up inside an ARB value where a
  translator has to know to keep it and a screen reader reads it as a word.
  - **The marker follows what the form actually blocks on**, which is hard
    rule 2's state-based validation: a field is starred on the screen where
    submitting without it fails, and unstarred on every screen where it does
    not. A price is not required to create an item and is required to list one,
    so the same value is starred in one sheet and bare in another.
  - It never replaces the error: a starred field that is left empty still
    reports it under the field on submit.

## Snackbars, dialogs and sheets

All three are built in `v3/` and in use across the app. **Never reach into
`v2/` for them** (hard rule 17), and never call the raw Flutter API as a
stopgap — a stopgap is how the app ends up with two snackbar looks.
`WIDGET_RULES.md` governs how to build a new one.

- **A message comes from the top, and it never takes a tap.** Owner's rule,
  and both halves are one decision: a card at the bottom sits under the
  thumb that just pressed the button, and a card anywhere that swallows
  touches makes the seller wait out an animation before they can carry on.
  `SdSnackBarPlacementV3.top` is the default, and the host wraps the card in
  an `IgnorePointer` — so tap-to-dismiss is gone on purpose, and the timer is
  the only thing that takes a message away.
- **A top message starts below the app bar, never over it.** Owner's rule.
  Back and app-bar actions are primary navigation controls; a transient
  message may not obscure them even though it ignores taps. The shared host
  clears the status bar plus `kToolbarHeight`, so every call site gets the
  same safe position without screen-specific offsets.
- **An add that worked says nothing.** Owner's rule. A sheet closing and the
  new row appearing behind it is the confirmation; a card on top of it is the
  app telling the seller what they can already see, and it costs the top of
  the screen for two seconds every time they add a row. So no
  `SdSnackBarUtilsV3.success` on a create or add flow.
  - **Failure always speaks**, on every flow, because nothing on screen says
    it (hard rule 6 decides the words).
  - **A result the seller cannot see still speaks.** A bulk action on forty
    rows, an invite sent to somebody else, a copy to the clipboard, a delete
    of the record whose screen is now gone — those are successes with no
    visible evidence, and they keep their message.
- Snackbars: always `SdSnackBarUtilsV3.success/error/info` — never raw
  `ScaffoldMessenger.showSnackBar`. It draws the app's own card and shows one
  message at a time. Pass a finished localized string; the kind picks the icon
  and accent, and the icon always differs so colour is never the only signal.
  **It must draw into the root `Overlay`, not a `ScaffoldMessenger`** — a
  messenger renders into the nearest registered `Scaffold`, so a route without
  one sends its messages to the screen *underneath*, where the very sheet that
  raised them covers them up. Widget tests do not catch it: `find.text`
  matches a widget the user cannot see. Placement is a second prop —
  `SdSnackBarPlacementV3.top` is the default and what every screen wants;
  `bottom` is for a route that owns the top of the screen. Assert on
  `SdSnackBarCardV3`, the only public handle on what a static presenter drew.
  - **Drawing into the root overlay means it cannot see the glass nav bar**,
    and for a while it landed inside the band the bar occupies on all five
    tab screens. `SdFloatingBarScopeV3` wraps `AppShell`'s body and is the
    only signal that a bar is down there; `SdSnackBarUtilsV3` reads it **from
    the caller's context**, never in the entry's builder, which sits above
    the shell and would always read "no bar". A pushed route is outside the
    scope and correctly reads `false` — it covers the bar anyway.
    `test/core/widgets/snack_bar_clears_nav_bar_test.dart` asserts on the
    rendered rectangle, because a message the user cannot see still matches
    `find.text`.
- Dialogs: always `showSdDialogV3` + `SdDialogV3`/`SdDialogOptionV3` — never
  raw `showDialog`.
- Sheets: always `showSdBottomSheetV3` — it must use the root navigator so
  sheets cover the floating glass tab bar; raw `showModalBottomSheet` slides
  under it.
- **Every sheet carries a close icon, and the chrome draws it.** Owner's rule,
  and it covers everything presented as a bottom sheet — a menu, a picker, a
  form, a screen shown as a sheet. `SdBottomSheetV3` puts the button at the
  end of its title row and pops its own route, and `closeTooltip` is required
  so a new sheet cannot compile without one. The grab handle and the barrier
  tap are conventions a seller has to already know; a visible control is the
  one exit nothing has to teach, and it sits where the thumb already is.
  - **No sheet draws its own.** A second close inside the content is two
    controls doing one job, and only one of them is the one people find.
- **A sheet sizes to its content, unless it is a document.** `SdBottomSheetV3`
  is `mainAxisSize.min` by default, which is right for a menu: a sheet taller
  than its rows is a sheet with dead space under the seller's thumb. A sheet
  that is *read* rather than chosen from — the flow overview — passes
  `heightFactor` and takes that share of the screen instead, so its scrollbar
  starts at a predictable place and the page behind stays visible enough to
  say the sheet is dismissable.
  - **It is a fraction, never a number of points.** A height typed in points
    is a height that is wrong on the next device.
- **A sheet's options are separated by a rule, not by air.** Owner's rule, and
  it covers every list of choices in a sheet — an actions sheet, a picker, the
  workspace switcher. `AppSheetOptionList` (`core/widgets/`) lays the rows out
  and puts `SdDividerV3` between them, so no sheet spaces its own and they
  cannot drift apart. A column of same-weight rows with only a gap between
  them reads as one block of text a seller has to parse before they can count
  the choices.
  - Between items only, per the divider rule below: nothing above the first row
    or below the last.
  - The rule keeps a small gap either side, because a picker's chosen row draws
    a rounded ground and a hairline flush against that corner reads as two
    shapes fighting.
- Use `SdPressableScaleV3` for tactile button feedback.

## The rest of the primitives

One widget per job, and feature code never reaches past it to the raw Flutter
one. All of these are built and in use; the rules are here so a screen does not
quietly re-invent one.

- **Cards: `SdCardV3`, never Material's `Card`.** Material's carries an
  invisible `EdgeInsets.all(4)` of margin, which is how a list whose separator
  says one number comes out at another and sits narrower than the list on the
  next tab. `SdCardV3` has **no margin at all** — the space *between* cards
  belongs to whoever places them (`sectionGap`) — and takes its inside padding
  from `SdContentPaddingV3.card`, because the inset inside a card is the same
  inset in every card.
- **Buttons: the look is a prop, never a named constructor.**
  `SdButtonVariantV3` selects it and every variant wears the same
  `SdContentPaddingV3.button`, so a filled, an outlined and a text button read
  the same size side by side. `SdButtonSizeV3` scales that padding, the icon
  and the gap together — a small button is the same shape scaled, never
  differently proportioned. Material's `.icon` constructors carry their own
  padding per variant, which is exactly the drift this avoids.
- **Icons: `SdIconV3`, and it always resolves to a concrete size.** A bare
  `Icon` inherits the ambient `IconTheme`, so the same glyph comes out at
  different sizes depending on what happens to wrap it.
- **Semantic glyph choices live in `AppIconConstant`.** Owner's rule. Feature
  and shared widget code asks for meanings such as `delete` and `add`; that
  one file decides whether each meaning uses Flutter `Icons` or Material
  Symbols, so changing the glyph library never becomes a screen-by-screen
  migration. **No file under `lib/` references `Icons.*` or `Symbols.*`
  directly except that registry**, and a source test enforces the boundary.
  `SdIconV3` still owns rendering, size and colour. **Every registry entry has
  one short doc comment stating its UI meaning and one blank line before the
  next entry.** The name alone is not enough when one glyph serves several
  workflows, and the separation keeps future icon-source swaps reviewable.
- **An enum's colour — and its label — live on that enum, as one extension in
  the enum's own file** — owner's rule. `ItemStatusDisplay` sits in
  `domain/enums/item_status.dart` beside the enum, carrying
  `label(BuildContext)` and `color(BuildContext)`; `ItemCondition` has the
  same. Not a static on a presenter class, not a switch at a call site: the
  value is asked, so there is exactly one answer and adding a case breaks the
  switch that hands it out. It is the one thing in `domain/` allowed to import
  Flutter — root `CLAUDE.md` carries that exception.
- **The hue is named, never numbered.** `AppTagHue.grey`, not an index into a
  list: a number tells the reader nothing and makes them count entries to find
  out what it was.
- **Every place that draws that value as a tag draws it in that colour** —
  owner's rule, the other half of the one above. The tag on a form and the
  badge on a card are the same value; two hues for it is the seller learning
  the palette twice. `SdBadgeV3.color` exists for exactly this, and it
  overrides the tone.
- **Tags: `SdTagV3` for a group of choices, `SdBadgeV3` for a state the app is
  reporting.** The badge is read-only and takes a *tone* from the five the
  package knows; the tag is tapped and takes a **colour**, because a set that
  must be told apart — four statuses, seven condition grades — runs past what
  five tones can say. The app maps its enum to a hue (`AppColors.tagSeries`)
  and hands it over, which is the same division as everywhere else: the
  package never learns what a domain value means.
- **Read-only card metadata is `SdBadgeV3` at `SdBadgeSizeV3.compact`** —
  owner's rule, and it settles which component a card tag is. The tag is the
  interactive picker and carries a picker's padding and border; a list row
  reports facts, so it draws the badge, and `compact` scales the inset, the
  glyph and the gap together — the same shape smaller, never differently
  proportioned. The label keeps its size, because the word is the signal.
  Inventory and Order cards use this presentation; form tags keep the full
  interactive `SdTagV3`.
- **A tag's colour is never its only signal.** The label is spelled out and
  the chosen one draws a filled radio as well as a filled ground.
- **Dividers: one thickness, one colour, and between items only**
  (`if (index > 0)`). A rule above the first row lands on the container's edge
  and reads as a border it does not have. Its height equals its thickness — see
  the divider trap under Spacing.
- **A hairline inside a card runs edge to edge.** Owner's rule. A rule that
  stops at the content inset reads as a line drawn under one block; one that
  crosses the card is the seam between two. The card takes
  `EdgeInsets.zero` and the blocks it separates carry the padding —
  `AppListCard` and the inventory row's money band are both built that way.
- **Modal colour is one slot and sheets and dialogs both wear it**
  (`SdThemeV3`). A dialog opening over a sheet must never be a second shade. It
  sits a step *below* the card, not above: a modal already separates itself with
  the scrim and its corners, and going darker keeps a card on it reading as the
  nearer layer. Material trains every tool to raise a modal instead, so the
  theme overrides it — a raw `Dialog` cannot come out a different colour.
- **Anything that must stay visible while sitting *on* a card or a sheet steps
  up** to the elevated surface. A tile left on the card colour disappears the
  moment its sheet is that colour.
- **Charts hide their marks from screen readers and expose a summary instead.**
  A chart without that label is silence to VoiceOver, and this app's analytics
  is mostly charts.
- **Tapping outside a focused field drops focus** — see Forms and input
  above, which owns that rule and says where it is wired.
- Every `Text` carries an explicit `style:` — root `CLAUDE.md`, Syntax. Not
  repeated here.

**A design mockup is reference, not authority.** Where a mockup and these rules
disagree, the rules win silently: build what the rules say and say what was
overridden. Every colour comes from the palette, every dimension from
`SdSpacingConstant`, every text style from the text theme. What a mockup *is*
for is hierarchy, rhythm, density and where the eye lands — take that, leave
the tokens.

## Working inside the package

`WIDGET_RULES.md` in the submodule is the authority. These are the ones that
get broken from this side.

- **Every generation-scoped name carries its suffix, including extension
  members.** `context.sdTheme3`, `.tabular3` — the suffix is why a file
  importing `index.dart` gets both generations' extensions without either
  shadowing the other. An unsuffixed member on a generation's extension is a
  bug, not a convenience.
- **`core/` is shared and it is the only shared thing** — raw dimensions any
  generation measures in, no look, no suffix. Adding a getter is additive and
  fine; **changing or removing one edits a shipped app**, because v2 renders
  BaroEase. When in doubt it goes in the generation folder: moving down into
  `core/` later is cheap, pulling it back out once two generations depend on it
  is not.
- **Even the glass gate is copied, not shared.** `SdGlassV3` declares its own
  support check and its own settings rather than importing v2's, because the
  tuning differs per product and the check is four lines. Copying it is cheaper
  than the coupling (hard rule 17).
- **A static holder that needs a colour or a text style takes a
  `BuildContext`.** A static getter cannot reach the theme, and a value baked in
  at authoring time is exactly the coupling the package exists to avoid. Pure
  dimensions stay parameterless.
- **One folder per widget, flat — never a grouping folder.** No `buttons/`, no
  `charts/`. The flat list with one folder each is what keeps adding a widget a
  folder, a file and one `export` line.
- **Four greps catch almost every violation** before a commit, and they are
  faster than reading the diff: a literal colour (`Color(0x`, `Colors.`), a raw
  number in a widget (`\.w\b|\.h\b|\.r\b|\.sp\b` outside `SdSpacingConstant`), a
  quoted user-facing string, and an import that starts with anything other than
  the framework, a declared dependency, or a sibling widget folder.
- **The package analyzes standalone** — `melos run analyze` does it first and
  from outside the app, on purpose. If it only analyzes from inside, an app
  dependency has leaked in.
