import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:reseller_studio/features/subscription/data/revenue_cat_product_mapper.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_intro_offer.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_offering.dart';

void main() {
  Package customPackage(
    String productId,
    String period, {
    IntroductoryPrice? intro,
  }) => Package(
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
      introductoryPrice: intro,
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

  test('a lifetime package becomes a lifetime offering', () {
    final PlanOffering? offering = RevenueCatProductMapper.offering(
      Package(
        r'$rc_lifetime',
        PackageType.lifetime,
        const StoreProduct(
          'premium_lifetime',
          'Premium',
          'Premium',
          199.99,
          r'$199.99',
          'USD',
        ),
        const PresentedOfferingContext('premium', null, null),
      ),
    );

    expect(offering?.period, BillingPeriod.lifetime);
  });

  test('a custom package with no period is not sold as lifetime', () {
    // It could be a consumable, and "forever" is a claim the receipt breaks.
    final PlanOffering? offering = RevenueCatProductMapper.offering(
      Package(
        'custom_lifetime',
        PackageType.custom,
        const StoreProduct(
          'premium_lifetime',
          'Premium',
          'Premium',
          199.99,
          r'$199.99',
          'USD',
        ),
        const PresentedOfferingContext('premium', null, null),
      ),
    );

    expect(offering, isNull);
  });

  test('unsupported custom duration is not sold as the wrong period', () {
    final PlanOffering? offering = RevenueCatProductMapper.offering(
      customPackage('premium_weekly', 'P1W'),
    );

    expect(offering, isNull);
  });

  test('a free introductory period becomes a trial on the offering', () {
    final PlanOffering? offering = RevenueCatProductMapper.offering(
      customPackage(
        'premium_yearly',
        'P1Y',
        intro: const IntroductoryPrice(
          0,
          r'$0.00',
          'P1W',
          1,
          PeriodUnit.week,
          1,
        ),
      ),
    );

    expect(offering?.introOffer?.isFree, isTrue);
    expect(offering?.introOffer?.unit, IntroPeriodUnit.week);
    expect(offering?.introOffer?.unitCount, 1);
  });

  test('a cheaper first period is an intro offer, never a trial', () {
    // Calling a discounted year a free trial is how a charge surprises
    // somebody.
    final PlanOffering? offering = RevenueCatProductMapper.offering(
      customPackage(
        'premium_yearly',
        'P1Y',
        intro: const IntroductoryPrice(
          49.99,
          r'$49.99',
          'P1Y',
          1,
          PeriodUnit.year,
          1,
        ),
      ),
    );

    expect(offering?.introOffer?.isFree, isFalse);
  });

  test('an offer whose length cannot be named is not disclosed', () {
    final PlanOffering? offering = RevenueCatProductMapper.offering(
      customPackage(
        'premium_yearly',
        'P1Y',
        intro: const IntroductoryPrice(
          0,
          r'$0.00',
          '',
          1,
          PeriodUnit.unknown,
          1,
        ),
      ),
    );

    expect(offering, isNotNull);
    expect(offering?.introOffer, isNull);
  });

  test('a product with no introductory price carries no offer', () {
    final PlanOffering? offering = RevenueCatProductMapper.offering(
      customPackage('premium_monthly', 'P1M'),
    );

    expect(offering?.introOffer, isNull);
  });
}
