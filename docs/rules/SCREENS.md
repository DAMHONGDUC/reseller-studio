# Screens — the frame, the list, and search

Read this when building or changing a screen: its app bar, its scrolling
list, its empty state, or its search mode.

Ported from the sibling app (BaroEase), whose chrome is frosted glass the body
scrolls behind. **v3's chrome is opaque and takes real layout space**, so every
rule that existed to make content pass *under* a bar is either dropped here or
kept for a different reason, and the reason is stated. Do not port the dropped
ones back — see `DECISIONS.md` § v3 keeps its own chrome.

Spacing is not in this file. Every inset, gap and padding named here comes from
`SdContentPaddingV3` and nothing else — `DESIGN_SYSTEM.md` § Spacing.

## The frame

- **A screen never constructs an `AppBar`.** It passes `SdAppBarV3` to
  `SdScaffoldV3`, or it uses `SdSearchHeaderV3` when its search box is the
  point. One widget owns the bar so two screens cannot drift into two.
- **The bar inserts its own leading button for any route that can pop**, and
  passes `automaticallyImplyLeading: false` so the framework cannot add a
  second one on top of it.
- **A screen with a create action gets it through `AppAddFabScaffold`** — the
  labelled `SdFabV3`, same button, same place, every screen. That is an
  always-apply rule and it lives in the root `CLAUDE.md`; the design-system
  half is in `DESIGN_SYSTEM.md`.
- **Every add or edit screen pins its save action to the bottom** — owner's
  rule, first stated about workspace setup and then restated for all of them,
  because two screens had let the button scroll away with the last field. Only
  the fields scroll; the button holds the bottom edge, so a seller never
  scrolls to find out how to finish, and the way to finish is in the same place
  on every screen. **This is not the `SdFabV3` rule above and does not compete
  with it**: that one is for a list screen creating a new row, this one is for a
  screen whose single action commits the screen itself.
  - **`AppPinnedAction` (`core/widgets/`) is the one implementation.** Three
    screens had written their own before it was extracted, which is three
    chances for the gap above the button to be a different number.
  - The action sits **below** the scroll view, never floating over it, so
    content can never pass behind it. That is why it wears no surface and no
    blur — `SdContentPaddingV3.pinnedActionsGap` above it is the whole
    separation, and `SdContentPaddingV3.bottom(context)` below it clears the
    home indicator.
  - The screen passes the button's own state down; the widget holding it stays
    small enough that a keystroke rebuilds it and not the fields above.
  - A sheet is already this shape — its action is its last row and the sheet
    is only as tall as its content — so it needs nothing extra.

## The device status bar — one source, and the two platforms disagree

Reseller Studio ships light **and** dark, so this is not a set-and-forget line: the
wrong value renders invisible icons on exactly one platform in exactly one
theme, which is the hardest kind of bug to be told about.

- **The status bar style belongs to the app bar theme, set once, never at a
  screen.** `AppBarTheme.systemOverlayStyle` in `AppTheme` is the one place it
  is decided.
- **Never call `SystemChrome.setSystemUIOverlayStyle` from a screen.** It is
  global and nothing restores it on pop, so the style leaks into the next route
  and the bug surfaces in whatever screen happened to come afterwards. A screen
  that legitimately differs — a full-bleed photo header, a light sheet over a
  dark app — wraps itself in an `AnnotatedRegion<SystemUiOverlayStyle>`, which
  unwinds when the route does.
- **The two platform fields are inverted.** `statusBarIconBrightness`
  (Android) describes the **icons**; `statusBarBrightness` (iOS) describes the
  **background behind them**:

  | Bar background | `statusBarIconBrightness` (Android) | `statusBarBrightness` (iOS) |
  |---|---|---|
  | dark | `Brightness.light` | `Brightness.dark` |
  | light | `Brightness.dark` | `Brightness.light` |

  Set **both**, every time. A style naming one field looks correct on the
  platform it was tested on and renders invisible icons on the other.
- **Derive it from the resolved theme brightness, in one place** — computed
  from `ThemeData.brightness`, not two hand-written constants that can disagree
  with the palette they are meant to match. This app follows the system theme,
  so **it cannot be a `const`**: a device switching to light mode keeps light
  icons on a light bar.
- **`statusBarColor` is Android-only and stays transparent.** iOS ignores it,
  so painting it opaque reads as "fixed on Android, still broken on iOS".
- **Assert on it rather than eyeballing it.** A widget test can read the
  `AnnotatedRegion` value, and that is the only thing that keeps this correct
  after a palette change.

`AppTheme.statusBarStyle(Brightness)` is that one place; `AppTheme._build`
hands it to `AppBarTheme.systemOverlayStyle`, and `ResellerStudioApp`'s builder wraps
the app in an `AnnotatedRegion` of the same value so a route with no app bar —
splash, login — is covered too. `test/core/theme/app_theme_test.dart` asserts
both platform fields in both themes. Android also needs
`SystemUiMode.edgeToEdge`, which `AppBootstrap` turns on in its own guarded
step.

