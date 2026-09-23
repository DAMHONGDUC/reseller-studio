import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../../../core/money/money.dart';
import '../../../orders/domain/enums/order_status.dart';
import '../../domain/entities/offer.dart';

/// How an [Offer] is stored.
final class OfferDto {
  static Offer toEntity(
    DocumentSnapshot<Map<String, Object?>> doc, {
    required String fallbackCurrency,
  }) => fromMap(
    WorkspaceTable.localId(doc.id),
    doc.data() ?? <String, Object?>{},
    fallbackCurrency: fallbackCurrency,
  );

  /// The map boundary both stores share (`docs/rules/GUEST_MODE.md`).
  ///
  /// The guest store keeps this DTO's own map, so one mapping serves
  /// Firestore and Drift — which is what makes the drain a copy.
  static Offer fromMap(
    String id,
    Map<String, Object?> data, {
    required String fallbackCurrency,
  }) {
    final String currency =
        FirestoreMapper.stringOrNull(data['currency']) ?? fallbackCurrency;

    return Offer(
      id: id,
      itemId: FirestoreMapper.stringOrNull(data['itemId']) ?? '',
      itemTitle: FirestoreMapper.stringOrNull(data['itemTitle']) ?? '',
      // Rows written before marketplaces were records already held the id as
      // a string; the name beside it is new and falls back to that id.
      marketplaceId:
          FirestoreMapper.stringOrNull(data['marketplaceId']) ?? 'other',
      marketplaceName:
          FirestoreMapper.stringOrNull(data['marketplaceName']) ??
          FirestoreMapper.stringOrNull(data['marketplaceId']) ??
          'Other',
      amount:
          FirestoreMapper.moneyOrNull(data['amountMinor'], currency) ??
          Money.zero(currency),
      status:
          FirestoreMapper.enumOrNull(OfferStatus.values, data['status']) ??
          OfferStatus.pending,
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      listingId: FirestoreMapper.stringOrNull(data['listingId']),
      expiresAt: FirestoreMapper.dateOrNull(data['expiresAt']),
      buyerName: FirestoreMapper.stringOrNull(data['buyerName']),
      message: FirestoreMapper.stringOrNull(data['message']),
      counterAmount: FirestoreMapper.moneyOrNull(
        data['counterAmountMinor'],
        currency,
      ),
      respondedAt: FirestoreMapper.dateOrNull(data['respondedAt']),
    );
  }

  static Map<String, Object?> toMap(Offer offer, {required String createdBy}) =>
      FirestoreMapper.pruned(<String, Object?>{
        'itemId': offer.itemId,
        'itemTitle': offer.itemTitle,
        'marketplaceId': offer.marketplaceId,
        'marketplaceName': offer.marketplaceName,
        'currency': offer.amount.currency,
        'amountMinor': offer.amount.minor,
        'status': offer.status.name,
        'listingId': offer.listingId,
        'expiresAt': _timestampOrNull(offer.expiresAt),
        'buyerName': offer.buyerName,
        'message': offer.message,
        'counterAmountMinor': FirestoreMapper.minorOrNull(offer.counterAmount),
        'respondedAt': _timestampOrNull(offer.respondedAt),
        'createdAt': Timestamp.fromDate(offer.createdAt),
        'updatedAt': FirestoreMapper.serverTimestamp,
        'createdBy': createdBy,
      });

  static Timestamp? _timestampOrNull(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);
}
