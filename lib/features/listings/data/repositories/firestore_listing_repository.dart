import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../dtos/listing_dto.dart';

/// Listings, in Firestore. One document per item per marketplace.
class FirestoreListingRepository implements ListingRepository {
  const FirestoreListingRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<Listing>> watchListings() => FirestoreStream.collection(
    _context.collections.listings.orderBy('createdAt', descending: true),
    _toEntity,
    operation: 'load listings',
  );

  @override
  Stream<List<Listing>> watchListingsForItem(String itemId) =>
      FirestoreStream.collection(
        _context.collections.listings.where('itemId', isEqualTo: itemId),
        _toEntity,
        operation: 'load listings for item',
      );

  @override
  Future<void> save(Listing listing) =>
      FailureMapper.guard('save listing', () async {
        await _context.collections.listings
            .doc(listing.id)
            .set(
              ListingDto.toMap(listing, createdBy: _context.uid),
              SetOptions(merge: true),
            );

        AppLogger.info('Listing saved', <String, Object>{
          'listingId': listing.id,
          'marketplace': listing.marketplace.name,
          'status': listing.status.name,
        });
      });

  @override
  Future<void> saveAll(List<Listing> listings) =>
      FailureMapper.guard('publish listings', () async {
        if (listings.isEmpty) return;

        // Cross-listing is one user intent and must not half-succeed
        // silently (plan §13): the batch either lands or it does not, and a
        // failure is reported once rather than as four separate errors.
        final WriteBatch batch = _context.collections.listings.firestore
            .batch();

        for (final Listing listing in listings) {
          batch.set(
            _context.collections.listings.doc(listing.id),
            ListingDto.toMap(listing, createdBy: _context.uid),
            SetOptions(merge: true),
          );
        }

        await batch.commit();

        AppLogger.info('Listings saved in bulk', <String, Object>{
          'count': listings.length,
        });
      });

  Listing _toEntity(DocumentSnapshot<Map<String, Object?>> doc) =>
      ListingDto.toEntity(doc, fallbackCurrency: _context.currency);
}
