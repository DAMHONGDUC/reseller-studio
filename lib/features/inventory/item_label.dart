import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import 'domain/entities/storage_location.dart';

/// Warehouse, shelf, bin.
final class LocationKindLabel {
  static String of(BuildContext context, LocationKind kind) => switch (kind) {
    LocationKind.warehouse => context.l10n.locationWarehouse,
    LocationKind.shelf => context.l10n.locationShelf,
    LocationKind.bin => context.l10n.locationBin,
  };
}
