# CLAUDE.md — inventory

Rules specific to the item list, the item forms and what a seller can do to an
item. The root `CLAUDE.md` still applies in full; this file only holds what
would be wrong to generalise.

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
- **A marketplace the item is already on is ticked and inert** — owner's rule.
  An empty circle beside a platform the item is live on is simply wrong, and
  the row stays disabled because a second listing on the same platform is not
  a thing to offer.
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

## The actions that would be refused are shown, not hidden

A move the item cannot make yet still appears in the sheet, and tapping it
says which field is missing (`ItemBlockPresenter`). Hiding "List" from an item
with no price teaches nothing; "Add an asking price to list this" teaches the
rule and points at the fix.

## The item form seeds through `FormSeed`

The record arrives on a stream, so the form learns it exists inside a `build` —
and writing the form's controller from there throws. See
`docs/rules/SCREENS.md`, which carries the rule and the reason.
