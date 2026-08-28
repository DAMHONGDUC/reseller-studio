# Home

Read this before changing what is on Home or the order it is in.

Home answers one question — *what do I need to do today?* — and every rule
below is about protecting that answer from the screen filling up around it.

## The order of the screen is a product decision, not a layout one

Top to bottom: **the three shortcut cards, Needs Attention, Getting started,
Performance, Flow overview, Recent Activity, Quick Action.** Owner's rules
decide it, and they are listed in the order they outrank each other.
`test/features/home/home_section_order_test.dart` holds the top of it.

1. **Three shortcut cards come first.** They are the ways *out* of Home — down
   to Quick Action, sideways into global search, and into Scan — not content,
   so a seller who opened the app to go somewhere does not read a dashboard on
   the way there.
   - **Scan replaces Flow overview in the row.** It is a frequent action a
     seller starts while holding an item, so it earns the one-tap entry.
   - **Three, and the list is closed.** A fourth makes the row a launcher, and
     a launcher above the figures is exactly what keeping the create actions at
     the bottom exists to prevent. The row works because it is short enough to
     take in without reading. Adding one is a product decision — ask.
   - `HomeShortcutConstant` is the list;
     `test/features/home/home_shortcuts_test.dart` holds the placement and the
     enum-to-card completeness.
2. **Needs Attention sits directly under the shortcut row, above the
   numbers.** Owner's rule, and it is the plan's own core principle back where
   it belongs: a seller opening the app at 8am needs the orders waiting to
   ship, not last night's revenue.
3. **Getting started rides immediately under Needs Attention.** The two answer
   the same question — what is waiting on me — for a business that has started
   and one that has not, so nothing goes between them. See below.
4. **Performance follows both.** It briefly sat directly under the shortcuts;
   that is no longer the order, and nothing should restore it from the record
   of the intermediate state.
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

**The shortcut card and Quick Action being last are one mechanism.** The card
scrolls to the end of the list rather than to a key, because a lazy
`ListView` has not built an off-screen target and `ensureVisible` on a key with
no `currentContext` does nothing — see `_HomeScreenState._toQuickAction` and
`ScrollUtils.toEnd`. Moving Quick Action off the bottom breaks that card, and
the Quick Access test is what says so.

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

It draws `WorkflowConstant.steps`, the same data About's diagram uses, and
badges the steps the app never blocks on; what "optional" means there is in
`docs/rules/SCREENS.md`. **Each step is an independent collapsed row that can
expand and collapse.** Owner's rule. The title, position and optional badge
stay visible for scanning; expanding reveals the explanation, instructions
and route action, and several steps may stay open while the seller compares
them. Each step opens the screen that performs it, so the sheet is a way in
rather than a picture.
