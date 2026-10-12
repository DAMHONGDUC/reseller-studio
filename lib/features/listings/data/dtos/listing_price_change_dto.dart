import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/listing_price_change.dart';
import '../../domain/enums/price_change_reason.dart';

/// How a [ListingPriceChange] is stored — one row per move, in
/// `listing_price_changes`.
final class ListingPriceChangeDto {
  static ListingPriceChange toEntity(
    DocumentSnapshot<Map<String, Object?>> doc, {
    required String fallbackCurrency,
  }) => fromMap(
    WorkspaceTable.localId(doc.id),
    doc.data() ?? <String, Object?>{},
    fallbackCurrency: fallbackCurrency,
  );

  /// The map boundary both stores share (`docs/rules/GUEST_MODE.md`).
  static ListingPriceChange fromMap(
    String id,
    Map<String, Object?> data, {
    required String fallbackCurrency,
  }) {
    final String currency =
        FirestoreMapper.stringOrNull(data['currency']) ?? fallbackCurrency;

    return ListingPriceChange(
      id: id,
      listingId: FirestoreMapper.stringOrNull(data['listingId']) ?? '',
      itemId: FirestoreMapper.stringOrNull(data['itemId']) ?? '',
      from:
          FirestoreMapper.moneyOrNull(data['fromMinor'], currency) ??
          Money.zero(currency),
      to:
          FirestoreMapper.moneyOrNull(data['toMinor'], currency) ??
          Money.zero(currency),
      reason:
          FirestoreMapper.enumOrNull(
            PriceChangeReason.values,
            data['reason'],
          ) ??
          PriceChangeReason.manual,
      ruleId: FirestoreMapper.stringOrNull(data['ruleId']),
      changedAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
    );
  }

  static Map<String, Object?> toMap(
    ListingPriceChange change, {
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'listingId': change.listingId,
    'itemId': change.itemId,
    'currency': change.to.currency,
    'fromMinor': change.from.minor,
    'toMinor': change.to.minor,
    'reason': change.reason.name,
    'ruleId': change.ruleId,
    'createdAt': Timestamp.fromDate(change.changedAt),
    'createdBy': createdBy,
  });
}
