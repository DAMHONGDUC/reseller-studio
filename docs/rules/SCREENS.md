# Screens — the frame, the list, and search

Read when building or changing a screen: its app bar, scrolling list, empty state, or search mode.

Ported from the sibling app (BaroEase), whose chrome is frosted glass the body scrolls behind. **v3's chrome is opaque and takes real layout space**, so every rule that made content pass *under* a bar is dropped here or kept for a stated different reason. Do not port the dropped ones back — see `DECISIONS.md` § v3 keeps its own chrome.

No spacing values here. Every inset, gap and padding named comes from `SdContentPaddingV3` alone — `DESIGN_SYSTEM.md` § Spacing.

## The frame

- **A screen wider than a phone caps and centres its body** — that rule and everything else that varies with window width is in `docs/rules/RESPONSIVE.md`. Nothing here depends on width unless it says so.
- **A screen never constructs an `AppBar`.** It passes `SdAppBarV3` to `SdScaffoldV3`, or uses `SdSearchHeaderV3` when the search box is the point. One widget owns the bar, so two screens cannot drift into two.
- **The bar inserts its own leading button for any route that can pop**, and passes `automaticallyImplyLeading: false` so the framework cannot add a second.
- **A screen's create action comes through `AppAddFabScaffold`** — the `+` `SdFabV3`, no title, same button, same place, every screen. An always-apply rule in root `CLAUDE.md`; the design-system half is in `DESIGN_SYSTEM.md`.
- **A screen with content and an action button pins the button to the bottom** — owner's rule. First stated for workspace setup, then every add and edit screen, now all of them: wherever content scrolls and the screen has an action, content scrolls and the action holds the bottom edge. A seller never scrolls to find how to finish, and finishing sits in the same place everywhere. **This is not the `SdFabV3` rule above and does not compete with it**: that one is a list screen creating a row; this one is a screen acting on what it shows.
  - **`AppPinnedAction` (`core/widgets/`) is the one implementation.** Three screens wrote their own before it was extracted — three chances for the gap above the button to differ. A screen chooses only its `variant`; the geometry is fixed.
  - The action sits **below** the scroll view, never floating over it, so content never passes behind it. So it wears no surface and no blur — `SdContentPaddingV3.pinnedActionsGap` above it is the whole separation, and `SdContentPaddingV3.bottom(context)` below it clears the home indicator.
  - The screen passes the button's state down; the widget holding it stays small enough that a keystroke rebuilds it, not the fields above.
  - **Two actions stack, never side by side, primary lowest.** Business details pins Save with Delete this business above it. A `Row` shrinks both labels and puts a destructive verb a thumb's width from the safe one; stacked, the button under the resting thumb is always the one the screen is for. `AppPinnedAction.secondary` is the slot; both share one bottom inset — a second padded widget would clear the home indicator twice.
  - **The second slot is not only for a destructive verb.** Quick Add pins Save with "Save and add another" above it — same stacking, same reason; the variant says which is which. The slot must never hold a second way to do the same thing at the same weight.
  - **The gap between the two is `SdContentPaddingV3.stackedActionsGap`, drawn by the slot** — owner's rule; it **reverses "a conditional second action carries its own gap"**. Two of the three screens with a second action drew no gap and their buttons touched, while the third drew its own — the exact drift a shared widget exists to stop, the same argument that put the insets above and below the slot inside it.
  - **A second action that does not apply is `null`, never an empty widget.** That is what the old rule really guarded: `_DangerZone` rendered `SizedBox.shrink()` for a seller who cannot delete, so a slot-owned gap would leave a hole above Save. The screen decides whether a second action exists; the slot decides how it looks.
  - **A button that does not apply disappears, never moves.** A screen with a conditional action — Subscription sells only to a non-paying seller, the paywall buys only once the store answers — renders nothing in the slot, and the scroll view takes the space back. Never leave a disabled button pinned to explain a state; the content above does.

