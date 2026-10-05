# Home

Read this before changing what is on Home or the order it is in.

Home answers one question — *what do I need to do today?* — and every rule
below is about protecting that answer from the screen filling up around it.

## The order of the screen is a product decision, not a layout one

Top to bottom: **Needs Attention, the shortcut row, Getting started,
Performance, Flow overview, Recent Activity, Quick Action.** Owner's rules
decide it, and they are listed in the order they outrank each other.
`test/features/home/home_section_order_test.dart` holds the top of it.

1. **Needs Attention comes first, as a grid of tiles.** Owner's rule, and it
   **reverses "three shortcut cards come first"** — the plan's own core
   principle is the tiebreaker: a seller opening the app at 8am needs the
   orders waiting to ship before any way out of the screen.
   - **Two tiles across, the count set large, the label under it.** A row of
     text with the count at its end made the number the last thing read; the
     tile makes it the first. A tile whose problem has a clock on it (an
     overdue order, an overdue payout) wears a tinted edge as well as the
     tinted detail line — colour is never the only signal.
   - **It carries the plan's four rows and one more: an overdue payout.**
     Orders to ship, offers waiting, items to list and stale inventory are
     §6's; "not paid out yet" is the only tile on Home that hands the seller
     money back rather than work, and a payout that never arrives is invisible
     until somebody goes looking for it.
   - **Overdue, never merely outstanding.** A payout three days old is a
     platform working normally, so the tile uses
     `PayoutReconciliation.overdueAfterDays` for its warning. A warning that
     is always there is one the eye learns to skip, which is what the rest of
     this section exists to prevent.
   - Adding a sixth tile is a product decision — ask. The block works because
     it is short enough that every tile still reads as urgent.
2. **The shortcut row follows it: three create actions, as buttons.** Owner's
   rule, replacing the three shortcut cards (Quick Action, Search, Scan).
   Quick add, Scan and Record sale are the three things a seller starts while
   holding an item or a sale, so they get one tap from the first screen.
   - **Quick add is the filled button; the other two are outlined.** One
     primary per row — three equal weights said three things mattered equally.
   - **Search left the row** because it is already the app bar's action, and
     two ways to the same place on one screen is one too many.
   - **Each button reuses its Quick Action row's words and route**, so the
     button and the row it shortcuts can never disagree.
   - **Three, and the list is closed.** A fourth makes the row a launcher.
     Adding one is a product decision — ask.
   - **Icon over label, not a pill.** "Enregistrer une vente" does not fit
     beside its icon at a third of a phone; stacked, a label takes two lines
     without the row changing shape.
   - `HomeShortcutConstant` is the list;
     `test/features/home/home_shortcuts_test.dart` holds the placement, that
     each shortcut is a Quick Action row opening that row's route, and that
     every label fits its button in every shipping locale.
3. **Getting started sits directly under the shortcut row, and wears a tinted
   edge.** Owner's rule. It is the only card on Home that asks the seller to
   do something rather than reporting on what they have done, and it is gone
   for good once the three steps are. See below.
4. **Performance follows all three.** It briefly sat directly under the
   shortcuts; that is no longer the order, and nothing should restore it from
   the record of the intermediate state.
5. **Flow overview is one full-width card, below the numbers.** The card owns
   both its title and description — there is no section header above it — so
   the whole explanation reads and taps as one destination. It opens the
   existing sheet and appears nowhere else on Home. **It is far enough down
   that a widget test has to scroll before tapping it** — see
   `flow_overview_test.dart`.
6. **Quick Action is one card of rows, split by titled sections, and stays
   last.** Owner's rule. Inventory holds Quick Add, Scan, Add item, Categories
   and Locations; Operations holds Purchases, Expenses and Sources; Business
   holds Team; App holds Analytics and About. The titles make the long list
   scannable like Settings, while one outer card keeps it reading as one Quick
   Action block rather than four unrelated dashboard sections. At the bottom
   it costs the seller who came to read nothing.

**Home is taller than a phone, so a section-order test cannot read pixels.**
A lazy sliver list estimates the extent of every child it has not built, which
makes `position.pixels` a moving target rather than an absolute coordinate —
two scrolled measurements compared against each other reported the wrong
order outright. `home_section_order_test.dart` scrolls from the top and
compares the order sections *come into view* in, sorting anything that arrives
in the same frame by its y within that frame.

**Quick Action stays last on its own merit, not because a card scrolls to
it.** The shortcut row no longer has a "Quick Action" button, so nothing
depends on the section being at the end of the list — keep it there for the
reason in point 6, not for a mechanism that is gone.

## Home never reports on a business that has not started

**Needs Attention with no rows has two answers, not one.** "All clear" is a
report on work, and a brand-new account has none — saying it there told a
seller the app had already looked at their business and found nothing worth
mentioning. `workspaceActivityProvider` picks:

- **`untouched`** — no items and no orders have ever existed → `_StartHere`,
  which names the first step and opens Quick Add. It disappears on the first
  record, so there is nothing to dismiss and nothing to remember.
