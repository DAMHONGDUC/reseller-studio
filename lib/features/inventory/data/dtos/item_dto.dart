import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';

/// How an [Item] is stored, and how it comes back.
///
/// **The DTO stops at the data layer.** A repository returns entities; nothing
/// in `domain/` or `presentation/` ever sees a `Map` or a `DocumentSnapshot`.
///
/// Field names carry their unit — `purchasePriceMinor`, not `purchasePrice` —
/// so a reader of the console or the Firestore dashboard cannot mistake 1999
/// for nineteen hundred dollars (`docs/DATA_MODEL.md`).
final class ItemDto {
  /// The document's own currency, falling back to the workspace's.
  ///
  /// Stored per document because a seller who buys in USD and sells in EUR is
  /// not an edge case, and a workspace-wide currency applied retroactively
  /// would rewrite what they paid.
  static const String currencyField = 'currency';

  static Item toEntity(
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
  static Item fromMap(
    String id,
    Map<String, Object?> data, {
    required String fallbackCurrency,
  }) {
    final String currency =
        FirestoreMapper.stringOrNull(data[currencyField]) ?? fallbackCurrency;

    return Item(
      // The id is the document id and is never stored as a field — storing it
      // twice means it can disagree with itself.
      id: id,
      title: FirestoreMapper.stringOrNull(data['title']) ?? '',
      quantity: FirestoreMapper.intOrNull(data['quantity']) ?? 1,
      status: _status(data['status']),
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      // Written as a server timestamp on every save, so it is null only for a
      // document that has not come back from the server yet.
      updatedAt: FirestoreMapper.dateOrNull(data['updatedAt']),
      purchasePrice: FirestoreMapper.moneyOrNull(
        data['purchasePriceMinor'],
        currency,
      ),
      expectedPrice: FirestoreMapper.moneyOrNull(
        data['expectedPriceMinor'],
        currency,
      ),
      minimumPrice: FirestoreMapper.moneyOrNull(
        data['minimumPriceMinor'],
        currency,
      ),
      purchaseId: FirestoreMapper.stringOrNull(data['purchaseId']),
      sourceId: FirestoreMapper.stringOrNull(data['sourceId']),
      categoryId: FirestoreMapper.stringOrNull(data['categoryId']),
      locationId: FirestoreMapper.stringOrNull(data['locationId']),
      sku: FirestoreMapper.stringOrNull(data['sku']),
      barcode: FirestoreMapper.stringOrNull(data['barcode']),
      condition: FirestoreMapper.enumOrNull(
        ItemCondition.values,
        data['condition'],
      ),
      description: FirestoreMapper.stringOrNull(data['description']),
      notes: FirestoreMapper.stringOrNull(data['notes']),
      photoUrls: FirestoreMapper.stringList(data['photoUrls']),
      purchaseDate: FirestoreMapper.dateOrNull(data['purchaseDate']),
      listedAt: FirestoreMapper.dateOrNull(data['listedAt']),
      soldAt: FirestoreMapper.dateOrNull(data['soldAt']),
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  /// The write payload.
  ///
  /// Nulls are pruned rather than written: a written null clears a field, and
  /// every write here is a merge, so an entity that simply does not carry a
  /// value must leave what is stored alone.
  /// The stored status, with the two states that were removed folded into
  /// the one that replaced them.
  ///
  /// **A document written before the enum shrank must still read.** `listed`
  /// and `reserved` were both stock the seller owned, so both are [inStock];
  /// anything unrecognised is a draft, which is the state that claims least.
  static ItemStatus _status(Object? raw) => switch (raw) {
    'listed' || 'reserved' => ItemStatus.inStock,
    _ => FirestoreMapper.enumOrNull(ItemStatus.values, raw) ?? ItemStatus.draft,
  };

  static Map<String, Object?> toMap(Item item, {required String createdBy}) =>
      FirestoreMapper.pruned(<String, Object?>{
        'title': item.title,
        'quantity': item.quantity,
        'status': item.status.name,
        currencyField: _currencyOf(item),
        'purchasePriceMinor': FirestoreMapper.minorOrNull(item.purchasePrice),
        'expectedPriceMinor': FirestoreMapper.minorOrNull(item.expectedPrice),
        'minimumPriceMinor': FirestoreMapper.minorOrNull(item.minimumPrice),
        'purchaseId': item.purchaseId,
        'sourceId': item.sourceId,
        'categoryId': item.categoryId,
        'locationId': item.locationId,
        'sku': item.sku,
        'barcode': item.barcode,
        'condition': item.condition?.name,
        'description': item.description,
        'notes': item.notes,
        'photoUrls': item.photoUrls,
        'purchaseDate': _timestampOrNull(item.purchaseDate),
        'listedAt': _timestampOrNull(item.listedAt),
        'soldAt': _timestampOrNull(item.soldAt),
        'deletedAt': _timestampOrNull(item.deletedAt),
        'createdAt': Timestamp.fromDate(item.createdAt),
        'updatedAt': FirestoreMapper.serverTimestamp,
        'createdBy': createdBy,
      });

  /// Whatever currency the item's own amounts are in, or null when none were
  /// entered — in which case the workspace's applies on the way back.
  static String? _currencyOf(Item item) =>
      (item.purchasePrice ?? item.expectedPrice ?? item.minimumPrice)?.currency;

  static Timestamp? _timestampOrNull(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);
}
