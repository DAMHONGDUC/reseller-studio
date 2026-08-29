import '../domain/enums/seller_plan.dart';

/// The names this app and the RevenueCat dashboard have to agree on.
///
/// **Entitlement identifiers, not product ids.** A product is one row in one
/// store; an entitlement is what the seller can do, and it survives renaming
/// a product, adding a yearly SKU or moving to a second store. Gating on a
/// product id is how a seller who bought the yearly plan loses their features.
///
/// If a name here does not match the dashboard, every seller reads as Free
/// and nothing throws — so this is the first thing to check when a paying
/// account looks unpaid.
final class SubscriptionProductConstant {
  /// Entitlement identifier → the plan it grants.
  ///
  static const Map<String, SellerPlan> planByEntitlement = <String, SellerPlan>{
    'premium': SellerPlan.premium,
  };
}
