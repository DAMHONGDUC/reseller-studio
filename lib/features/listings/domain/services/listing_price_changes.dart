import 'package:system_design/common.dart';

import '../entities/listing.dart';
import '../entities/listing_price_change.dart';
import '../enums/price_change_reason.dart';

/// The price history a write leaves behind, worked out from the listings as
/// they were and as they will be.
///
/// One function every writer calls, so a reprice from a bulk bar and one from
/// an item's form cannot record the same move two different ways.
final class ListingPriceChanges {
  /// A change for every listing in [after] whose price differs from its row
  /// in [before]. A listing [before] does not hold is new, not repriced.
  static List<ListingPriceChange> between({
    required List<Listing> before,
    required List<Listing> after,
    required PriceChangeReason reason,
    required DateTime at,
    String? ruleId,
  }) {
    final Map<String, Listing> previous = <String, Listing>{
      for (final Listing listing in before) listing.id: listing,
    };
    final List<ListingPriceChange> changes = <ListingPriceChange>[];

    for (final Listing listing in after) {
      final Listing? was = previous[listing.id];

      if (was == null || was.price == listing.price) continue;
      changes.add(
        ListingPriceChange(
          id: SdId.unique(),
          listingId: listing.id,
          itemId: listing.itemId,
          from: was.price,
          to: listing.price,
          reason: reason,
          ruleId: ruleId,
          changedAt: at,
        ),
      );
    }

    return changes;
  }
}
