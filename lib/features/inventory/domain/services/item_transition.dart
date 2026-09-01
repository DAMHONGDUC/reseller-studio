import '../entities/item.dart';
import '../enums/item_status.dart';

/// Why an item cannot move to the status the seller asked for.
///
/// A named reason rather than a bool, because the screen has to say *which*
/// field is missing — "Add a price to list this" is actionable, "Cannot list"
/// is not. The string a user reads is chosen in the presentation layer from
/// this value; `domain/` holds no strings (hard rule 7).
enum ItemTransitionBlock {
  /// The item is somewhere this move does not start from — listing something
  /// already sold, selling something archived.
  wrongStatus,

  /// Nothing on the shelf to move.
  noQuantity,
}

/// The result of asking whether an item may change status.
class ItemTransitionCheck {
  const ItemTransitionCheck._(this.blocks);

  const ItemTransitionCheck.allowed() : blocks = const <ItemTransitionBlock>[];

  factory ItemTransitionCheck.blocked(List<ItemTransitionBlock> blocks) =>
      ItemTransitionCheck._(List<ItemTransitionBlock>.unmodifiable(blocks));

  /// Empty when the move is allowed. Every reason at once, not the first —
  /// a form that reveals one missing field per attempt is a form a seller
  /// fills in three rounds.
  final List<ItemTransitionBlock> blocks;

  bool get isAllowed => blocks.isEmpty;
}

/// **Create takes the minimum; a state transition takes the rest** — hard
/// rule 2 and plan §29, expressed as one place that decides.
///
/// Quick Add makes an item from a title alone, so an item is allowed to exist
/// with no price, no photo, no category and no source. The requirements attach
/// when it *moves*: listing needs a price, selling needs a sale price. Putting
/// that here rather than in a form means the rule holds for the bulk path too
/// (hard rule 16) — forty items relisted at once are checked by the same code
/// as one.
///
/// Pure Dart, no Flutter, no strings: the presentation layer turns a
/// [ItemTransitionBlock] into a localized sentence.
final class ItemTransition {
  /// Whether [item] may become [target] right now.
  static ItemTransitionCheck check(Item item, ItemStatus target) {
    final List<ItemTransitionBlock> blocks = <ItemTransitionBlock>[];

    if (item.quantity <= 0) blocks.add(ItemTransitionBlock.noQuantity);

    switch (target) {
      case ItemStatus.sold:
        if (item.status == ItemStatus.sold ||
            item.status == ItemStatus.archived) {
          blocks.add(ItemTransitionBlock.wrongStatus);
        }
      case ItemStatus.draft:
      case ItemStatus.inStock:
      case ItemStatus.archived:
        // Moving backwards or out of inventory asks for nothing: a seller
        // un-listing or archiving is correcting a mistake, and a rule that
        // blocked the correction would be the bug.
        break;
    }

    return blocks.isEmpty
        ? const ItemTransitionCheck.allowed()
        : ItemTransitionCheck.blocked(blocks);
  }

  /// Whether more marketplaces may be added for this item (plan §13).
  ///
  /// **Deliberately not `check(item, listed)`.** That one refuses an item
  /// that is already listed, which is exactly the item cross-listing is for:
  /// it is on eBay and the seller wants it on Depop as well. What is refused
  /// here is an item that has left inventory — a sold or archived one — and
  /// an empty shelf.
  ///
  /// **A price is not required at this point** and asking for one would be
  /// hard rule 2 backwards: the cross-list screen is itself where the price
  /// is entered, so requiring it beforehand would block the screen that
  /// collects it.
  static ItemTransitionCheck crossListCheck(Item item) {
    final List<ItemTransitionBlock> blocks = <ItemTransitionBlock>[];

    if (item.quantity <= 0) blocks.add(ItemTransitionBlock.noQuantity);

    if (item.status == ItemStatus.sold || item.status == ItemStatus.archived) {
      blocks.add(ItemTransitionBlock.wrongStatus);
    }

    return blocks.isEmpty
        ? const ItemTransitionCheck.allowed()
        : ItemTransitionCheck.blocked(blocks);
  }

  /// [item] marked as live on a marketplace.
  ///
  /// **Going live is not a status move any more** — owner's rule, since an
  /// item on eBay is still stock the seller owns. What it does change is
  /// `listedAt`, the clock staleness is measured from, and a draft becomes
  /// stock the moment it is offered for sale.
  ///
  /// **The clock is set once and never moved by a relist**: an item listed in
  /// March and cross-listed in June has been sitting since March, and that is
  /// the number the seller has to see.
  static Item markListed(Item item, {required DateTime now}) => item.copyWith(
    listedAt: item.listedAt ?? now,
    status: item.status == ItemStatus.draft ? ItemStatus.inStock : item.status,
  );

