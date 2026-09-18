# Responsive — one app, three widths

Read this before changing any layout that has to survive a window wider than
a phone: the shell, a screen's body, a list, a sheet, or anything that reads a
width.

Spacing values are not in this file. Every dimension named here lives in
`SdSpacingConstant`, `SdBreakpointConstant` or `SdContentPaddingV3` —
`DESIGN_SYSTEM.md` § Spacing is the authority on which, and this file only
says when a width changes what a screen does.

## What this replaces

The app shipped one layout, drawn for one phone, and the design system
resolves every dimension through `flutter_screenutil` against
`ResellerStudioApp.designSize`. On a phone that is the point: a dimension
chosen on a 6.1" canvas holds its proportion on a 5.4" one. On a tablet it is
the bug — the canvas is roughly half the window, so every padding, icon,
radius and font is scaled up by the ratio and a seller with twice the screen
gets the same six rows, twice as large.

**So the first rule is about scale, not about columns.** A tablet layout that
adds a second column on top of inflated tokens is two problems stacked.

## The three widths

- **`SdBreakpoint` is a named enum — `compact`, `medium`, `expanded` — and a
  width comparison never appears at a call site.** Same argument as "never
  index a palette by number" in `CLAUDE.md`: `width > 600` says nothing about
  what 600 was, and the second call site to type it is the one that types a
  different number. The thresholds live in `SdBreakpointConstant` and nowhere
  else.
- **Read it through `context.sdBreakpoint3`, which reads `MediaQuery.sizeOf`.**
  The `3` suffix is `SdContextV3X`'s own convention and its reason is on that
  extension.
  `sizeOf` rather than `of` so a size change rebuilds the widgets that asked
  about size and not every widget under the query.
- **Never cache it, and never read it once at route entry.** iPadOS Split View
  and Stage Manager resize a live window: a breakpoint captured in `initState`
  is a layout that is correct until the seller drags a divider.
- What each width is for:

  | Width | Device it is really about | What the app does |
  |---|---|---|
  | `compact` | every phone | exactly what ships today, unchanged |
  | `medium` | tablet portrait, a phone unfolded, a narrow split view | one column, capped and centred, bottom nav kept |
  | `expanded` | tablet landscape | side rail, and content in columns |

## Tokens scale on a phone and stop at the clamp

- **The design size stays the phone canvas; what changes is that the scale is
  clamped at `SdBreakpointConstant.maxTokenScale`.** The clamp is above every
  phone the app ships to, so a phone resolves exactly the dimension it
  resolves today and nothing in `compact` moves by a pixel.
- **Clamped, never switched.** Switching the canvas at a threshold makes every
  dimension in the app jump at one width — invisible on a device that cannot
  change size, and a lurch on the one that can, which is precisely the device
  this file exists for.
- **One place resolves it: `ResellerStudioApp`, where `ScreenUtilInit` is
  built.** The resolver is `SdBreakpointConstant.designSizeFor`, so the rule
  is testable without pumping the app, and no second `ScreenUtilInit` in a
  test may pass a raw size and quietly opt out of the clamp.

## Width is capped in one place, and screens do not cap themselves

- **`SdContentPaddingV3.screen` and `.fullBleed` do the capping themselves.**
  They already take a context and already hand every screen its side insets,
  so the cap arrives everywhere without a single call site changing — and a
  screen that never learned about widths cannot be the one that forgot.
- **A screen never writes its own `ConstrainedBox` or `Center` for width.**
  Two screens capping themselves is two caps, and the second one is a
  different number.
- The cap is about reading, not taste: a row of type run to the full width of
  a landscape tablet forces the eye back across the whole window to find the
  next line, and a two-value card with that much space between its label and
  its figure stops reading as one row.
- **Which cap is an enum, never a width.** `SdPageWidthV3.column` is the
  default and is the reading column every form, detail and list gets;
  `SdPageWidthV3.wide` is for a body that turns extra width into columns. A
  screen names the shape it is, and `SdContentPaddingV3` owns both numbers.
- **The inset is measured from the window, and the rail is the one thing that
  will break that.** Today nothing sits beside the body, so the window's width
  is the body's width. When the rail lands it takes a leading strip, and the
  measurement moves to the scope that already carries the bar's footprint —
  not to a `LayoutBuilder` at a call site.

## Where the extra width goes

- **A form, a detail screen and a settings list get the cap and nothing
  else** — one column, centred. They are a sequence of decisions; a second
  column turns reading order into a choice.
- **A list of cards gains columns through `SdResponsiveGridV3`**, which takes
  the column count from the breakpoint. Inventory, Orders, Listings and the
  stat rows are the screens this is for.
- **Never write a screen twice.** There is no `if (expanded) return _WideBody()`
  beside a `_NarrowBody()`: the same widgets lay out at a different column
  count. Two trees for one screen is two screens, and the second one is the
  one that stops getting the fix.
- **A number of columns is not a number at a call site either.** It comes from
  the breakpoint, the same way a colour comes from the palette.

## The nav

- **The rail replaces the floating bar at `expanded` only.** Tablet portrait
  keeps the bar: it is held like a large phone and the bottom edge is still
  the reachable one. Landscape is where the bottom centre of the window is
  furthest from either hand.
- **This does not touch hard rule 13.** The list is still the same five tabs
  in the same order; what changes is the edge they sit on.
- **The rail's footprint travels the way the bar's does** — through
  `SdContentPaddingV3` and `SdFloatingBarScopeV3`, never typed by a screen.
  The bar costs a bottom inset and the rail costs a leading one, and a screen
  that guessed either is a screen with a row under the chrome.
- **Adjacent-tab swipe belongs to the bar and goes with it.** A horizontal
  drag that switches tabs while the nav sits on the left edge is a gesture
  with nothing on screen to explain it.

## Sheets, dialogs and pinned actions

- **The widget caps itself; the call site never does.** `SdBottomSheetV3`,
  `SdDialogV3` and `AppPinnedAction` each run the full width of a phone, and
  the full width of a landscape tablet is a band of chrome with a button lost
  in the middle of it.
- A sheet keeps the bottom edge — it is still a sheet, not a dialog — and caps
  and centres its content inside it.

## Tests

- **`pumpScreen` takes a size, and the default stays the phone.** Every test
  written before this file ran at one viewport, which is why no test has ever
  seen a wide window.
- **A screen that changes at a breakpoint is pinned at both.** One assertion
  per width, in the screen's own test — not a golden, which would fail on
  every unrelated visual change.
- `test/core/responsive/` holds the two rules that are not any one screen's:
  the clamp, and which nav the shell builds at each width.

## What is deliberately not here

- **Two-pane list-and-detail is not in this generation.** It is a router
  change — `StatefulShellRoute.indexedStack` gives each tab one navigator and
  a detail pane needs a second — and it is worth doing on its own, after the
  widths above are true everywhere.
- **There is no desktop width.** The app ships to phones and tablets; a
  breakpoint for a window nothing runs in is a branch no one tests.
