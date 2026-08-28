import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/app_photo.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../../pricing/domain/services/profit_calculator.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';
import '../../item_label.dart';

part 'item_card_headline.dart';
part 'item_card_marketplaces.dart';
part 'item_card_money_cell.dart';
part 'item_card_money_line.dart';
part 'item_card_state_badges.dart';
part 'item_card_thumbnail.dart';

/// One row of Inventory.
///
/// **Two zones.** Across the top, what the item *is*: its photo, its title,
/// the asking price at the end of that line, and the badges naming its state.
/// Underneath, at the card's own edges, what it is *worth*: cost against
/// expected profit, then the marketplaces it is live on. Everything else is
/// on the detail screen.
///
/// The split is what makes the figures fit. Held inside the top row they had
/// a 64pt photo on one side and a 36pt button on the other, so the profit
/// ellipsized on a $1,299 item; given the full width they do not.
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
    this.isSelected = false,
    this.isSelecting = false,
    super.key,
  });

  final Item item;

  /// This item's live listings, for the marketplace badges.
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
          // Two zones, and the split is what buys the width back: what the
          // item IS across the top, what it is WORTH underneath, where the
          // figures start at the card's own edge instead of after a 64pt
          // photo and end before a 36pt button.
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
                    _Headline(item: item),
                    SizedBox(height: SdSpacingConstant.h6),
                    _StateBadges(item: item, now: now),
                  ],
                ),
              ),
              if (onActions != null && !isSelecting)
                _ActionsButton(onPressed: onActions!),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h10),
          _MoneyLine(item: item),
          _Marketplaces(listings: listings),
        ],
      ),
    ),
  );
}

/// The row's way into `ItemActionsSheet`.
///
/// **`more_vert`, not the detail screen's `tune`** — owner's rule. A glyph is
/// all the width allows next to a title, two badges and a price line, so it
/// has to be one a seller already knows, and the overflow dots are what every
/// list row on the platform uses to mean "more you can do to this". `tune`
/// reads as filtering when it is not sitting beside the word Actions.
///
/// **The glyph sits on the card's content edge, not an `IconButton`'s worth
/// further in.** A default `IconButton` centres its icon in a 48pt box, which
/// put these dots 17 points inside where every `AppRowChevron` sits — a
/// column of end glyphs that does not line up reads as a mistake even to
/// somebody who cannot say which card is wrong. The tap target is bought back
/// in height rather than width, so it stays comfortable without moving the
/// glyph off the edge.
class _ActionsButton extends StatelessWidget {
  const _ActionsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.l10n.itemActions,
    child: InkWell(
      onTap: onPressed,
      borderRadius: SdRadiusV3.cardAll,
      // The box is wide enough to hit and the glyph is pinned to its right
      // edge, so the tap area grows inward while the dots stay on the card's
      // content edge. `IconButton` cannot do this: Material 3 builds it from
      // a `ButtonStyle` and ignores `constraints`, so its 48pt target centres
      // the glyph 16 points short of where it belongs.
      child: SizedBox(
        width: SdSpacingConstant.r36,
        height: SdSpacingConstant.r44,
        child: Align(
          alignment: Alignment.centerRight,
          child: SdIconV3(
            AppIconConstant.moreVert,
            size: SdIconV3.smallSize,
            color: context.sdTheme3.textTertiary,
          ),
        ),
      ),
    ),
  );
}
