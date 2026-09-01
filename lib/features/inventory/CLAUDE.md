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
way to set it. The cross-list screen collects **one price per marketplace**,
and `crossList` takes a `Map<Marketplace, Money>`.

- **The price field sits under the marketplace it belongs to** — owner's rule.
  Choosing a platform and pricing it is one decision, and it replaced a
  separate Review section whose rows opened a sheet to edit one number: the
  seller ticked something and had to scroll to find out what that had done.
  The fee and what is left ride under the field as its helper.
- **There is no asking price box above the list** — owner's rule. Every price
  on the screen belongs to the marketplace it sits under, so a box that priced
  nothing was one number too many: a seller filled it in and still had to read
  down the rows to find out what it had done.
- **Ticking seeds that row from what the item is already live at**, so the
  common case — one number everywhere — is still no typing at all. The seed is
  taken once, from the top live price (`ListingPricing.topPrice`), and never
  reaches back into a row already on screen: a number moving in a field nobody
  is watching is worse than retyping one.
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
- **The seed seeds the rows and is written nowhere else.** It used to also
  become the item's own `askingPrice`; the item has no price of its own any
  more (see below), so `crossList` writes listings and nothing but.
- `test/features/listings/cross_list_test.dart` holds them.

## One screen prices a marketplace, and the detail screen links to it

Owner's rule, and it **reverses the inline reprice** the detail screen used to
do. Marketplaces management prices every platform an item is on and is the only
screen that can add another; a second set of boxes on the detail screen was the
same number written two ways, and the half a seller reached first could not do
the thing they usually came for.

- **Item detail's Listings section reports and links.** It lists what each
  marketplace asks, and its Edit pushes `AppRoutes.crossList` — the section
  keeps its header and its Edit, and hands the whole question over
  (`docs/rules/SCREENS.md`).
- **An item on no marketplace gets no Edit**, only the line saying so: there is
  no price to move, and the way onto a first platform is the actions sheet,
  which names it.
- **`ItemDetailSection` has no `listings` value, and the controller has no
  listing write.** The link is the whole feature; a save path left standing
  beside it is the second writer this rule exists to remove.
- **A reprice does not re-stamp `listedAt`**, which would reset the staleness
  clock: moving a price is not putting the item on sale again.
- `test/features/inventory/item_detail_sections_test.dart` pins where Edit
  goes and that the section opens no field of its own.

## An item has no price of its own; every price belongs to a marketplace

Owner's rule, and it **deletes `Item.askingPrice`** — the field, not just its
place on a screen. It departs from the plan's item field list on purpose: the
plan wrote the field before cross-listing existed, and once the same jacket is
live at three numbers, "the price" is a question only a marketplace can
answer.

- **A price that may be true nowhere is worse than no price.** One figure on
  the item was the number a seller typed once and then never reconciled with
  what eBay, Depop and Poshmark were actually showing. Every screen that read
  it was reporting a guess with the confidence of a fact.
- **`Listing.price` is the only price of a thing for sale.** `purchasePrice`
  is what the seller paid and stays; `minimumPrice` is the floor for offers
  and stays; there is nothing in between.
- **What died with the field, and none of it is coming back behind another
  name:**
  - `Item.expectedProfit` — a derivation with no numerator left.
  - `ItemFilterCriteria`'s asking-price presence and range filters. An item
    does not carry its listings, so the filter cannot be repointed at them
    without loading every listing to answer one predicate.
  - `ItemTransition`'s `missingPrice` block. Nothing about an item is missing
    a price any more; the cross-list screen is where a price is entered and it
    refuses to publish a row without one.
  - The Offers screen's "% off the asking price". An offer is made on a
    marketplace, so the number it should be compared against is that
    marketplace's listing — read at the screen, where the listings are.
  - The asking column in the Reports export.
- **Where a screen still needs a price to seed a field, it reads the
  listings.** Mark as sold and Record sale seed from the item's live listings
  rather than from a field on the item, because that is where the number a
  buyer was shown actually lives.
- **`ItemDto` stops reading and writing `askingPriceMinor`.** A document
  written before this keeps the key; nothing rewrites it and no migration
  runs, exactly as with the retired statuses.

## The inventory row is two zones, and every figure has a place

Owner's rule — the row must be **good-looking, sensible and complete**, in
that order of argument and none of them at the cost of the others. `ItemCard`
answers it with a split, ruled off by a hairline:

- **Above: what the item is.** Photo, title, then one line of compact display
  badges — state, grade and the marketplaces together, wrapping when the words
  are long — all in one column beside the photo, sharing one left edge.
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

- **Qty and Cost take equal shares; the arrow measures itself** — owner's
  rule, and it **reverses "spaced apart, not divided into shares"**. Cells
  that all measured themselves under `spaceBetween` put the gaps where the
  content left them, which meant the middle cell sat at a different place on
  every card: scrolling the list, `Cost` and its figure shuffled sideways row
  by row. That is the one thing a column of money must not do, and it is the
  rule `AppListRow.trailingText` already states one level down.
  - **The old rule's reason expired.** Shares were rejected because they
    "spent width on a two-character count and then ellipsized a four-figure
    price" — true when three cells held money. The third now holds a 20pt
    chevron, so the two that carry figures split everything else and neither
    is close to ellipsizing.
  - **Quantity still holds the card's left edge and the arrow still holds its
    right**, which is the half of the old rule that was about the band's ends
    rather than its middle. `test/features/inventory/item_card_figures_test.dart`
    pins both, and pins that Cost does not move between two cards whose
    amounts differ.
