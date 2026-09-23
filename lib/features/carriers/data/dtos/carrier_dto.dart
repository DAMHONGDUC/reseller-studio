import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../domain/entities/carrier.dart';

final class CarrierDto {
  static Carrier toEntity(DocumentSnapshot<Map<String, Object?>> doc) =>
      fromMap(
        WorkspaceTable.localId(doc.id),
        doc.data() ?? <String, Object?>{},
      );

  /// The map boundary both stores share (`docs/rules/GUEST_MODE.md`).
  ///
  /// The guest store keeps this DTO's own map, so one mapping serves
  /// Firestore and Drift — which is what makes the drain a copy.
  static Carrier fromMap(String id, Map<String, Object?> data) {
    return Carrier(
      id: id,
      name: FirestoreMapper.stringOrNull(data['name']) ?? '',
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  static Map<String, Object?> toMap(
    Carrier carrier, {
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'name': carrier.name,
    'deletedAt': carrier.deletedAt == null
        ? null
        : Timestamp.fromDate(carrier.deletedAt!),
    'createdAt': Timestamp.fromDate(carrier.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });
}
