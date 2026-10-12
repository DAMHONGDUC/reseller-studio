import '../entities/listing.dart';
import '../entities/listing_price_change.dart';

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
  ///
  /// [priceChanges] land in the same write, so a price and its history can
  /// never disagree — `ListingPriceChanges.between` works them out.
  Future<void> saveAll(
    List<Listing> listings, {
    List<ListingPriceChange> priceChanges = const <ListingPriceChange>[],
  });

  /// Every price move of one item's listings, newest first.
  Stream<List<ListingPriceChange>> watchPriceChangesForItem(String itemId);
}