- **"Action button" means the screen's action, not a row's.** Without this line the rule is unfollowable; these sit on the other side of it:
  - **A button inside a row or card acts on that record and stays there** — a recurring expense's Record, an offer card's Accept. Pinning those tears an action from the thing it names, and a screen listing twelve has no single bottom edge. **A destructive action on the record the whole screen is about is not one of these** — Business details' Delete this business was once read that way, wrongly: the screen is the record, so the verb is the screen's.
  - **An empty state's action stays in the empty state.** No content exists to pin it away from — the empty state *is* the screen — and `AppListEmptyState` already owns its place.
  - **A detail screen's Actions button stays in the app bar**: it opens a sheet of several verbs instead of committing one. Its own owner's rule, further down.
  - **A selection bar is already pinned** and stays a `bottomNavigationBar`: it appears with the selection and replaces the FAB, which a pinned action below the list cannot do.
  - A sheet only as tall as its content already has this shape — its action is its last row — and needs nothing. **A sheet that scrolls is a screen for this rule**: `PaywallScreen` is a route presented as a sheet, takes nine tenths of the height whatever the store returns, and holds its purchase button outside the scroll. It is the one place not using `AppPinnedAction` — `SdBottomSheetV3` already pays the horizontal gutter and home-indicator inset, so the shared widget would draw both twice. Only `pinnedActionsGap` is taken from it.

## The device status bar — one source, and the platforms disagree

Reseller Studio ships light **and** dark, so this is not set-and-forget: the wrong value renders invisible icons on exactly one platform in exactly one theme — the hardest bug to be told about.

- **The status bar style belongs to the app bar theme, set once, never per screen.** `AppBarTheme.systemOverlayStyle` in `AppTheme` is the one place it is decided.
- **Never call `SystemChrome.setSystemUIOverlayStyle` from a screen.** It is global and nothing restores it on pop, so the style leaks into the next route and the bug surfaces wherever came next. A screen that truly differs — a full-bleed photo header, a light sheet over a dark app — wraps itself in an `AnnotatedRegion<SystemUiOverlayStyle>`, which unwinds with the route.
- **The two platform fields are inverted.** `statusBarIconBrightness` (Android) describes the **icons**; `statusBarBrightness` (iOS) the **background behind them**:

  | Bar background | `statusBarIconBrightness` (Android) | `statusBarBrightness` (iOS) |
  |---|---|---|
  | Dark | `Brightness.light` | `Brightness.dark` |
  | Light | `Brightness.dark` | `Brightness.light` |

  Set **both**, every time. A style naming one looks right on the platform tested and renders invisible icons on the other.
- **Derive it from the resolved theme brightness, in one place** — from `ThemeData.brightness`, not two hand-written constants that can disagree with their palette. The app follows the system theme, so **it cannot be `const`**: a device switching to light mode would keep light icons on a light bar.
- **`statusBarColor` is Android-only and stays transparent.** iOS ignores it, so painting it opaque reads as "fixed on Android, still broken on iOS".
- **Assert on it; don't eyeball it.** A widget test can read the `AnnotatedRegion` value — the only thing that keeps this right after a palette change.

`AppTheme.statusBarStyle(Brightness)` is that one place. `AppTheme._build` hands it to `AppBarTheme.systemOverlayStyle`, and `ResellerStudioApp`'s builder wraps the app in an `AnnotatedRegion` of the same value, so a route with no app bar — splash, login — is covered too. `test/core/theme/app_theme_test.dart` asserts both platform fields in both themes. Android also needs `SystemUiMode.edgeToEdge`, which `AppBootstrap` enables in its own guarded step.

## The tab shell

The floating glass bar, `extendBody`, and the `floatingNav: true` padding that goes with it are in `DESIGN_SYSTEM.md` § The tab bar. What belongs here is about the shell, not the bar:

- **The selection indicator slides, never fades.** Same duration as all other chrome, from `SdMotionV3`. No flash, no strobe.
- **The complete frame is `SdBottomNavigationV3`.** Owner's rule. It owns the glass bar and adjacent-tab swipe; `AppShell` owns only GoRouter branch selection, analytics and localized destination data.
- **Tabs are branches of an `IndexedStack`: no route is pushed, so a navigator observer sees nothing.** Screen-view analytics for the five tabs cannot come from the router, or tab analytics are silently empty and read as if nobody uses the app. `AppShell` logs from `initState` and `didUpdateWidget` — the session's first tab counts; re-tapping the active tab does not — through `AppAnalytics.tabViewed`, naming the tab from `NavTabConstant`. **The name is an identifier, never a localized label**: one that changes with locale splits a tab into two series.
  - The one analytics event raised from a widget, not a controller. No controller sits between a tab tap and the shell, and it is a lifecycle callback, never `build`.
  - **Every other screen is `AppScreenTracker`'s** (`core/analytics/`). It listens to the router delegate — the whole stack, not one of six navigators — and reports the top screen's route template (`/orders/:orderId`), never its location, so no record id reaches the report. It skips `AppRoutes.tabRoots`, counted above; a new tab root goes into that set or is counted twice.

