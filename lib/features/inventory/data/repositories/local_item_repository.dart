import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../dtos/item_dto.dart';

/// Inventory, before anyone signs in (`docs/rules/GUEST_MODE.md`).
///
/// **The same DTO as the Firestore repository**, which is the point: a guest's
/// record and a signed-in seller's are the same map, so the drain moves it
/// rather than translating it.
class LocalItemRepository implements ItemRepository {
  LocalItemRepository(LocalDatabase db, {required String currency})
    : _collection = LocalCollection<Item>(
        table: LocalTable(db, db.localItems),
        fromMap: (String id, Map<String, Object?> data) =>
            ItemDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (Item item) => ItemDto.toMap(item, createdBy: GuestConstant.uid),
        idOf: (Item item) => item.id,
        createdAtOf: (Item item) => item.createdAt,
        isDeleted: (Item item) => item.isDeleted,
        logTag: LogTagConstant.item,
        label: 'item',
      );

  final LocalCollection<Item> _collection;

  @override
  Stream<List<Item>> watchItems() => _collection.watchAll();

  @override
  Stream<Item?> watchItem(String id) => _collection.watchOne(id);

  @override
  Future<Item?> findById(String id) => _collection.findById(id);

  @override
  Stream<List<Item>> watchItemsForPurchase(String purchaseId) =>
      _collection.watchWhere((Item item) => item.purchaseId == purchaseId);

  @override
  Future<void> save(Item item) => _collection.save(item);

  @override
  Future<void> saveAll(List<Item> items) => _collection.saveAll(items);

  @override
  Future<void> delete(String id) => _collection.softDelete(id);
}
