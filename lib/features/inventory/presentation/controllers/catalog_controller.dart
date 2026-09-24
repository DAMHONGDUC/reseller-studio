import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/storage_location.dart';

/// Categories and locations — the workspace's reference data.
///
/// One controller for both because they are the same three verbs over two
/// small collections, and two controllers would be two copies of the same
/// logging and error handling.
///
/// Every method logs what it did with the data and rethrows; the screen turns
/// the throw into the one message hard rule 6 allows.
class CatalogController extends Notifier<bool> {
  /// True while a write is in flight.
  @override
  bool build() => false;

  /// Returns the record's id, so a caller creating one inline can select it.
  Future<String?> saveCategory({
    required String name,
    String? id,
    String? parentId,
  }) async {
    final String trimmed = name.trim();
    final String categoryId = id ?? SdId.unique();

    if (trimmed.isEmpty) return null;

    state = true;
    SdLogger.action(LogTagConstant.catalog, 'Save category', <String, Object>{
      'categoryId': categoryId,
      'isNew': id == null,
    });

    try {
      await ref
          .read(categoryRepositoryProvider)
          .save(
            ItemCategory(
              id: categoryId,
              name: trimmed,
              createdAt: DateTime.now(),
              parentId: parentId,
            ),
          );

      return categoryId;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.catalog,
        'Failed to save category',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'categoryId': categoryId},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> deleteCategory(String id) async {
    state = true;
    SdLogger.action(LogTagConstant.catalog, 'Delete category', <String, Object>{
      'categoryId': id,
    });

    try {
      await ref.read(categoryRepositoryProvider).delete(id);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.catalog,
        'Failed to delete category',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'categoryId': id},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// Returns the record's id, so a caller creating one inline can select it.
  Future<String?> saveLocation({
    required String name,
    required LocationKind kind,
    String? id,
    String? parentId,
    String? barcode,
  }) async {
    final String trimmed = name.trim();
    final String locationId = id ?? SdId.unique();

    if (trimmed.isEmpty) return null;

    state = true;
    SdLogger.action(LogTagConstant.catalog, 'Save location', <String, Object>{
      'locationId': locationId,
      'kind': kind.name,
      'isNew': id == null,
    });

    try {
      await ref
          .read(locationRepositoryProvider)
          .save(
            StorageLocation(
              id: locationId,
              name: trimmed,
              kind: kind,
              createdAt: DateTime.now(),
              parentId: parentId,
              barcode: barcode?.trim().isEmpty ?? true ? null : barcode!.trim(),
            ),
          );

      return locationId;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.catalog,
        'Failed to save location',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'locationId': locationId, 'kind': kind.name},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> deleteLocation(String id) async {
    state = true;
    SdLogger.action(LogTagConstant.catalog, 'Delete location', <String, Object>{
      'locationId': id,
    });

    try {
      await ref.read(locationRepositoryProvider).delete(id);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.catalog,
        'Failed to delete location',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'locationId': id},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<CatalogController, bool> catalogControllerProvider =
    NotifierProvider<CatalogController, bool>(CatalogController.new);