## Lists

- **The screen pads INSIDE the scrollable, never around it.** A `Padding` or `SafeArea` around the list clips the scrollable, and content stops where the wrapper does. Padding goes on the `SliverPadding` or the list's own `padding`. Under an opaque bar this is not about scrolling behind chrome — the scrollbar, the overscroll glow and the last row's clearance of the floating tab bar all belong to the scrollable.
- **A list is a `CustomScrollView` of slivers, padded per sliver.** That lets a header sit flush while rows below take the gutter and item gap; one `ListView` padding cannot express it, and screens that try end up with a header inset differently from its list.
- **Item spacing is `SliverList.separated` with `listItemGap`** — never a tile margin, never a raw number. Rows that inset themselves sit flush and take no gap.
- **Bounce only when content overflows.** Material's default wraps iOS physics in `AlwaysScrollableScrollPhysics`, so every short list drags and bounces against nothing — idle motion on a screen with none to give. Pass `AlwaysScrollableScrollPhysics` **explicitly and only** where pull-to-refresh must work on content shorter than the viewport.
- **Never nest two scrollables on one axis.** Where a widget scrolls horizontally itself — a chip strip, a thumbnail row — hand it a bare row.
- **Chrome driven by scroll position reads a `NotificationListener` on the list** and compares `metrics.pixels` with the element's own extent. **Ignore nested notifications (`notification.depth != 0`)** or a horizontal chip row inside the list drives the collapse. The threshold is a static on its own widget; an element that must fully scroll out before firing must start at offset 0, so nothing may be padded in above it. `SdSearchHeaderV3` and `SdBottomNavigationV3` are the two implementations — read them before writing a third.
- **Pull-to-refresh is one wrapper.** No v3 refresh indicator exists yet; when one is added it goes in the package, not a screen. Its `edgeOffset` is 0 under this app's opaque bar — the scaffold already subtracted the bar — and the header's own height on a screen whose scrollable starts with a search header, so the spinner drops in below the chips, not over them.

## A filtered list says how many filters are on, and offers Reset

Owner's rule. Inventory and Orders keep their filters in a sheet, so without a line on screen a row missing to a filter and one missing to a bug look identical — and the seller's only check is reopening the sheet and reading every group.

- **`AppActiveFilterBar` (`core/widgets/`) is the one implementation**, rendered under the strip on the screen only. The filter sheet has no bar: its Reset is a footer button beside Apply (below).
- **It renders nothing at zero.** "0 filters" is chrome describing absent chrome.
- **Count by group, never by chip.** Three ticked categories are one filter; a seller who made one choice cannot square "3 filters" with the sheet in front of them.
- **The search box is not counted, and Reset leaves it alone.** It is visible with its own clear button, so it is not the filter that went missing.
- **Nothing applies until Apply is pressed.** Owner's rule; it **reverses "the sheet applies as it is tapped"**. Chips edit a draft the sheet holds; the list behind does not move while the seller decides, and closing any other way — the X, a drag, back — leaves the list as it was. Under the old rule, trying two combinations had already changed the screen twice.
  - **The primary button says "Apply", not a count.** Rows left is a fact about an applied filter; this button applies one.
  - **The sheet's footer is two buttons, Reset then Apply** — owner's rule; it **reverses "the sheet's Reset is the bar at its top"**. Both sit where the thumb already is when the seller is done, and the pair is `AppFilterSheetActions` (`core/widgets/`), so both sheets build it once.
  - **A sheet's Reset empties what that sheet shows, nothing else.** The full sheet empties every group; a one-group sheet its one group. Nothing applies until Apply, as with a tick. Disabled while nothing it shows is pending — a Reset with nothing to reset does nothing.
  - **No Show preset: Status is the one group asking where a record is** — owner's rule; it **reverses "both sheets open with the preset as their first group"** and, with it, the plan's tab lists (§7, §8). The presets were statuses renamed — Draft, In stock and Sold sat in both groups — so a seller had two chips for one question and no way to tell which.
    - **Inventory's Status adds Stale as one more option** (`ItemStatusFilter`). The one preset no status could express — on hand, listed long ago — so it joins the group instead of leaving.
    - **Orders' Status is the raw statuses.** To Ship and Returns were several statuses ticked at once, which multi-select already does.
    - **Options OR within the group**; the group ANDs with the rest, like every multi-select group.
    - **Each status chip shows its row count**, taken under every other group and the search but not this one — what ticking it alone would show.
  - **Ticking a chip is a method on the criteria, not the notifier** (`ItemFilterCriteria.withStatusToggled`). Two places tick a chip — the draft and the applied value — so a tick's meaning lives in one place, and the controller keeps only `apply(pending)`.
