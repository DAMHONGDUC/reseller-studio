import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_price_change.dart';
import '../../domain/repositories/listing_repository.dart';
import '../dtos/listing_dto.dart';
import '../dtos/listing_price_change_dto.dart';

/// Listings, before anyone signs in (`docs/rules/GUEST_MODE.md`).
class LocalListingRepository implements ListingRepository {
  LocalListingRepository(this._db, {required String currency})
    : _collection = LocalCollection<Listing>(
        table: LocalTable(_db, _db.localListings),
        fromMap: (String id, Map<String, Object?> data) =>
            ListingDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (Listing listing) =>
            ListingDto.toMap(listing, createdBy: GuestConstant.uid),
        idOf: (Listing listing) => listing.id,
        createdAtOf: (Listing listing) => listing.createdAt,
        logTag: LogTagConstant.listing,
        label: 'listing',
      ),
      _collectionOfPriceChanges = LocalCollection<ListingPriceChange>(
        table: LocalTable(_db, _db.localListingPriceChanges),
        fromMap: (String id, Map<String, Object?> data) =>
            ListingPriceChangeDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (ListingPriceChange change) =>
            ListingPriceChangeDto.toMap(change, createdBy: GuestConstant.uid),
        idOf: (ListingPriceChange change) => change.id,
        createdAtOf: (ListingPriceChange change) => change.changedAt,
        logTag: LogTagConstant.listing,
        label: 'listing price change',
      );

  final LocalDatabase _db;
  final LocalCollection<Listing> _collection;
  final LocalCollection<ListingPriceChange> _collectionOfPriceChanges;

  @override
  Stream<List<Listing>> watchListings() => _collection.watchAll();

  @override
  Stream<List<Listing>> watchListingsForItem(String itemId) =>
      _collection.watchWhere((Listing listing) => listing.itemId == itemId);

  @override
  Future<void> save(Listing listing) => _collection.save(listing);

  /// One transaction for both tables — the local half of the Firestore batch.
  @override
  Future<void> saveAll(
    List<Listing> listings, {
    List<ListingPriceChange> priceChanges = const <ListingPriceChange>[],
  }) => _db.transaction(() async {
    await _collection.saveAll(listings);
    await _collectionOfPriceChanges.saveAll(priceChanges);
  });

  @override
  Stream<List<ListingPriceChange>> watchPriceChangesForItem(String itemId) =>
      _collectionOfPriceChanges.watchWhere(
        (ListingPriceChange change) => change.itemId == itemId,
      );
}
