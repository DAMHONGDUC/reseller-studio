import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/storage_location.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../dtos/catalog_dtos.dart';

/// Item categories, in Firestore.
class FirestoreCategoryRepository implements CategoryRepository {
  const FirestoreCategoryRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<ItemCategory>> watchCategories() =>
      FirestoreStream.collection(
        _context.collections.categories.orderBy('name'),
        ItemCategoryDto.toEntity,
        operation: 'load categories',
      ).map(
        (List<ItemCategory> rows) =>
            rows.where((ItemCategory row) => !row.isDeleted).toList(),
      );

  @override
  Future<void> save(ItemCategory category) =>
      FailureMapper.guard('save category', () async {
        await _context.collections.categories
            .doc(category.id)
            .set(
              ItemCategoryDto.toMap(category, createdBy: _context.uid),
              SetOptions(merge: true),
            );

        AppLogger.info('Category saved', <String, Object>{
          'categoryId': category.id,
        });
      });

  @override
  Future<void> delete(String id) =>
      FailureMapper.guard('delete category', () async {
        await _context.collections.categories.doc(id).set(<String, Object?>{
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        AppLogger.info('Category soft-deleted', <String, Object>{
          'categoryId': id,
        });
      });
}

/// Storage locations, in Firestore.
class FirestoreLocationRepository implements LocationRepository {
  const FirestoreLocationRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<StorageLocation>> watchLocations() =>
      FirestoreStream.collection(
        _context.collections.locations.orderBy('name'),
        StorageLocationDto.toEntity,
        operation: 'load locations',
      ).map(
        (List<StorageLocation> rows) =>
            rows.where((StorageLocation row) => !row.isDeleted).toList(),
      );

  @override
  Future<void> save(StorageLocation location) =>
      FailureMapper.guard('save location', () async {
        await _context.collections.locations
            .doc(location.id)
            .set(
              StorageLocationDto.toMap(location, createdBy: _context.uid),
              SetOptions(merge: true),
            );

        AppLogger.info('Location saved', <String, Object>{
          'locationId': location.id,
          'kind': location.kind.name,
        });
      });

  @override
  Future<void> delete(String id) =>
      FailureMapper.guard('delete location', () async {
        await _context.collections.locations.doc(id).set(<String, Object?>{
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        AppLogger.info('Location soft-deleted', <String, Object>{
          'locationId': id,
        });
      });
}
