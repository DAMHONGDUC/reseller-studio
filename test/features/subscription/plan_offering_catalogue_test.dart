import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_offering.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_offering_catalogue.dart';

void main() {
  PlanOffering offering(BillingPeriod period, {String id = 'id'}) =>
      PlanOffering(
        productId: id,
        plan: SellerPlan.premium,
        period: period,
        formattedPrice: r'$1',
      );

  test('the recommended period leads, whatever order the store used', () {
    final List<PlanOffering> ordered = PlanOfferingCatalogue.ordered(
      <PlanOffering>[
        offering(BillingPeriod.monthly),
        offering(BillingPeriod.yearly),
      ],
    );

    expect(
      ordered.map((PlanOffering row) => row.period),
      <BillingPeriod>[BillingPeriod.yearly, BillingPeriod.monthly],
    );
  });

  test('a period sold twice renders once', () {
    final List<PlanOffering> ordered = PlanOfferingCatalogue.ordered(
      <PlanOffering>[
        offering(BillingPeriod.yearly, id: 'first'),
        offering(BillingPeriod.yearly, id: 'second'),
      ],
    );

    expect(ordered, hasLength(1));
    expect(ordered.single.productId, 'first');
  });

  test('a period that is not on sale falls back to what is', () {
    final List<PlanOffering> monthlyOnly = <PlanOffering>[
      offering(BillingPeriod.monthly),
    ];

    expect(
      PlanOfferingCatalogue.selected(
        monthlyOnly,
        BillingPeriod.yearly,
      )?.period,
      BillingPeriod.monthly,
    );
    expect(
      PlanOfferingCatalogue.selected(
        const <PlanOffering>[],
        BillingPeriod.yearly,
      ),
      isNull,
    );
  });

  test('a lone offering is not a better deal than anything', () {
    final List<PlanOffering> yearlyOnly = <PlanOffering>[
      offering(BillingPeriod.yearly),
    ];

    expect(
      PlanOfferingCatalogue.isBestValue(yearlyOnly.single, yearlyOnly),
      isFalse,
    );
  });
}
