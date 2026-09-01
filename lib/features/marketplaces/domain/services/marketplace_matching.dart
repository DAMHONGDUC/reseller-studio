import '../entities/marketplace.dart';

/// Joins a listing's platform back to the marketplace record the business
/// owns.
///
/// **Two types are called `Marketplace` in this app**: the closed enum a
/// listing carries, and the record a seller owns, renames and sets a fee on
/// (`marketplaces/domain/entities/marketplace.dart`). Nothing stores a
/// foreign key between them, so the join is by key — and a join written at a
/// call site is one every other call site would write differently.
///
/// **Id first, name second.** A seeded record's id is the enum's own name
/// (`ebay`, `depop`), which is exact; the name is the fallback for a record
/// the seller created themselves and happened to call "eBay".
final class MarketplaceMatching {
  /// What [byKey] holds for [marketplace], under the same id-then-name rule
  /// [matching] uses.
  ///
  /// Null means this platform is not in the map — a marketplace the item is
  /// not listed on, which is a real answer and not a missing price.
  static T? valueFor<T>(Marketplace marketplace, Map<String, T> byKey) {
    final Map<String, T> lowered = <String, T>{
      for (final MapEntry<String, T> entry in byKey.entries)
        entry.key.toLowerCase(): entry.value,
    };

    return lowered[marketplace.id.toLowerCase()] ??
        lowered[marketplace.name.toLowerCase()];
  }

  /// The records named by [keys], in [marketplaces]' own order.
  ///
  /// An empty result is a real answer: none of the platforms the item is on
  /// is a marketplace this business still has.
  static List<Marketplace> matching(
    List<Marketplace> marketplaces,
    Set<String> keys,
  ) {
    final Set<String> wanted = <String>{
      for (final String key in keys) key.toLowerCase(),
    };

    return <Marketplace>[
      for (final Marketplace marketplace in marketplaces)
        if (wanted.contains(marketplace.id.toLowerCase()) ||
            wanted.contains(marketplace.name.toLowerCase()))
          marketplace,
    ];
  }
}
