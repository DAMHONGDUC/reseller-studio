import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/supplier_product.dart';
import '../../domain/repositories/sourcing_repository.dart';
import '../dtos/supplier_product_dto.dart';

/// Supplier products, before anyone signs in (`docs/rules/GUEST_MODE.md`).
class LocalSupplierProductRepository implements SupplierProductRepository {
  LocalSupplierProductRepository(LocalDatabase db, {required String currency})
    : _collection = LocalCollection<SupplierProduct>(
        table: LocalTable(db, db.localSupplierProducts),
        fromMap: (String id, Map<String, Object?> data) =>
            SupplierProductDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (SupplierProduct product) => SupplierProductDto.toMap(
          product,
          currency: currency,
          createdBy: GuestConstant.uid,
        ),
        idOf: (SupplierProduct product) => product.id,
        createdAtOf: (SupplierProduct product) => product.createdAt,
        logTag: LogTagConstant.dropship,
        label: 'supplier product',
      );

  final LocalCollection<SupplierProduct> _collection;

  @override
  Stream<List<SupplierProduct>> watchProducts() => _collection.watchAll();

  @override
  Future<void> save(SupplierProduct product) => _collection.save(product);

  @override
  Future<void> saveAll(List<SupplierProduct> products) =>
      _collection.saveAll(products);

  @override
  Future<void> delete(String productId) => _collection.softDelete(productId);
}
