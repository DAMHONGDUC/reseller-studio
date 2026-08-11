import '../entities/listing.dart';

/// Reading and writing listings.
abstract interface class ListingRepository {
  Stream<List<Listing>> watchListings();

  /// Every marketplace this one item is live on — what the item detail's
  /// Listings block and the cross-listing screen read.
  Stream<List<Listing>> watchListingsForItem(String itemId);

  Future<void> save(Listing listing);

  /// Publish one item to several marketplaces at once (plan §13).
  ///
  /// Its own method because cross-listing is a single user intent that must
  /// not half-succeed silently: the implementation batches, and a partial
  /// failure is reported as one, not as four separate errors the seller has
  /// to reconcile.
  Future<void> saveAll(List<Listing> listings);
}
