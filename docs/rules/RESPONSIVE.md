# Responsive — one app, three widths

Read before changing any layout that must survive a window wider than a phone: the shell, a screen's frame, a panel, anything that reads a width.

No spacing values here. Every dimension named lives in `SdBreakpointConstant`, `SdScreenScale` or `SdContentPaddingV3` — `DESIGN_SYSTEM.md` § Spacing says which; this file says only when a width changes what the app does.

**The one invariant: every rule here is a no-op at phone width.** If any of it moves one pixel on an iPhone, something is wrong — and a test asserts it, not a person. That invariant is why all of this ships without re-checking the phone build by hand.

## What this replaces

The app shipped one layout for one phone, and the design system resolves every dimension through `flutter_screenutil` against `AppScreenUtil.designSize`.

- On a phone that is the point: a dimension chosen on a 6.1" canvas keeps its proportion on a 5.4" one.
- On a tablet it is the bug: the canvas is about half the window, so every padding, icon, radius and font scales up by the ratio — twice the screen, the same six rows, twice as large.
- Worse than large: screenutil resolves its four token ladders through different ratios, so a window shorter than the canvas renders stretched on one axis and shrunk on the other — grown gutters and type beside icons and tap targets smaller than the phone's. Nothing overflows, no test fails; every number is just wrong.
- `minTextAdapt` plays no part: `ScreenUtilInit` defaults `fontSizeResolver` to the width, and a resolver is consulted before the flag.

**So the first rule is about scale, not columns.** A second column on top of inflated tokens is two problems stacked.

## The three widths

- **`SdBreakpoint` is a named enum — `compact`, `medium`, `expanded` — and no call site compares a width.** Same argument as "never index a palette by number" in `CLAUDE.md`: `width > 600` says nothing about what 600 was, and the second call site types a different number. Thresholds live in `SdBreakpointConstant` alone.
- **The thresholds are Material's, not ours to invent.** They sit where the hardware is; a boundary chosen by taste lands mid-device and puts one iPad in two classes by how it is held.
- **They are raw logical pixels, never a `SdSpacingConstant` value.** They are compared against the window, which screenutil knows nothing about — a scaled threshold moves whenever the design scales, the one thing a threshold may not do.
- **Read it through `context.sdBreakpoint3`, which reads `MediaQuery.sizeOf`.** The `3` suffix is `SdContextV3X`'s convention; its reason is on that extension.
- **Measure the window, never the device.** Never `shortestSide`, never `Platform.isIOS` plus a model check, never `defaultTargetPlatform`. An iPad in Split View gives the app a window narrower than a phone while every device-shaped question still says "tablet" — so window width stays the layout input even when the platform overrides an orientation request.
- **Never cache it or read it once at route entry**, for the same reason: Split View and Stage Manager resize a live window.

  | Width | Hardware it is really about | What the app does |
  |---|---|---|
  | `compact` | Every phone, a narrow split view | Exactly what ships today |
  | `medium` | Tablet portrait | Nav becomes a labelled panel at the leading edge |
  | `expanded` | Wider tablet window | The same, and where a second column would go if one ever does |

## Tokens scale on a phone and stop at the clamp

- **The design size stays the phone canvas; the scale is clamped at `SdScreenScale.maxScale`.** The canvas grows to match the window instead of the ratio growing — which is why the clamp is a size, not a factor.
- **One class owns the ceiling, and it is not `SdBreakpointConstant`.** A width class is a layout decision at a threshold; the scale is a ratio that never steps. They were two fields answering "how big is this tablet?" with different answers — the app read one, the sibling app the other.
- **All four of screenutil's ladders stop at it, not just width.** `.w` and `.sp` take the width ratio, `.h` the height, `.r` — every icon, radius and square tap target — the smaller of the two. Floored at a phone's design height, a window shorter than the canvas drove `.r` below 1: icons and tap targets *smaller* than the phone, under Apple's minimum, beside grown gutters and type. So once the width clamp engages, height follows the same ceiling, not a phone's floor: past that point the window is a tablet, and a tablet renders one scale.
- **A framework constant is on no ladder and will not move.** `kToolbarHeight` is a raw 56 at any window, so anything measured against the app bar reads `SdAppBarV3.toolbarHeight` — same number, scaled. The one that did not overlapped the bar it should sit below.
- **The clamp sits above every phone the app ships to**, so a phone resolves exactly what it resolved before the clamp. Not a happy accident to re-derive each time: it is the safety property, and `test/core/responsive/` asserts it.
- **Clamped, never switched.** Switching the canvas at a threshold makes every dimension jump at one width — invisible on a fixed-size device, a lurch on the one that resizes.
- **The value means "the same app at arm's length,"** not "as big as it fits": a tablet is held further away, so type and touch targets earn a little growth and nothing more. A clamp of 1 is the opposite mistake — a phone-sized app stranded mid-screen.
- **One place resolves it: `AppScreenUtil`.** The only `ScreenUtilInit` in the app *or its tests*, so no tree can pass a raw canvas and quietly skip the clamp — the one tree that would never see the bug.

