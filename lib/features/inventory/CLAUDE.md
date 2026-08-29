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
- **A round 44pt target, centred on the glyph** — owner's rule. It was a 36×44
  box with the dots pinned to its right edge: a squeezed target, and a ripple
  that came up as a rounded rectangle nowhere near what it was acknowledging.
  The glyph still lands on the card's content edge, where every
  `AppRowChevron` sits — the target is centred on it and the button is nudged
  outward by what centring cost, overhanging the card's padding rather than
  pushing the dots inward. `IconButton` cannot do either: Material 3 builds it
  from a `ButtonStyle` and ignores `constraints`.
  `test/features/inventory/item_card_actions_test.dart` pins the size and the
  shape.
- **It disappears while a bulk selection is open.** Every tap ticks a row
  then, and a sheet for one item would lose the forty the seller had just
  picked — the same reason a tap selects instead of navigating in that mode.
- **`onActions` is nullable**, so a list that only navigates simply does not
  pass it.
- `test/features/inventory/item_card_actions_test.dart` holds all of it.

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
answers it with a split, ruled off by a hairline:

- **Above: what the item is.** Photo, title, then two lines of compact display
  badges — state and grade on the first, the marketplaces on the second — all
  in one column beside the photo, sharing one left edge.
- **Below: what it is worth.** A band across the card's full width — how many
  are left and what they cost, each a label with its figure under it, then an
  arrow into the marketplace prices.

The shape is the answer to two failed ones, and both failures are worth
keeping written down:

- **Three figures stacked as lines** made the card tall, and with the label at
  one edge and the amount at the other every label was marooned a card's width
  from the number it names.
- **Three figures side by side inside the top row** had a 64pt photo on one
  side and a 36pt button on the other, so a four-figure amount ellipsized.

Across the foot the labels share one baseline and the figures share the next,
which is what lets the amounts be compared at a glance.

- **The cells are spaced apart, not divided into shares** — owner's rule.
  `MainAxisAlignment.spaceBetween` on cells that measure themselves: quantity
  holds the card's left edge, the arrow holds its right, and the gaps fall
  where the content leaves them. Fixed flex shares spent width on a
  two-character count and then ellipsized a four-figure price, which is the
  failure this replaces.
- **The asking price is not on the row** — owner's rule. What the item is
  asked for is a per-marketplace number, so one figure on the card is a price
  that may be true nowhere; the row points at the screen that lists them all
  instead of printing the item's own.
- **The band ends in an arrow into `AppRoutes.crossList`** — owner's rule, and
  it is what replaced that figure. That screen is where every marketplace's
  price is, so the row answers "what is it going for?" by opening the place
  that can answer it per platform rather than by averaging the question away.
  - **The card does not navigate; it takes `onMarketPrices`**, the way it
    already takes `onTap` and `onActions`. A widget that pushes its own route
    cannot be put on a screen that wants a different destination.
  - **Only an item that can be listed gets one.** The cross-list screen
    refuses a sold or archived item, so an arrow on that row would be an
    affordance leading to a refusal. Those rows keep the arrow's space as an
    empty slot, so Qty and Cost stay in one column down the whole list.
  - **It goes while a bulk selection is open**, for the same reason the
    actions button does: every tap ticks a row then, and a push would lose the
    rows the seller had just picked.
  - **It is the same 44pt round target the actions button is**
    (`_CardIconButton`), so the two glyphs on the card's content edge are one
    control drawn twice rather than two that happen to look alike.
- **The quantity leads** — owner's rule that the row carry what is left. It
  replaces the old `×3` badge: a figure with a permanent cell is one a seller
  can find without reading the chips.
- **`Item.quantityOnHand` is zero once the item is sold or archived**,
  whatever `quantity` says. The field records how many were taken in; a row
  answering "what is left" must not answer with that number after the last one
  went out. That zero is known rather than missing, which is why it is not an
  em dash.

- **The amount is a size louder than its label.** The figures are what the row
  exists to show, and a label at the same weight makes the seller hunt for the
  number among the words introducing it.
- **`SdDividerV3` between the zones**, not a gap alone: it makes the band
  deliberate rather than a block that happens to start further left than
  everything above it.
- **The cost renders `—` when unknown** (hard rule 5), never `0`: an item
  added through Quick Add has none, and a zero would tell the seller it was
  free.
- **Expected profit is not on the row** — owner's rule. `Item.expectedProfit`
  is derived from an asking price nobody has been offered yet and ignores fees
  and shipping, so on a list it took a cell the width of a real figure to say
  something rougher than either number beside it. The detail screen still
  shows it, and `ProfitBreakdown` on a completed order is the real one.

## The row carries the grade, and the date it last changed

Owner's rule.

- **The condition sits with the state badges.** It is what a buyer reads first
  on every marketplace, and on a list it explains a price a seller would
  otherwise have to open the item to justify.
