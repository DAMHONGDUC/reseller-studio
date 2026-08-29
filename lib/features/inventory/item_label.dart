import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
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
/// **The duration alone, above the marketplace count.** Repeating the status
/// name would add words without adding information, and the card has no width
/// to spare for them.
final class ItemAgeLabel {
  static String of(Item item, {required DateTime now}) =>
      DateTimeUtils.compactAge(now.difference(item.stateSince));
}
