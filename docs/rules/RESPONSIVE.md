# Responsive — one app, three widths

Read this before changing any layout that has to survive a window wider than
a phone: the shell, a screen's frame, a panel, or anything that reads a width.

Spacing values are not in this file. Every dimension named here lives in
`SdBreakpointConstant` or `SdContentPaddingV3` — `DESIGN_SYSTEM.md` § Spacing
is the authority on which, and this file only says when a width changes what
the app does.

**The one invariant: every rule here is a no-op at phone width.** If applying
any of it moves a single pixel on an iPhone, something is wrong — and a test
asserts it rather than a person checking. That invariant is what makes the
whole of this shippable without re-verifying the phone build by hand.

## What this replaces

The app shipped one layout, drawn for one phone, and the design system
resolves every dimension through `flutter_screenutil` against
`AppScreenUtil.designSize`. On a phone that is the point: a dimension chosen
on a 6.1" canvas holds its proportion on a 5.4" one. On a tablet it is the
bug — the canvas is roughly half the window, so every padding, icon, radius
and font is scaled up by the ratio and a seller with twice the screen gets the
same six rows, twice as large.

Worse than large: screenutil takes the **smaller** of the two ratios for type
(`minTextAdapt`), so a tablet in landscape renders the app stretched in one
axis and shrunk in the other. Nothing overflows and no test fails — every
number is simply wrong.

**So the first rule is about scale, not about columns.** A tablet layout that
adds a second column on top of inflated tokens is two problems stacked.

## The three widths

- **`SdBreakpoint` is a named enum — `compact`, `medium`, `expanded` — and a
  width comparison never appears at a call site.** Same argument as "never
  index a palette by number" in `CLAUDE.md`: `width > 600` says nothing about
  what 600 was, and the second call site to type it is the one that types a
  different number. The thresholds live in `SdBreakpointConstant` and nowhere
  else.
- **The thresholds are Material's, and are not ours to invent.** They sit
  where the hardware is; a boundary chosen by taste lands in the middle of a
  device and puts one iPad in two classes depending on how it is held.
- **They are raw logical pixels, never a `SdSpacingConstant` value.** They are
  compared against the window, which screenutil knows nothing about — a scaled
  threshold moves every time the design scales, which is the one thing a
  threshold may not do.
- **Read it through `context.sdBreakpoint3`, which reads `MediaQuery.sizeOf`.**
  The `3` suffix is `SdContextV3X`'s own convention and its reason is on that
  extension.
- **Measure the window, never the device.** Never `shortestSide`, never
  `Platform.isIOS` and a model check, never `defaultTargetPlatform`. An iPad in
  Split View hands the app a window narrower than a phone's while every
  device-shaped question still answers "tablet" — so available window width remains the layout input even when the
  platform overrides an orientation request.
- **Never cache it, and never read it once at route entry**, for the same
  reason: Split View and Stage Manager resize a live window.

  | Width | The hardware it is really about | What the app does |
  |---|---|---|
  | `compact` | every phone, and a narrow split view | exactly what ships today, unchanged |
  | `medium` | tablet portrait | the nav becomes a labelled panel at the leading edge |
  | `expanded` | wider tablet window | the same, and where a second column would go if one ever does |

## Tokens scale on a phone and stop at the clamp

- **The design size stays the phone canvas; what changes is that the scale is
  clamped at `SdBreakpointConstant.maxTokenScale`.** The canvas is grown to
  match the window rather than the ratio being allowed to grow, which is why
  the clamp is a size and not a factor.
- **The clamp is above every phone the app ships to**, so a phone resolves
  exactly the dimension it resolved before the clamp existed. That is not a
  happy accident to be re-derived each time the value is touched: it is the
  safety property, and `test/core/responsive/` asserts it.
- **Clamped, never switched.** Switching the canvas at a threshold makes every
  dimension in the app jump at one width — invisible on a device that cannot
  change size, and a lurch on the one device that can.
- **The value means "the same app at arm's length."** Not "as big as it
  fits": a tablet is held further away, so type and touch targets earn a
  little growth and nothing earns more. A clamp of 1 is the opposite mistake —
  it strands a phone-sized app in the middle of a big screen.
- **One place resolves it: `AppScreenUtil`.** It is the only `ScreenUtilInit`
  in the app *or its tests*, so no tree can pass a raw canvas and quietly opt
  out of the clamp — which would be the one tree that never sees the bug.

## Proportional columns and centred content