## The tab shell

The floating glass bar, `extendBody`, and the `floatingNav: true` padding that
goes with it are in `DESIGN_SYSTEM.md` § The tab bar. Two things belong here
because they are about the shell, not the bar:

- **The selection indicator slides, it does not fade.** Same duration as every
  other piece of chrome, from `SdMotionV3`. No flash, no strobe.
- **The complete frame is `SdBottomNavigationV3`.** Owner's rule. It owns the
  glass bar and adjacent-tab swipe; `AppShell` owns only GoRouter branch
  selection, analytics and localized destination data.
- **Tabs are branches of an `IndexedStack`, so no route is pushed and a
  navigator observer sees nothing.** Screen-view analytics for the five tabs
  therefore cannot come from the router, or tab analytics are silently empty
  and read as if nobody uses the app. `AppShell` logs it from `initState` and
  `didUpdateWidget` — the first tab of a session counts, and re-tapping the
  active tab does not — through `AppAnalytics.tabViewed`, naming the tab from
  `NavTabConstant`. **The name is an identifier, never a localized label**: one
  that changes with the locale splits a tab into two series.
  - This is the one analytics event raised from a widget rather than a
    controller. There is no controller between a tab tap and the shell, and it
    is a lifecycle callback, never `build`.

## Lists

- **The screen pads INSIDE the scrollable, never around it.** A `Padding` or a
  `SafeArea` wrapping the list clips the scrollable and the content then stops
  where the wrapper does. Padding goes on the `SliverPadding`, or on the list's
  own `padding`. Under an opaque bar this is not about scrolling behind chrome
  — it is about the scrollbar, the overscroll glow and the last row's clearance
  of the floating tab bar all belonging to the scrollable itself.
- **A list is a `CustomScrollView` of slivers, and padding is per sliver.**
  That is what lets a header sit flush while the rows below take the gutter and
  the item gap; one `ListView` padding cannot express it, and screens that try
  end up with a header inset differently from its list.
- **Item spacing is `SliverList.separated` with `listItemGap`** — never a
  margin on the tile, never a raw number. Rows that inset themselves sit flush
  and take no gap.
- **Physics: bouncing only when the content actually overflows.** Material's
  default wraps iOS physics in `AlwaysScrollableScrollPhysics`, so every short
  list drags and bounces against nothing — idle motion on a screen with none to
  give. Pass `AlwaysScrollableScrollPhysics` **explicitly and only** where
  pull-to-refresh must work on content shorter than the viewport.
- **Never nest two scrollables in the same axis.** Where a widget supplies its
  own horizontal scrolling — a chip strip, a thumbnail row — hand it a bare
  row.
- **Chrome driven by scroll position reads a `NotificationListener` on the
  list** and compares `metrics.pixels` against the element's own extent.
  **Ignore nested notifications (`notification.depth != 0`)** or a horizontal
  chip row inside the list drives the collapse. The threshold is a static on
  the widget it belongs to; an element that must scroll fully out before it
  fires has to start at offset 0, so nothing may be padded in above it.
  `SdSearchHeaderV3` and `AppAddFabScaffold` are the two implementations —
  read them before writing a third.
- **Pull-to-refresh is one wrapper.** There is no v3 refresh indicator yet;
  when one is added it goes in the package, not in a screen. Its `edgeOffset`
  is 0 under this app's opaque bar — the scaffold already subtracted the bar —
  and becomes the header's own height on a screen whose scrollable starts with
  a search header, so the spinner drops in below the chips rather than over
  them.

## Empty states

- **An empty state still scrolls**, or the one screen a seller most wants to
  refresh is the one screen that cannot be. Wrap it as
  `SliverFillRemaining(hasScrollBody: false)`.
- **Use the sliver, not a `LayoutBuilder`.** A `LayoutBuilder` builds its child
  *during* layout, and a Riverpod consumer resuming inside that build throws
  `setState() called during build`.
- **The empty state says which empty it is.** "No items yet" and "nothing
  matches that search" are different situations and get different copy, chosen
  off the trimmed query — otherwise a search with no hits reads as data loss.
  Both strings go through ARB keys (hard rule 7).

## Search

- **Search is a mode of the header, not a widget parked above the list.**
  Entering it swaps the title row for the field and the actions for the clear
  button. A screen that changes only one of them leaves the seller with a
  search field and a back arrow that pops the route out from under them.
- **The visibility flag is screen state; the query is not.** Whether the field
  is showing dies with the screen and can be `setState`. **The query lives in a
  controller** so filtering survives a tab switch, a rebuild and a rotation — a
  query held in the widget resets the moment the shell rebuilds the branch, and
  the seller's list silently repopulates.
- **Opening focuses the field in the same action.** Revealing a field the
  seller then has to tap is two taps for one intent.
- **Cancel clears, unfocuses and exits — in that order, in one method.**
  Leaving the query behind on exit is the bug that ships: the field is gone,
  the list is still filtered, and nothing on screen explains why. Clear the
  controller *and* the `TextEditingController`, drop focus, then flip the flag.
