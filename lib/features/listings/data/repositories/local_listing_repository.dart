import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../dtos/listing_dto.dart';

/// Listings, before anyone signs in (`docs/rules/GUEST_MODE.md`).
class LocalListingRepository implements ListingRepository {
  LocalListingRepository(LocalDatabase db, {required String currency})
    : _collection = LocalCollection<Listing>(
        table: LocalTable(db, db.localListings),
        fromMap: (String id, Map<String, Object?> data) =>
            ListingDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (Listing listing) =>
            ListingDto.toMap(listing, createdBy: GuestConstant.uid),
        idOf: (Listing listing) => listing.id,
        createdAtOf: (Listing listing) => listing.createdAt,
        logTag: LogTagConstant.listing,
        label: 'listing',
      );

  final LocalCollection<Listing> _collection;

  @override
  Stream<List<Listing>> watchListings() => _collection.watchAll();

  @override
  Stream<List<Listing>> watchListingsForItem(String itemId) =>
      _collection.watchWhere((Listing listing) => listing.itemId == itemId);

  @override
  Future<void> save(Listing listing) => _collection.save(listing);

  @override
  Future<void> saveAll(List<Listing> listings) => _collection.saveAll(listings);
}
