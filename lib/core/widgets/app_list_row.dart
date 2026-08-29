import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import 'app_row_chevron.dart';

/// The row every list of records in this app is made of.
///
/// Categories, locations, sources, expenses, team members, marketplaces,
/// settings — all the same shape: an optional glyph, a title, a supporting
/// line, and something on the right. Written once, in `core/widgets/`, because
/// the second copy is the trigger and there were going to be seven.
///
/// **A list of physical things does not use this** — items and orders get a
/// thumbnail card instead, because sellers recognise a row by the picture
/// (`docs/rules/DESIGN_SYSTEM.md`).
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconTint,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.onLongPress,
    this.showChevron = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// The tint behind [icon]. Defaults to the primary accent, which is right
  /// for a navigation row and wrong for a status one — pass a semantic colour
  /// when the glyph means something.
  final Color? iconTint;

  /// Anything on the right: a badge, a switch, a menu button. Takes precedence
  /// over [trailingText] and the chevron.
  final Widget? trailing;

  /// A figure on the right — a price, a count. Rendered with tabular figures,
  /// because a column of money that shuffles sideways as it updates is the
  /// one thing this app must not do.
  final String? trailingText;

  final VoidCallback? onTap;

  /// Starts a bulk selection where a screen has one. Long-press rather than a
  /// tick box in every row: the box would be permanent chrome for a mode most
  /// sellers open twice a month.
  final VoidCallback? onLongPress;

  /// The chevron says "this opens something". A row that only displays, or
  /// one whose trailing widget is the interaction, must turn it off — an
  /// affordance that leads nowhere is worse than none.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final Color tint = iconTint ?? context.colorScheme3.primary;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: SdRadiusV3.cardAll,
      child: Padding(
        padding: SdContentPaddingV3.row,
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              SdIconTileV3(icon: icon!, tint: tint),
              SizedBox(width: SdSpacingConstant.w12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...<Widget>[
                    SizedBox(height: SdSpacingConstant.h2),
                    Text(
                      subtitle!,
                      style: context.textTheme3.bodySmall!.faint3(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (trailingText != null)
              Text(
                trailingText!,
                style: context.textTheme3.bodyMedium!.tabular3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              )
            else if (showChevron && onTap != null)
              const AppRowChevron(),
          ],
        ),
      ),
    );
  }
}

/// A card holding [AppListRow]s with hairlines between them.
///
/// The divider is drawn here rather than by each row, so the last row does not
/// have to know it is last.
class AppListCard extends StatelessWidget {
  const AppListCard({required this.children, this.borderColor, super.key});

  final List<Widget> children;

  /// Tints the edge, forwarded to `SdCardV3`. Its rule applies unchanged:
  /// colour is never the only signal, so a tinted card always carries a label
  /// saying the same thing.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => SdCardV3(
    padding: EdgeInsets.zero,
    borderColor: borderColor,
    child: Column(
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          children[i],
          if (i != children.length - 1) const SdDividerV3(),
        ],
      ],
    ),
  );
}
