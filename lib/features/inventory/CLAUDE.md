# CLAUDE.md — inventory

Rules specific to the item list, the item forms and what a seller can do to an
item. The root `CLAUDE.md` still applies in full; this file only holds what
would be wrong to generalise.

## New-business category defaults

Every new business starts with three normal category records: Clothing,
Shoes, and Accessories. They are editable and soft-deletable like categories
the seller creates later; defaults remove setup work but never form a closed
taxonomy.

- **The three categories and the user's workspace pointer share the final
  creation batch.** A partial default set is indistinguishable from a seller
  deleting one, so the workspace is not exposed until all defaults exist.
- **Default ids and names have one owner in Inventory.** Workspace creation
  consumes that definition and never repeats the strings.

## Every action on an item is reachable from the row

Owner's rule. `ItemActionsSheet` opens from two places and they offer the same
list: the detail screen's Actions button, and **the `more_vert` button on
`ItemCard`**.

- **The row is the point.** Listing, repricing and marking sold are what a
  seller does while looking at the list. Reaching them only through detail
  cost a push and a pop per item — on a forty-row afternoon, eighty taps that
  buy nothing.
- **One sheet, not two lists of verbs.** Both entry points call
  `ItemActionsSheet.show`, so an action added there cannot go missing from the
  row.
- **`more_vert`, not the detail screen's `tune`** — owner's rule. A glyph is
  all the width allows beside a title, two badges and a price line, so it has
  to be one a seller already knows; `tune` reads as filtering when it is not
  sitting next to the word Actions. The detail screen keeps `tune` because it
  has room for the label.
- **It disappears while a bulk selection is open.** Every tap ticks a row
  then, and a sheet for one item would lose the forty the seller had just
  picked — the same reason a tap selects instead of navigating in that mode.
- **`onActions` is nullable**, so a list that only navigates simply does not
  pass it.
- `test/features/inventory/item_card_actions_test.dart` holds all four.

## One List row, and it opens the cross-list screen

Owner's rule. The actions sheet used to carry **two** verbs for putting an
item on a marketplace — a `List` sheet for exactly one, and `Cross-list` for
several. They are now one row, `itemActionList`, opening `CrossListScreen`.

- **They read as the same verb.** Nothing on either row said which to use, and
  a seller meeting the sheet for the first time has no way to tell.
- **The narrower one stopped working after the first listing.** `List` was
  gated on `ItemTransition.check(item, listed)`, which refuses an item that is
  already listed — the exact item cross-listing exists for. So the first thing
  it did once a seller had listed anything was refuse and point at nothing,
  while the row they wanted sat underneath.
- **The row is gated on `crossListCheck`**, which refuses only a sold or
  archived item and an empty shelf — and asks for no price, because the screen
  it opens is where the price is entered (hard rule 2).
- **Nothing was lost.** Picking one marketplace on that screen writes the same
  listing and makes the same status move the sheet did.
  `ListItemSheet` and `ItemActionsController.listItem` are deleted rather than
  left as a second way to write a listing.
- `test/features/listings/cross_list_test.dart` holds both halves: the sheet
  offers List and no Cross-list, and the old gate would still refuse the item
  the new one allows.

## Every marketplace may carry its own price

Owner's rule. `Listing.price` was always per-listing; what was missing was a
way to set it. The cross-list screen now collects **a shared price plus the
exceptions**, and `crossList` takes a `Map<Marketplace, Money>`.

- **The price field sits under the marketplace it belongs to** — owner's rule.
  Choosing a platform and pricing it is one decision, and it replaced a
  separate Review section whose rows opened a sheet to edit one number: the
  seller ticked something and had to scroll to find out what that had done.
  The fee and what is left ride under the field as its helper.
- **Ticking seeds that row from the shared price**, so the common case — one
  number everywhere — is still no typing at all. The shared field is the seed,
  not the answer: changing it afterwards does not reach back into rows already
  on screen, because a number moving in a field nobody is watching is worse
  than retyping one.
- **A marketplace the item is already on is ticked, and its price is
  editable** — owner's rule. An empty circle beside a platform the item is
  live on is simply wrong; the circle cannot be unticked, because a second
  listing on the same platform is not a thing to offer, but the price it is
  live at is the thing sellers most often came to change.
- **Save covers both halves and counts both.** Adding a platform and moving
  another's price are one intent when one button was pressed, so they ride in
  one `saveAll` — and a reprice on its own is reason enough to enable Save.
- **Publish needs a price on every ticked row.** A row whose field was emptied
  holds publish closed rather than falling back to the seed, which would list
  at a number the seller had just deleted.
- **Unticking a platform drops its price.** A hidden number that came back on
  the next tick is one nobody chose that time.
- **The item's `askingPrice` takes the shared price, never a platform's.**
  What the item is worth is not whichever marketplace happened to be cheapest,
  so `crossList` takes it as a separate argument and leaves the item alone
  when it is null.
