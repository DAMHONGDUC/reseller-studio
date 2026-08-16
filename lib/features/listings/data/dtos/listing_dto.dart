import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/money/money.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
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
      id: doc.id,
      itemId: FirestoreMapper.stringOrNull(data['itemId']) ?? '',
      marketplace:
          FirestoreMapper.enumOrNull(
            Marketplace.values,
            data['marketplaceId'],
          ) ??
          Marketplace.other,
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
    'marketplaceId': listing.marketplace.name,
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
