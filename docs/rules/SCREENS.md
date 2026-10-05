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

- **A screen wider than a phone caps and centres its body** — that rule and
  everything else that changes with the width of the window is in
  `docs/rules/RESPONSIVE.md`. Nothing on this page is width-dependent unless
  it says so.
- **A screen never constructs an `AppBar`.** It passes `SdAppBarV3` to
  `SdScaffoldV3`, or it uses `SdSearchHeaderV3` when its search box is the
  point. One widget owns the bar so two screens cannot drift into two.
- **The bar inserts its own leading button for any route that can pop**, and
  passes `automaticallyImplyLeading: false` so the framework cannot add a
  second one on top of it.
- **A screen with a create action gets it through `AppAddFabScaffold`** — the
  `+` `SdFabV3` with no title, same button, same place, every screen. That is an
  always-apply rule and it lives in the root `CLAUDE.md`; the design-system
  half is in `DESIGN_SYSTEM.md`.
- **A screen with content and an action button pins that button to the bottom**
  — owner's rule. It was first stated about workspace setup, then about every
  add and edit screen, and now about all of them: wherever content scrolls and
  the screen has an action, the content scrolls and the action holds the bottom
  edge. A seller never scrolls to find out how to finish, and the way to finish
  is in the same place on every screen. **This is not the `SdFabV3` rule above
  and does not compete with it**: that one is for a list screen creating a new
  row, this one is for a screen acting on what it is already showing.
  - **`AppPinnedAction` (`core/widgets/`) is the one implementation.** Three
    screens had written their own before it was extracted, which is three
    chances for the gap above the button to be a different number. Its
    `variant` is the only thing a screen chooses; the geometry is not
    negotiable.
  - The action sits **below** the scroll view, never floating over it, so
    content can never pass behind it. That is why it wears no surface and no
    blur — `SdContentPaddingV3.pinnedActionsGap` above it is the whole
    separation, and `SdContentPaddingV3.bottom(context)` below it clears the
    home indicator.
  - The screen passes the button's own state down; the widget holding it stays
    small enough that a keystroke rebuilds it and not the fields above.
  - **Two actions stack, they never sit side by side, and the primary is
    lowest.** Business details pins Save with Delete this business above it.
    A `Row` shrinks both labels to fit and puts a destructive verb a thumb's
    width from the safe one; stacked, the button under the resting thumb is
    always the one the screen is for. `AppPinnedAction.secondary` is the slot,
    and both share the one bottom inset — a second padded widget would clear
    the home indicator twice.
  - **The second slot is not only for a destructive verb.** Quick Add pins
    Save with "Save and add another" above it — same stacking, same reason:
    the button under the resting thumb is the one the screen is for, and the
    variant is what says which is which. What the slot must never hold is a
    second way to do the same thing at the same weight.
  - **The gap between the two is `SdContentPaddingV3.stackedActionsGap`, and
    the slot draws it** — owner's rule, and it **reverses "a conditional
    second action carries its own gap"**. Two of the three screens with a
    second action drew no gap at all and their buttons touched, while the
    third drew its own — which is exactly the drift a shared widget exists to
    stop, and the same argument that put the inset above and below the slot
    inside it.
  - **A second action that does not apply is `null`, never an empty widget.**
    That is what the old rule was really protecting against: `_DangerZone`
    rendered a `SizedBox.shrink()` for a seller who cannot delete, so a gap
    owned by the slot would have left a hole above Save. The screen decides
    whether there is a second action; the slot decides what it looks like
    when there is.
  - **The button disappears rather than moves when it does not apply.** A
    screen whose action is conditional — Subscription only sells to a seller
    who is not paying, the paywall only buys once the store has answered —
    renders nothing in the slot, and the scroll view takes the space back.
    Never leave a disabled button pinned to explain a state; the content above
    already does.

