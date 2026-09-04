# Orders — feature rules

Read this before changing anything under `lib/features/orders/`. The root
`CLAUDE.md` is still the engineering authority; this file only holds what is
true of orders alone.

## There are exactly two ways to create an order

Owner's rule, and the list is closed.

1. **From an item** — Actions → Mark as sold, on any screen that can open an
   item: Inventory, item detail, Search, Listings, a purchase, an order line.
2. **From the Orders tab** — the create button on Orders opens
   `RecordSaleScreen`, which picks the item first and then opens the same
   sheet.

The two are one flow entered from either end. A seller thinks *"I just sold
that thing"* as often as they think *"open the shelf, that one is gone"*, and
before the second way existed the Orders tab was a screen that could only be
filled from somewhere else.

**Neither is a second implementation.** Both open `MarkSoldSheet` and both end
in `RecordSaleController.record`, which writes the order and moves the item
together. A third caller writing its own order is the bug this rule exists to
stop — an item flipped to sold with no order behind it disappears from every
figure the product is judged on (hard rule 3).

**Accepting an offer is not a third way.** `OfferActionsController.accept`
calls the same controller, because the plan's flow is
`Offer → Review → Accept → Order`.

**Recording a sale lives in `orders/`, not in `inventory/`.** It creates an
order; the item move is a consequence. It sat on `ItemActionsController` while
Inventory was the only door, and Offers already had to import Inventory's
*presentation* layer to reach it — which the dependency rule forbids. One
controller in the feature that owns the record, reached through
`orders/providers.dart`, is what makes every caller legal.

**`MarkSoldSheet` is in `core/widgets/`** for the same reason: two features
open it, and that is where a widget goes the moment the second one does.

## The sale flow shows what decides the pick, not a price it will re-ask for

Owner's rule, in two halves, both about `RecordSaleScreen` and the sheet it
opens.

- **A row carries where the item is listed and what it is expected to fetch —
  never a listing price.** The row used to print the *top* of the item's live
  prices: one of several numbers, belonging to whichever platform happened to
  carry it, and the very figure the sheet was about to ask the seller to
  confirm. What actually decides which row to tap is whether the thing is out
  there and what they wanted for it — so the subtitle counts the marketplaces
  (`Not listed` when there are none) and the trailing figure is
  `Item.expectedPrice` (`lib/features/inventory/CLAUDE.md`).
- **The sheet states the fee it would estimate, and where to change it** —
  owner's rule. The box was optional with a rate quoted under it, so a seller
  who left it empty had no idea what number the app was about to use, or that
  the rate behind it was theirs to correct.
  - **The figure, not just the rate.** `salePrice × rate` in money, recomputed
    as the price is typed — a percentage is a fact about the platform, and
    what the seller is deciding whether to accept is an amount.
  - **It says where the rate lives**: More → Marketplaces. A number the app
    presents as its own is one nobody thinks to go and fix.
  - **It sits under Sold on, not under the fee box** — owner's rule. The
    estimate is a fact about the platform the seller just picked, so it
    belongs to that answer; under the fee box it read as a note about a field
    they had deliberately left empty.
  - **It disappears the moment a fee is typed.** Then there is nothing to
    estimate: the box holds the fact, and echoing it back under itself would
    read as a second figure.
  - The rate is the marketplace record's own (`Marketplace.feeRate`), which is
    what that screen edits.

- **The marketplace picker offers only the platforms that item is on.** A list
  of every marketplace the business sells on makes the seller find the one
  this jacket was live at, and a mis-pick writes an order against a platform
  that never carried it — which then lands in that platform's fees, payouts
  and analytics.
  - **An item on no marketplace gets the full list.** Cash in hand is a sale,
    `RecordSaleScreen` offers unlisted stock on purpose, and an empty picker
    is a flow with no way out.
  - The fallback lives in `marketplacesForItemProvider`, not at the call site,
    so the sheet and anything that opens it next cannot disagree about what an
    unlisted item may be sold on.
  - The join is `MarketplaceMatching`: a listing names a `Marketplace` *enum*
    and an order names a marketplace *record*, and nothing stores a key
    between them.
