import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/domain/enums/item_fulfilment.dart';
import '../../../inventory/domain/enums/item_status.dart';
import '../../domain/entities/supplier_product.dart';

/// Everything a seller does to a supplier product: save it, check it, list
/// it, rank it against a backup (`docs/DROPSHIPPING_PLAN.md`).
///
/// True while a write is in flight.
class SupplierProductController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> save(SupplierProduct product) => _run(
    'Save supplier product',
    <String, Object>{'productId': product.id, 'sourceId': product.sourceId},
    () => ref.read(supplierProductRepositoryProvider).save(product),
  );

  Future<void> delete(String productId) => _run(
    'Delete supplier product',
    <String, Object>{'productId': productId},
    () => ref.read(supplierProductRepositoryProvider).delete(productId),
  );

  /// The seller looked at the supplier today and the figures are current —
  /// the manual half of price and stock monitoring.
  Future<void> markChecked(SupplierProduct product) => _run(
    'Mark supplier product checked',
    <String, Object>{'productId': product.id},
    () => ref
        .read(supplierProductRepositoryProvider)
        .save(product.copyWith(lastCheckedAt: DateTime.now())),
  );

  /// Creates the dropship item [product] stocks and links the two; returns
  /// the item's id. Only a title is set on the item (hard rule 2) — the
  /// price is entered where every price is, on the cross-list screen.
  Future<String> listIt(SupplierProduct product) async {
    final String itemId = SdId.unique();

    await _run(
      'List supplier product',
      <String, Object>{'productId': product.id, 'itemId': itemId},
      () async {
        await ref
            .read(itemRepositoryProvider)
            .save(
              Item(
                id: itemId,
                title: product.title,
                quantity: 1,
                status: ItemStatus.draft,
                createdAt: DateTime.now(),
                sourceId: product.sourceId,
                fulfilment: ItemFulfilment.dropship,
              ),
            );
        await ref
            .read(supplierProductRepositoryProvider)
            .save(product.copyWith(itemId: itemId, rank: 1));
      },
    );

    return itemId;
  }

  /// Links [product] to [itemId] behind the suppliers it already has.
  Future<void> linkBackup(
    String itemId,
    SupplierProduct product,
    List<SupplierProduct> current,
  ) {
    final int next = current.fold<int>(
      0,
      (int top, SupplierProduct p) => p.rank > top ? p.rank : top,
    );

    return _run(
      'Link backup supplier',
      <String, Object>{'itemId': itemId, 'productId': product.id},
      () => ref
          .read(supplierProductRepositoryProvider)
          .save(product.copyWith(itemId: itemId, rank: next + 1)),
    );
  }

  /// Moves [product] to rank 1 and everything that was ahead of it down one,
  /// in one write.
  Future<void> makePrimary(
    SupplierProduct product,
    List<SupplierProduct> current,
  ) {
    final List<SupplierProduct> reranked = <SupplierProduct>[
      for (final SupplierProduct p in current)
        if (p.id == product.id)
          p.copyWith(rank: 1)
        else if (p.rank < product.rank)
          p.copyWith(rank: p.rank + 1),
    ];

    return _run(
      'Make supplier primary',
      <String, Object>{'productId': product.id, 'moved': reranked.length},
      () => ref.read(supplierProductRepositoryProvider).saveAll(reranked),
    );
  }

  Future<void> _run(
    String describe,
    Map<String, Object> data,
    Future<void> Function() write,
  ) async {
    SdLogger.action(LogTagConstant.dropship, describe, data);
    state = true;

    try {
      await write();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.dropship,
        'Failed to ${describe.toLowerCase()}',
        error: error,
        stackTrace: stackTrace,
        data: data,
      );
      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<SupplierProductController, bool>
supplierProductControllerProvider =
    NotifierProvider<SupplierProductController, bool>(
      SupplierProductController.new,
    );