## Proportional columns and centred content

**The tablet panel expands and collapses.** Owner's rule, replacing the fixed panel width and the old ban on collapsing. The seller trades visible nav labels for working space without changing destinations.

- **Expanded, the sidebar takes `SdNavPanelV3.expandedPanelFlex` beside `SdNavPanelV3.expandedContentFlex`.** The owner's revised share supersedes the old expanded and collapsed proportions.
- **Its surface spans the full shell height and meets the content directly.** Owner's correction: the joined sidebar/content of iPad Settings, not a detached glass capsule. No outer panel margin, rounded outer surface, or gap to the content scaffold.
- Expanded destinations use `SdNavCellShapeV3.row`. Collapsed, the panel is hidden outright and content takes the whole window — no narrow rail.
- **Collapsed, the reopen control is the screen's own leading control.** Owner's rule. The panel draws nothing and publishes `SdNavPanelScopeV3`; the chrome the screen already wears takes the menu — `SdAppBarV3` in its `leading` slot, `SdSearchHeaderV3` in the matching place, since Inventory wears no app bar and would be the one tab with no way back. A screen never places the control itself: a screen that could place it could forget to.
- **Content fills its region**: beside the open panel, across the window when closed. The screen's own gutter is the only inset either side, and it is symmetric.
- The toggle is separate from the destinations. Hard rule 13 applies in both states: no business header, no destination promoted from More.
- Default is expanded. Toggling keeps the selected tab and its state.
- **Expanding and collapsing animate the joined panel and content widths.** Owner's rule: the transition shows where the working space moves. `SdMotionV3.normal` and `SdMotionV3.emphasized`; reduced motion skips it. Keep the owner-chosen menu icon; localized tooltips and expanded semantics tell its action apart.
- **Collapsed content starts where it would with no sidebar**, which moving the control into the chrome bought: no strip above the screen, so the top safe inset has one owner in both states — the screen's chrome — and nothing must be told not to reserve it twice. The control keeps its tap target and localized tooltip.
- Phone widths keep `SdBottomNavigationV3`, with no panel toggle.
- **A pushed route fills the window; no page has an outer margin at any width.** Owner's rule, replacing the tablet page margin. A route beside the shell has no panel next to it and nothing to leave room for, so a margin there is a strip shaped like absent chrome. It once landed a detail at the width of the tab it came from; a collapsible panel has no single width to match, and each screen's gutter is the whole inset.

## Portrait policy

**The app requests portrait-up everywhere, phones and tablets.** Owner's rule: orientation must not create a second nav layout to learn.

- `AppBootstrap` registers a guarded orientation step before the first frame.
- Native iPhone and iPad orientation lists match it; `UIRequiresFullScreen` disables iPad multitasking so the request takes effect.
- Android's main activity declares portrait and opts out of the large-screen orientation override where the target SDK allows.
- The OS can override these requests; wider-window tests stay as defensive coverage, not a landscape product mode.

### Pages take gutters; panels keep ceilings

| Kind | Rule | What it is |
|---|---|---|
| Page — fills the window | Its own gutter, nothing outside it | Every screen |
| Panel — floats over a page | A max width, centred | A sheet, a dialog, the paywall, onboarding |

A sheet spanning a landscape tablet is a slab with a column of controls lost in its middle. Each panel has its own ceiling on `SdContentPaddingV3`, kept as **separate fields holding the same number, not one shared constant** — different things that happen to measure alike today.

## The nav becomes a panel

The shell picks the chrome through `context.sdBreakpoint3`: the phone keeps its floating glyph-only pill; a tablet uses the proportional panel above. Both share `SdNavCellV3`, its selected capsule, semantics and tap targets.

The panel is a real column and publishes `SdFloatingBarEdgeV3.leading`. Screens still pass `floatingNav: true`; `SdContentPaddingV3.bottom` reclaims the bottom inset, since no bar sits below. No adjacent-tab swipe on a tablet: horizontal drags belong to the content.

## Do not reflexively widen the grids

**Measure before adding a column.** With content filling the window, a tablet card in portrait is about two thirds again a phone's, in landscape more than double — so a third column is right only if its cell stays wider than the phone's *in both orientations*. Under a capped column it would not have been; filling the window it may be. That depends on the margin rule above: settle it, measure, then decide — never assume from spare room.

## Tests

`test/core/responsive/tablet_layout_test.dart` measures:

- rendered panel and content regions in both expansion states;
- symmetric content gutters;
- a pushed route reaching both window edges;
- the shared app-bar edges;
- destination semantics and switching;
- phone bottom navigation.

Shell tests check the real router keeps the selected tab and state through toggles. Orientation tests check Flutter's platform request and the matching native declarations.

Keep phone token scaling and insets unchanged. Test wider windows defensively: the OS can override orientation requests.

## Deliberately not here

The nav toggle adds no two-column page, list-and-detail router, or desktop breakpoint. Grid column counts change only after real content measurements.
