import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:reseller_studio/features/subscription/data/revenue_cat_product_mapper.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_offering.dart';

void main() {
  Package customPackage(String productId, String period) => Package(
    'custom_$productId',
    PackageType.custom,
    StoreProduct(
      productId,
      'Premium',
      'Premium',
      9.99,
      r'$9.99',
      'USD',
      subscriptionPeriod: period,
    ),
    const PresentedOfferingContext('premium', null, null),
  );

  test('custom monthly package still becomes a buyable offering', () {
    final PlanOffering? offering = RevenueCatProductMapper.offering(
      customPackage('premium_monthly', 'P1M'),
    );

    expect(offering?.period, BillingPeriod.monthly);
  });

  test('custom yearly package still becomes a buyable offering', () {
    final PlanOffering? offering = RevenueCatProductMapper.offering(
      customPackage('premium_yearly', 'P1Y'),
    );

    expect(offering?.period, BillingPeriod.yearly);
  });

  test('unsupported custom duration is not sold as the wrong period', () {
    final PlanOffering? offering = RevenueCatProductMapper.offering(
      customPackage('premium_weekly', 'P1W'),
    );

    expect(offering, isNull);
  });
}
