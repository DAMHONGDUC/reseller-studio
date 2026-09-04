# CLAUDE.md — inventory

Rules specific to the item list, the item forms and what a seller can do to an
item. The root `CLAUDE.md` still applies in full; this file only holds what
would be wrong to generalise.

## Two ways in: Quick Add for one thing, the intake session for a trip

Both create items and **both require only a title** (hard rule 2). What
separates them is how many things the seller is holding.

- **Quick Add** (`/inventory/quick-add`) is the single item found on a shelf.
  One field, save, gone.
- **The intake session** (`/inventory/intake`) is the car boot, the estate
  sale, the auction lot — thirty things from one source on one day. It asks
  for the source and the date **once for the trip**, then loops on title and
  cost with the keyboard up.

**The cost box is why it exists.** What a seller paid is the only figure that
lives solely in the moment they are standing in the shop; a week later nobody
remembers whether the jumper was $3 or $5. A missing cost makes every profit
figure downstream `—` (hard rule 5), so this is the flow the whole insight
half of the product is fed by. Asking for a source and a date per item is two
extra taps thirty times over, which is why in practice neither was ever filled
in.

**It adds no required field.** The cost stays optional exactly as it is
everywhere else. What changed is where it sits.

**Items are written as they are typed; the purchase is written at the end.**
That order is the whole durability story and it is deliberate:

- an abandoned session still leaves every item entered, with its cost, source
  and date — nothing typed is lost;
- and it leaves **no purchase**, because there was no completed trip. A
  purchase created up front would be a record of a visit that did not happen,
  and a `purchaseId` stamped on items before it existed would dangle.

**`Purchase.totalCost` is the receipt, not the sum of the lines.** The screen
offers a separate optional box for it, because that field is the one place in
the app allowed to disagree with its items — a $40 box lot apportioned across
eleven things is exactly the case it exists for. Never fill it in from the
running total.

`test/features/inventory/intake_session_test.dart` pins all four.

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
- **Edit is the first row, and it is the way into the record.** Owner's rule.
  Every other row is one verb; changing a title, a count or a price is the
  detail screen's job, and from the list the only step to it was closing the
  sheet and tapping the card underneath it.
- **It is the one row the detail screen does not draw** — `isOnDetail` says
  so. An Edit that pushes the screen it was opened from is a verb that does
  nothing, and that is not an action going missing from the row: the screen it
  leads to is already the one under the sheet.
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

## The actions sheet names no marketplace, and never did more than one thing

Owner's rule, in two moves. The sheet first collapsed **two** verbs into one —
a `List` sheet for exactly one marketplace beside a `Cross-list` row for
several — and then lost that row as well: marketplaces are answered on Item
detail, under Price.

- **The two verbs read as the same one.** Nothing on either row said which to
  use, and the narrower one was gated on `ItemTransition.check(item, listed)`,
  which refuses an item that is already listed — the exact item cross-listing
  exists for. `ListItemSheet` and `ItemActionsController.listItem` are deleted
  rather than left as a second way to write a listing.
- **The surviving row left too.** A sheet row and a section header were two
  doors onto `CrossListScreen`, and the one a seller met first was the one
  furthest from the prices they came to read. `itemActionList` is deleted with
  it.
- **The gate moved with the row, not away.** Item detail's Listings Edit calls
  `crossListCheck`, which refuses only a sold or archived item and an empty
  shelf — and asks for no price, because the screen it opens is where the
  price is entered (hard rule 2).
- **What is left in the sheet is what the sheet is for**: state transitions
  and writes that carry side effects. Marketplaces are neither.
- `test/features/listings/cross_list_test.dart` holds both halves: the sheet
  names no marketplace row, and the gate still refuses a sold item.

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
- **The section sits directly under Price** — owner's rule. What the item cost
  and what each platform asks are one question with two halves, and the seller
  reading the money on this screen now reads it in one run instead of
  scrolling past where the item came from.
- **An item on no marketplace gets the same Edit**, above the line saying it
  is listed nowhere — owner's rule, and it replaced a header with nothing in
  it. The actions sheet no longer names a marketplace row, so this is the only
  way onto a first platform; a section that reported a state and offered no
  way to leave it was a dead end.
- **`ItemDetailSection` has no `listings` value, and the controller has no
  listing write.** The link is the whole feature; a save path left standing
  beside it is the second writer this rule exists to remove.
- **A reprice does not re-stamp `listedAt`**, which would reset the staleness
  clock: moving a price is not putting the item on sale again.
- `test/features/inventory/item_detail_sections_test.dart` pins where Edit
  goes and that the section opens no field of its own.

## The item carries what it is expected to fetch, and nothing a buyer is asked

Owner's rule, in two moves, and the second one narrows the first rather than
undoing it.

**`Item.expectedPrice` is the one price the item owns.** Not required (hard
rule 2), never a listing's price, and never shown as one: it is what the
seller thought the thing was worth when they bought it.

- **It is the number that is true when nothing else is.** An item on no
  marketplace has no ask at all, and an item on four has four; the expected
  price is one figure, present either way, which is why the inventory row, the
  record-sale row and the mark-sold seed can all read it.
