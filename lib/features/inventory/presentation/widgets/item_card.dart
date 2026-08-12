import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../pricing/domain/services/profit_calculator.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';

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
  const ItemCard({required this.item, required this.now, this.onTap, super.key});

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

/// Cost and asking price, side by side.
///
/// Both render `—` when unknown, which is most of the point: an item added
/// through Quick Add has neither, and the row must say so rather than imply
/// the item is free.
class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.item});

  final Item item;

  // Every cell is Flexible and every value ellipsizes. A fixed Row overflowed
  // by 35px once the amounts grew — money strings are as long as the numbers
  // in them, and a card cannot get wider.
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Flexible(
        child: _PriceCell(
          label: 'Cost',
          value: context.money(item.purchasePrice),
          color: context.sdTheme3.textSecondary,
        ),
      ),
      SizedBox(width: SdSpacingConstant.w12),
      Flexible(
        child: _PriceCell(
          label: 'Asking',
          value: context.money(item.askingPrice),
          color: context.sdTheme3.textPrimary,
        ),
      ),
      if (item.expectedProfit != null) ...<Widget>[
        SizedBox(width: SdSpacingConstant.w12),
        Flexible(
          child: _PriceCell(
            label: 'Profit',
            value: context.money(item.expectedProfit),
            color: item.expectedProfit!.isNegative
                ? context.sdTheme3.loss
                : context.sdTheme3.profit,
          ),
        ),
      ],
    ],
  );
}

class _PriceCell extends StatelessWidget {
  const _PriceCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        label,
        style: context.textTheme3.bodySmall!.faint3(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        value,
        style: context.textTheme3.bodyMedium!.semiBold3.tabular3.copyWith(
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

/// The item's photo, or a placeholder well.
///
/// A placeholder rather than nothing: without it, rows with photos and rows
/// without would have different heights and the list would look broken.
///
/// Deliberately larger than the icon tiles elsewhere — in a list of physical
/// objects the picture is what a seller recognises a row by, so it earns the
/// space even while it is still a placeholder.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final Item item;

  static double get size => SdSpacingConstant.r64;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.sdTheme3.surfaceSunken,
      borderRadius: SdRadiusV3.thumbnailAll,
      border: Border.all(color: context.sdTheme3.divider),
    ),
    alignment: Alignment.center,
    child: SdIconV3(
      Symbols.image_rounded,
      size: SdIconV3.defaultSize,
      color: context.sdTheme3.textTertiary,
    ),
  );
}
