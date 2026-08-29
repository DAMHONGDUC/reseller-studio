import 'package:purchases_flutter/purchases_flutter.dart';

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
    );
  }

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
