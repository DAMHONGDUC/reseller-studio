// `cloud_firestore` exports its own `Order` (a query index direction), which
// collides with this feature's entity. Hidden rather than prefixed so the
// entity keeps its plain name everywhere in the app.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/money/money.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../domain/entities/order.dart';
import '../../domain/enums/order_status.dart';

/// How an [Order] is stored, and how it comes back.
///
/// **Line items are embedded, not a subcollection.** An order has a handful of
/// lines, they are always read with the order, and they never change after the
/// sale — exactly when embedding wins (`docs/DATA_MODEL.md`).
final class OrderDto {
  static Order toEntity(
    DocumentSnapshot<Map<String, Object?>> doc, {
    required String fallbackCurrency,
  }) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};
    final String currency =
        FirestoreMapper.stringOrNull(data['currency']) ?? fallbackCurrency;
    final Object? lines = data['lines'];

    return Order(
      id: doc.id,
      status:
          FirestoreMapper.enumOrNull(OrderStatus.values, data['status']) ??
          OrderStatus.toShip,
      marketplaceRecordId:
          FirestoreMapper.stringOrNull(data['marketplaceId']) ?? 'other',
      marketplaceNameSnapshot:
          FirestoreMapper.stringOrNull(data['marketplaceName']) ??
          _legacyMarketplaceName(data['marketplaceId']),
      lines: lines is List
          ? lines
                .whereType<Map<Object?, Object?>>()
                .map(
                  (Map<Object?, Object?> line) => _lineToEntity(line, currency),
                )
                .toList()
          : const <OrderLine>[],
      salePrice:
          FirestoreMapper.moneyOrNull(data['salePriceMinor'], currency) ??
          Money.zero(currency),
      orderedAt: FirestoreMapper.dateOr(data['orderedAt'], DateTime.now()),
      fees: FirestoreMapper.moneyOrNull(data['feesMinor'], currency),
      shippingCost: FirestoreMapper.moneyOrNull(
        data['shippingCostMinor'],
        currency,
      ),
      refund: FirestoreMapper.moneyOrNull(data['refundMinor'], currency),
      // The one stored figure that is not derived — a fact the marketplace
      // reported, not a calculation (hard rule 3).
      payout: FirestoreMapper.moneyOrNull(data['payoutMinor'], currency),
      externalOrderId: FirestoreMapper.stringOrNull(data['externalOrderId']),
      buyerName: FirestoreMapper.stringOrNull(data['buyerName']),
      trackingNumber: FirestoreMapper.stringOrNull(data['trackingNumber']),
      carrier: FirestoreMapper.stringOrNull(data['carrier']),
      shipByDate: FirestoreMapper.dateOrNull(data['shipByDate']),
      shippedAt: FirestoreMapper.dateOrNull(data['shippedAt']),
      deliveredAt: FirestoreMapper.dateOrNull(data['deliveredAt']),
      returnRequestedAt: FirestoreMapper.dateOrNull(data['returnRequestedAt']),
      returnedAt: FirestoreMapper.dateOrNull(data['returnedAt']),
      refundedAt: FirestoreMapper.dateOrNull(data['refundedAt']),
      settledAt: FirestoreMapper.dateOrNull(data['settledAt']),
      notes: FirestoreMapper.stringOrNull(data['notes']),
    );
  }

  static Map<String, Object?> toMap(Order order, {required String createdBy}) =>
      FirestoreMapper.pruned(<String, Object?>{
        'status': order.status.name,
        'marketplaceId': order.marketplaceId,
        'marketplaceName': order.marketplaceName,
        'currency': order.salePrice.currency,
        'lines': order.lines.map(_lineToMap).toList(),
        'salePriceMinor': order.salePrice.minor,
        'orderedAt': Timestamp.fromDate(order.orderedAt),
        'feesMinor': FirestoreMapper.minorOrNull(order.fees),
        'shippingCostMinor': FirestoreMapper.minorOrNull(order.shippingCost),
        'refundMinor': FirestoreMapper.minorOrNull(order.refund),
        'payoutMinor': FirestoreMapper.minorOrNull(order.payout),
        'externalOrderId': order.externalOrderId,
        'buyerName': order.buyerName,
        'trackingNumber': order.trackingNumber,
        'carrier': order.carrier,
        'shipByDate': _timestampOrNull(order.shipByDate),
        'shippedAt': _timestampOrNull(order.shippedAt),
        'deliveredAt': _timestampOrNull(order.deliveredAt),
        'returnRequestedAt': _timestampOrNull(order.returnRequestedAt),
        'returnedAt': _timestampOrNull(order.returnedAt),
        'refundedAt': _timestampOrNull(order.refundedAt),
        'settledAt': _timestampOrNull(order.settledAt),
        'notes': order.notes,
        'updatedAt': FirestoreMapper.serverTimestamp,
        'createdBy': createdBy,
      });

  static OrderLine _lineToEntity(Map<Object?, Object?> line, String currency) {
    final Map<String, Object?> data = <String, Object?>{
      for (final MapEntry<Object?, Object?> entry in line.entries)
        if (entry.key is String) entry.key! as String: entry.value,
    };

    return OrderLine(
      itemId: FirestoreMapper.stringOrNull(data['itemId']) ?? '',
      title: FirestoreMapper.stringOrNull(data['title']) ?? '',
      quantity: FirestoreMapper.intOrNull(data['quantity']) ?? 1,
      unitPrice:
          FirestoreMapper.moneyOrNull(data['unitPriceMinor'], currency) ??
          Money.zero(currency),
      unitCost: FirestoreMapper.moneyOrNull(data['unitCostMinor'], currency),
    );
  }

  static Map<String, Object?> _lineToMap(OrderLine line) =>
      FirestoreMapper.pruned(<String, Object?>{
        'itemId': line.itemId,
        // Denormalised at sale time and never refreshed: repricing an item
        // afterwards must not rewrite what the buyer actually paid.
        'title': line.title,
        'quantity': line.quantity,
        'unitPriceMinor': line.unitPrice.minor,
        'unitCostMinor': FirestoreMapper.minorOrNull(line.unitCost),
      });

  static Timestamp? _timestampOrNull(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);

  static String _legacyMarketplaceName(Object? raw) =>
      FirestoreMapper.enumOrNull(Marketplace.values, raw)?.displayName ??
      Marketplace.other.displayName;
}