- **"Action button" means the screen's action, not a row's.** The rule above
  would be unfollowable without the line, and these sit on the wrong side of
  it:
  - **A button inside a row or a card acts on that record and stays there** —
    the recurring expense's Record, an offer card's Accept. Pinning those
    would tear an action away from the thing it names, and a screen listing
    twelve of them has no single bottom edge to pin to. **A destructive action
    on the record the whole screen is about is not one of these** — Business
    details' Delete this business was read that way once and was wrong: the
    screen is the record, so the verb is the screen's.
  - **An empty state's action stays in the empty state.** There is no content
    for the button to be pinned away from — the empty state *is* the screen —
    and `AppListEmptyState` already owns where it sits.
  - **A detail screen's Actions button stays in the app bar**, because it
    opens a sheet of several verbs rather than committing one. That is its own
    owner's rule, further down this file.
  - **A selection bar is already pinned** and stays a `bottomNavigationBar`:
    it appears with the selection and replaces the FAB, which a pinned action
    below the list cannot do.
  - A sheet only as tall as its content is already this shape — its action is
    its last row — so it needs nothing extra. **A sheet that scrolls is a
    screen for this rule**: `PaywallScreen` is a route presented as a sheet,
    takes nine tenths of the height whatever the store returns, and holds its
    purchase button out of the scroll like any other screen. It is the one
    place that does not use `AppPinnedAction` — `SdBottomSheetV3` already pays
    the horizontal gutter and the home-indicator inset, so the shared widget
    would draw both twice. Only `pinnedActionsGap` is taken from it.

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
  `SdSearchHeaderV3` and `SdBottomNavigationV3` are the two implementations —
  read them before writing a third.
- **Pull-to-refresh is one wrapper.** There is no v3 refresh indicator yet;
  when one is added it goes in the package, not in a screen. Its `edgeOffset`
  is 0 under this app's opaque bar — the scaffold already subtracted the bar —
  and becomes the header's own height on a screen whose scrollable starts with
  a search header, so the spinner drops in below the chips rather than over
  them.

## A filtered list says how many filters are on, and offers Reset

Owner's rule. Inventory and Orders both keep their vocabulary of filters in a
sheet, so without a line on the screen a row missing because of a filter and a
row missing because of a bug look identical — and the seller's only way to
check is to reopen the sheet and read every group.

- **`AppActiveFilterBar` (`core/widgets/`) is the one implementation**, and it
  renders in two places at once: under the strip on the screen, and at the top
  of that screen's filter sheet. One widget, so the two counts are one line of
  code — what each one counts is not the same, and the sheet's is below.
- **It renders nothing at zero.** A row saying "0 filters" is chrome describing
  the absence of chrome.
- **The count is by group, never by chip.** Three categories ticked is one
  filter; a seller who made one choice cannot reconcile "3 filters" with the
  sheet in front of them.
- **The selected tab counts as one whenever it is not `All`**, and Reset
  returns it there. A seller looking at three rows of eleven is filtered by the
  tab exactly as much as by the sheet, and a bar reading "no filters" over a
  narrowed list would be describing a different screen.
- **The search box is not counted and Reset leaves it alone.** It is visible on
  the screen with its own clear button, so it is not the filter that went
  missing.
- **Nothing is applied until Apply is pressed.** Owner's rule, and it
  **reverses "the sheet applies as it is tapped"**. The chips edit a draft the
  sheet holds; the list behind it does not move while the seller is still
  deciding, and closing the sheet any other way — the X, a drag, the back
  gesture — leaves the list exactly as they found it. A seller trying two
  combinations had already changed the screen twice under the old rule.
  - **The primary button says "Apply", not a count.** How many rows are left
    is a fact about a filter that has been applied, and this button is what
    applies one.
  - **The sheet's own bar counts the draft, and never the tab.** The tab is
    not in the sheet, so a number counting it could not be made true by the
    Reset beside it — inside the sheet, Reset empties what is pending and
    nothing else. The strip's bar still counts the tab and its Reset still
    clears it.
  - **Ticking a chip is a method on the criteria, not on the notifier**
    (`ItemFilterCriteria.withStatusToggled`). Two places tick a chip now — the
    draft and the applied value — so what a tick means lives in one place, and
    `apply(pending)` is all the controller keeps.
