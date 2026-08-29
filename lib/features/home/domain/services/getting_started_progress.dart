import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/domain/enums/item_status.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../orders/domain/entities/order.dart';
import '../enums/getting_started_step.dart';

/// Which of the three first moves a workspace has already made.
///
/// **A later step being done ticks the earlier ones.** A seller can reach a
/// sale without this app ever seeing the listing — marked sold straight off
/// the shelf, or an order imported — and a checklist showing "sale recorded"
/// above an unticked "list it" reads as broken rather than as flexible. The
/// list is a progress report, not an audit.
///
/// Pure Dart on purpose: this is the rule that decides when Home stops
/// offering the checklist, and it is worth a unit test rather than a widget
/// one.
final class GettingStartedProgress {
  const GettingStartedProgress._();

  /// Proof that an item reached a marketplace, whether or not a `Listing`
  /// document survives to say so.
  ///
  /// The clock rather than the status: `listed` stopped being a state, and
  /// `listedAt` is the fact it left behind.
  static bool _hasBeenListed(Item item) =>
      item.listedAt != null || item.status == ItemStatus.sold;

  static Set<GettingStartedStep> completed({
    required List<Item> items,
    required List<Listing> listings,
    required List<Order> orders,
  }) {
    final bool sold = orders.isNotEmpty;
    final bool listed =
        sold || listings.isNotEmpty || items.any(_hasBeenListed);
    final bool added = listed || items.isNotEmpty;

    return <GettingStartedStep>{
      if (added) GettingStartedStep.addItem,
      if (listed) GettingStartedStep.listItem,
      if (sold) GettingStartedStep.recordSale,
    };
  }
}