  /// One unit out the door.
  ///
  /// **Quantity is what decides whether the record is sold** — owner's rule.
  /// Selling one of ten used to mark the whole row sold and leave the count
  /// at ten, so the shelf claimed nine items that Inventory said were gone.
  /// A sale now takes one off the count, and only the sale that empties it
  /// moves the status.
  ///
  /// Throws for the same reason [apply] does: nothing on the shelf to sell,
  /// no sale price, or an item that has already left inventory.
  static Item sell(Item item, {required DateTime now}) {
    final ItemTransitionCheck result = check(item, ItemStatus.sold);
    final int left = item.quantity - 1;

    if (!result.isAllowed) {
      throw StateError(
        'Cannot sell item ${item.id}: '
        '${result.blocks.map((ItemTransitionBlock b) => b.name).join(', ')}',
      );
    }

    // Still stock behind it: the record stays exactly where it was — listed
    // stays listed, and its staleness clock is not touched.
    if (left > 0) return item.copyWith(quantity: left);

    return apply(item, ItemStatus.sold, now: now);
  }

  /// [item] after its count was edited — back on the shelf if the seller put
  /// stock behind a sold record.
  ///
  /// **The other half of the rule above** — owner's rule. A sold row given a
  /// quantity again is a seller saying they have the thing, and leaving it
  /// sold made the card claim nothing was left of ten. Nothing else moves:
  /// archiving is a deliberate withdrawal, and a count does not undo it.
  static Item restocked(Item item, {required DateTime now}) {
    if (item.status != ItemStatus.sold || item.quantity <= 0) return item;

    return apply(item, ItemStatus.inStock, now: now);
  }

  /// [count] more of [item] on the shelf.
  ///
  /// **Restocking adds to the count and puts the row back in stock** —
  /// owner's rule. A seller who buys five more of something that sold out is
  /// not creating a new item: it is the same record, with the same cost
  /// history and the same listings, and having to un-sell it by hand first
  /// was the step that made people create a duplicate instead.
  ///
  /// Adds rather than replaces: the box asks how many arrived, which is the
  /// number on the receipt in the seller's hand. An archived item comes back
  /// too — restocking it is the seller saying they have it again.
  static Item restock(Item item, int count, {required DateTime now}) {
    final Item stocked = item.copyWith(quantity: item.quantity + count);

    if (count <= 0) {
      throw StateError('Cannot restock item ${item.id} by $count');
    }

    return apply(stocked, ItemStatus.inStock, now: now);
  }

  /// [item] moved to [target], with the timestamps that move implies.
  ///
  /// **Throws if the move is blocked.** Callers check first; this is the
  /// second line, so a bulk path that forgot cannot write a half-valid item.
  static Item apply(Item item, ItemStatus target, {required DateTime now}) {
    final ItemTransitionCheck result = check(item, target);

    if (!result.isAllowed) {
      throw StateError(
        'Cannot move item ${item.id} from ${item.status.name} to '
        '${target.name}: ${result.blocks.map((ItemTransitionBlock b) => b.name).join(', ')}',
      );
    }

    return setStatus(item, target, now: now);
  }

  /// [item] moved to [target] with no gate at all — the seller's own choice.
  ///
  /// **The status a seller picks on the form is never refused** — owner's
  /// rule. That screen is where they correct what the app got wrong, and a
  /// correction that argues back is the thing they came to fix. The verbs are
  /// unchanged: [apply] still checks, so Mark as sold and the bulk paths ask
  /// for what they need.
  ///
  /// The side effects come along either way, because they are what keeps the
  /// record consistent rather than what keeps it legal.
  static Item setStatus(
    Item item,
    ItemStatus target, {
    required DateTime now,
  }) => item.copyWith(
    status: target,
    // Sold means sold out, whichever way it was reached: the count goes to
    // zero so the card, the restock box and Analytics all agree with the
    // status rather than each other.
    quantity: target == ItemStatus.sold ? 0 : null,
    soldAt: target == ItemStatus.sold ? now : null,
    // Coming back onto the shelf undoes the sale, and the date has to go with
    // it: an item on hand that still carries a sold date is one every export
    // and every report reads as sold.
    clearSoldAt: target.isOnHand && item.soldAt != null,
  );
}
