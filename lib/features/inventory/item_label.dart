import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import 'domain/entities/item.dart';
import 'domain/entities/storage_location.dart';
import 'domain/enums/item_status.dart';

/// The words for an item's status, its condition and a location's level.
///
/// `domain/` holds no strings (hard rule 7): the enums carry the concepts and
/// this carries the language. It also replaces a `name`-to-title-case trick
/// that used to derive "New with tags" from `newWithTags` — clever, and wrong
/// the moment the app is read in Vietnamese.
final class ItemStatusLabel {
  static String of(BuildContext context, ItemStatus status) => switch (status) {
    ItemStatus.draft => context.l10n.itemStatusDraft,
    ItemStatus.inStock => context.l10n.itemStatusInStock,
    ItemStatus.sold => context.l10n.itemStatusSold,
    ItemStatus.archived => context.l10n.itemStatusArchived,
  };
}

/// **A value's colour lives on its own enum** — owner's rule, see
/// `docs/rules/DESIGN_SYSTEM.md`. One value, one colour, wherever it is drawn:
/// the tag on the item form and the badge on the card both ask this, so they
/// cannot come out as two shades of nearly the same thing.
extension ItemStatusColor on ItemStatus {
  /// **The four indices are chosen, not incidental**: grey for a draft that
  /// claims nothing, green for stock, blue for a sale, amber for a withdrawal.
  Color color(BuildContext context) => AppColors.tag(context, switch (this) {
    ItemStatus.draft => 7,
    ItemStatus.inStock => 0,
    ItemStatus.sold => 1,
    ItemStatus.archived => 5,
  });
}

/// The condition grades resellers actually use in listings.
final class ItemConditionLabel {
  static String of(BuildContext context, ItemCondition condition) =>
      switch (condition) {
        ItemCondition.newWithTags => context.l10n.conditionNewWithTags,
        ItemCondition.newWithoutTags => context.l10n.conditionNewWithoutTags,
        ItemCondition.likeNew => context.l10n.conditionLikeNew,
        ItemCondition.good => context.l10n.conditionGood,
        ItemCondition.fair => context.l10n.conditionFair,
        ItemCondition.poor => context.l10n.conditionPoor,
        ItemCondition.forParts => context.l10n.conditionForParts,
      };
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

/// Warehouse, shelf, bin.
final class LocationKindLabel {
  static String of(BuildContext context, LocationKind kind) => switch (kind) {
    LocationKind.warehouse => context.l10n.locationWarehouse,
    LocationKind.shelf => context.l10n.locationShelf,
    LocationKind.bin => context.l10n.locationBin,
  };
}

/// How long the item has been in the state it is in — `3d`, `5w`, `2mo`.
///
/// **The duration alone, next to the status badge that names the state.**
/// "Listed 84d" beside a badge already reading *Listed* says the word twice,
/// and the row has no width to spare for it.
final class ItemAgeLabel {
  static String of(Item item, {required DateTime now}) =>
      DateTimeUtils.compactAge(now.difference(item.stateSince));
}
