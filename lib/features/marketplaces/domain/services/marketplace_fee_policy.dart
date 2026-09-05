import '../enums/marketplace.dart';

/// What a marketplace's commission is *for this business*.
///
/// **The seller's own rate wins over the published one** — owner's rule. Real
/// fees vary by category, seller tier, promotion and country, and a seller on
/// eBay's shop tier pays a different cut from one who is not. The rates come
/// from that business's own marketplace records
/// (`marketplaceFeeRatesProvider`); the enum's published number is the
/// fallback for a platform this business has no record of.
///
/// **This is the half of the app that still speaks the enum** — listings,
/// offers and the sourcing calculator hold a `Marketplace` value rather than a
/// record id, so the lookup is by `Marketplace.name`. It matches the seeded
/// ids, and a platform outside that overlap falls back. Anything holding a
/// record id asks `Order.feeRate` or the record itself.
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
    Map<String, double> rates = const <String, double>{},
  }) => rates[marketplace.name] ?? marketplace.estimatedFeeRate;
}
