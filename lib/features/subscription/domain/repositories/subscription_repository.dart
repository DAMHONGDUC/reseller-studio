import '../entities/plan_offering.dart';
import '../entities/subscription_status.dart';

/// Reading entitlement and buying it.
///
/// **No receipt crosses this boundary.** The implementation asks the billing
/// SDK what the seller is entitled to; nothing above this line validates a
/// transaction, stores one, or logs one (hard rule 9).
abstract interface class SubscriptionRepository {
  /// What the seller is entitled to, updated as the store answers.
  ///
  /// Emits [SubscriptionStatus.free] rather than an error when entitlement
  /// cannot be resolved: a seller with no signal must keep using the app.
  Stream<SubscriptionStatus> watchStatus();

  /// What is on sale, priced in the store's own currency.
  ///
  /// Empty when billing is not configured, which is what the Subscription
  /// screen renders its "not available yet" state from.
  Future<List<PlanOffering>> offerings();

  /// Opens the store's purchase sheet. Returns the status after it closes —
  /// unchanged if the seller cancelled.
  Future<SubscriptionStatus> purchase(PlanOffering offering);

  /// Re-reads entitlement from the store. Required by App Store review for
  /// any app selling a subscription.
  Future<SubscriptionStatus> restore();
}
