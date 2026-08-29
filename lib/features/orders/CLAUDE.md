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

## An order always names an item

`OrderLine.itemId` is non-null, so there is no walk-in sale — nothing sells
that inventory has never heard of. `RecordSaleScreen` therefore lists what is
on hand and nothing else, and a workspace with no items sends the seller to
Inventory rather than offering a form that cannot be completed.

Multi-line orders, and lines that belong to no item, are a product decision
that has not been made. Both would change the entity, every screen that taps
through to an item, and what "profit" means for an order — raise it before
building either.

## The create button obeys the app-wide create rules

- `AppAddFabScaffold` with `floatingNav: true`, because Orders is a tab screen.
- Quick Action on Home lists **every** create action, so the record-sale route
  is in `QuickActionConstant` — `test/features/home/quick_action_test.dart`
  fails the day a screen grows a create button that Home does not offer.
- The empty state's action is the same one the button is. Orders used to point
  the seller at Inventory because it had no create action of its own; that
  sentence in `docs/rules/SCREENS.md` now applies to Listings alone.

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

## Refund and timeline facts

- A refund is positive and cannot exceed the sale price. Returning an item
  alone does not erase revenue; the recorded refund is what reduces it.
- Each lifecycle event stores its own timestamp. The timeline includes order,
  shipment, delivery, return request, returned item, refund, and settlement;
  current status is not a substitute for when a past event happened.
