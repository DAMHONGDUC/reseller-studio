/// What the seller is paying for (plan §27).
///
/// Ordered cheapest first, and the order is load-bearing: [isAtLeast] is how
/// every gate is written, so a feature added to Pro is automatically in
/// Business and nobody has to remember to list it twice.
enum SellerPlan {
  free,
  pro,
  business;

  /// Whether this plan includes everything [other] does.
  bool isAtLeast(SellerPlan other) => index >= other.index;

  bool get isPaid => this != SellerPlan.free;
}
