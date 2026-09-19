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
  device-shaped question still answers "tablet" — and there is no
  `UIRequiresFullScreen` in a modern iPad app, so that is the ordinary case
  rather than an edge one.
- **Never cache it, and never read it once at route entry**, for the same
  reason: Split View and Stage Manager resize a live window.

  | Width | The hardware it is really about | What the app does |
  |---|---|---|
  | `compact` | every phone, and a narrow split view | exactly what ships today, unchanged |
  | `medium` | tablet portrait | the nav becomes a labelled panel at the leading edge |
  | `expanded` | tablet landscape | the same, and where a second column would go if one ever does |

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

## One margin number

**Screen edge to nav, nav to content, content to the far edge are the same
number, and it does not change with the screen or the orientation.** That
number is `SdContentPaddingV3.tabletMargin`, and content fills whatever the
margins leave.

- **Not a max-width column.** Capping the content and centring it is the
  obvious move and it is wrong: it produces three different gaps, because two
  of them are leftover page margin from a ceiling and only one of them is a
  decision. One number is a decision.
- **`pageMargin` is what a screen adds, and it is the margin less the gutter
  the screen already pays.** Screens pad themselves by
  `SdContentPaddingV3.horizontal` already; adding the full margin on top
  stacks two gutters and the gap comes out wrong.
- **It is applied around the whole `Scaffold`, app bar included** — and
  `SdScaffoldV3` is the one place that does it, so no screen has to remember.
  A header spanning the window over an inset body reads as two screens
  stacked.
- **A surface goes behind it.** A pushed route has nothing of its own behind
  it, so the strips either side would show whatever the route below left —
  black, on a fresh push.
- **A screen with no nav beside it gets half the nav column extra per side.**
  A pushed detail is a sibling of the shell, not a child of a branch, so the
  rail is gone and a plain margin would make it a nav column wider than the
  tab screen it was opened from — content visibly jumping outward on the way
  in and back on the way out. The scope answering "which edge, or none" is
  what makes the two widths identical.

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

**A phone gets the glyph-only pill; a tablet gets a labelled panel standing in
its own column.** Owner's rule, and it **reverses "glyph-only is what keeps
the pill and the panel one control"** — which this file said until the panel
was drawn. The argument it replaces was about consistency between two chromes;
the argument that won is about the device: a tablet has room for the word, and
a glyph a seller has to decode is a glyph they decode every time.

- **The shell picks the chrome and nothing else in the app knows which one is
  up.** A screen never asks; it reads its insets, and the chrome publishes
  what it occupies through `SdFloatingBarScopeV3`.
- **This does not touch hard rule 13.** The panel carries **exactly the five
  tabs, in the same order, and nothing else** — no workspace header, no More
  destinations hoisted up beside them. What changes is the edge and the
  labelling, not the list. A panel that grew a sixth row would be the bottom
  bar growing by another name.
- **Always visible, and it does not collapse.** A toggle is a second state to
  remember per device, a second default to argue about per orientation, and a
  control that hides the thing it is for. The panel is either the chrome or it
  is not.
- **The cell is shared, the chrome is not.** One `SdNavCellV3` draws a
  destination in both chromes and owns everything about being one — the glyph,
  the fill it animates to, the timing, the semantics, the tap target. What
  differs is a shape it is told to take, which is an enum rather than a pair
  of booleans.

  | | pill (phone) | panel (tablet) |
  |---|---|---|
  | layout | floats; the body scrolls behind the glass | a real column |
  | cell | glyph alone, equal segments across | glyph and label, a row each down |
  | its measure | height is vertical, cells divide the width | **width is horizontal**, row height is vertical |
  | inner margin | — | none — the gap to content is the content's own `pageMargin` |
  | adjacent-tab swipe | yes | no |
  | what it publishes | `bottom` | `leading` |

- **A real column, not a floating strip.** A phone has no width to give away
  and a tablet does; the panel in its own column means no screen has to pad a
  side for it.
- **No swipe.** An adjacent-tab swipe is a thumb gesture on a one-handed
  device. At tablet width a horizontal drag is a chart being panned or a row
  being dismissed, and taking it would break both.
- **No inner margin on the panel.** The gap to the content is the content's to
  leave. An inner margin stacks on `pageMargin` and makes one of the three
  gaps bigger than the other two — exactly the bug the margin rule closes.
- **The panel's width is a horizontal dimension and its row height a vertical
  one.** Put either on the wrong ladder and screenutil punishes you: a
  landscape tablet's height ratio sits below its width ratio, so the control
  would come out at two sizes depending on how the tablet is held. One
  measure per axis, always the axis it is actually measured along.
- **The bottom inset is reclaimed, and the flag is what asks.** Tab screens
  pad their bottom to clear the floating pill; with the nav down the side
  there is nothing on the bottom edge and that padding is dead space.
  `floatingNav: true` means "I am a tab screen", not "there is a bar below
  me" — `SdContentPaddingV3.bottom` asks the scope which edge the chrome is
  on, and the screen never learns the answer.
- **The scope answers presence and edge only.** It must not import
  `SdContentPaddingV3`: padding is what asks the question, so the answer
  cannot depend on it. Every caller computes its own distance.
- **The one thing to keep measuring is what the panel leaves.** It is wide,
  and a tablet held upright is not: the content column is what the panel is
  traded against, and if it ever reads narrower than a phone's the trade has
  gone the wrong way.

## Do not reflexively widen the grids

**Measure before adding a column.** With content filling the window, a card on
a tablet in portrait is roughly two thirds again a phone's, and in landscape
more than double — so a third column is only right if its cell stays wider
than the phone's *in both orientations*. Under a capped column it would not
have been; filling the window it may be. The answer depends on the margin
rule above, so that is settled first, then measured, then decided — never
assumed from the fact that there is room.

## Tests

- **`pumpScreen` takes a window size, defaulted to the phone canvas**, so no
  existing test changes and every existing assertion keeps meaning what it
  meant.
- **`test/core/responsive/` holds the rules that are no one screen's**, pumped
  at a tablet in both orientations:

  1. a gutter renders at the clamp, not at the window's ratio;
  2. at phone width it renders at exactly what it was drawn at;
  3. the three gaps are equal, and equal to `tabletMargin`;
  4. at phone width `pageMargin` is zero;
  5. a pushed detail lands on the same content width as the tab screen;
  6. the app bar shares the content's left and right edges;
  7. each width gets the right chrome, and content clears the nav;
  8. the rail is longer than it is thick, and one thickness in both
     orientations;
  9. every tab still switches from the rail;
  10. the bottom inset is reclaimed on a tablet and kept on a phone;
  11. no tab screen and no multi-step flow overflows, either orientation.

- **Assertions 2, 4 and the second half of 10 are the important ones** — they
  are the invariant at the top of this file, and they are what makes the phone
  build safe without a person looking at it.
- **Measure the card, not the box around it.** The box carries the screen's
  own gutter inside it, and the gap a reader sees is to the card's edge.

## What is deliberately not here

- **Phone landscape is a separate project.** A short window breaks multi-step
  flows and tall panels, and none of the rules above help with it.
- **No two-column page, and no list-and-detail.** The first is cheap when it
  comes — an existing list of sections split in two — and the second is a
  router change rather than a layout one, because the detail has to render
  inline. Neither is in this generation.
- **There is no desktop width.** The app ships to phones and tablets; a
  breakpoint for a window nothing runs in is a branch no one tests.
