import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_time_utils.dart';
import 'domain/entities/item.dart';
import 'domain/entities/storage_location.dart';

/// Warehouse, shelf, bin.
final class LocationKindLabel {
  static String of(BuildContext context, LocationKind kind) => switch (kind) {
    LocationKind.warehouse => context.l10n.locationWarehouse,
    LocationKind.shelf => context.l10n.locationShelf,
    LocationKind.bin => context.l10n.locationBin,
  };
}

/// How long the item has been in the state it is in — `3d`, `5w`, `2mo`.
///
/// **The duration alone, above the marketplace count.** Repeating the status
/// name would add words without adding information, and the card has no width
/// to spare for them.
final class ItemAgeLabel {
  static String of(Item item, {required DateTime now}) =>
      DateTimeUtils.compactAge(now.difference(item.stateSince));
}
