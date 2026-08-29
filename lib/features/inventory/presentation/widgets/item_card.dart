import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/app_photo.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../pricing/domain/services/profit_calculator.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';

part 'item_card_icon_button.dart';
part 'item_card_marketplaces.dart';
part 'item_card_money_cell.dart';
part 'item_card_money_line.dart';
part 'item_card_state_badges.dart';
part 'item_card_updated.dart';
part 'item_card_thumbnail.dart';

/// One row of Inventory.
///
/// **Two zones.** Beside the photo, what the item *is*: its title and the
/// compact tags naming its state, grade and marketplace count. Below, running
/// to the card's own left edge, what it is *worth*: how many are left, what
/// they cost and what they are being asked for — then when the record last
/// changed. Everything else is on the detail screen.
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

  @override
  // The long-press wraps the card rather than living on it: `SdCardV3` takes
  // a tap and nothing else, and giving the design system a second gesture for
  // one screen's benefit is the wrong direction of dependency.
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: onLongPress,
    child: SdCardV3(
      onTap: onTap,
      // Outlined as well as ticked: colour is never the only signal, and
      // the tick is never the only one either.
      borderColor: isSelected ? context.colorScheme3.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The money band runs to the card's own left edge — owner's rule —
          // so the Row above holds only what sits beside the photo.
          Row(
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
                      style: context.textTheme3.bodyLarge!.semiBold3.copyWith(
                        color: context.sdTheme3.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SdSpacingConstant.h6),
                    _StateBadges(item: item, now: now, listings: listings),
                  ],
                ),
              ),
              // `more_vert`, not the detail screen's `tune` — owner's rule.
              // A glyph is all the width allows next to a title and a price,
              // so it has to be one a seller already knows.
              if (onActions != null && !isSelecting)
                _CardIconButton(
                  icon: AppIconConstant.moreVert,
                  tooltip: context.l10n.commonActions,
                  onPressed: onActions!,
                ),
            ],
          ),
          // The rule makes the band deliberate rather than a block that
          // happens to start further left than everything above it.
          SdDividerV3(gap: SdSpacingConstant.h12),
          _MoneyLine(
            item: item,
            onMarketPrices: isSelecting ? null : onMarketPrices,
          ),
          _UpdatedLine(item: item),
        ],
      ),
    ),
  );
}
