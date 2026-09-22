// `cloud_firestore` exports a pigeon-generated `Source`, which collides with
// this feature's entity. Hidden rather than prefixed so the entity keeps its
// plain name everywhere in the app.
import 'package:cloud_firestore/cloud_firestore.dart' hide Source;

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/source.dart';

/// How a [Source] is stored.
///
/// Soft-deleted, never removed (hard rule 15): hard-deleting a source orphans
/// every purchase pointing at it and destroys the ROI history the Sourcing
/// feature exists to show.
final class SourceDto {
  static Source toEntity(DocumentSnapshot<Map<String, Object?>> doc) => fromMap(
    WorkspaceTable.localId(doc.id),
    doc.data() ?? <String, Object?>{},
  );

  /// The map boundary both stores share (`docs/rules/GUEST_MODE.md`).
  ///
  /// The guest store keeps this DTO's own map, so one mapping serves
  /// Firestore and Drift — which is what makes the drain a copy.
  static Source fromMap(String id, Map<String, Object?> data) {
    return Source(
      id: id,
      name: FirestoreMapper.stringOrNull(data['name']) ?? '',
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      type: FirestoreMapper.enumOrNull(SourceType.values, data['type']),
      address: FirestoreMapper.stringOrNull(data['address']),
      phone: FirestoreMapper.stringOrNull(data['phone']),
      website: FirestoreMapper.stringOrNull(data['website']),
      notes: FirestoreMapper.stringOrNull(data['notes']),
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  static Map<String, Object?> toMap(
    Source source, {
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'name': source.name,
    'type': source.type?.name,
    'address': source.address,
    'phone': source.phone,
    'website': source.website,
    'notes': source.notes,
    'deletedAt': source.deletedAt == null
        ? null
        : Timestamp.fromDate(source.deletedAt!),
    'createdAt': Timestamp.fromDate(source.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });
}

/// How a [Purchase] is stored.
///
/// `totalCostMinor` is what left the seller's pocket, from the receipt — not
/// the sum of its items' costs. The two legitimately disagree when a box lot
/// is apportioned by judgement, and deriving the total would rewrite what was
/// actually paid. See the entity's own doc.
final class PurchaseDto {
  static Purchase toEntity(
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
  static Purchase fromMap(
    String id,
    Map<String, Object?> data, {
    required String fallbackCurrency,
  }) {
    final String currency =
        FirestoreMapper.stringOrNull(data['currency']) ?? fallbackCurrency;

    return Purchase(
      id: id,
      purchaseDate: FirestoreMapper.dateOr(
        data['purchaseDate'],
        DateTime.now(),
      ),
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      sourceId: FirestoreMapper.stringOrNull(data['sourceId']),
      totalCost: FirestoreMapper.moneyOrNull(data['totalCostMinor'], currency),
      receiptUrl: FirestoreMapper.stringOrNull(data['receiptUrl']),
      notes: FirestoreMapper.stringOrNull(data['notes']),
      itemCount: FirestoreMapper.intOrNull(data['itemCount']) ?? 0,
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  static Map<String, Object?> toMap(
    Purchase purchase, {
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'purchaseDate': Timestamp.fromDate(purchase.purchaseDate),
    'sourceId': purchase.sourceId,
    'currency': purchase.totalCost?.currency,
    'totalCostMinor': FirestoreMapper.minorOrNull(purchase.totalCost),
    'receiptUrl': purchase.receiptUrl,
    'notes': purchase.notes,
    // Denormalised so the Purchases list does not fan out a query per row.
    'itemCount': purchase.itemCount,
    'deletedAt': purchase.deletedAt == null
        ? null
        : Timestamp.fromDate(purchase.deletedAt!),
    'createdAt': Timestamp.fromDate(purchase.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });
}
