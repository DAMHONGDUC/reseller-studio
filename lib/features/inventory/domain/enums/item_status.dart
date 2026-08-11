/// Where an item is in its life (plan §29).
///
/// ```text
/// draft → inStock → listed → reserved → sold
///                     ↑         │
///                     └─────────┘   (offer declined / expired)
/// ```
///
/// **`stale` is deliberately not here.** Stale is a *query* — listed, and
/// listed a long time ago — not a state something transitions into. As a
/// status it would need a nightly job flipping thousands of documents, and a
/// seller who repriced would wait for that job before the item left the Stale
/// tab. See `StaleInventoryPolicy` and `docs/DATA_MODEL.md`.
enum ItemStatus {
  /// Created but not yet part of sellable inventory. What Quick Add produces
  /// when only a title was given.
  draft,

  /// On the shelf, not listed anywhere.
  inStock,

  /// Live on at least one marketplace.
  listed,

  /// An offer was accepted, or a buyer is committed, but the sale has not
  /// completed. Held back from other listings so it cannot be sold twice.
  reserved,

  /// Sold. Terminal for the item, though the order may still be in flight.
  sold,

  /// Withdrawn from inventory without a sale — damaged, lost, kept, returned
  /// to the source. Excluded from inventory value and sell-through.
  archived;

  /// Statuses that count toward inventory the seller still owns.
  ///
  /// `sold` and `archived` are out: neither is on the shelf, and counting
  /// them would overstate inventory value, which is a number sellers use for
  /// insurance and tax.
  bool get isOnHand => switch (this) {
    ItemStatus.draft ||
    ItemStatus.inStock ||
    ItemStatus.listed ||
    ItemStatus.reserved => true,
    ItemStatus.sold || ItemStatus.archived => false,
  };

  /// Whether this item can be listed on a marketplace right now.
  bool get isListable => this == ItemStatus.draft || this == ItemStatus.inStock;
}

/// The condition grades resellers actually use in listings.
///
/// Deliberately the vocabulary the marketplaces share, so cross-listing does
/// not have to invent a mapping for every platform on day one.
enum ItemCondition {
  newWithTags,
  newWithoutTags,
  likeNew,
  good,
  fair,
  poor,
  forParts,
}