- **`Updated <date>` is the card's last line, and its quietest.** It answers
  "did my edit save?" and "which of these did I touch this morning?" — a
  different question from every figure above it, and one that deserves none of
  their weight. It is absent when nothing has ever updated the record, rather
  than dressing the creation date up as an edit.
- **Both dates are read-only, and the full pair lives in the detail screen** —
  `Added` and `Last updated`, in the provenance block. No form offers either:
  a date the seller can type is not a record of anything. See
  `docs/DATA_MODEL.md` for how `updatedAt` is written.

## The row does not show state age

Owner's rule. The compact `Now` / age tag is absent from `ItemCard`; the row
reports actionable state instead of elapsed metadata. `now` still enters the
card as an injected clock value solely to decide whether the Stale tag applies.

## The row counts its marketplaces and prices none of them

Owner's rule, and it replaces the earlier one that put a figure per platform
on the card. `ItemCard` shows **one count of the distinct marketplaces the item
is live on** — no names and no amounts.

- **A price per platform is not what a list is scanned for.** Where the item
  is takes one glance; what it costs on each takes a comparison, and a
  comparison belongs on the detail screen where the numbers can be laid out.
- **One compact count replaces the wrapped badge list.** The list made a card
  grow with every marketplace and slowed scanning; the detail screen keeps the
  full names for the seller who needs them.
- **The tags are two lines, and the split is by question** — owner's rule.
  Line one is what the item *is*: its status, its Stale marker and its grade.
  Line two is where it *stands on the marketplaces*: the count, or that
  nothing carries it. One `Wrap` let a long grade push the market count onto a
  line of its own at some widths and not others, so the row's shape depended
  on the words in it.
- **Stale rides on line one.** It is a fact about the item's state, not about
  its distribution — the clock says it has not moved, which is not the same
  claim as where it is listed.
- **Line two is absent, not empty, when there is nothing to say.** A sold or
  archived item shows no marketplace tag at all, so the card loses the line
  rather than keeping a gap where one used to be.
- **An item on no marketplace says so, in red** — owner's rule. Nothing at all
  read as "no platforms worth naming" when the truth was stock earning
  nothing, which is the one thing on this row a seller can fix today. Only an
  item that *could* be listed gets it: a sold or archived item is not late, it
  is finished, and it shows no marketplace tag at all.
- **Every chip-like element on the card is `SdBadgeV3` at
  `SdBadgeSizeV3.compact`, never `SdTagV3`** — owner's rule that the card's
  tags be smaller, and it replaces the read-only-tag wrapper the row used to
  carry. The tag is the item form's picker and wears a picker's padding and
  border; the card reports, so it draws the design system's marker for
  reporting at the size a list row can afford. The colour still comes from the
  enum through `SdBadgeV3.color`, so one value is one hue on the card and on
  the form.
- **The marketplace-count tag is neutral grey.** Distribution count is
  metadata, not an info state competing with status, Stale or condition. The
  unlisted tag is the exception and is `danger`, because it is the one that
  asks for an action.
- **The count is deduped by marketplace**, so two listing records on one
  platform still read as one market.
- `test/features/inventory/item_card_marketplaces_test.dart` holds all three:
  the distinct count is on the row, no marketplace name or listing price is,
  and an unlisted item on the shelf shows the red tag.
  `item_card_figures_test.dart` holds the money and the age;
  `item_derived_test.dart` holds the two getters they read.

## Four statuses, and quantity moves between two of them

Owner's rule, and it replaces the six-state lifecycle:

| Status | What it means |
|---|---|
| `draft` | Created, not part of sellable inventory yet |
| `inStock` | On the shelf and for sale — live on a marketplace or not |
| `sold` | Sold out: the count reached zero through sales |
| `archived` | Withdrawn without a sale |

- **`listed` and `reserved` are gone.** An item live on eBay is still stock
  the seller owns, so it is `inStock` with listings beside it; an item held
  for a buyer was a state nothing in the app could act on. Cross-listing no
  longer moves the status — `ItemTransition.markListed` stamps `listedAt` and
  turns a draft into stock, and that timestamp is what staleness, the Stale
  tab and Home's progress read.
- **A document written before the change still reads.** `ItemDto` folds
  `listed` and `reserved` into `inStock`; nothing rewrites them until the item
  is next saved, and no migration runs.
- **`isListable` now means `isOnHand`.** A draft can be put on a marketplace —
  listing it is what makes it stock. What cannot is an item that has left
  inventory.
- **The Inventory tabs follow**: All, Draft, In stock, Sold, Stale. Stale is
  still a query, not a status (`docs/DATA_MODEL.md`).

## Restock adds to the count and brings the row back

Owner's rule. `ItemTransition.restock` takes how many arrived, adds them to
`quantity`, and moves the item to `inStock` in the same write.

- **The box asks how many arrived, not what the new total is** — that is the
  number on the receipt in the seller's hand, and the only one they do not
  have to work out.