- **`active`** → `_AllClear`, unchanged.
- **`unknown`** — a stream has not delivered → neither. Reading a loading
  stream as an empty business would flash "start here" at a seller with four
  hundred items, the same mistake as showing the login form while auth
  resolves (hard rule 1).

**The two are never both on screen.** One card answers the section, or they
stand next to each other claiming different things.
`test/features/home/first_run_test.dart` pins it.

**A section owns its own header.** Home rendered the "Recent Activity" heading
and the section under it decided whether to build anything, which on a new
account left a title over a gap. Whatever answers "does this section exist"
renders the heading too — see `_RecentActivity` and `_GettingStarted`.

## Getting started is a separate section from the Start here card

Owner's rule: **the checklist is its own section, and `_StartHere` stays.**
They look alike and do different jobs, which is why both are on screen on a
fresh account:

- **`_StartHere`, inside Needs Attention, names the one next action** and
  carries the button that performs it. It answers "what do I do now".
- **`_GettingStarted`, the section below, is the progress report** — three
  rows, ticked as they are done, with the count in the header. It answers "how
  far along am I", which is the question a seller with two items and no sale
  is actually asking, and which a single CTA cannot answer.

**The card carries a tinted border** (`AppListCard.borderColor`, forwarded to
`SdCardV3`). That widget's rule applies unchanged — colour is never the only
signal — and the "N of 3 done" in the section header is the label that says
the same thing.

**Three steps, and they are the lifecycle's spine** — add an item, list it,
record the sale. `GettingStartedStep` is the list. Anything the app never
blocks on stays out; the full nine steps live in the flow overview sheet, and
a checklist that also asked for a category and a location would be teaching the
spreadsheet this app replaces.

**A later step ticks the earlier ones.** `GettingStartedProgress` is pure Dart
and unit-tested for exactly this: a seller can reach a sale this app never saw
listed — marked sold off the shelf, or an order imported — and "sale recorded"
above an unticked "list it" reads as broken rather than as flexible.

**It removes itself, header included, and there is no dismiss control.** Once
all three are done the section is gone for good, so an established seller has
nothing to scroll past and nothing to remember having hidden. It also renders
nothing while a source is still loading — `gettingStartedProvider` returns null
rather than an empty set, for the same reason `workspaceActivityProvider` has
an `unknown`.

## Where Home sends the seller

- **Search is `push`; Analytics is `go`.** Search lives outside the shell and
  comes back here. Analytics is a tab, and pushing a branch root over Home
  leaves the seller on the wrong tab with a back button they should not have.
- **Nothing on Home opens a form.** Every card and row hands off to the screen
  that owns the records it creates, so Home never learns how to save anything.

## Quick Action is complete or it is worthless

**Adding a create action anywhere means adding it to `QuickActionConstant`.**
A section that shows seven of the eight is worse than none: a seller who has
learned to look here stops finding what they need and cannot tell whether the
action is missing or the app cannot do it. `quick_access_test.dart` reads every
screen wearing an `AppAddFabScaffold` off the source and fails on one this list
does not know about, so the two cannot drift.

`QuickActionConstant.sections` owns both grouping and order;
`QuickActionConstant.actions` is only its flattened audit view. A second flat
list beside the sections would let the UI and completeness test disagree.

## Two rows in Quick Action do not create anything

Owner's rule, and they ride at the end: **About last, Analytics just above it.**
The create actions above them keep the section's shape, and a seller scanning
for "add" never steps over them.

**How a Quick Action row opens is a property of the row**, not something its
call site works out: `QuickActionOpen` says push or go. Analytics is `go`
because a branch root pushed over Home would leave the seller on the wrong tab
with a back button they should not have.

**Flow overview is its own Home section, not a Quick Action row** — never in
both. A launcher that lists the same destination twice is one a seller stops
reading.

## The flow overview sheet is a document, not a menu

It takes the near-full-screen share named by `FlowOverviewSheet.heightFactor`
and spells every step out — what it is, whether the app ever asks for it, and
what the seller actually does — because it is the answer to "how do I use
this", and a list of nine nouns is not an answer. The remaining strip of Home
keeps the sheet visibly dismissible.

**The Optional badge sits above its step, on its own line** — owner's rule.
Beside the title it competed for a row that also carries the expand arrow, and
on the longer titles it was the first thing squeezed; over the step it reads as
a label on the whole thing, which is what it is.

**The title takes an `Expanded`, never a `Flexible` beside a `Spacer`.** Those
two share the free space between them, so the arrow floated a different
distance in on every step depending on how long its title was.
`flow_overview_test.dart` measures both.

It draws `WorkflowConstant.steps`, the same data About's diagram uses, and
badges the steps the app never blocks on; what "optional" means there is in
`docs/rules/SCREENS.md`. **Each step is an independent collapsed row that can
expand and collapse.** Owner's rule. The title, position and optional badge
stay visible for scanning; expanding reveals the explanation, instructions
and route action, and several steps may stay open while the seller compares
them. Each step opens the screen that performs it, so the sheet is a way in
rather than a picture.
