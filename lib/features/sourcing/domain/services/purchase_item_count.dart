import '../../../inventory/domain/entities/item.dart';
import '../entities/purchase.dart';

/// How many items a purchase brought in.
///
/// **A denormalised count, so it has to be kept in step.** `Purchase.itemCount`
/// is written on the document because the Purchases list and Books both show
/// it beside the receipt total, and neither can count a collection Firestore
/// has not handed them. It used to be set once, by the intake flow, at the
/// moment the items were created — so filing an item under a purchase
/// afterwards left the row reading "0 items" next to twelve of them.
///
/// The rule lives here rather than at the two call sites that file items, for
/// the reason every shared rule does: two spellings of one count is how the
/// screens come to disagree.
final class PurchaseItemCount {
  /// Items filed under [purchaseId] that still exist — a deleted row is not
  /// something the purchase brought in any more.
  static int of(List<Item> items, String purchaseId) => items
      .where((Item item) => item.purchaseId == purchaseId && !item.isDeleted)
      .length;

  /// [purchase] with its count brought back in line with [items].
  ///
  /// Returns null when nothing changed, so a caller can skip a write rather
  /// than stamping `updatedAt` on a document nobody touched.
  static Purchase? recounted(Purchase purchase, List<Item> items) {
    final int counted = of(items, purchase.id);

    return counted == purchase.itemCount
        ? null
        : purchase.copyWith(itemCount: counted);
  }
}
