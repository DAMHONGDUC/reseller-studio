/// One of the marketplaces a new business starts with.
class MarketplaceSeed {
  const MarketplaceSeed({
    required this.id,
    required this.name,
    required this.feeRate,
  });

  /// A stable, readable id — so a seeded row is recognisable in Firestore and
  /// two businesses name eBay the same way, which is what lets a future
  /// report compare them.
  final String id;

  final String name;
  final double feeRate;
}

/// **The five marketplaces a new business is created with** — owner's rule.
///
/// Not a closed list: they are a starting point the seller adds to, renames
/// and deletes. They exist so a brand-new account can list something without
/// first being asked to describe the industry it works in — the same reason
/// Quick Add takes only a title (hard rule 2).
///
/// The rates are the platforms' published headline numbers, which is all
/// anyone can know before the seller tells us their own; a seller on a shop
/// tier corrects it in the marketplace's own screen.
final class MarketplaceConstant {
  static const List<MarketplaceSeed> defaults = <MarketplaceSeed>[
    MarketplaceSeed(id: 'ebay', name: 'eBay', feeRate: 0.1325),
    MarketplaceSeed(id: 'etsy', name: 'Etsy', feeRate: 0.095),
    MarketplaceSeed(id: 'depop', name: 'Depop', feeRate: 0.10),
    MarketplaceSeed(id: 'poshmark', name: 'Poshmark', feeRate: 0.20),
    MarketplaceSeed(id: 'vinted', name: 'Vinted', feeRate: 0),
  ];

  /// A rate is a fraction of the sale price, so anything outside this is a
  /// typo rather than a fee — 100% of a sale is already absurd, and negative
  /// is not a fee at all.
  static const double maxFeeRate = 1;

  static bool isValidFeeRate(double rate) => rate >= 0 && rate <= maxFeeRate;
}