- **A divider separates every group in a filter sheet from the next** — owner's rule. A blank gap between a dozen chip groups reads as one wall of chips; a rule shows where one question stops. It is `AppFilterGroupDivider` (`core/widgets/`), so both sheets space it alike, and it sits only between groups — never above the first or below the last.
- **The strip is the sheet, laid sideways** — owner's rule; it **reverses "the entry point is an app-bar action, never a chip on the strip"** and the preset tabs the strip carried. A seller wanting one question answered had to open a sheet of ten and scroll.
  - **The first chip opens the whole sheet, always first.** It carries the `tune` glyph and is selected while anything narrows the list.
  - **Then one chip per group, in the sheet's order.** Each opens a sheet with that group alone — same draft, same Reset beside Apply, same "nothing moves until Apply". Editing a group here or in the full sheet writes the one applied value.
  - **A group's chip is selected while its group narrows** and carries a caret, since it opens something rather than toggling. Its label is the group's title, the word the full sheet prints above it.
  - The groups are domain enums (`ItemFilterGroup`, `OrderFilterGroup`), so the chips, the full sheet and the one-group sheet are three readings of one list, and a new group cannot reach one without the others.
- `test/features/inventory/inventory_filter_sheet_test.dart` and `test/features/orders/order_filter_sheet_test.dart` hold the count, the two places it renders, and Reset.

## The loading screen is watched, not glimpsed

Owner's rule. The splash stays up for `SplashHoldController.minimum` every time it appears — cold start and right after sign-in alike — even when its answer already landed.

- **A hold, never a delay.** The work runs the whole time; only the route change waits. Nothing is scheduled behind it and no call is slowed to make room.
- **It only keeps the seller on the splash; it never sends them there.** A hold left standing while on Home costs nothing — what makes arming it early safe.
- **It re-arms whenever the app starts deciding again**, which covers sign-in. `appIsResolvingProvider` is the signal, mirroring the redirect's own splash conditions — change one, change the other.
- **The clock belongs to `SplashScreen`, not the hold.** What is awaited is the animation being *seen*, so it starts when the screen appears and cancels when it goes — nothing counts down while the loading view is not up, and a test that never shows it has no timer left running.
- **A standing hold is left alone.** A second question arriving mid-swing does not restart it, or a seller whose profile and workspace land a moment apart waits twice.
- The animation is `SdLoadingV3Page`, the page-sized half of the one loading indicator (`DESIGN_SYSTEM.md`).

## Empty states

