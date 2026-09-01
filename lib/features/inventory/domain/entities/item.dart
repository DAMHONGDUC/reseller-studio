import '../../../../core/money/money.dart';
import '../enums/item_status.dart';

/// A single piece of inventory — the centre of the whole product.
///
/// **Only [id], [title], [quantity] and [status] are non-nullable**, and that
/// is hard rule 2 expressed as a type. Quick Add creates an item from a title
/// alone; everything else is something the seller may fill in later, or never.
/// A required `purchasePrice` here would make the fast path impossible and
/// turn the app into the spreadsheet it replaces.
///
/// [purchaseId] and [sourceId] are how an item joins the chain
/// `Source → Purchase → Item`. Both nullable: the item photographed in a car
/// park has neither, and it is still a perfectly good item.
class Item {
  const Item({
    required this.id,
    required this.title,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.purchasePrice,
    this.askingPrice,
    this.minimumPrice,
    this.purchaseId,
    this.sourceId,
    this.categoryId,
    this.locationId,
    this.sku,
    this.barcode,
    this.condition,
    this.description,
    this.notes,
    this.photoUrls = const <String>[],
    this.purchaseDate,
    this.listedAt,
    this.soldAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final int quantity;
  final ItemStatus status;
  final DateTime createdAt;

  /// When the record last changed, or null for one nothing has touched since
  /// it was written.
  ///
  /// **Stamped by whoever saves, not derived** — Firestore writes it as a
  /// server timestamp, so two devices editing the same item cannot disagree
  /// about which edit was later. It is read-only everywhere in the app: no
  /// form offers it, because a date the seller can type is not a record of
  /// anything.
  final DateTime? updatedAt;

  /// What the seller paid. **Null means nobody entered it**, not zero — every
  /// profit figure derived from this item is then `—` rather than wrong. See
  /// `Money`'s class doc and hard rule 5.
  final Money? purchasePrice;

  /// What it is listed at, or what the seller intends to list at.
  final Money? askingPrice;

  /// The floor for offers and bulk repricing. A seller who sets this can
  /// accept offers automatically without watching them.
  final Money? minimumPrice;

  /// Denormalised from the purchase — see `docs/DATA_MODEL.md`. Inventory
  /// sorts and filters by these, and Firestore cannot order by a field on a
  /// referenced document.
  final String? purchaseId;
  final String? sourceId;
  final DateTime? purchaseDate;

  final String? categoryId;
  final String? locationId;
  final String? sku;
  final String? barcode;
  final ItemCondition? condition;
  final String? description;
  final String? notes;
  final List<String> photoUrls;

  /// When it first went live anywhere. What staleness is measured from — see
  /// `StaleInventoryPolicy`.
  final DateTime? listedAt;

  final DateTime? soldAt;

  /// Soft delete (hard rule 15). Non-null means gone from every list, but
  /// still joinable by the purchases and orders that reference it.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Expected profit if it sells at [askingPrice], or null when either the
  /// cost or the asking price is unknown.
  ///
  /// **Ignores fees and shipping on purpose** — those depend on which
  /// marketplace it sells on, which is not known until it sells. This is the
  /// rough number for an inventory row; `ProfitBreakdown` is the real one for
  /// a completed order.
  Money? get expectedProfit {
    final Money? cost = purchasePrice;
    final Money? asking = askingPrice;

    if (cost == null || asking == null) return null;

    return asking - cost;
  }

  /// How many are still on the shelf.
  ///
  /// **Zero once the item is sold or archived, whatever [quantity] says.**
  /// The field records how many were taken in; a row asking "what is left"
  /// must not answer with that number after the last one went out the door.
  /// This is a known zero, not a missing figure — hard rule 5 is about the
  /// difference.
  int get quantityOnHand => status.isOnHand ? quantity : 0;

  /// When the item entered the state it is in now — what "how long has this
  /// sat?" is measured from.
  ///
  /// Sold reads from [soldAt], stock from [listedAt] when it has one,
  /// everything else from [createdAt]. One timestamp per state, so a row can
  /// show an age without each screen picking its own field and disagreeing
  /// about what it means.
  DateTime get stateSince => switch (status) {
    ItemStatus.sold => soldAt ?? createdAt,
    // On the shelf and live somewhere: how long it has been sitting is
    // measured from the day it went up, not the day it was entered.
    ItemStatus.inStock => listedAt ?? createdAt,
    _ => createdAt,
  };

  /// The value this item contributes to inventory worth — its cost, times how
  /// many are on hand.
  ///
  /// **Cost, not asking price.** Inventory value at retail is a number that
  /// flatters the seller and is wrong for insurance and tax, which is what
  /// the figure is actually used for.
  Money? get inventoryValue {
    final Money? cost = purchasePrice;

    if (cost == null || !status.isOnHand) return null;

    return cost * quantity;
  }

  /// **A null argument means "leave it alone", never "clear it"** — which is
  /// why unsetting a field needs its own flag.
  ///
  /// [clearSoldAt] was the first: an item back on the shelf still carrying a
  /// sold date reads as sold in an export. The rest arrived with the detail
  /// screen's editable sections, where emptying a box *is* the seller
  /// removing the value — a meaning a bare null cannot carry.
  Item copyWith({
    String? title,
    int? quantity,
    ItemStatus? status,
    Money? purchasePrice,
    Money? askingPrice,
    Money? minimumPrice,
    String? sourceId,
    String? categoryId,
    String? locationId,
    String? sku,
    String? barcode,
    ItemCondition? condition,
    String? description,
    String? notes,
    List<String>? photoUrls,
    DateTime? purchaseDate,
    DateTime? listedAt,
    DateTime? soldAt,
    DateTime? deletedAt,
    DateTime? updatedAt,
    bool clearSoldAt = false,
    bool clearPurchasePrice = false,
    bool clearAskingPrice = false,
    bool clearMinimumPrice = false,
    bool clearBarcode = false,
    bool clearDescription = false,
    bool clearNotes = false,
  }) => Item(
    id: id,
    title: title ?? this.title,
    quantity: quantity ?? this.quantity,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    purchasePrice: clearPurchasePrice
        ? null
        : purchasePrice ?? this.purchasePrice,
    askingPrice: clearAskingPrice ? null : askingPrice ?? this.askingPrice,
    minimumPrice: clearMinimumPrice ? null : minimumPrice ?? this.minimumPrice,
    purchaseId: purchaseId,
    sourceId: sourceId ?? this.sourceId,
    categoryId: categoryId ?? this.categoryId,
    locationId: locationId ?? this.locationId,
    sku: sku ?? this.sku,
    barcode: clearBarcode ? null : barcode ?? this.barcode,
    condition: condition ?? this.condition,
    description: clearDescription ? null : description ?? this.description,
    notes: clearNotes ? null : notes ?? this.notes,
    photoUrls: photoUrls ?? this.photoUrls,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    listedAt: listedAt ?? this.listedAt,
    soldAt: clearSoldAt ? null : soldAt ?? this.soldAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );
}
