import '../entities/purchase.dart';
import '../entities/source.dart';
import '../entities/supplier_product.dart';

/// Reading and writing sources.
abstract interface class SourceRepository {
  Stream<List<Source>> watchSources();

  Future<Source?> findById(String id);

  Future<void> save(Source source);

  /// Soft delete (hard rule 15).
  Future<void> delete(String id);
}

/// Reading and writing purchases.
///
/// Separate from [SourceRepository] despite living in the same feature: they
/// are different aggregates with different lifetimes, and a seller records
/// dozens of purchases against one source.
abstract interface class PurchaseRepository {
  Stream<List<Purchase>> watchPurchases();

  /// Every purchase from one source — the Source detail screen's spend
  /// history, and what its ROI is computed over.
  Stream<List<Purchase>> watchPurchasesForSource(String sourceId);

  Future<Purchase?> findById(String id);

  Future<void> save(Purchase purchase);

  Future<void> delete(String id);
}

/// A dropship supplier's products (`docs/DROPSHIPPING_PLAN.md`).
abstract interface class SupplierProductRepository {
  /// Every product, soft-deleted ones included — orders point at them.
  Stream<List<SupplierProduct>> watchProducts();

  Future<void> save(SupplierProduct product);

  Future<void> saveAll(List<SupplierProduct> products);

  /// Soft delete (hard rule 15).
  Future<void> delete(String productId);
}
