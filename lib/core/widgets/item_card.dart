import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../features/inventory/domain/entities/item.dart';
import '../../features/inventory/domain/enums/item_status.dart';
import '../../features/inventory/domain/enums/item_warning.dart';
import '../../features/inventory/domain/services/item_consistency.dart';
import '../../features/listings/domain/entities/listing.dart';
import '../../features/listings/domain/services/listing_marketplaces.dart';
import '../../features/pricing/domain/services/profit_calculator.dart';
import '../constants/app_icon_constant.dart';
import '../constants/item_card_metric_constant.dart';
import '../extensions/context_extensions.dart';
import '../utils/date_time_utils.dart';
import 'app_photo.dart';
import 'app_row_chevron.dart';
import 'app_row_icon_button.dart';

part 'item_card_marketplaces.dart';
part 'item_card_money_cell.dart';
part 'item_card_money_line.dart';
part 'item_card_state_badges.dart';
part 'item_card_updated.dart';
part 'item_card_thumbnail.dart';

/// One row of Inventory.
///
/// **Two zones.** Beside the photo, what the item *is*: its title, the compact
/// tags naming its state, grade and marketplace count, and the date the record
/// last changed. Below, running to the card's own left edge, what it is
/// *worth*: how many are left and what they cost, then the way into what each
/// marketplace is asking. Everything else is on the detail screen.
///
/// The figures start at the edge rather than after the photo — owner's rule.
/// It gives them the card's full width, and it separates the two questions
/// the row answers instead of running them into one column.
///
/// **The actions sheet opens from the row, not only from the detail screen**
/// — owner's rule. Listing, repricing and marking sold are what a seller does
/// while looking at the list; making each one cost a push into detail and a
/// pop back out is how a forty-row afternoon turns into eighty extra taps.
/// It is the same sheet the detail screen opens, so a verb added there cannot
/// go missing here.
class ItemCard extends StatelessWidget {
  const ItemCard({
    required this.item,
    required this.now,
    this.listings = const <Listing>[],
    this.onTap,
    this.onLongPress,
    this.onActions,
    this.onMarketPrices,
    this.isSelected = false,
    this.isSelecting = false,
    this.notice,
    super.key,
  });

  final Item item;

  /// This item's live listings, for the distinct marketplace count.
  ///
  /// **Passed in, not watched per card.** The list groups one `listingsProvider`
  /// read by item id; a family watch on every row would be one subscription
  /// per card and a rebuild storm on any listing write.
  final List<Listing> listings;

  /// Passed in rather than read from the clock, so every row in one build
  /// agrees about what "stale" means and a widget test can pin it.
  final DateTime now;

  final VoidCallback? onTap;

  /// Starts a bulk selection (hard rule 16). Long-press rather than a mode
  /// button in the app bar: the row a seller wants is the one under their
  /// thumb, and reaching for a toggle first loses it.
  final VoidCallback? onLongPress;

  /// Opens the item's actions sheet. Null on a list that only navigates.
  ///
  /// **Hidden while a selection is open**: every tap ticks a row then, and a
  /// button that opened a sheet for one item mid-bulk-edit would lose the
  /// forty rows the seller had just picked.
  final VoidCallback? onActions;

  /// Opens the cross-list screen, where every marketplace's own price is.
  ///
  /// **The card does not push the route itself** — the same reason [onTap] is
  /// a callback: a widget that knows its destination cannot be put on a
  /// screen that wants another one. Null on a list that only navigates, and
  /// ignored while a selection is open.
  final VoidCallback? onMarketPrices;

  final bool isSelected;

  /// True once *any* row is ticked, so every row shows its checkbox rather
  /// than only the selected one — a list where the boxes appear one at a time
  /// gives no sign that tapping now selects instead of opening.
  final bool isSelecting;

  /// Something this row has to say that is not on the record itself — the
  /// sale picker's reason an item cannot be sold.
  ///
  /// **Drawn only when the item has no warning of its own**, so one row never
  /// states the same problem twice. **The card is never drawn dead** — a
  /// blocked row keeps every gesture and explains when tapped
  /// (`lib/features/orders/CLAUDE.md`).
  final String? notice;

  @override
  // The long-press wraps the card rather than living on it: `SdCardV3` takes
  // a tap and nothing else, and giving the design system a second gesture for
  // one screen's benefit is the wrong direction of dependency.
  Widget build(BuildContext context) {
    final List<ItemWarning> warnings = ItemConsistency.warnings(item);

    return GestureDetector(
      onLongPress: onLongPress,
      child: SdCardV3(
        onTap: onTap,
        // - selected: outlined as well as ticked, so colour is never the
        //   only signal
        // - stale: the warning edge repeats the Stale badge on the card
        borderColor: isSelected
            ? context.colorScheme3.primary
            : _StateBadges.isStale(item, now)
            ? context.sdTheme3.warning
            : null,
        // The card holds no inset of its own: the hairline between its two
        // zones runs edge to edge, so the padding belongs to the zones it
        // separates rather than to the card around both of them.
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // The money band runs to the card's own left edge — owner's rule —
            // so the Row above holds only what sits beside the photo.
            Padding(
              padding: SdContentPaddingV3.card.copyWith(
                bottom: ItemCardMetricConstant.bandGap,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (isSelecting) ...<Widget>[
                    SdIconV3(
                      isSelected
                          ? AppIconConstant.checkCircle
                          : AppIconConstant.radioButtonUnchecked,
                      color: isSelected
                          ? context.colorScheme3.primary
                          : context.sdTheme3.textTertiary,
                      semanticLabel: isSelected
                          ? context.l10n.inventorySelected
                          : context.l10n.inventoryNotSelected,
                    ),
                    SizedBox(width: SdSpacingConstant.w12),
                  ],
                  _Thumbnail(item: item),
                  SizedBox(width: SdSpacingConstant.w12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.title,
                          style: context.textTheme3.bodyLarge!.semiBold3
                              .copyWith(color: context.sdTheme3.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: ItemCardMetricConstant.titleGap),
                        _StateBadges(item: item, now: now, listings: listings),
                        _UpdatedLine(
                          item: item,
                          warnings: warnings,
                          notice: notice,
                        ),
                      ],
                    ),
                  ),
                  // `more_vert`, not the detail screen's `tune` — owner's rule.
                  // A glyph is all the width allows next to a title and a price,
                  // so it has to be one a seller already knows.
                  if (onActions != null && !isSelecting)
                    AppRowIconButton(
                      icon: AppIconConstant.moreVert,
                      tooltip: context.l10n.commonActions,
                      onPressed: onActions!,
                    ),
                ],
              ),
            ),
            // Edge to edge, with no gap of its own — owner's rule. A hairline
            // that stops short of the card reads as a line drawn on the
            // content; one that crosses it is the card's two zones. The air
            // around it is the zones' padding, the way `AppListCard` does it.
            const SdDividerV3(),
            Padding(
              padding: SdContentPaddingV3.card.copyWith(
                top: ItemCardMetricConstant.bandGap,
              ),
              child: _MoneyLine(
                item: item,
                onMarketPrices: isSelecting ? null : onMarketPrices,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
