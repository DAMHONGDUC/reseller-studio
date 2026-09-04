import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_warning.dart';

/// What the record says that cannot all be true at once.
///
/// **One widget, drawn by the row and by the detail screen** — owner's rule.
/// A contradiction is something a seller has to find while scanning the list,
/// so it cannot live only on the screen they reach after going looking.
///
/// **A full-width line, never a compact badge.** The message names both halves
/// and asks for the fix, and shortening it to fit a badge row is how it
/// stopped saying anything.
class ItemWarningLines extends StatelessWidget {
  const ItemWarningLines({
    required this.item,
    required this.warnings,
    this.isCompact = false,
    super.key,
  });

  final Item item;

  /// Passed in rather than computed here, so the caller knows whether to open
  /// a gap above this widget without asking twice.
  final List<ItemWarning> warnings;

  /// The list row's size. The card is already carrying a title, four badges
  /// and three figures, so the sentence goes in at the size the money band's
  /// labels use.
  final bool isCompact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      for (final ItemWarning warning in warnings)
        _WarningLine(
          message: warning.message(context, item),
          color: warning.color(context),
          isCompact: isCompact,
        ),
    ],
  );
}

/// One contradiction, spelled out beside the glyph that flags it.
class _WarningLine extends StatelessWidget {
  const _WarningLine({
    required this.message,
    required this.color,
    required this.isCompact,
  });

  final String message;
  final Color color;
  final bool isCompact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SdIconV3(
          AppIconConstant.warning,
          color: color,
          size: isCompact ? SdIconV3.smallSize : SdIconV3.defaultSize,
        ),
        SizedBox(width: SdSpacingConstant.w6),
        Expanded(
          child: Text(
            message,
            style:
                (isCompact
                        ? context.textTheme3.bodySmall!
                        : context.textTheme3.bodyMedium!)
                    .semiBold3
                    .copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}
