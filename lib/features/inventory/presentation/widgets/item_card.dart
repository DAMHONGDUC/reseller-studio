import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_photo.dart';
import '../../../pricing/domain/services/profit_calculator.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';
import '../../item_label.dart';

part 'item_card_price_cell.dart';
part 'item_card_price_line.dart';
part 'item_card_thumbnail.dart';

/// One row of Inventory.
///
/// Shows the four things a seller scans a list for: **what it is, what state
/// it is in, what it costs, what it is priced at.** Everything else is on the
/// detail screen.
///
/// The status badge and the stale badge are separate, and both can be
/// present: an item can be listed *and* stale, and collapsing that into one
/// marker would lose the fact that it is still live and still earning
/// nothing.
class ItemCard extends StatelessWidget {
  const ItemCard({
    required this.item,
    required this.now,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelecting = false,
    super.key,
  });

  final Item item;

  /// Passed in rather than read from the clock, so every row in one build
  /// agrees about what "stale" means and a widget test can pin it.
  final DateTime now;

  final VoidCallback? onTap;

  /// Starts a bulk selection (hard rule 16). Long-press rather than a mode
  /// button in the app bar: the row a seller wants is the one under their
  /// thumb, and reaching for a toggle first loses it.
  final VoidCallback? onLongPress;

  final bool isSelected;

  /// True once *any* row is ticked, so every row shows its checkbox rather
  /// than only the selected one — a list where the boxes appear one at a time
  /// gives no sign that tapping now selects instead of opening.
  final bool isSelecting;

  @override
  Widget build(BuildContext context) {
    final bool isStale =
        item.status == ItemStatus.listed &&
        StaleInventoryPolicy.isStale(item.listedAt, now: now);

    // The long-press wraps the card rather than living on it: `SdCardV3` takes
    // a tap and nothing else, and giving the design system a second gesture
    // for one screen's benefit is the wrong direction of dependency.
    return GestureDetector(
      onLongPress: onLongPress,
      child: SdCardV3(
        onTap: onTap,
        // Outlined as well as ticked: colour is never the only signal, and
        // the tick is never the only one either.
        borderColor: isSelected ? context.colorScheme3.primary : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (isSelecting) ...<Widget>[
              SdIconV3(
                isSelected
                    ? Symbols.check_circle_rounded
                    : Symbols.radio_button_unchecked_rounded,
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
                  Wrap(
                    spacing: SdSpacingConstant.w6,
                    runSpacing: SdSpacingConstant.h4,
                    children: <Widget>[
                      SdBadgeV3(
                        label: ItemStatusLabel.of(context, item.status),
                        tone: _statusTone(item.status),
                      ),
                      if (isStale)
                        SdBadgeV3(
                          label: context.l10n.itemStale,
                          tone: SdBadgeToneV3.warning,
                          icon: Symbols.hourglass_bottom_rounded,
                        ),
                      if (item.quantity > 1)
                        SdBadgeV3(
                          label: context.l10n.itemQuantityTimes(item.quantity),
                        ),
                    ],
                  ),
                  SizedBox(height: SdSpacingConstant.h8),
                  _PriceLine(item: item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static SdBadgeToneV3 _statusTone(ItemStatus status) => switch (status) {
    ItemStatus.draft => SdBadgeToneV3.neutral,
    ItemStatus.inStock => SdBadgeToneV3.info,
    ItemStatus.listed => SdBadgeToneV3.success,
    ItemStatus.reserved => SdBadgeToneV3.warning,
    ItemStatus.sold => SdBadgeToneV3.neutral,
    ItemStatus.archived => SdBadgeToneV3.neutral,
  };
}