- **Picking a platform fills the sale price with what that platform is
  asking** — owner's rule, and it overwrites a figure the seller had already
  typed. That is the point: the box is what *this* marketplace is asking, and
  a number left behind from the platform before it would be the wrong one
  shown as confirmed. An item live at 185 on eBay and 175 on Depop has two
  right answers, and the picker is what chooses between them.
  - **A platform the item is not on falls back to `Item.expectedPrice`** —
    the one number that is true either way. The sheet opens on the same rule,
    seeded from the marketplace it opens on.
  - The price map is `ListingPricing.byMarketplace` and the lookup is
    `MarketplaceMatching.valueFor`, so the enum-to-record key rule is written
    once and the sheet does not know it.
- `test/features/orders/record_sale_test.dart` pins the row, both halves of
  the picker, and the price following it.

## Nothing is hidden from the sale picker; what cannot be sold is disabled

Owner's rule, and it is hard rule 2's shape one level up — the same one the
item actions sheet already follows: **the rows that would be refused are
shown, not hidden.**

- **The picker draws the inventory card, not a list row** — owner's rule. A
  seller picking a jacket recognises it by its photo, its tags and what it
  cost, which is the whole reason Inventory's list is cards and not rows; a
  chooser that strips all of that asks them to identify stock by its title
  alone. The card moved to `core/widgets/` to make this legal rather than
  being copied (`lib/features/inventory/CLAUDE.md`).
  - **It arrives with two slots empty.** No actions button and no marketplace
    arrow: this screen's tap is the sale, and a second verb on the row would
    take the seller out of the flow they came for.
  - **A blocked row carries its reason where the card carries its warnings** —
    a tag beside the update date, the same place and the same marker a
    contradiction uses, so a seller learns one shape for "this row is trying
    to tell you something". The tag is short on purpose: the reason in full is
    what the tap opens.
  - **It is not drawn twice.** An item on the shelf with a count of zero is
    both a contradiction and a reason it cannot be sold, and the two sentences
    say the same thing; the card keeps its own warning and drops the picker's
    (`lib/features/inventory/CLAUDE.md`).
- **The picker lists every item the business has**, not only what is on the
  shelf. A seller looking for a jacket that is already marked sold used to
  find an empty search and no explanation — the row was filtered out, so the
  screen said the item does not exist rather than that it cannot be sold.
- **A row that cannot be sold still takes a tap; the tap explains.** Owner's
  rule, and it replaced a greyed-out card. A dead row tells a seller they did
  something wrong and nothing else — worse than the filtered-out row it
  replaced, because now they can see the thing and still cannot use it. So the
  card is drawn at full strength, carries the reason on its warning line, and
  a tap (or a long-press, which would otherwise start a bundle it cannot join)
  opens `CannotSellSheet`.
  - **The sheet names the reason and points at the fix.** The sentences are
    `ItemBlockPresenter.messages` — the same ones the actions sheet shows,
    because it is the same `ItemTransition.check(item, sold)` deciding — and
    the primary action opens the item, where the status and the count are both
    edited.
  - **A sheet rather than a snackbar**, unlike the actions sheet's refusal: a
    snackbar over a list the seller is scanning is gone before they have
    finished reading it, and this one has somewhere to send them.
- **`ItemBlockPresenter` is imported across the feature boundary on purpose.**
  It is a root-level presenter, the tier `item_label.dart` sits at, and the
  alternative is Orders writing its own sentence for Inventory's block enum —
  two answers to "why can this not be sold", which is exactly what the
  presenter exists to stop.
- **The bundle is still built from sellable items only.** A disabled row
  cannot be ticked, and `recordSaleSelectionItemsProvider` still reads
  `sellableItemsProvider`, so an item that goes off the shelf mid-selection
  drops out of the run rather than being sold twice.