- **The entry point is an app-bar action, never a chip on the strip.** Five
  tabs are already wider than a phone, so a sixth chip pushes a real tab off
  the edge to reach a sheet that is not a tab.
- **That action is lit while the sheet holds something** — owner's rule.
  `SdAppBarActionButtonV3.isActive` fills the glyph and paints it primary, so
  a seller who scrolled past the bar under the strip can still see, from the
  chrome that never moves, that the list is narrower than the shelf. It
  follows the sheet's own groups and not the tab, for the reason the sheet's
  bar does: the strip already shows which tab is picked, and a lit glyph over
  a sheet that opens empty is a lie about where the rows went.
- `test/features/inventory/inventory_filter_sheet_test.dart` and
  `test/features/orders/order_filter_sheet_test.dart` hold the count, the two
  places it renders, and Reset.

## The loading screen is watched, not glimpsed

Owner's rule. The splash stays up for `SplashHoldController.minimum` every
time it comes up — the cold start and the moment after sign-in alike — even
when the answer it is waiting for has already landed.

- **It is a hold, never a delay.** The work runs the whole time; what waits is
  only the route change. Nothing is scheduled behind it and no call is slowed
  down to make room for it.
- **It only keeps the seller on the splash; it never sends them there.** A
  hold left standing while the app is on Home costs nothing, which is what
  makes it safe to arm early.
- **It re-arms whenever the app starts deciding again**, which is what covers
  sign-in. `appIsResolvingProvider` is the signal, and it mirrors the
  redirect's own splash conditions — change one and change the other.
- **The clock belongs to `SplashScreen`, not to the hold.** What is being
  waited for is the animation being *seen*, so it starts when the screen
  appears and is cancelled when it goes — nothing counts down while the
  loading view is not up, and a test that never shows it is left with no timer
  running.
- **A hold already standing is left alone.** A second question arriving
  mid-swing does not restart it, or a seller whose profile and workspace land
  a moment apart waits twice.
- The animation itself is `SdLoadingV3Page`, which is the page-sized half of
  the one loading indicator (`DESIGN_SYSTEM.md`).

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
- **A filtered list picks between the two with `AppListEmptyState`, and its
  `hasAny` reads the unfiltered source.** Four screens had written the choice
  by hand and three of them got it wrong the same way: Orders, Offers and
  Listings told a seller who had never added anything that nothing matched a
  filter they never set. The widget is what makes the filter half impossible
  to write twice, and its `hasAny` is deliberately awkward to pass from a
  filtered list, because a count taken after filtering is the bug.
- **The "not started yet" half carries an action; the filter half does not.**
  A filter has an obvious fix already on screen. A first empty list is where a
  new seller stops, so it names the next step and opens it — including on the
  lists with no create action of their own, where the step is upstream
  (Listings sends the seller to Inventory).
- **A list that has a create action offers that action, never a detour.**
  Orders was the exception until it got one: it now opens the record-sale
  screen from both its button and its empty state, and the two say the same
  words. An empty state pointing somewhere other than the screen's own create
  button teaches a route the seller then has to unlearn
  (`lib/features/orders/CLAUDE.md`).

- **An empty *block* is not an empty screen, and says so with
  `SdEmptyStateVariantV3.inline`.** Owner's rule. The page variant carries the
  screen's own band — 32 above, 32 plus the floating bar's footprint below —
  which is right when the empty state *is* the screen and wrong the moment it
  is one item in a list: Analytics' marketplace breakdown sits between two
  headings, and that band put a hundred points of dead air under three lines
  and left the words reading as if they were set too high.
  - **The inline block keeps the container the rows would have filled.** The
    breakdown renders the same `SdCardV3` either way, so the screen's rhythm
    does not change with the data, and the words centre on the card's own
    padding.
  - **Filling the height is not centring.** `Column(mainAxisSize: max)` makes
    the column *be* the available space and lands its children at the top of
    it — the opposite of what it looks like it does. The centring is the
    `Center` above it, and it only works while the column stays `min`.
  - `test/features/analytics/marketplace_breakdown_empty_test.dart` pins the
    card and the equal air.

## A form seeds through `FormSeed`, never straight from `build`

