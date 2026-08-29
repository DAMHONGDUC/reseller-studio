import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_tag_hue.dart';

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

/// **How a status is shown lives on the status** — owner's rule: its words and
/// its colour, both on the enum, so a value is asked and there is exactly one
/// answer. Adding a state breaks these switches, which is the point.
extension ItemStatusDisplay on ItemStatus {
  String label(BuildContext context) => switch (this) {
    ItemStatus.draft => context.l10n.itemStatusDraft,
    ItemStatus.inStock => context.l10n.itemStatusInStock,
    ItemStatus.sold => context.l10n.itemStatusSold,
    ItemStatus.archived => context.l10n.itemStatusArchived,
  };

  /// **The four hues are chosen, not incidental**: grey for a draft that
  /// claims nothing, green for stock, blue for a sale, amber for a
  /// withdrawal.
  Color color(BuildContext context) => switch (this) {
    ItemStatus.draft => AppTagHue.grey,
    ItemStatus.inStock => AppTagHue.green,
    ItemStatus.sold => AppTagHue.blue,
    ItemStatus.archived => AppTagHue.amber,
  }.of(context);
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

/// How a grade is shown — its words, and its own colour.
///
/// **The hues run best-to-worst**, so the seven read as a scale: new is green,
/// for-parts is red. They are deliberately not the semantic tokens — "Fair" is
/// a grade, not a warning.
extension ItemConditionDisplay on ItemCondition {
  String label(BuildContext context) => switch (this) {
    ItemCondition.newWithTags => context.l10n.conditionNewWithTags,
    ItemCondition.newWithoutTags => context.l10n.conditionNewWithoutTags,
    ItemCondition.likeNew => context.l10n.conditionLikeNew,
    ItemCondition.good => context.l10n.conditionGood,
    ItemCondition.fair => context.l10n.conditionFair,
    ItemCondition.poor => context.l10n.conditionPoor,
    ItemCondition.forParts => context.l10n.conditionForParts,
  };

  Color color(BuildContext context) => switch (this) {
    ItemCondition.newWithTags => AppTagHue.green,
    ItemCondition.newWithoutTags => AppTagHue.blue,
    ItemCondition.likeNew => AppTagHue.violet,
    ItemCondition.good => AppTagHue.indigo,
    ItemCondition.fair => AppTagHue.teal,
    ItemCondition.poor => AppTagHue.amber,
    ItemCondition.forParts => AppTagHue.red,
  }.of(context);
}
