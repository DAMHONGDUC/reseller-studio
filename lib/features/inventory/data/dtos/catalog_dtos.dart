import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/storage_location.dart';

/// How an [ItemCategory] is stored.
final class ItemCategoryDto {
  static ItemCategory toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};

    return ItemCategory(
      id: WorkspaceTable.localId(doc.id),
      name: FirestoreMapper.stringOrNull(data['name']) ?? '',
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      parentId: FirestoreMapper.stringOrNull(data['parentId']),
      description: FirestoreMapper.stringOrNull(data['description']),
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  static Map<String, Object?> toMap(
    ItemCategory category, {
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'name': category.name,
    'parentId': category.parentId,
    'description': category.description,
    'deletedAt': category.deletedAt == null
        ? null
        : Timestamp.fromDate(category.deletedAt!),
    'createdAt': Timestamp.fromDate(category.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });
}

/// How a [StorageLocation] is stored.
final class StorageLocationDto {
  static StorageLocation toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};

    return StorageLocation(
      id: WorkspaceTable.localId(doc.id),
      name: FirestoreMapper.stringOrNull(data['name']) ?? '',
      kind:
          FirestoreMapper.enumOrNull(LocationKind.values, data['kind']) ??
          LocationKind.bin,
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      parentId: FirestoreMapper.stringOrNull(data['parentId']),
      address: FirestoreMapper.stringOrNull(data['address']),
      barcode: FirestoreMapper.stringOrNull(data['barcode']),
      notes: FirestoreMapper.stringOrNull(data['notes']),
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  static Map<String, Object?> toMap(
    StorageLocation location, {
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'name': location.name,
    'kind': location.kind.name,
    'parentId': location.parentId,
    'address': location.address,
    'barcode': location.barcode,
    'notes': location.notes,
    'deletedAt': location.deletedAt == null
        ? null
        : Timestamp.fromDate(location.deletedAt!),
    'createdAt': Timestamp.fromDate(location.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });
}
