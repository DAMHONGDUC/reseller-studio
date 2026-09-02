import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/offers/domain/entities/offer.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/offers/domain/services/offer_evaluation.dart';

/// The question a seller with a clock running actually has.
///
/// The card already said how far below asking an offer was. It did not say
/// whether the money left over still paid for the jacket — which is the
/// decision, and which the app has every number for.
void main() {
  const String gbp = 'GBP';

  Money gbpOf(int minor) => Money(minor, gbp);

  Offer offerOf(Money amount) => Offer(
    id: 'off-1',
    itemId: 'itm-1',
    itemTitle: 'Cord jacket',
    marketplace: Marketplace.depop,
    amount: amount,
    status: OfferStatus.pending,
    createdAt: DateTime(2026, 6, 1),
  );

  test('what is left is the offer less the platform cut and the cost', () {
    // £40 on Depop at 10% is £4 of fees; a £15 jacket leaves £21.
    final OfferEvaluation evaluation = OfferEvaluation.of(
      offerOf(gbpOf(4000)),
      feeRate: 0.10,
      cost: gbpOf(1500),
    );

    expect(evaluation.fees, gbpOf(400));
    expect(evaluation.profit, gbpOf(2100));
    expect(evaluation.isLoss, isFalse);
  });

  test('an offer that does not cover the item is a loss', () {
    final OfferEvaluation evaluation = OfferEvaluation.of(
      offerOf(gbpOf(1500)),
      feeRate: 0.10,
      cost: gbpOf(1500),
    );

    expect(evaluation.profit, gbpOf(-150));
    expect(evaluation.isLoss, isTrue);
  });

  test('an unknown cost is unanswerable, not a warning', () {
    final OfferEvaluation evaluation = OfferEvaluation.of(
      offerOf(gbpOf(4000)),
      feeRate: 0.10,
    );

    // A red line on every item nobody entered a price for is one the seller
    // learns to ignore (hard rule 5).
    expect(evaluation.profit, isNull);
    expect(evaluation.isLoss, isFalse);
  });

  test('below the floor is about the seller\'s own rule, not the profit', () {
    final OfferEvaluation evaluation = OfferEvaluation.of(
      offerOf(gbpOf(2500)),
      feeRate: 0.10,
      cost: gbpOf(500),
      minimumPrice: gbpOf(3000),
    );

    // It would still make money; the seller said they would not go there.
    expect(evaluation.isLoss, isFalse);
    expect(evaluation.isBelowFloor, isTrue);
  });

  test('no floor set is never below one', () {
    final OfferEvaluation evaluation = OfferEvaluation.of(
      offerOf(gbpOf(100)),
      feeRate: 0.10,
    );

    expect(evaluation.isBelowFloor, isFalse);
  });

  test('an offer exactly at the floor is not below it', () {
    final OfferEvaluation evaluation = OfferEvaluation.of(
      offerOf(gbpOf(3000)),
      feeRate: 0.10,
      minimumPrice: gbpOf(3000),
    );

    expect(evaluation.isBelowFloor, isFalse);
  });
}
