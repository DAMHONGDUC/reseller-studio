import 'package:flutter/widgets.dart';

import '../../inventory/domain/enums/item_status.dart';
import '../../inventory/item_label.dart';
import '../../listings/domain/enums/listing_status.dart';
import '../../listings/listing_label.dart';
import '../../orders/domain/enums/order_status.dart';
import '../../orders/presentation/order_status_label.dart';
import '../providers.dart';

/// The second line of a search result.
///
/// **It exists because a status cannot be worded where a search hit is built.**
/// `searchResultsProvider` has no `BuildContext`, so the only string it could
/// produce is `status.name` — a Dart identifier. A seller searching for a
/// refund would have read `partiallyRefunded`.
///
/// Each feature already owns the words for its own statuses; this only picks
/// the right one and joins it to whatever else the row has to say.
final class SearchSubtitle {
  /// Null when there is nothing to add under the title.
  static String? of(BuildContext context, SearchHit hit) {
    final String? status = _status(context, hit.status);
    final List<String> parts = <String>[?status, ?hit.detail];

    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String? _status(BuildContext context, Enum? status) => switch (status) {
    final ItemStatus value => ItemStatusLabel.of(context, value),
    final OrderStatus value => OrderStatusLabel.of(context, value),
    final ListingStatus value => ListingStatusLabel.of(context, value),
    _ => null,
  };
}
