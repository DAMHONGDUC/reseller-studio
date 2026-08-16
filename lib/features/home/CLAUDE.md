# Home

Read this before changing what is on Home or the order it is in.

Home answers one question — *what do I need to do today?* — and every rule
below is about protecting that answer from the screen filling up around it.

## The order of the screen is a product decision, not a layout one

Top to bottom: **the three shortcut cards, Needs Attention, Performance,
Recent Activity, Quick Action, Quick Access.** Three owner's rules decide it,
and they are listed in the order they outrank each other.

1. **Three shortcut cards come first, above even Needs Attention.** They are
   the ways *out* of Home — down to Quick Action, sideways into global search,
   across to Analytics — not content, so a seller who opened the app to go
   somewhere does not read a dashboard on the way there.
   - **Three, and the list is closed.** A fourth makes the row a launcher, and
     a launcher above the figures is exactly what keeping the create actions at
     the bottom exists to prevent. The row works because it is short enough to
     take in without reading. Adding one is a product decision — ask.
   - `HomeShortcutConstant` is the list;
     `test/features/home/home_shortcuts_test.dart` holds the placement and the
     enum-to-card completeness.
2. **Needs Attention sits above the numbers**, inverting the plan's own order
   (§6). A seller opening the app at 8am needs the orders waiting to ship, not
   last night's revenue.
3. **Quick Action is rows, and the two bottom sections are last.** Eight of
   anything is a list, and a grid of tiles above the figures made the screen
   open on a launcher instead of on the answer. At the bottom it is where a
   seller who came to *add* something scrolls to, and it costs the seller who
   came to *read* nothing. `test/features/home/quick_access_test.dart` holds
   both halves.

**The shortcut card and those two sections being last are one mechanism.** The
card scrolls to the end of the list rather than to a key, because a lazy
`ListView` has not built an off-screen target and `ensureVisible` on a key with
no `currentContext` does nothing — see `_HomeScreenState._toQuickAction` and
`ScrollUtils.toEnd`. Moving Quick Action off the bottom breaks that card, and
the Quick Access test is what says so.

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
