import '../../core/theme/app_tag_hue.dart';

/// One of the marketplaces a new business starts with.
class MarketplaceSeed {
  const MarketplaceSeed({
    required this.id,
    required this.name,
    required this.hue,
  });

  /// A stable, readable id — so a seeded row is recognisable in Firestore and
  /// two businesses name eBay the same way, which is what lets a future
  /// report compare them.
  final String id;

  final String name;

  /// A different hue each, so the colour tags mean something on the first
  /// screen a new seller opens rather than after they have configured five
  /// records.
  final AppTagHue hue;
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
    MarketplaceSeed(id: 'ebay', name: 'eBay', hue: AppTagHue.blue),
    MarketplaceSeed(id: 'etsy', name: 'Etsy', hue: AppTagHue.amber),
    MarketplaceSeed(id: 'depop', name: 'Depop', hue: AppTagHue.red),
    MarketplaceSeed(id: 'poshmark', name: 'Poshmark', hue: AppTagHue.violet),
    MarketplaceSeed(id: 'vinted', name: 'Vinted', hue: AppTagHue.teal),
  ];
}