- **The sheet does the arithmetic out loud** — owner's rule: what is on the
  shelf now, and what will be there after, updating as the seller types. A box
  that only takes an addend leaves them adding in their head to check they
  typed the right thing. The total is `—` until the box holds a usable count,
  never the current figure (hard rule 5).
- **It is the way a sold-out row comes back.** Having to un-sell an item by
  hand before saying more arrived is the step that made sellers create a
  duplicate item instead — and a duplicate loses the cost history, the
  listings and the sales the original carries.
- **An archived item comes back too**: restocking one is the seller saying
  they have it again.
- **`Make it in stock` is the draft's own row**, shown only on a draft. It
  carries no count: the item already has one, and what the seller is saying is
  that it is ready to sell.
- Both go through `_bulk`, so forty rows are one write (hard rule 16).

## Quantity is required on the item form, and only there

Owner's rule. The full Add/Edit form refuses to save without a count; **Quick
Add still asks for a title and nothing else** (hard rule 2), and creates the
item with one.

- A seller who opened the full form is entering stock, and how many there are
  is the figure the card, the Sold transition and every count in Analytics are
  built from.

## Status and condition are tag groups, and switching is free

Owner's rules, in the order they arrived, and they replaced two picker rows
that each opened a sheet.

- **Tags, not sheets.** Four statuses and seven condition grades are the
  answer to one question each; hiding them behind a row costs two taps to see
  what the choices even are. Laid out, the seller reads the whole vocabulary
  at once. Both groups are built from `SdTagV3` through one `_TagGroupField`,
  extracted on its second use so the two cannot answer the same shape of
  question two ways.
- **Both the colour and the words live on the enum** — owner's rule:
  `ItemStatusDisplay` and `ItemConditionDisplay` are extensions declared in
  `domain/enums/item_status.dart` itself, carrying `label(context)` and
  `color(context)`, so a value is *asked* and there is exactly one answer.
  They pick a named `AppTagHue`, which exists because the semantic tones run
  out at five and three of the four statuses shared `neutral`: a row of radios
  in one grey is a shape test, not a colour one. The general rule is in
  `docs/rules/DESIGN_SYSTEM.md`.
- **Every place that draws one as a tag uses that colour** — the radio on the
  form, the badge on the card, the badge on the detail screen. `SdBadgeV3`
  takes the colour rather than a tone for these two.
  - **The condition palette is ordered best-to-worst**, so the seven grades
    read as a scale rather than seven equal options.
  - **The status hues are chosen, not incidental**: grey for a draft that
    claims nothing, green for stock, blue for a sale, amber for a withdrawal.
- **Switching is free** — owner's rule, and it is the newest of them. The form
  checks nothing and refuses nothing: this is the screen where a seller
  corrects what the app got wrong, and a correction that argues back is the
  thing they came to fix. `ItemTransition.setStatus` is that path.
  - **The verbs are unchanged.** `ItemTransition.check` still gates Mark as
    sold, cross-listing and the bulk paths, which is where a missing price
    actually matters.
  - **The side effects still ride along**, because they keep the record
    consistent rather than legal: setting `sold` empties the count, and coming
    back onto the shelf clears `soldAt`.
  - It writes **no order**: revenue and profit are read from orders (hard rule
    3), so a sale that has to show up in the figures is recorded through Mark
    as sold.

## An item that has left inventory can come back, and the sale goes with it

Owner's rule, after a sold item was given a quantity of 10 and stayed sold.

- **Status never moves through the item form.** `ItemFormController.submit`
  writes back the status it was seeded with, so editing quantity, price or
  photos cannot change what state an item is in. Hard rule 2 puts state
  changes behind verbs, and `ItemTransition` is the one place that decides —
  a form field that quietly restocked a sold item would be a second one.
- **The archive row is decided by `status.isOnHand`, not by `archived`.** On
  the shelf it offers Archive; off it — sold *or* archived — it offers "Put
  back in stock". A sold item previously had no way back at all: the row said
  Archive, and the only route to stock was archiving it and undoing that.
- **`restore` goes through `ItemTransition.apply`**, not a bare `copyWith`.
  Returning an item is a state change like any other, and the transition is
  what knows the sold date has to go with it.
- **Coming back onto the shelf clears `soldAt`**, and it is the only field the
  app ever unsets — hence `Item.copyWith(clearSoldAt: true)`, since a null
  argument there means "leave it alone". An item on hand still carrying a sold
  date is one every CSV export and every days-to-sell figure reads as sold.
  **Archiving a sold item keeps it**: that one really did sell.
- `test/features/inventory/item_transition_test.dart` holds both halves.

## The actions that would be refused are shown, not hidden

A move the item cannot make yet still appears in the sheet, and tapping it
says which field is missing (`ItemBlockPresenter`). Hiding "List" from an item
with no price teaches nothing; "Add an asking price to list this" teaches the
rule and points at the fix.

## The item form seeds through `FormSeed`

The record arrives on a stream, so the form learns it exists inside a `build` —
and writing the form's controller from there throws. See
`docs/rules/SCREENS.md`, which carries the rule and the reason.
