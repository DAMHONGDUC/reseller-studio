/// What the seller is paying for (plan §27).
///
/// Ordered cheapest first, and the order is load-bearing: [isAtLeast] is how
/// every feature gate is written, so Premium includes every Free capability.
enum SellerPlan {
  free,
  premium;

  /// Whether this plan includes everything [other] does.
  bool isAtLeast(SellerPlan other) => index >= other.index;

  bool get isPaid => this != SellerPlan.free;
}
