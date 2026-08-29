import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Where an item is in its life (plan §29).
///
/// ```text
/// draft → inStock → sold
///            ↓
///        archived
/// ```
///
/// **Four states, and the count is what moves between the last two** —
/// owner's rule. `listed` and `reserved` were removed: an item live on a
/// marketplace is still stock the seller owns, so it is `inStock` with
/// listings beside it, and `listedAt` — not a status — is what staleness is
/// measured from. A document written before that reads back as [inStock].
///
/// **`stale` is deliberately not here either.** Stale is a *query* — on hand,
/// and listed a long time ago — not a state something transitions into. As a
/// status it would need a nightly job flipping thousands of documents, and a
/// seller who repriced would wait for that job before the item left the Stale
/// tab. See `StaleInventoryPolicy` and `docs/DATA_MODEL.md`.
enum ItemStatus {
  /// Created but not yet part of sellable inventory. What Quick Add produces
  /// when only a title was given.
  draft,

  /// On the shelf and for sale — whether or not it is live on a marketplace.
  inStock,

  /// Sold out: the count reached zero through sales. Terminal until the
  /// seller restocks, though the orders may still be in flight.
  sold,

  /// Withdrawn from inventory without a sale — damaged, lost, kept, returned
  /// to the source. Excluded from inventory value and sell-through.
  archived;

  /// Statuses that count toward inventory the seller still owns.
  ///
  /// `sold` and `archived` are out: neither is on the shelf, and counting
  /// them would overstate inventory value, which is a number sellers use for
  /// insurance and tax.
  bool get isOnHand => this == ItemStatus.draft || this == ItemStatus.inStock;

  /// Whether the item may be put on a marketplace right now.
  ///
  /// A draft can be: listing it is what makes it stock. What cannot is an
  /// item that has left inventory.
  bool get isListable => isOnHand;
}

/// **A status's colour lives on the status** — owner's rule. One value, one
/// colour, wherever it is drawn: the radio on the item form and the badge on
/// the card both ask this, so they cannot come out as two shades of nearly
/// the same thing. Adding a state breaks this switch, which is the point.
///
/// **The four hues are chosen, not incidental**: grey for a draft that claims
/// nothing, green for stock, blue for a sale, amber for a withdrawal.
extension ItemStatusColor on ItemStatus {
  Color color(BuildContext context) => AppColors.tag(context, switch (this) {
    ItemStatus.draft => 7,
    ItemStatus.inStock => 0,
    ItemStatus.sold => 1,
    ItemStatus.archived => 5,
  });
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

/// The grade's own colour, best to worst.
///
/// **The palette is ordered light-to-serious**, so the seven grades read as a
/// scale by index alone: new is green, for-parts is red. They are deliberately
/// not the semantic tokens — "Fair" is a grade, not a warning.
extension ItemConditionColor on ItemCondition {
  Color color(BuildContext context) => AppColors.tag(context, switch (this) {
    ItemCondition.newWithTags => 0,
    ItemCondition.newWithoutTags => 1,
    ItemCondition.likeNew => 2,
    ItemCondition.good => 3,
    ItemCondition.fair => 4,
    ItemCondition.poor => 5,
    ItemCondition.forParts => 6,
  });
}