- `test/features/listings/cross_list_test.dart` holds all six.

## Two places price a marketplace, and they answer different questions

Owner's rule, and it is deliberate rather than a duplication left standing.

- **The item form edits the prices of listings that already exist**, inline —
  cost, asking price and minimum are on that screen already, and the number a
  buyer actually sees is the one a seller most often came to change. It never
  creates a listing, and renders nothing when the item is on no marketplace.
  The edits ride on `ItemFormState.listingPrices`, keyed by listing id, and
  are written by the form's own Save — so changing a title and a price is one
  button.
- **The List screen adds marketplaces**, and prices both the new ones and the
  live ones. It is where "put this somewhere new" is answered.
- **Neither writes through the other.** The form's `_saveListingPrices` reads
  the listings fresh and moves only the price; `crossList` batches new
  listings and repriced ones together. A shared write path would have to know
  which screen called it, which is the coupling the split avoids.
- **`askingPrice` is the item's own number and stays that** — what the seller
  wants for the thing, shown on its card. A marketplace price never writes
  back to it, and a reprice on its own does not re-stamp `listedAt`, which
  would reset the staleness clock.

## The inventory row is two zones, and every figure has a place

Owner's rule — the row must be **good-looking, sensible and complete**, in
that order of argument and none of them at the cost of the others. `ItemCard`
answers it with a split rather than a longer list of lines:

- **Across the top, what the item is**: photo, title, the asking price at the
  end of that line, then the badges naming its state. **Underneath, at the
  card's own edges, what it is worth**: cost against expected profit, then the
  marketplaces it is live on.
- **The split is what makes the figures fit.** Held inside the top row the
  money had a 64pt photo on one side and a 36pt actions button on the other,
  and `Profit $140.00 (76%)` ellipsized on a four-figure item. Given the
  card's full width it does not.
- **The asking price sits at the end of the title row**, the same place the
  order and offer cards put theirs. It is what a seller scans a list for, and
  at the edge it forms a column the eye runs straight down; buried in a line
  of three labelled cells it was one figure among three.
- **Cost at the start of the money line, profit at the end**, so the profit
  lands under the asking price and the two numbers a seller compares share a
  column. The margin rides inside the profit cell: a percentage is what makes
  $140 a good number or a thin one.
- **A cell is one paragraph, not a label widget beside a value widget.** The
  label and its figure have to ellipsize as one thing — a `Row` clips
  whichever child the constraints reach first, which is how the margin
  disappeared while `Cost` sat on width it did not need.
- **Nothing here is stored** (hard rule 3): `Item.expectedProfit` and
  `Item.expectedMargin` are derived, and both are null — rendered `—`, never
  `0` — the moment a figure behind them is missing (hard rule 5).

## The row says how long, not only what

Owner's rule, part of the same one above. A badge beside the status carries
the age of the state the item is in — `3w`, `2mo` — from `Item.stateSince`.

- **One timestamp per state**: sold reads `soldAt`, listed reads `listedAt`,
  everything else `createdAt`. A screen picking its own field is how two
  places end up disagreeing about what "how long has this sat" means.
- **The duration alone, beside the badge that names the state.** "Listed 84d"
  next to a badge already reading *Listed* says the word twice, and the row
  has no width to spare.
- **It is not the stale badge.** Stale says a threshold was crossed; the age
  says by how far, and an item three days over reads differently from one at
  six months.

## The row names its marketplaces and prices none of them

Owner's rule, and it replaces the earlier one that put a figure per platform
on the card. `ItemCard` shows **every marketplace the item is live on, as
plain badges** — no amounts.

- **A price per platform is not what a list is scanned for.** Where the item
  is takes one glance; what it costs on each takes a comparison, and a
  comparison belongs on the detail screen where the numbers can be laid out.
- **Every marketplace shows, wrapped rather than cut to one line.** The old
  line ellipsized, which hid exactly the platform a seller with five listings
  was looking for. A card grows a row instead.
- **Deduped and walked in `Marketplace.values` order**, so two listings on one
  platform read as one badge and the row cannot reshuffle between builds.
- `test/features/inventory/item_card_marketplaces_test.dart` holds both
  halves: every name is on the row, and no listing price is.
  `item_card_figures_test.dart` holds the money and the age;
  `item_derived_test.dart` holds the two getters they read.

## The actions that would be refused are shown, not hidden

A move the item cannot make yet still appears in the sheet, and tapping it
says which field is missing (`ItemBlockPresenter`). Hiding "List" from an item
with no price teaches nothing; "Add an asking price to list this" teaches the
rule and points at the fix.

## The item form seeds through `FormSeed`

The record arrives on a stream, so the form learns it exists inside a `build` —
and writing the form's controller from there throws. See
`docs/rules/SCREENS.md`, which carries the rule and the reason.
