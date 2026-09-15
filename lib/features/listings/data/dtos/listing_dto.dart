import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/listing.dart';
import '../../domain/enums/listing_status.dart';

/// How a [Listing] is stored.
///
/// One document per item **per marketplace** — cross-listing means one item
/// has several (plan §13). `externalListingId` stays null until a publish
/// succeeds, which is also how a draft is told from a failed publish.
final class ListingDto {
  static Listing toEntity(
    DocumentSnapshot<Map<String, Object?>> doc, {
    required String fallbackCurrency,
  }) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};
    final String currency =
        FirestoreMapper.stringOrNull(data['currency']) ?? fallbackCurrency;

    return Listing(
      id: WorkspaceTable.localId(doc.id),
      itemId: FirestoreMapper.stringOrNull(data['itemId']) ?? '',
      // **Rows written before marketplaces were records need no migration**:
      // the field already held the platform's id as a string, and the ids a
      // business is created with are those same words. What is new is the
      // name beside it, and a row without one falls back to the id — which is
      // what the marketplace was called then anyway.
      marketplaceId:
          FirestoreMapper.stringOrNull(data['marketplaceId']) ?? 'other',
      marketplaceName:
          FirestoreMapper.stringOrNull(data['marketplaceName']) ??
          FirestoreMapper.stringOrNull(data['marketplaceId']) ??
          'Other',
      title: FirestoreMapper.stringOrNull(data['title']) ?? '',
      price:
          FirestoreMapper.moneyOrNull(data['priceMinor'], currency) ??
          Money.zero(currency),
      status:
          FirestoreMapper.enumOrNull(ListingStatus.values, data['status']) ??
          ListingStatus.draft,
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      description: FirestoreMapper.stringOrNull(data['description']),
      photoUrls: FirestoreMapper.stringList(data['photoUrls']),
      externalListingId: FirestoreMapper.stringOrNull(
        data['externalListingId'],
      ),
      externalUrl: FirestoreMapper.stringOrNull(data['externalUrl']),
      publishedAt: FirestoreMapper.dateOrNull(data['publishedAt']),
      endedAt: FirestoreMapper.dateOrNull(data['endedAt']),
      viewCount: FirestoreMapper.intOrNull(data['viewCount']),
      watcherCount: FirestoreMapper.intOrNull(data['watcherCount']),
      lastError: FirestoreMapper.stringOrNull(data['lastError']),
    );
  }

  static Map<String, Object?> toMap(
    Listing listing, {
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'itemId': listing.itemId,
    'marketplaceId': listing.marketplaceId,
    'marketplaceName': listing.marketplaceName,
    'title': listing.title,
    'currency': listing.price.currency,
    'priceMinor': listing.price.minor,
    'status': listing.status.name,
    'description': listing.description,
    'photoUrls': listing.photoUrls,
    'externalListingId': listing.externalListingId,
    'externalUrl': listing.externalUrl,
    'publishedAt': _timestampOrNull(listing.publishedAt),
    'endedAt': _timestampOrNull(listing.endedAt),
    'viewCount': listing.viewCount,
    'watcherCount': listing.watcherCount,
    'lastError': listing.lastError,
    'createdAt': Timestamp.fromDate(listing.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });

  static Timestamp? _timestampOrNull(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);
}