- **The empty state now means an empty business.** With nothing filtered out,
  the only way the list is empty is that there are no items at all — which is
  what "Nothing to sell" already said, and the way on is still Inventory.
- **Source order is kept**, blocked rows included: re-sorting the refused ones
  to the bottom would list items in an order Inventory does not.

## An order always names an item, and may name several

`OrderLine.itemId` is non-null, so there is still no walk-in sale — nothing
sells that inventory has never heard of. `RecordSaleScreen` therefore lists
what is on hand and nothing else, and a workspace with no items sends the
seller to Inventory rather than offering a form that cannot be completed.

**Multi-line orders are now built; lines that belong to no item are still
not.** The owner approved the first half only, and the two halves are
independent: a bundle is several of the seller's own items, while a line with
no item is a sale the app cannot cost, cannot move stock for and cannot
attribute to a source. Raise that one before building it.

### A bundle is one payment, split by judgement

- **One order, one line per item.** Poshmark bundles and Depop's "2 for £15"
  are everyday, and writing them as several orders with invented prices
  destroys the per-item ROI that Sourcing exists to measure.
- **`Order.salePrice` is what the buyer paid**; `BundleAllocation` decides each
  line's share. By `expectedPrice` when every item has one, evenly when any
  does not — weighting only the priced ones would load the bundle onto them
  and report the rest as nearly free.
- **The parts always sum to the total, exactly.** Money is integer minor units,
  so a proportional split leaves a remainder; it is handed to the largest
  parts rather than dropped, because an order whose lines do not add up to the
  payment is a reconciliation nobody can close.
- **The split is shown before the sale, not discovered after it.** The sheet
  lists each item's share as the total is typed, and says which of the two
  rules produced it.
- **The picker offers the union of the items' platforms**, not the
  intersection. A bundle is things the buyer happened to take together and
  they are rarely all live on the same platform, so an intersection would
  usually be empty — the empty picker `marketplacesForItemProvider` exists to
  prevent. None listed anywhere still falls back to the full list.
- **A bundle is built on `RecordSaleScreen` and nowhere else.** Long-press
  starts a selection, the same gesture Inventory uses; an item's own action
  sheet has already chosen one item, so it passes a list of one.
- **`recordSale` takes a list and commits once.** Every item is checked before
  any is written, so a bundle whose third item has already sold leaves the
  first two alone.
- `test/features/orders/bundle_allocation_test.dart` and
  `bundle_sale_test.dart` pin the split, the totals and the selection.

## The create button obeys the app-wide create rules

- `AppAddFabScaffold` with `floatingNav: true`, because Orders is a tab screen.
- Quick Action on Home lists **every** create action, so the record-sale route
  is in `QuickActionConstant` — `test/features/home/quick_action_test.dart`
  fails the day a screen grows a create button that Home does not offer.
- The empty state's action is the same one the button is. Orders used to point
  the seller at Inventory because it had no create action of its own; that
  sentence in `docs/rules/SCREENS.md` now applies to Listings alone.

## The next move is pinned; every other verb is in the sheet

Owner's rule, and it replaced a column of full-width buttons at the foot of
the detail screen.

- **One pinned button, and it is the move the status implies**: `toShip` ships,
  `shipped` gets marked delivered, a requested return gets taken back in.
  `_NextMove` sits outside the `ListView` (`AppPinnedAction` in the scaffold's
  bottom slot), so it holds the bottom edge whatever the list is scrolled to.
  A seller draining a To Ship queue used to scroll two screens — past items,
  profit, shipping and the timeline — to reach the one button they came for.
- **Nothing is pinned when the order is finished.** Delivered, refunded and
  cancelled have no next step, and a bar holding a bookkeeping verb would make
  the rare thing look like the expected one.
