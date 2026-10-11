import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';

/// Why a listing's price moved — what its price history explains.
///
/// Stored by [name], so a case is never renamed once written.
enum PriceChangeReason {
  /// The seller typed a new price for one listing.
  manual,

  /// A bulk reprice across a selection (hard rule 16).
  bulk,

  /// A pricing rule was applied.
  rule,

  /// A rule lowered a listing that had not sold.
  stale,

  /// A supplier's price moved and a rule followed it.
  supplierChange,
}

/// How a reason reads in a price history row.
extension PriceChangeReasonDisplay on PriceChangeReason {
  String label(BuildContext context) => switch (this) {
    PriceChangeReason.manual => context.l10n.priceChangeReasonManual,
    PriceChangeReason.bulk => context.l10n.priceChangeReasonBulk,
    PriceChangeReason.rule => context.l10n.priceChangeReasonRule,
    PriceChangeReason.stale => context.l10n.priceChangeReasonStale,
    PriceChangeReason.supplierChange =>
      context.l10n.priceChangeReasonSupplierChange,
  };
}