- **An empty state still scrolls**, or the screen a seller most wants to refresh is the one that cannot. Wrap it as `SliverFillRemaining(hasScrollBody: false)`.
- **Use the sliver, not a `LayoutBuilder`.** A `LayoutBuilder` builds its child *during* layout, and a Riverpod consumer resuming inside that build throws `setState() called during build`.
- **The empty state says which empty it is.** "No items yet" and "nothing matches that search" are different situations with different copy, chosen off the trimmed query — otherwise a search with no hits reads as data loss. Both strings go through ARB keys (hard rule 7).
- **A filtered list picks between the two with `AppListEmptyState`, whose `hasAny` reads the unfiltered source.** Four screens wrote the choice by hand and three got it wrong the same way: Orders, Offers and Listings told a seller who had added nothing that nothing matched a filter they never set. The widget makes the filter half impossible to write twice, and `hasAny` is deliberately awkward to pass from a filtered list: a count taken after filtering is the bug.
- **The "not started yet" half carries an action; the filter half does not.** A filter's fix is already on screen. A first empty list is where a new seller stops, so it names the next step and opens it — even on lists with no create action, where the step is upstream (Listings sends the seller to Inventory).
- **A list with a create action offers that action, never a detour.** Orders was the exception until it got one: its button and empty state both open the record-sale screen, with the same words. An empty state pointing elsewhere than the screen's own create button teaches a route the seller must unlearn (`lib/features/orders/CLAUDE.md`).

- **An empty *block* is not an empty screen; it says so with `SdEmptyStateVariantV3.inline`.** Owner's rule. The page variant carries the screen's own band — 32 above, 32 plus the floating bar's footprint below — right when the empty state *is* the screen, wrong once it is one item in a list. Analytics' marketplace breakdown sits between two headings; that band put a hundred points of dead air under three lines and made the words read as set too high.
  - **The inline block keeps the container the rows would fill.** The breakdown renders the same `SdCardV3` either way, so the screen's rhythm does not change with the data, and the words centre on the card's own padding.
  - **Filling the height is not centring.** `Column(mainAxisSize: max)` makes the column *be* the space and puts its children at the top — the opposite of how it looks. The `Center` above does the centring, and only while the column stays `min`.
  - `test/features/analytics/marketplace_breakdown_empty_test.dart` pins the card and the equal air.

## A form seeds through `FormSeed`, never straight from `build`

A form editing an existing record learns of it in a `build` — the record arrives on a stream, so nowhere earlier exists. **Copying it into the form's controller there throws**: `Tried to modify a provider while the widget tree was building`. Not debug-only in practice — the form stayed empty, and the seller saw an edit screen that never filled in.

- **Use the `FormSeed` mixin (`core/state/`) and call `seedOnce`.** It defers the copy to the end of the frame — the fix Riverpod's own error names — and owns the once-only flag.
- **Once, not once per build.** The record rebuilds the screen whenever a teammate edits it; re-seeding then discards every keystroke the seller made meanwhile. Never re-derive the guard per screen — two screens wrote it themselves, both with the bug beside it.
- **One frame of empty fields is the cost, and it is invisible**: the screen already showed empty fields while the record loaded.
- Held by `test/features/inventory/item_form_seed_test.dart` and `test/features/workspace/workspace_detail_seed_test.dart`, both failing on the direct call.

## A detail screen edits in place, one section at a time

Owner's rule; it replaces the edit screen for every record with a detail screen. **No separate screen exists for changing an existing record.** A seller spotting a wrong cost was pushed onto a full form, scrolled past nine fields they were not changing, and popped back — for one number.

- **Each section holding fields has its own Edit, which becomes Cancel and Save.** The section is the unit because it already groups the screen's fields: fixing a price and fixing an address are separate intents and separate saves.
- **One section edits at a time.** Opening a second closes the first — two open drafts are two sets of unsaved keystrokes and no way to tell which Save is which.
- **Read and edit mode show the same rows in the same order.** A section that reflows on Edit makes the seller re-find the field they came for.
- **Only stored fields open.** A derived figure has no field (hard rule 3), and a recorded timestamp is not something a seller types.
- **A state transition stays in the actions sheet, never a section.** Mark sold, Archive, Ship, Mark delivered and Record refund have side effects — an inventory write, an audit entry, a timeline fact — and a status field writing the value alone would skip them (hard rule 2).
- **A section whose rows belong to another screen sends Edit there instead of opening fields.** Owner's rule, stated for Item detail's Listings block: what a marketplace asks is edited on Marketplaces management, the only screen that can also put the item on a new one. Editing one number in two places is two ways to write it, and the half reached first cannot finish the job. The section still reads as one — same header, same Edit — it hands the whole question over.
- **Which section is open, and the save, live in a controller**; the text controllers stay on the screen, as in every form here. A widget deciding what to write is the rule this repo does not bend.
- **Cancel restores from the record, not a copy taken on Edit.** The record is a stream a teammate may have changed while the draft was open; re-seeding from the current value is the only answer that is not stale.
- **Saving writes only the fields that section owns**, re-read at write time — the rule the workspace detail screen already follows.
- **The create form stays a screen.** Creating has no record to show sections of, and hard rule 2 keeps its requirements to a title.
- **While a section is open, the app bar says so.** Owner's rule. A seller scrolled away from the open section saw nothing saying a draft was waiting, and the back arrow silently threw it away. `AppEditingAppBar` (`core/widgets/`) replaces the screen's bar while a section is open:
  - the title reads "Editing <section>"; the record's title moves to the subtitle;
  - the back arrow becomes a close that cancels the draft, and **a system back does the same** — it leaves edit mode, never the screen;
  - the actions control is gone: a state transition mid-draft is a second write racing the first.

