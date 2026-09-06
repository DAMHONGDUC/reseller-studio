import '../../../../core/money/money.dart';
import '../entities/offer.dart';

/// Whether taking this offer is worth it.
///
/// **The question the card was not answering.** "£22, 35% below asking" says
/// how far the buyer came down; it does not say whether £22 still pays for the
/// jacket. A seller with a clock running works that out in their head, gets it
/// wrong, and either takes a loss or lets the offer lapse — and the app knows
/// every number involved.
///
/// **Postage is deliberately out of it.** Nobody has bought a label yet, so
/// including a guess would be inventing a cost; the card says the figure is
/// before postage rather than claiming a precision it does not have.
///
/// Pure, and it takes the numbers rather than reading them: the interesting
/// cases are an item whose cost nobody entered and an offer under the seller's
/// own floor, and a service that fetched its own data could be tested at
/// neither.
class OfferEvaluation {
  const OfferEvaluation({
    required this.amount,
    required this.fees,
    required this.profit,
    required this.floor,
  });

  /// What the buyer offered.
  final Money amount;

  /// What the platform would take at that price.
  final Money fees;

  /// What would be left after the platform's cut and the cost of the item.
  ///
  /// **Null when the item's cost was never entered** — the answer is then
  /// unknowable rather than zero, and the card renders `—` (hard rule 5).
  final Money? profit;

  /// The seller's own floor for this item, when they set one.
  final Money? floor;

  /// Whether the offer is under the price the seller said they would not go
  /// below. A fact about their own rule, not a judgement about the offer.
  bool get isBelowFloor {
    final Money? limit = floor;

    return limit != null && amount < limit;
  }

  /// Whether accepting would cost the seller money.
  ///
  /// **Never true on an unknown cost.** An unanswerable question is not a
  /// warning, and a red line on every item nobody entered a price for is how
  /// a seller learns to ignore the line.
  bool get isLoss {
    final Money? left = profit;

    return left != null && left.isNegative;
  }

  /// Work out what accepting [offer] would leave.
  ///
  /// [feeRate] is the platform's cut as a fraction, resolved by the caller the
  /// same way every other fee figure in the app is (`Order.feeRate`).
  factory OfferEvaluation.of(
    Offer offer, {
    required double feeRate,
    Money? cost,
    Money? minimumPrice,
  }) {
    final Money fees = offer.amount.applyRate(feeRate);
    final Money? paid = cost;

    return OfferEvaluation(
      amount: offer.amount,
      fees: fees,
      profit: paid == null ? null : offer.amount - paid - fees,
      floor: minimumPrice,
    );
  }
}
