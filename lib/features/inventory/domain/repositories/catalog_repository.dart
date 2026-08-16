import '../entities/item_category.dart';
import '../entities/storage_location.dart';

/// Reading and writing item categories.
///
/// Small, slow-changing reference data — a workspace has tens of these, not
/// thousands — so the whole list is one live stream and every screen folds
/// over it rather than querying by parent.
abstract interface class CategoryRepository {
  Stream<List<ItemCategory>> watchCategories();

  Future<void> save(ItemCategory category);

  /// Soft delete (hard rule 15): items point at this.
  Future<void> delete(String id);
}

/// Reading and writing storage locations.
abstract interface class LocationRepository {
  Stream<List<StorageLocation>> watchLocations();

  Future<void> save(StorageLocation location);

  Future<void> delete(String id);
}