## A detail screen opens on a summary, and every section stays open

Owner's call, approved with `docs/plans/UI_POLISH_PLAN.md`; the owner later removed the folding half (`docs/rules/DESIGN_SYSTEM.md`, Swiping and motion). It sits on top of the in-place editing rule above.

- **Item detail opens on a summary block** — photo, title, state, and three figures (cost, expected price, on hand) across the row. Every section below is open.
- **The item's title appears once, never twice.** Owner's rule. While the summary block is in view the app bar reads the generic "Item" over the SKU; once it scrolls away, the item's title fades into the bar. A title in the bar and again in the block right under it spent two lines on one thing.
- **Order detail keeps its pinned next move** (`lib/features/orders/CLAUDE.md`); Order, Profit, Shipping and the Timeline are all open.
- **A create form asks for what every record needs and puts the rest behind More details.** The item form shows Title and Quantity (hard rule 2 and the quantity rule). The rest **opens by itself when something in it is already filled** — a remembered category or bin, a scanned barcode — so a prefill is never hidden.

## Search

- **Search is a mode of the header, not a widget parked above the list.** Entering it swaps the title row for the field and the actions for the clear button. A screen changing only one leaves the seller with a search field and a back arrow that pops the route from under them.
- **The visibility flag is screen state; the query is not.** Whether the field shows dies with the screen and can be `setState`. **The query lives in a controller**, so filtering survives a tab switch, a rebuild and a rotation — a query in the widget resets when the shell rebuilds the branch, and the list silently repopulates.
- **Opening focuses the field in the same action.** A field the seller must then tap is two taps for one intent.
- **Cancel clears, unfocuses and exits — in that order, one method.** Leaving the query behind on exit is the bug that ships: field gone, list still filtered, nothing on screen saying why. Clear the controller *and* the `TextEditingController`, drop focus, then flip the flag.
- **Clear is separate from cancel, and keeps focus.** The X empties the query and **re-requests focus** so typing continues; the leading button leaves search. One control doing both drops a seller out of search when they meant to fix a typo.
- **The clear action exists only while the query is non-empty.** An X over an empty field does nothing.
- **Own the `TextEditingController` and the `FocusNode`, and dispose both.** They live as long as the screen; a `State` that creates them and skips `dispose()` leaks one per visit.
- **Filtering is not the field's job.** The query lives in a controller, matching is a `*Utils` method or a `domain/services/` class, and the field only reports `onChanged` (no business logic in widgets).
- **Two kinds of search entry exist on purpose** — the docking header Inventory and Orders share, and the Search screen's plain autofocused field. A recorded decision, not duplication to clean up: `DECISIONS.md`.
- **Orders searches what a seller has in hand for a sale** — item, buyer, platform order number, tracking number, platform (`OrderSearch`). Owner's request: finding one sale among hundreds should not need a date filter.

## Home carries Quick Action, and it must stay complete

Owner's rule. Create actions are scattered by design — each lives on the screen owning its records, behind that screen's own `SdFabV3`. Right for a seller already on the screen, wrong for one who opened the app holding a receipt, so Home lists **every** one.

`QuickActionConstant.actions` is that list, the only one. A row pushes the screen owning the action; it never opens a form Home would then have to know how to save.

**Rows, always last on the screen** — owner's rule. Home answers "what needs attention today" first, so a launcher above the figures opens the screen on the wrong thing. At the bottom it is where a seller who came to *add* scrolls to, and costs the one who came to *read* nothing.

