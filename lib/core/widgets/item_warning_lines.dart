import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../features/inventory/domain/entities/item.dart';
import '../../features/inventory/domain/enums/item_warning.dart';
import '../constants/app_icon_constant.dart';

/// What the record says that cannot all be true at once.
///
/// **The sentence, for a screen with room for one.** The inventory row flags
/// the same thing as a tag beside its update date — short, because a row's job
/// is to be scanned (`lib/features/inventory/CLAUDE.md`); this is where the
/// contradiction is named in full.
class ItemWarningLines extends StatelessWidget {
  const ItemWarningLines({
    required this.item,
    required this.warnings,
    super.key,
  });

  final Item item;

  /// Passed in rather than computed here, so the caller knows whether to open
  /// a gap above this widget without asking twice.
  final List<ItemWarning> warnings;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      for (final ItemWarning warning in warnings)
        AppWarningLine(
          message: warning.message(context, item),
          color: warning.color(context),
        ),
    ],
  );
}

/// One thing a row is trying to tell the seller, beside the glyph that flags
/// it.
///
/// **Public, because two kinds of message use it** — a record that contradicts
/// itself, and a sale picker row saying why it cannot be sold. One shape, so a
/// seller learns to read it once.
class AppWarningLine extends StatelessWidget {
  const AppWarningLine({required this.message, required this.color, super.key});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SdIconV3(AppIconConstant.warning, color: color),
        SizedBox(width: SdSpacingConstant.w6),
        Expanded(
          child: Text(
            message,
            // Small — owner's rule: `bodySmall` is the floor of the scale. A
            // warning is a fact the screen carries, not a headline.
            style: context.textTheme3.bodySmall!.semiBold3.copyWith(
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}
