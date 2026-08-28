import '../entities/item.dart';
import '../enums/item_status.dart';

/// Why an item cannot move to the status the seller asked for.
///
/// A named reason rather than a bool, because the screen has to say *which*
/// field is missing — "Add a price to list this" is actionable, "Cannot list"
/// is not. The string a user reads is chosen in the presentation layer from
/// this value; `domain/` holds no strings (hard rule 7).
enum ItemTransitionBlock {
  /// Listing needs something to list at.
  missingPrice,

  /// Selling needs to know what it sold for.
  missingSalePrice,

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
      case ItemStatus.listed:
        if (!item.status.isListable) {
          blocks.add(ItemTransitionBlock.wrongStatus);
        }
        if (item.askingPrice == null) {
          blocks.add(ItemTransitionBlock.missingPrice);
        }
      case ItemStatus.sold:
        if (item.status == ItemStatus.sold ||
            item.status == ItemStatus.archived) {
          blocks.add(ItemTransitionBlock.wrongStatus);
        }
        if (item.askingPrice == null) {
          blocks.add(ItemTransitionBlock.missingSalePrice);
        }
      case ItemStatus.reserved:
        if (item.status != ItemStatus.listed) {
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

    return item.copyWith(
      status: target,
      // First time live anywhere is what staleness is measured from, so it is
      // set once and never moved by a relist.
      listedAt: target == ItemStatus.listed ? item.listedAt ?? now : null,
      soldAt: target == ItemStatus.sold ? now : null,
      // Coming back onto the shelf undoes the sale, and the date has to go
      // with it: an item on hand that still carries a sold date is one every
      // export and every report reads as sold.
      clearSoldAt: target.isOnHand && item.soldAt != null,
    );
  }
}
