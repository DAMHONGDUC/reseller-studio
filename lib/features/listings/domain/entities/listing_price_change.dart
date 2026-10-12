import '../../../../core/money/money.dart';
import '../enums/price_change_reason.dart';

/// One move of one listing's price (plan §12 "listing history").
///
/// A fact about when the asking price changed, not a figure about a sale, so
/// hard rule 3 has nothing to say about storing it.
class ListingPriceChange {
  const ListingPriceChange({
    required this.id,
    required this.listingId,
    required this.itemId,
    required this.from,
    required this.to,
    required this.reason,
    required this.changedAt,
    this.ruleId,
  });

  final String id;
  final String listingId;

  /// Denormalised so an item's whole price story is one query.
  final String itemId;

  final Money from;
  final Money to;
  final PriceChangeReason reason;

  /// The rule that set [to], when [reason] is a rule's.
  final String? ruleId;

  final DateTime changedAt;
}