- **No price is on the row but the cost** — owner's rule. What the item is
  asked for is a per-marketplace number, so one figure on the card is a price
  that may be true nowhere; the row points at the screen that lists them all.
  It is the same argument the item's own asking price lost (see below).
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
    (`AppRowIconButton`, in `core/widgets/` — the card no longer keeps a
    private one), so the two glyphs on the card's content edge are one control
    drawn twice rather than two that happen to look alike.
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
- **Expected profit is nowhere at all.** It was derived from the item's asking
  price, and that price is gone — a figure built on a number nobody has been
  offered, ignoring fees and shipping, computed from a field that no longer
  exists. `ProfitBreakdown` on a completed order is the real one and always
  was.

## The row carries the grade, and the date it last changed

Owner's rule.

- **The condition sits with the state badges.** It is what a buyer reads first
  on every marketplace, and on a list it explains a price a seller would
  otherwise have to open the item to justify.
- **`Updated <date>` sits with the title and the tags, never in the money
  band** — owner's rule, and it **replaces "the card's last line"**. It
  answers "did my edit save?" and "which of these did I touch this morning?",
  which is a fact about the *record* rather than about what the item is worth;
  hung under Qty and Cost with no separation it read as a fourth row of that
  grid, so a date sat in a block of figures.
  - It closes the identity column, under the tag lines, in the same left edge
    as the title — the quietest thing in the zone that says what this row is.
  - **The money band is Qty, Cost and the arrow, and nothing else.** Three
    cells sharing one baseline is what that grid was designed as, and anything
    appended to it is a fourth cell the layout never accounted for.
  - It is absent when nothing has ever updated the record, rather than
    dressing the creation date up as an edit.
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
- **The tags are one wrapping line, and the marketplace count is the last of
  them** — owner's rule, and it **reverses "the tags are two lines, and the
  split is by question"**. Status, Stale, grade and the marketplace count sit
  in one `Wrap`, in that reading order.
  - **The old rule's cost was measured and the old rule lost.** Splitting by
    question bought a guaranteed shape and charged a whole badge line for it —
    a fixed cost on every card in the list, paid so that a *sometimes*
    two-line first line could not happen. The row's job now is to get smaller,
    and a line reserved for one badge is the largest thing on the card that
    holds no fact of its own.
  - **What the old rule bought is genuinely lost**: a long grade can push the
    count onto a run of its own at some widths and not others, so the card's
    height again depends on the words in it. That is accepted, not overlooked
    — the wrap costs a run only when the words are long, where the split cost
    a line always.
  - **The reading order carries the split the layout no longer does.** What
    the item *is* comes first and where it *stands* comes last, so the eye
    still meets them in that order whether or not they share a run.
- **The run gap is the tightest on the card** (`tagRunGap`). A wrapped run is
  still the same line of tags, so it must not open a gap that reads as the
  separation the two lines used to be.
- **The marketplace tag is absent, not empty, when there is nothing to say.**
  A sold or archived item shows no marketplace tag at all, so the wrap simply
  holds one badge fewer.
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
  It also holds that the four badges share one `Wrap` rather than two.
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
says which field is missing (`ItemBlockPresenter`). Hiding "Mark as sold" from
an item with nothing on the shelf teaches nothing; "There is none left to
sell" teaches the rule and points at the fix.

## The item form seeds through `FormSeed`

The record arrives on a stream, so the form learns it exists inside a `build` —
and writing the form's controller from there throws. See
`docs/rules/SCREENS.md`, which carries the rule and the reason.

## The row carries enough; what it must do is stay short without crowding

Owner's rule. The information on the inventory card is settled — every figure
above has a rule of its own and none of them leaves. What was wrong was the
height: a card that answers four questions in the space of a phone screen and
a half means a seller scrolls to compare two items that should have been
visible together.

- **Nothing is removed to make room.** Compaction is spacing, glyph and
  thumbnail size — never a fact. A denser card that dropped the cost would be
  a different card, not a smaller one.
- **`ItemCardMetricConstant` owns every gap and size the card is tuned by**,
  so a pass changes numbers in one class instead of hunting `SizedBox`es
  through six part files.
- **The compaction pass went one step too far, and the gaps came back** —
  owner's rule. Title to tags, badge to badge and the column's own steps were
  tight enough that the row read as one block of text; they are the three that
  reopened. **Height is bought from the gaps that carry nothing, never from
  the ones that separate two different things.**
- **The two zones and the money band stay exactly as they are.** Every rule
  above about what sits where survives both passes; only the air between them
  moves.

## The item form creates; the detail screen edits

Owner's rule, and it retires `AppRoutes.editItem`. `ItemFormScreen` is now
reached only to add an item, and changing an existing one happens in the
detail screen's own sections — see the in-place editing rule in
`docs/rules/SCREENS.md`, which is where the shape of that lives.

- **Overview, Pricing, Provenance, Description and Notes each open on their
  own.** Description and Notes are drawn even when empty now, because a
  section that is hidden until it has content is one a seller cannot use to
  add content.
- **Status is not one of them.** Listing, selling and archiving move quantity
  between the four statuses and write an order or a listing with it — the
  actions sheet owns every one of those, and a status field writing the value
  by itself would skip the write that makes it true.