- **Clear is a separate action from cancel, and it keeps focus.** The X empties
  the query and **re-requests focus** so typing continues; the leading button
  leaves search altogether. One control doing both is how a seller ends up
  dropped out of search when they meant to fix a typo.
- **The clear action exists only while the query is non-empty.** An X over an
  empty field is a control that does nothing.
- **Own the `TextEditingController` and the `FocusNode`, and dispose both.**
  They are screen-lifetime objects; a `State` that creates them and forgets
  `dispose()` leaks one per visit.
- **Filtering is not the field's job.** The query lives in a controller, the
  matching is a `*Utils` method or a `domain/services/` class, and the field
  only reports `onChanged` (no business logic in widgets).
- **There are two search entry points on purpose** — Inventory's docking header
  and the Search screen's plain autofocused field. That is a recorded decision,
  not a duplication to clean up: `DECISIONS.md`.

## Home carries Quick Action, and it must stay complete

Owner's rule. The create actions are scattered by design — each lives on the
screen owning the records it makes, behind that screen's own `SdFabV3`. That
is right for a seller already on the screen and wrong for one who opened the
app holding a receipt, so Home lists **every** one of them.

`QuickActionConstant.actions` is that list and the only one. A row pushes the
screen that owns the action; it never opens a form Home would then have to
know how to save.

**Two rows here do not create anything, and they ride at the end** — owner's
rule, About last and Analytics just above it. About lives two levels deep under
Settings, so Home is what keeps it findable; putting both at the end is what
stops a seller scanning for "add" from stepping over them. Nothing else
non-create joins them without the same decision.

**Scan is a Home shortcut; Flow overview is its own section directly below
the shortcut row.** Owner's rule. Scan is an action a seller reaches for while
holding an item, so it belongs in the one-glance row. Flow overview needs more
context than a small launcher card can carry, so its dedicated section opens
the existing sheet and appears in one place only.

**Analytics opens with `go`, not `push`.** It is a branch root, and pushing one
over Home leaves the seller on the wrong tab with a back button they should not
have — which is why `QuickAction` carries how it opens rather than a route
alone.

- **`WorkflowConstant.steps` is the content, and stays the only copy of the
  chain.** The sheet and About's diagram draw the same data — a second list
  written for the sheet is how the app ends up teaching two workflows.
- **A step carries `isOptional`, and optional means the app never blocks on
  it** — not "unimportant". Listing, shipping and recording a source are all
  things a seller can skip entirely and still get paid, and hard rule 2 is why:
  requirements attach when a record *moves*, never when it is created. Saying
  so out loud is the point of the badge, because a seller who thinks all nine
  are mandatory goes back to the spreadsheet.
- The badge is `SdBadgeV3` in the neutral tone. Optional is not a warning.

The shortcut card at the top of Home is named after the section it lands on
and scrolls to the end — a card that said something other than where it goes
is a card that lies.

## Dense destination screens expose their hierarchy

**More is grouped into titled sections, never one undifferentiated list.**
Owner's rule. Operations contains Sourcing, Listings, Categories and
Locations; Finance contains Expenses, Payouts, Reports, Receipts and Tax;
Business contains Marketplaces, Team and Activity; Account contains
Subscription and Settings. Signed-out More renders only the Account section
with Settings.

**An item detail exposes its action sheet with a labelled app-bar button, not
an ellipsis glyph.** Owner's rule. The sheet holds several important state
transitions, so a subtle three-dot icon makes the main way to act on an item
look decorative; the localized Actions label is the affordance.

**Rows, and always last on the screen** — owner's rule. Home answers "what
needs attention today" first, so a launcher sitting above the figures makes
the screen open on the wrong thing. At the bottom it is where a seller who
came to *add* something scrolls to, and it costs the seller who came to
*read* nothing.

**Adding a create action anywhere means adding it here.**
`test/features/home/quick_action_test.dart` reads `lib/features/` for screens
wearing `AppAddFabScaffold` and fails on any the section cannot start — a
section that lists six of eight is worse than none, because a seller who has
learned to look here stops being able to tell "missing" from "the app cannot
do it".

## About draws the workflow, and the diagram is navigable

Owner's rule: the app carries an About screen holding what it is plus the
workflow, so a seller can see how the parts connect. **It lives under
Settings, not in the top-level More list** — More is a long list of places
work is done, and "what is this app" is asked once rather than worked from.
Home's Quick Action list carries the shortcut, last, so it stays one tap
away.

`WorkflowConstant.steps` is the chain `CLAUDE.md` writes as one line, as data.
It is drawn **vertically** — nine links across a phone is either unreadable or
a horizontal scroll nobody finds — and **each step opens the screen that
performs it**, because a page explaining a workflow you cannot enter is the
screen this rulebook says will be redesigned.

The order carries the meaning. `test/features/more/about_screen_test.dart`
pins the sequence against the lifecycle and fails on a step pointing at a
parameterised route, which cannot be pushed and would be a dead link inside
the one screen that exists to explain the app.
