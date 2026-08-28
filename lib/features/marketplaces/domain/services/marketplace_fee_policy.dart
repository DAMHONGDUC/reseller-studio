import '../enums/marketplace.dart';

/// What a marketplace's commission is *for this business*.
///
/// **The published rate is a starting point, not the answer** — owner's rule.
/// Real fees vary by category, seller tier, promotion and country, and a
/// seller on eBay's shop tier pays a different cut from one who is not. The
/// enum keeps the platform's headline number; a workspace may correct it, and
/// `Workspace.marketplaceFeeRates` holds only the corrections.
///
/// **Only the exceptions are stored.** A map filled in with every platform's
/// default would make "this seller told us their rate" indistinguishable from
/// "nobody has said", and a published rate that later changed would be frozen
/// at whatever the app shipped with.
///
/// Pure Dart, and the rates arrive as an argument rather than from a provider,
/// because `PayoutReconciliation` runs here too and `domain/` imports no
/// Flutter.
final class MarketplaceFeePolicy {
  const MarketplaceFeePolicy._();

  /// A rate is a fraction of the sale price, so anything outside this is a
  /// typo rather than a fee — 100% of a sale is already absurd, and negative
  /// is not a fee at all.
  static const double maxRate = 1;

  static bool isValid(double rate) => rate >= 0 && rate <= maxRate;

  /// This workspace's rate for [marketplace], or the platform's published one.
  static double rateFor(
    Marketplace marketplace, {
    Map<String, double> overrides = const <String, double>{},
  }) => overrides[marketplace.name] ?? marketplace.estimatedFeeRate;

  /// Whether the seller has corrected this platform's rate themselves.
  static bool isOverridden(
    Marketplace marketplace, {
    Map<String, double> overrides = const <String, double>{},
  }) => overrides.containsKey(marketplace.name);
}
