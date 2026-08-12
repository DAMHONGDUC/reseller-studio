import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../pricing/domain/services/profit_calculator.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';

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
    super.key,
  });

  final Item item;

  /// Passed in rather than read from the clock, so every row in one build
  /// agrees about what "stale" means and a widget test can pin it.
  final DateTime now;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isStale =
        item.status == ItemStatus.listed &&
        StaleInventoryPolicy.isStale(item.listedAt, now: now);

    return SdCardV3(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
                      label: _statusLabel(item.status),
                      tone: _statusTone(item.status),
                    ),
                    if (isStale)
                      const SdBadgeV3(
                        label: 'Stale',
                        tone: SdBadgeToneV3.warning,
                        icon: Symbols.hourglass_bottom_rounded,
                      ),
                    if (item.quantity > 1)
                      SdBadgeV3(label: '×${item.quantity}'),
                  ],
                ),
                SizedBox(height: SdSpacingConstant.h8),
                _PriceLine(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(ItemStatus status) => switch (status) {
    ItemStatus.draft => 'Draft',
    ItemStatus.inStock => 'In stock',
    ItemStatus.listed => 'Listed',
    ItemStatus.reserved => 'Reserved',
    ItemStatus.sold => 'Sold',
    ItemStatus.archived => 'Archived',
  };

  static SdBadgeToneV3 _statusTone(ItemStatus status) => switch (status) {
    ItemStatus.draft => SdBadgeToneV3.neutral,
    ItemStatus.inStock => SdBadgeToneV3.info,
    ItemStatus.listed => SdBadgeToneV3.success,
    ItemStatus.reserved => SdBadgeToneV3.warning,
    ItemStatus.sold => SdBadgeToneV3.neutral,
    ItemStatus.archived => SdBadgeToneV3.neutral,
  };
}