- **It answers no question `Listing.price` answers.** A buyer is never shown
  it, no fee is computed from it, and nothing reconciles it against a
  platform. A screen that needs to know what someone is actually being asked
  reads the listings, exactly as before.
- **It seeds Mark sold** — replacing the top live listing price, which was the
  highest of several numbers and belonged to whichever platform happened to
  carry it.
- **Stored as `expectedPriceMinor`**, and it joins `_currencyOf`: an item
  whose only amount is an expected price still records the currency it was
  entered in.
- Boxes on both forms and on the detail screen's Pricing block; an emptied box
  clears it (`clearExpectedPrice`), because a removed figure is not the same
  as one left alone.
- `test/features/inventory/item_detail_sections_test.dart` and
  `item_card_figures_test.dart` pin the field and the cell.

**And it still deletes `Item.askingPrice`** — the field, not just its place on
a screen. It departs from the plan's item field list on purpose: the
plan wrote the field before cross-listing existed, and once the same jacket is
live at three numbers, "the price" is a question only a marketplace can
answer.

- **A price that may be true nowhere is worse than no price.** One figure on
  the item was the number a seller typed once and then never reconciled with
  what eBay, Depop and Poshmark were actually showing. Every screen that read
  it was reporting a guess with the confidence of a fact.
- **`Listing.price` is the only price a buyer is shown.** `purchasePrice` is
  what the seller paid and stays; `expectedPrice` is what they hope to get;
  `minimumPrice` is the floor for offers. None of the three is what any
  platform is currently asking, and that is the only number `askingPrice`
  claimed to be.
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
- **Where a screen needs a price to seed a field, it reads the expected
  price.** Mark as sold seeds from it; the cross-list screen still seeds a
  newly ticked marketplace from what the item is already live at, because
  there the question really is what a buyer is being shown.
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
- **The row carries the cost and the expected price, and no marketplace's
  ask** — owner's rule, and the second half of it arrived with
  `Item.expectedPrice` (see below). What the item is *asked* for is a
  per-marketplace number, so one such figure on the card would be a price that
  may be true nowhere; what the seller *expects* for it is a single number the
  item carries itself. The arrow still points at the screen that lists what
  each platform asks.
  - **Three figure cells, and they split the row.** Qty, Cost and Expected
    take equal shares and the chevron takes only its glyph — the ellipsizing
    the old three-money layout suffered came from cells that measured
    themselves, not from the count.
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
- **The hairline runs edge to edge, and carries no gap of its own** — owner's
  rule. A rule that stops at the content inset reads as a line drawn under one
  zone; one that crosses the card is the seam between two. So the card holds
  `EdgeInsets.zero` and each zone carries `SdContentPaddingV3.card`, the way
  `AppListCard` already does it — the air around the hairline is the two
  zones' padding (`ItemCardMetricConstant.bandGap`), never the divider's.
- **A cell that opens something lays out at its own height** — owner's rule.
  Reserving the 44pt target in the layout made the band taller than the two
  lines it holds and left dead space under the arrow while the cells beside it
  stopped at their text; the ink overhangs the card's inset instead, which is
  what every other end glyph in the app already does
  (`docs/rules/DESIGN_SYSTEM.md`).
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

## Four statuses, and the seller picks between them

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

## There is no Restock verb; the count is edited on the detail screen

Owner's rule, and it replaces one. Restock was a row in the actions sheet that
asked how many arrived, added that to `quantity` and moved the item to
`inStock`. The row, `RestockSheet`, `ItemActionsController.restock` and
`ItemTransition.restock` are all gone.

- **A count is a fact about the record, not a verb.** The detail screen is
  where a seller corrects what the app got wrong, so one place changes the
  number — not a sheet that adds to it and a field that replaces it,
  disagreeing about what the seller just typed.
- **It is its own section, not a box inside Overview** — owner's rule.
  Overview answers what the item *is*: a title, a state, a grade. How many
  there are is a different question and the one most often reopened, and its
  own Edit is what stops changing it from putting a title box on screen too.
- **The box takes the new total, not an addend**, so the arithmetic the sheet
  spelled out is not arithmetic any more: the figure the record holds is on
  screen while the seller types over it.
- **A stepper flanks the box** — owner's rule. One more or one fewer is what
  actually happens to a count, and doing it by selecting a number and typing
  another is three interactions for an increment. The box stays for the times
  the answer is twelve.
  - **It stops at zero**, so `-1` is disabled on an empty shelf rather than
    writing a negative count nothing in the app can mean.
  - **An unreadable box counts as zero for the stepper**, so `+1` on an empty
    field gives one — the same answer typing nothing already saves.
  - `ItemQuantityField` owns both halves, so a second screen taking a count
    cannot offer a box without the buttons.
- **A count moves nothing else.** `saveQuantity` writes the count and stops
  there: a sold row given stock stays sold and says so with an alert tag, and
  the seller picks the status themselves in the section under it. The rule and
  its reasons are the section below.
- **`Make it in stock` is the draft's own row**, shown only on a draft. It
  carries no count: the item already has one, and what the seller is saying is
  that it is ready to sell.
