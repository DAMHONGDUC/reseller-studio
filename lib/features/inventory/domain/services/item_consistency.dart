import '../entities/item.dart';
import '../enums/item_warning.dart';

/// What an item says that cannot all be true at once.
///
/// **The other half of editing freely** — owner's rule. Quantity and status
/// are independent and neither writes the other, so the pair is allowed to
/// contradict itself; this is what notices, and the screen draws the result as
/// a tag rather than refusing the save.
///
/// Pure Dart, no Flutter and no strings: `ItemWarning` carries the words.
final class ItemConsistency {
  /// Every contradiction [item] currently holds, in the order they are shown.
  ///
  /// **Only what is on the shelf is checked.** An archived or sold row keeping
  /// a count is not a contradiction: withdrawing something is not giving it
  /// away, and `Item.quantityOnHand` already reads zero for both.
  static List<ItemWarning> warnings(Item item) {
    final List<ItemWarning> found = <ItemWarning>[];

    if (isShelfEmpty(item)) found.add(ItemWarning.emptyShelf);

    return List<ItemWarning>.unmodifiable(found);
  }

  /// True when the row claims to be stock with nothing on the shelf.
  ///
  /// **The one predicate behind both signals** — the warning tag and the red
  /// count read it, so a figure in red without its tag, or the other way
  /// round, is not a state the app can reach.
  static bool isShelfEmpty(Item item) =>
      item.status.isOnHand && item.quantity <= 0;
}
