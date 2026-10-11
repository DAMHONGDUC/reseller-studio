import '../../../../core/money/money.dart';
import '../entities/supplier_product.dart';

/// What a dropshipped item costs to fulfil, read off its supplier products.
final class SupplierCost {
  /// Price, shipping and tax together — what one order from [product] costs.
  ///
  /// Null when the supplier price is unknown: shipping alone is not a cost of
  /// goods (hard rule 5). Missing shipping or tax add nothing rather than
  /// blanking the figure, because a supplier that charges none is common.
  static Money? landed(SupplierProduct product) {
    final Money? price = product.supplierPrice;

    if (price == null) return null;

    final Money shipping =
        product.supplierShipping ?? Money.zero(price.currency);
    final Money tax = product.supplierTax ?? Money.zero(price.currency);

    if (shipping.currency != price.currency || tax.currency != price.currency) {
      return null;
    }

    return price + shipping + tax;
  }

  /// The supplier an item is ordered from first: the live product with the
  /// lowest rank, or null when it has none.
  static SupplierProduct? primaryFor(
    String itemId,
    List<SupplierProduct> products,
  ) {
    final List<SupplierProduct> live =
        products
            .where((SupplierProduct p) => p.itemId == itemId && !p.isDeleted)
            .toList()
          ..sort(
            (SupplierProduct a, SupplierProduct b) => a.rank.compareTo(b.rank),
          );

    return live.isEmpty ? null : live.first;
  }
}
