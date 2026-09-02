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
