import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/source.dart';
import '../../domain/repositories/sourcing_repository.dart';
import '../dtos/sourcing_dtos.dart';

/// Where stock comes from, before anyone signs in
/// (`docs/rules/GUEST_MODE.md`).
class LocalSourceRepository implements SourceRepository {
  LocalSourceRepository(LocalDatabase db)
    : _collection = LocalCollection<Source>(
        table: LocalTable(db, db.localSources),
        fromMap: SourceDto.fromMap,
        toMap: (Source source) =>
            SourceDto.toMap(source, createdBy: GuestConstant.uid),
        idOf: (Source source) => source.id,
        createdAtOf: (Source source) => source.createdAt,
        isDeleted: (Source source) => source.isDeleted,
        logTag: LogTagConstant.sourcing,
        label: 'source',
      );

  final LocalCollection<Source> _collection;

  @override
  Stream<List<Source>> watchSources() => _collection.watchAll();

  @override
  Future<Source?> findById(String id) => _collection.findById(id);

  @override
  Future<void> save(Source source) => _collection.save(source);

  @override
  Future<void> delete(String id) => _collection.softDelete(id);
}

/// Buying trips, before anyone signs in.
class LocalPurchaseRepository implements PurchaseRepository {
  LocalPurchaseRepository(LocalDatabase db, {required String currency})
    : _collection = LocalCollection<Purchase>(
        table: LocalTable(db, db.localPurchases),
        fromMap: (String id, Map<String, Object?> data) =>
            PurchaseDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (Purchase purchase) =>
            PurchaseDto.toMap(purchase, createdBy: GuestConstant.uid),
        idOf: (Purchase purchase) => purchase.id,
        createdAtOf: (Purchase purchase) => purchase.purchaseDate,
        isDeleted: (Purchase purchase) => purchase.isDeleted,
        logTag: LogTagConstant.sourcing,
        label: 'purchase',
      );

  final LocalCollection<Purchase> _collection;

  @override
  Stream<List<Purchase>> watchPurchases() => _collection.watchAll();

  @override
  Stream<List<Purchase>> watchPurchasesForSource(String sourceId) => _collection
      .watchWhere((Purchase purchase) => purchase.sourceId == sourceId);

  @override
  Future<Purchase?> findById(String id) => _collection.findById(id);

  @override
  Future<void> save(Purchase purchase) => _collection.save(purchase);

  @override
  Future<void> delete(String id) => _collection.softDelete(id);
}