- **Everything else lives in `OrderActionsSheet`**, opened from a small
  Actions button in the app bar — the same grammar `ItemActionsSheet` gives
  Inventory. Four equally loud full-width buttons said four things mattered
  equally, when Record fees and payout is a monthly job and Ship it is a daily
  one.
- **The sheet lists the pinned move as well.** The button is the fast path;
  the sheet is the complete list, so a verb added there cannot go missing from
  what a seller learned to open.
- **The label is `commonActions`**, one key for both features: it is one word
  doing one job, and two keys is how the two sheets end up called different
  things.
- `test/features/orders/order_actions_placement_test.dart` pins all of it.

## The order row's tags are the compact display badge

Owner's rule, given for Inventory and applied here in the same turn: status,
marketplace and Late are read-only metadata sitting beside a title and a
price, so they are `SdBadgeV3` at `SdBadgeSizeV3.compact` — the same
presentation `ItemCard` uses. Two cards a seller scans one after the other
must not tag the same kind of fact at two sizes.
`docs/rules/DESIGN_SYSTEM.md` carries the rule itself.

## Order transitions are domain rules, never button rules

- **Only `toShip` may become `shipped`.** An unpaid order cannot leave, and a
  return request belongs to the returns workflow rather than Shipping Queue.
- **Every transition validates the current state below the UI.** A stale
  screen or a second device may call a controller after the record moved; a
  hidden button is not a data boundary.
- **Shipping Queue contains `toShip` alone.** Returns remain actionable, but
  their action is receiving the item rather than shipping it again.

## Sale and return inventory writes are atomic

Creating an order and decrementing the item are one commit. Closing a return
and restoring its quantities are one commit. A network failure between two
writes must never leave an order without the inventory move it claims.

## Orders point at business marketplaces

An order stores the seller-owned marketplace id plus a name snapshot. New
sales choose from active marketplace records; deleting or renaming a market
does not rewrite the historical name already printed on an order.

## Return and refund labels say which way the thing moved

Owner's rule. The two words name opposite movements — the **item** comes back
to the seller, the **money** goes out to the buyer — and a label that names
only the noun leaves the seller working out which one is happening. Every verb,
sheet title and dialog title spells the direction out: "Open a return from the
buyer", "Item is back with you", "Refund the buyer".

- **The status labels stay short** — `Returned`, `Refunded`. They are read as
  a tag in a column of a dozen rows, where the extra words cost more than the
  ambiguity does; the direction is spelled out on the actions, which are what
  change something.
- **The sheet's confirm keeps the short word.** It sits under a title that has
  already said who is being refunded, so `refundAction` is "Refund" and
  `orderRefundBuyer` is the row in `OrderActionsSheet` — two labels because
  one of them has a title above it and the other has nothing.

## Refund and timeline facts

- A refund is positive and cannot exceed the sale price. Returning an item
  alone does not erase revenue; the recorded refund is what reduces it.
- Each lifecycle event stores its own timestamp. The timeline includes order,
  shipment, delivery, return request, returned item, refund, and settlement;
  current status is not a substitute for when a past event happened.

## The order's sections edit in place; its transitions do not

Owner's rule, and the general shape is in `docs/rules/SCREENS.md`. Three of
the order detail screen's sections carry their own Edit and Save:

- **Order** — the buyer's name, what it sold for, and when it was ordered.
- **Profit** — the platform fee alone. Every other line on that statement is
  derived (hard rule 3) or belongs to another record, and a figure with no
  stored field behind it has nothing to edit.
- **Shipping** — carrier, tracking number, ship-by date and shipping cost.

**Status is not editable, and neither are the lines or the timeline.** Ship,
Mark delivered, Record refund and Cancel each write more than the status —
inventory moves back, a timeline fact is recorded, a refund amount is stored —
and they stay in the pinned next move and the actions sheet where the domain
rules can run (`Order transitions are domain rules, never button rules`,
above). A dropdown that set `status` alone would produce an order that says
delivered with nothing to show for it.