**The tablet panel expands and collapses.** Owner's rule, replacing the fixed
panel width and the earlier ban on collapsing. The seller can trade visible
navigation labels for more working space without changing destinations.

- **The expanded sidebar occupies the share defined by
  `SdNavPanelV3.expandedPanelFlex` beside
  `SdNavPanelV3.expandedContentFlex`.** The owner's revised share supersedes
  the previous expanded and collapsed proportions.
- **Its surface spans the full shell height and meets the content directly.**
  Owner's correction: use the joined sidebar/content composition of iPad
  Settings, not a detached glass capsule. No outer panel margin, rounded outer
  surface, or gap between the panel and the content scaffold.
- Expanded destinations use `SdNavCellShapeV3.row`. Implementation default
  for collapse is to hide the panel and give the content the full width, with
  a visible reopen control. The owner has not separately confirmed that
  collapsed presentation after revising the expanded share.
- **Content is horizontally centred in its available region**: beside the
  panel when open, across the window when closed. Screen gutters remain
  symmetric inside the content; `pageMargin` adds no outside gap in the shell.
- The toggle is separate from the destinations. Hard rule 13 applies to both
  states; there is no business header and no destination promoted from More.
- The default is expanded. Toggling keeps the selected tab and its state.
- **Expansion and collapse animate the joined panel and content widths.**
  Owner's rule: the transition should show where the working space moves. Use
  `SdMotionV3.normal` and `SdMotionV3.emphasized`; reduced motion skips it.
  The toggle uses distinct directional sidebar icons for opening and closing,
  replacing the previous shared icon so its next action is visible.
- Phone widths keep `SdBottomNavigationV3` without a panel toggle.
- Outside the shell, `SdContentPaddingV3.pageMargin` still wraps the whole
  scaffold. Pushed routes remain centred in their own available window;
  their width no longer promises to match both shell expansion states.

## Portrait policy

**The app requests portrait-up throughout**, on phones and tablets. Owner's
rule: orientation must not create a second navigation layout to learn.
`AppBootstrap` registers a guarded orientation step before the first frame.
Native iPhone and iPad orientation lists match it; `UIRequiresFullScreen`
disables iPad multitasking so the orientation request can take effect.
Android's main activity declares portrait and opts out of the large-screen
orientation override where the target SDK permits it. Operating-system
restrictions can override these requests; wider-window tests remain defensive
coverage, not a landscape product mode.

### Pages take margins; panels keep ceilings

| Kind | Rule | What it is |
|---|---|---|
| page — fills the window | `pageMargin`, content fills what is left | every screen |
| panel — floats over a page | a max width, centred | a sheet, a dialog, the paywall, onboarding |

A sheet spanning a landscape tablet is a slab with a column of controls lost
in the middle of it. Each panel carries its own ceiling on
`SdContentPaddingV3`, and they stay **separate fields holding the same number
rather than one shared constant** — they are different things that happen to
measure alike today.

## The nav becomes a panel

The shell chooses the chrome through `context.sdBreakpoint3`. The phone
keeps its floating glyph-only pill; a tablet uses the proportional panel
specified above. Both share `SdNavCellV3`, its selected capsule, semantics,
and tap targets.

The panel is a real column and publishes `SdFloatingBarEdgeV3.leading`.
Screens still pass `floatingNav: true`; `SdContentPaddingV3.bottom` reclaims
the bottom inset because there is no bar below them. There is no adjacent-tab
swipe on a tablet, where horizontal drags belong to the content.

## Do not reflexively widen the grids

**Measure before adding a column.** With content filling the window, a card on
a tablet in portrait is roughly two thirds again a phone's, and in landscape
more than double — so a third column is only right if its cell stays wider
than the phone's *in both orientations*. Under a capped column it would not
have been; filling the window it may be. The answer depends on the margin
rule above, so that is settled first, then measured, then decided — never
assumed from the fact that there is room.

## Tests

`test/core/responsive/tablet_layout_test.dart` measures rendered panel and
content regions in both expansion states, symmetric content margins, the
shared app-bar edges, destination semantics and switching, and phone bottom
navigation. Shell tests verify the real router retains the selected tab and
state through toggles. Orientation tests verify Flutter's platform request
and the matching native declarations.

Keep phone token scaling and insets unchanged. Test wider windows defensively
because operating systems can override orientation requests.

## What is deliberately not here

No two-column page, list-and-detail router, or desktop-specific breakpoint is
introduced by the navigation toggle. Grid column counts still require actual
content measurements before changing them.
