import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/money/money.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../../orders/domain/enums/order_status.dart';
import '../../domain/entities/offer.dart';

/// How an [Offer] is stored.
final class OfferDto {
  static Offer toEntity(
    DocumentSnapshot<Map<String, Object?>> doc, {
    required String fallbackCurrency,
  }) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};
    final String currency =
        FirestoreMapper.stringOrNull(data['currency']) ?? fallbackCurrency;

    return Offer(
      id: doc.id,
      itemId: FirestoreMapper.stringOrNull(data['itemId']) ?? '',
      itemTitle: FirestoreMapper.stringOrNull(data['itemTitle']) ?? '',
      marketplace:
          FirestoreMapper.enumOrNull(
            Marketplace.values,
            data['marketplaceId'],
          ) ??
          Marketplace.other,
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
        'marketplaceId': offer.marketplace.name,
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
