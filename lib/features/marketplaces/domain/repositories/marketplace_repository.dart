import '../entities/marketplace.dart';

abstract interface class MarketplaceRepository {
  /// Every marketplace this business sells on, deleted ones included — the
  /// caller decides whether a past order's platform should still be offered
  /// as a destination.
  Stream<List<Marketplace>> watchMarketplaces();

  Future<void> save(Marketplace marketplace);

  /// Seeds a brand-new business. Its own method rather than a loop over
  /// [save], because four writes that half-succeed leave an account with a
  /// partial list and nothing to say so.
  Future<void> saveAll(List<Marketplace> marketplaces);

  /// Soft-delete (hard rule 15): listings and orders point at this by id.
  Future<void> delete(String marketplaceId);
}