**Two rows create nothing, and ride at the end** — owner's rule: About last, Analytics just above it. About sits near the end of a long More list, so Home keeps it findable; putting both last stops a seller scanning for "add" from stepping over them. Nothing else non-create joins them without the same decision.

**Scan is a Home shortcut; Flow overview is its own section just below the shortcut row.** Owner's rule. Scan is what a seller reaches for while holding an item, so it belongs in the one-glance row. Flow overview needs more context than a small launcher card holds, so its own section opens the existing sheet and appears in one place only.

**Analytics opens with `go`, not `push`.** It is a branch root; pushing one over Home leaves the seller on the wrong tab with a back button they should not have — so `QuickAction` carries how it opens, not only a route.

- **`WorkflowConstant.steps` is the content and stays the only copy of the chain.** The sheet and About's diagram draw the same data — a second list for the sheet is how the app ends up teaching two workflows.
- **A step carries `isOptional`, meaning the app never blocks on it** — not "unimportant". Listing, shipping and recording a source can all be skipped and the seller still gets paid, by hard rule 2: requirements attach when a record *moves*, never at creation. Saying so is the badge's point: a seller who thinks all nine are mandatory goes back to the spreadsheet.
- The badge is `SdBadgeV3` in the neutral tone. Optional is not a warning.

The shortcut card at the top of Home is named after the section it lands on and scrolls to the end — a card saying something other than where it goes lies.

**Adding a create action anywhere means adding it here.** `test/features/home/quick_action_test.dart` reads `lib/features/` for screens wearing `AppAddFabScaffold` and fails on any the section cannot start — a section listing six of eight is worse than none: a seller who learned to look here can no longer tell "missing" from "the app cannot do it".

## Dense destination screens expose their hierarchy

**More is grouped into titled sections, never one flat list.** Owner's rule.

| Section | Contains |
|---|---|
| Operations | Sourcing, Listings, Categories, Locations |
| Finance | Expenses, Payouts, Reports, Receipts, Tax |
| Business | Marketplaces, Team, Activity |
| Account | Subscription, Settings |

Signed-out More renders only the Account section, with Settings.

**An item detail opens its action sheet from a labelled app-bar button, not an ellipsis glyph.** Owner's rule. The sheet holds several important state transitions, so a subtle three-dot icon makes the main way to act on an item look decorative; the localized Actions label is the affordance.

## About draws the workflow, and the diagram is navigable

Owner's rule: the app has an About screen holding what it is plus the workflow, so a seller sees how the parts connect. It is a row in More's App section — no Settings screen exists to hold it (`lib/features/more/CLAUDE.md`). Home's Quick Action list carries the shortcut, last, keeping it one tap away.

`WorkflowConstant.steps` is the chain `CLAUDE.md` writes as one line, as data. It is drawn **vertically** — nine links across a phone are unreadable or a horizontal scroll nobody finds — and **each step opens the screen that performs it**: a page explaining a workflow you cannot enter is the screen this rulebook says will be redesigned.

The order carries the meaning. `test/features/more/about_screen_test.dart` pins the sequence against the lifecycle and fails on a step pointing at a parameterised route — unpushable, a dead link inside the one screen that explains the app.

**About is the guide to both businesses, and Home's app bar opens it.** Owner's rule. An info button sits beside Search and Scan, because "how does this work?" is asked on the first screen, not five rows down More.

- **Two guides, one rail.** A Reselling / Dropshipping switch picks `WorkflowConstant.steps` or `WorkflowConstant.dropshipSteps`. Sell, Profit and Analyze are shared kinds — one sale, one profit, one tab — and the supplier's steps replace Purchase, Inventory and Ship.
- **Every step carries its how-lines**, the same `WorkflowLabel.how` Home's flow overview spells out, so About is a guide, not a map. Both draw them with `AppBulletLine`.
- **Home's flow overview stays the reseller's loop.** It answers "how do I use this" for the chain `CLAUDE.md` writes; the dropship loop lives on About alone until the owner says otherwise.
- `test/features/more/about_screen_test.dart` pins the dropship order; `home_shortcuts_test.dart` the info button's route.