A form that edits an existing record learns it has one in a `build` — the
record arrives on a stream, so there is nowhere earlier. **Copying it into the
form's controller from there throws**: `Tried to modify a provider while the
widget tree was building`. It is not a debug-only assertion in practice — the
form stayed empty, and the seller saw an edit screen that never filled in.

- **Use the `FormSeed` mixin (`core/state/`) and call `seedOnce`.** It defers
  the copy to the end of the frame, which is the fix Riverpod's own error
  message names, and it owns the once-only flag.
- **Once, not once per build.** The record rebuilds the screen whenever a
  teammate edits it, and re-seeding then throws away every keystroke the
  seller made in between. Never re-derive the guard per screen — two screens
  had written it themselves and both had the bug beside it.
- **One frame of empty fields is the cost, and it is invisible**: the screen
  was already showing empty fields while the record loaded.
- Held by `test/features/inventory/item_form_seed_test.dart` and
  `test/features/workspace/workspace_detail_seed_test.dart`, both of which
  fail on the direct call.

## A detail screen edits in place, one section at a time

Owner's rule, and it replaces the edit screen for every record that has a
detail screen. **There is no separate screen for changing an existing record.**
A seller who spots a wrong cost was pushed onto a full form, made to scroll
past nine fields they were not changing, and popped back — for one number.

- **Each section that holds fields carries its own Edit, and Edit becomes
  Cancel and Save.** The section is the unit because the section is already
  how the screen groups fields: correcting a price and correcting an address
  are separate intents and must be separate saves.
- **One section edits at a time.** Opening a second closes the first — two
  open drafts is two sets of unsaved keystrokes and no way to tell which Save
  belongs to which.
- **Read mode and edit mode are the same rows in the same order.** A section
  that reflows on Edit makes the seller re-find the field they came for.
- **Only stored fields open.** A derived figure has no field to edit
  (hard rule 3), and a recorded timestamp is not a thing a seller types.
- **A state transition stays in the actions sheet, never in a section.** Mark
  sold, Archive, Ship, Mark delivered and Record refund carry side
  effects — an inventory write, an audit entry, a timeline fact — and a status
  field that wrote the value alone would skip all of them (hard rule 2).
- **A section whose rows belong to another screen sends Edit there instead of
  opening fields.** Owner's rule, stated for Item detail's Listings block: what
  a marketplace asks is edited on Marketplaces management, which is also the
  only screen that can put the item on a new one. Editing the same number in
  two places is two ways to write it, and the half the seller reaches first is
  the one that cannot do the rest of the job. The section still reads as a
  section — same header, same Edit — it just hands the whole question over.
- **Which section is open, and the save, live in a controller**; the text
  controllers stay on the screen, the way every other form here does it. A
  widget deciding what to write is the rule this repo does not bend.
- **Cancel restores from the record, not from a copy taken on Edit.** The
  record is a stream and a teammate may have changed it while the draft was
  open; re-seeding from what is current is the only answer that is not stale.
- **Saving writes only the fields that section owns**, re-read at the moment
  of the write — the same rule the workspace detail screen already follows.
- **The create form stays a screen.** Creating has no record to show sections
  of, and hard rule 2 keeps that form's requirements to a title.

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
rule, About last and Analytics just above it. About sits near the end of a
long More list, so Home is what keeps it findable; putting both at the end is what
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
workflow, so a seller can see how the parts connect. It is a row in More's
App section — there is no Settings screen to hold it
(`lib/features/more/CLAUDE.md`). Home's Quick Action list carries the
shortcut, last, so it stays one tap away.

`WorkflowConstant.steps` is the chain `CLAUDE.md` writes as one line, as data.
It is drawn **vertically** — nine links across a phone is either unreadable or
a horizontal scroll nobody finds — and **each step opens the screen that
performs it**, because a page explaining a workflow you cannot enter is the
screen this rulebook says will be redesigned.

The order carries the meaning. `test/features/more/about_screen_test.dart`
pins the sequence against the lifecycle and fails on a step pointing at a
parameterised route, which cannot be pushed and would be a dead link inside
the one screen that exists to explain the app.
