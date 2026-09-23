import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/storage_location.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../dtos/catalog_dtos.dart';

/// Categories, before anyone signs in (`docs/rules/GUEST_MODE.md`).
class LocalCategoryRepository implements CategoryRepository {
  LocalCategoryRepository(LocalDatabase db)
    : _collection = LocalCollection<ItemCategory>(
        table: LocalTable(db, db.localCategories),
        fromMap: ItemCategoryDto.fromMap,
        toMap: (ItemCategory category) =>
            ItemCategoryDto.toMap(category, createdBy: GuestConstant.uid),
        idOf: (ItemCategory category) => category.id,
        createdAtOf: (ItemCategory category) => category.createdAt,
        isDeleted: (ItemCategory category) => category.isDeleted,
        logTag: LogTagConstant.catalog,
        label: 'category',
      );

  final LocalCollection<ItemCategory> _collection;

  @override
  Stream<List<ItemCategory>> watchCategories() => _collection.watchAll();

  @override
  Future<void> save(ItemCategory category) => _collection.save(category);

  @override
  Future<void> delete(String id) => _collection.softDelete(id);
}

/// Storage locations, before anyone signs in.
class LocalLocationRepository implements LocationRepository {
  LocalLocationRepository(LocalDatabase db)
    : _collection = LocalCollection<StorageLocation>(
        table: LocalTable(db, db.localLocations),
        fromMap: StorageLocationDto.fromMap,
        toMap: (StorageLocation location) =>
            StorageLocationDto.toMap(location, createdBy: GuestConstant.uid),
        idOf: (StorageLocation location) => location.id,
        createdAtOf: (StorageLocation location) => location.createdAt,
        isDeleted: (StorageLocation location) => location.isDeleted,
        logTag: LogTagConstant.catalog,
        label: 'location',
      );

  final LocalCollection<StorageLocation> _collection;

  @override
  Stream<List<StorageLocation>> watchLocations() => _collection.watchAll();

  @override
  Future<void> save(StorageLocation location) => _collection.save(location);

  @override
  Future<void> delete(String id) => _collection.softDelete(id);
}