- **The section's card carries the figure, and a badge never did.** It read
  `×5` beside the status tags and only when it was above one, so on most items
  the number the seller came to change was not on the screen at all.
- `test/features/inventory/item_quantity_test.dart` holds both halves: the
  actions sheet offering no Restock, and the detail screen putting a sold row
  back on the shelf.

## Quantity and status are independent, and a contradiction is a tag

Owner's rule, and it cuts every link between the two. A seller who types one
of them is saying that one thing, not two.

- **Editing one never writes the other.** Picking `sold` no longer empties the
  count, and putting stock behind a sold row no longer brings it back —
  `ItemTransition.restocked` is deleted, and the `quantity` line is out of
  `setStatus`. What stays there is `soldAt`, which is a timestamp of the move
  rather than a second opinion about the shelf.
- **Both are edited freely, and nothing is refused.** Status is its own
  section on the detail screen — four tags, the same freedom the form already
  had — beside the count's own section.
- **A pair that cannot both be true is drawn, never refused.**
  `ItemConsistency.warnings` names the contradictions and `ItemWarning`
  carries the words and the hue. There is exactly one today: **on hand with
  nothing on the shelf** — a row whose tag says In stock or Draft while its
  count says zero.
- **"Sold with a count left" is deliberately not one of them.** It looks like
  the obvious second warning and it is wrong: `quantity` is what was taken in
  and `Item.quantityOnHand` already reads zero for anything off the shelf, so
  a sold row keeping its count is the normal state of every sold item — the
  seeded ones included. A warning that fires on every sold row teaches sellers
  to ignore the warning.
- **The message names both halves and asks for the fix** — owner's rule.
  "Warning: none on the shelf but status is In stock — please update", not
  "Check the count": a seller reading it has to know which two facts disagree
  without opening anything, and what to do about it. That is why
  `ItemWarningDisplay.message` takes the item — the status word and the count
  are in the sentence.
- **It is a full-width line, never a compact badge.** A sentence does not fit
  the badge row, and shortening it to fit is how it stopped saying anything.
- **It shows on the inventory row as well as on the detail screen** — owner's
  rule, and it is why `ItemWarningLines` is one widget both draw. A row that
  contradicts itself is one a seller has to find while scanning the list; a
  warning only the detail screen carries is one they see after they have
  already gone looking for something else. On the card it sits under the money
  band, which is where the count it is arguing with already is.
- **An archived item with stock is not one of them.** Withdrawing something is
  not giving it away, and the count is what the seller still owns.
- **The verbs still move both, because a sale is an event rather than an
  edit.** `ItemTransition.sell` takes one off the shelf and marks the row sold
  when it empties — a fact the app recorded, not a field somebody typed. The
  freedom in this rule is the seller's over their own record; it is not a
  licence for a flow to write two fields when it was asked for one.
- `test/features/inventory/item_warning_test.dart` holds the pairs.

## The create form opens on the last filing

A seller booking in twenty things from one haul picked the same category and
the same bin twenty times. The intake session had already answered this shape
of problem by asking for the source **once for the trip**; the full form is
the other half of the same afternoon and got the same treatment.

- **Prefilled, never required** (hard rule 2). Both pickers are on screen with
  the value in them, and one tap changes either. Nothing is refused and no new
  field is asked for.
- **Only on create, and only from a create.** `startCreate` seeds the two
  pickers; `submit` writes them back **only when the form was not editing** —
  correcting one old item's bin is not a decision about the next twenty.
- **Never on Quick Add.** That screen shows neither field, so a remembered bin
  there would be filing stock somewhere the seller was never shown. Quick Add
  still asks for a title and nothing else.
- **Device-local, in `PrefsKeyConstant`** — `lastItemCategoryId` and
  `lastItemLocationId`. It is a fact about the afternoon this phone is having,
  like the theme and the intro flag, not about the business.
- **A remembered id that no longer names anything is dropped.** A deleted bin
  left in preferences would seed a picker with a value its own list cannot
  show, and the seller would be looking at a blank field they did not empty —
  so the id is checked against the live categories and locations first.
- **Nothing picked clears the key** rather than keeping the last answer: a
  seller who deliberately filed one item nowhere is saying so.
- `test/features/inventory/item_form_remembers_filing_test.dart` holds all
  five.

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
  - **The one side effect left is `soldAt`**: it is stamped on the way to
    `sold` and cleared on the way back, because a row on hand carrying a sold
    date is one every export reads as sold. The count is not touched — see the
    section on quantity and status being independent.
  - It writes **no order**: revenue and profit are read from orders (hard rule
    3), so a sale that has to show up in the figures is recorded through Mark
    as sold.

## An item that has left inventory can come back, and the sale goes with it

Owner's rule, after a sold item was given a quantity of 10 and stayed sold.

- **One thing moves a status without a verb: the tags the seller picks.**
  Every field is inert — a count, a price, a photo or a note cannot change
  what state an item is in. Hard rule 2 puts state changes behind verbs, and
  `ItemTransition` stays the one place that decides what a move carries.
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
