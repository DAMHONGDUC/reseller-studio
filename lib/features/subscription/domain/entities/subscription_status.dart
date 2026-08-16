import '../enums/seller_plan.dart';

/// Where the entitlement came from. Shown on the Subscription screen so a
/// seller knows which shop to cancel in — the app cannot do it for them.
enum SubscriptionSource { none, appStore, playStore, promotional }

/// What the seller is entitled to right now (plan §25, §27).
///
/// **The client copy is a cache for rendering, never the authority.** A
/// Cloud Function mirrors RevenueCat's webhook into Firestore and
/// `firestore.rules` reads that — a client that could write its own plan is a
/// paywall with a free bypass. See `docs/rules/DECISIONS.md`.
///
/// No receipt, token or store transaction id is ever held here. A receipt is
/// a credential (hard rule 9), and this object is logged.
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.plan,
    required this.source,
    this.renewsAt,
    this.willRenew = false,
    this.isInGracePeriod = false,
  });

  /// What an unknown or signed-out seller gets: the free tier, never a locked
  /// app. A failed entitlement lookup must not present as "you have nothing".
  static const SubscriptionStatus free = SubscriptionStatus(
    plan: SellerPlan.free,
    source: SubscriptionSource.none,
  );

  final SellerPlan plan;
  final SubscriptionSource source;

  /// When the current period ends. Null on [SellerPlan.free] and on a
  /// promotional grant with no expiry.
  final DateTime? renewsAt;

  /// False after a cancellation that has not lapsed yet — the seller keeps
  /// the plan until [renewsAt], and the screen says so rather than showing a
  /// renewal date that will not happen.
  final bool willRenew;

  /// Billing failed and the store is retrying. Access continues, so this is a
  /// prompt to fix a card, never a downgrade.
  final bool isInGracePeriod;

  /// What a log line may carry: the shape, never the receipt.
  Map<String, Object?> toLogData() => <String, Object?>{
    'plan': plan.name,
    'source': source.name,
    'willRenew': willRenew,
    'isInGracePeriod': isInGracePeriod,
  };
}
