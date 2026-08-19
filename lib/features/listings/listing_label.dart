import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import 'domain/enums/listing_status.dart';

/// The words for a listing status.
///
/// **`domain/` holds none** (hard rule 7) — the enum is the fact, the sentence
/// is presentation, and this is the one place that turns one into the other.
///
/// It sits beside the feature rather than under `presentation/` for the same
/// reason `inventory/item_label.dart` does: search reads it too, and reaching
/// into another feature's `presentation/` is what the dependency rule forbids.
final class ListingStatusLabel {
  static String of(BuildContext context, ListingStatus status) =>
      switch (status) {
        ListingStatus.draft => context.l10n.listingStatusDraft,
        ListingStatus.active => context.l10n.listingStatusActive,
        ListingStatus.paused => context.l10n.listingStatusPaused,
        ListingStatus.ended => context.l10n.listingStatusEnded,
        ListingStatus.sold => context.l10n.listingStatusSold,
        ListingStatus.error => context.l10n.listingStatusError,
      };
}
