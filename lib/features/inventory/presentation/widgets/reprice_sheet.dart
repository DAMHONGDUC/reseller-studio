import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/price_entry_sheet.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/services/listing_pricing.dart';
import '../../../listings/providers.dart';
import '../../domain/entities/item.dart';
import '../controllers/item_actions_controller.dart';

/// Move every marketplace price on one item, or on forty.
///
/// **The sheet itself is `PriceEntrySheet` in `core/widgets/`** — Listings
/// asks the same question about a different record, and one prompt shared is
/// what stops the two drifting into two. What stays here is everything that
/// is about *items*: which price to pre-fill, which controller writes, and
/// what "done" says.
///
/// The item has no price of its own, so what it writes is the price of every
/// listing the selection carries.
final class RepriceSheet {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    List<Item> items,
  ) {
    final int count = items.length;

    return PriceEntrySheet.show(
      context,
      title: count == 1
          ? context.l10n.repriceTitle
          : context.l10n.repriceTitleBulk(count),
      fieldLabel: context.l10n.repriceNewPrice,
      submitLabel: context.l10n.repriceSubmit,
      initialPrice: sharedPrice(
        ref.read(listingsProvider).value ?? const <Listing>[],
        items,
      ),
      helperText: count == 1 ? null : context.l10n.repriceBulkHelp,
      onSubmit: (Money price) => ref
          .read(itemActionsControllerProvider.notifier)
          .reprice(items, price),
    );
  }

  /// The price to start the field at, or null when the selection disagrees.
  ///
  /// **Null is the important case**: pre-filling a number that belongs to one
  /// of forty rows, and then applying it to all forty, is a silent bulk edit
  /// nobody asked for.
  static Money? sharedPrice(List<Listing> listings, List<Item> items) {
    final Set<String> itemIds = items.map((Item item) => item.id).toSet();

    return ListingPricing.sharedPrice(
      listings
          .where((Listing listing) => itemIds.contains(listing.itemId))
          .toList(growable: false),
    );
  }
}
