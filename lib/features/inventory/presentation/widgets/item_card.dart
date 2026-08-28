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

part 'item_card_marketplaces.dart';
part 'item_card_money_cell.dart';
part 'item_card_money_line.dart';
part 'item_card_state_badges.dart';
part 'item_card_thumbnail.dart';

/// One row of Inventory.
///
/// **Two zones.** Beside the photo, what the item *is*: its title and the
/// badges naming its state. Below, running to the card's own left edge, what
/// it is *worth*: what it cost, what it is being asked for, and the
/// marketplaces it is live on. Everything else is on the detail screen.
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
                    _StateBadges(item: item, now: now),
                    _Marketplaces(listings: listings),
                  ],
                ),
              ),
              if (onActions != null && !isSelecting)
                _ActionsButton(onPressed: onActions!),
            ],
          ),
          // The rule makes the band deliberate rather than a block that
          // happens to start further left than everything above it.
          SdDividerV3(gap: SdSpacingConstant.h12),
          _MoneyLine(item: item),
        ],
      ),
    ),
  );
}

/// The row's way into `ItemActionsSheet`.
///
/// **`more_vert`, not the detail screen's `tune`** — owner's rule. A glyph is
/// all the width allows next to a title and a price, so it has to be one a
/// seller already knows, and the overflow dots are what every list row on the
/// platform uses to mean "more you can do to this". `tune` reads as filtering
/// when it is not sitting beside the word Actions.
///
/// **A round 44pt target, centred on the glyph** — owner's rule. The button
/// was a 36×44 box with the dots pinned to its right edge: a squeezed target,
/// and a ripple that came up as a rounded rectangle nowhere near the thing it
/// was acknowledging. `InkResponse` with a circular highlight is what an
/// icon-only control looks like everywhere else on the platform.
///
/// **The glyph still sits on the card's content edge**, where every
/// `AppRowChevron` sits — a column of end glyphs that does not line up reads
/// as a mistake even to somebody who cannot say which card is wrong. So the
/// target is centred on the glyph and the whole button is nudged outward by
/// what centring cost it, overhanging the card's padding rather than pushing
/// the dots inward. That is also why it is not an `IconButton`: Material 3
/// builds one from a `ButtonStyle` and ignores `constraints`, so its 48pt
/// target centres the glyph well short of where it belongs.
class _ActionsButton extends StatelessWidget {
  const _ActionsButton({required this.onPressed});

  final VoidCallback onPressed;

  /// Half the glyph's own width, which is the gap centring leaves between it
  /// and the target's edge — and therefore exactly how far the target has to
  /// move to put the glyph back on the card's content edge.
  static double get _edgeNudge =>
      (SdSpacingConstant.r44 - SdIconV3.smallSize) / 2;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: Offset(_edgeNudge, 0),
    child: Tooltip(
      message: context.l10n.itemActions,
      child: InkResponse(
        onTap: onPressed,
        radius: SdSpacingConstant.r22,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: SdSpacingConstant.r44,
          height: SdSpacingConstant.r44,
          child: Center(
            child: SdIconV3(
              AppIconConstant.moreVert,
              size: SdIconV3.smallSize,
              color: context.sdTheme3.textTertiary,
            ),
          ),
        ),
      ),
    ),
  );
}
