import 'package:purchases_flutter/purchases_flutter.dart';

import '../domain/entities/plan_intro_offer.dart';
import '../domain/entities/plan_offering.dart';
import '../domain/enums/seller_plan.dart';

/// Translates RevenueCat packages into the two periods this app sells.
///
/// A RevenueCat package may use a custom dashboard identifier even when its
/// Store Product is monthly or yearly. The store period is therefore the
/// fallback when the package type itself does not name the duration.
final class RevenueCatProductMapper {
  static PlanOffering? offering(Package package) {
    final BillingPeriod? period = _period(package);

    if (period == null) return null;

    return PlanOffering(
      productId: package.storeProduct.identifier,
      plan: SellerPlan.premium,
      period: period,
      formattedPrice: package.storeProduct.priceString,
      introOffer: _introOffer(package),
    );
  }

  /// The offer the store attached before the normal price, if any.
  ///
  /// Eligibility is not decided here — the repository asks the store and
  /// drops the offer for a seller who has already used one.
  static PlanIntroOffer? _introOffer(Package package) {
    final IntroductoryPrice? intro = package.storeProduct.introductoryPrice;
    final IntroPeriodUnit? unit = _introUnit(intro?.periodUnit);

    if (intro == null || unit == null) return null;

    return PlanIntroOffer(
      unit: unit,
      unitCount: intro.periodNumberOfUnits,
      formattedPrice: intro.priceString,
      isFree: intro.price == 0,
    );
  }

  /// `unknown` maps to null on purpose: an offer whose length cannot be named
  /// cannot be disclosed, and guideline 3.1.2 wants it named.
  static IntroPeriodUnit? _introUnit(PeriodUnit? unit) => switch (unit) {
    PeriodUnit.day => IntroPeriodUnit.day,
    PeriodUnit.week => IntroPeriodUnit.week,
    PeriodUnit.month => IntroPeriodUnit.month,
    PeriodUnit.year => IntroPeriodUnit.year,
    PeriodUnit.unknown || null => null,
  };

  static BillingPeriod? _period(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return BillingPeriod.monthly;
      case PackageType.annual:
        return BillingPeriod.yearly;
      default:
        return switch (package.storeProduct.subscriptionPeriod) {
          'P1M' => BillingPeriod.monthly,
          'P1Y' => BillingPeriod.yearly,
          _ => null,
        };
    }
  }
}
