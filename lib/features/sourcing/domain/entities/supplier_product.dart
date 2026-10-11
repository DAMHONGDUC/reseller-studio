import '../../../../core/money/money.dart';

/// One product — one variant — a dropship supplier sells
/// (`docs/DROPSHIPPING_PLAN.md`).
///
/// **One item per supplier variant** (decision 11.7), so a product points at
/// the item it stocks through [itemId], ranked by [rank] when an item has a
/// backup supplier. A product nobody has listed yet has no item.
///
/// Every amount is nullable: an unknown price is not a free one (hard rule 4).
class SupplierProduct {
  const SupplierProduct({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.createdAt,
    this.itemId,
    this.rank = 1,
    this.url,
    this.externalProductId,
    this.externalVariantId,
    this.supplierPrice,
    this.supplierShipping,
    this.supplierTax,
    this.shippingDays,
    this.stock,
    this.lastCheckedAt,
    this.deletedAt,
  });

  final String id;

  /// The supplier — a `Source` of type `dropshipSupplier`.
  final String sourceId;

  /// The supplier's own title, frozen when the product was added.
  final String title;

  final DateTime createdAt;

  /// The item this product stocks, once it has been listed.
  final String? itemId;

  /// 1 is ordered first; anything higher is a backup.
  final int rank;

  final String? url;
  final String? externalProductId;
  final String? externalVariantId;

  /// What the supplier charges for the product itself.
  final Money? supplierPrice;

  /// What the supplier charges to ship it to a buyer.
  final Money? supplierShipping;

  /// Sales tax the supplier adds — on eBay US some suppliers charge it and
  /// some do not, so a break-even that ignores it is wrong for half of them.
  final Money? supplierTax;

  /// How many days the supplier takes to deliver; the estimated arrival.
  final int? shippingDays;

  /// Units the supplier reports in stock. Null means it did not say.
  final int? stock;

  /// When the seller last confirmed price and stock at the supplier.
  final DateTime? lastCheckedAt;

  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get isPrimary => rank == 1;

  SupplierProduct copyWith({
    String? title,
    String? itemId,
    int? rank,
    String? url,
    String? externalProductId,
    String? externalVariantId,
    Money? supplierPrice,
    Money? supplierShipping,
    Money? supplierTax,
    int? shippingDays,
    int? stock,
    DateTime? lastCheckedAt,
    DateTime? deletedAt,
    bool clearSupplierShipping = false,
    bool clearSupplierTax = false,
    bool clearStock = false,
  }) => SupplierProduct(
    id: id,
    sourceId: sourceId,
    title: title ?? this.title,
    createdAt: createdAt,
    itemId: itemId ?? this.itemId,
    rank: rank ?? this.rank,
    url: url ?? this.url,
    externalProductId: externalProductId ?? this.externalProductId,
    externalVariantId: externalVariantId ?? this.externalVariantId,
    supplierPrice: supplierPrice ?? this.supplierPrice,
    supplierShipping: clearSupplierShipping
        ? null
        : supplierShipping ?? this.supplierShipping,
    supplierTax: clearSupplierTax ? null : supplierTax ?? this.supplierTax,
    shippingDays: shippingDays ?? this.shippingDays,
    stock: clearStock ? null : stock ?? this.stock,
    lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );
}
