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

/// How a plan is named on screen.
///
/// **On the enum, in the enum's file** — the repo's rule for display, and the
/// reason it is not on `SubscriptionLabels`: More shows the name too, and one
/// feature may not import another's `presentation/`.
///
/// No `BuildContext`: hard rule 7 defers the *translation* until release, and
/// these two names move into ARB with the rest of the backfill.
extension SellerPlanDisplay on SellerPlan {
  String get label => switch (this) {
    SellerPlan.free => 'Free',
    SellerPlan.premium => 'Premium',
  };
}
