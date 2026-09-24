import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import 'app_row_chevron.dart';

/// A tinted icon tile, a one-line title, a detail line under it, then the
/// chevron — the shape Home's guest banner and More's sync card share.
///
/// **Extracted because a second copy of it appeared** — one widget so the
/// two cards cannot quietly drift apart on padding, type scale or how many
/// lines the detail gets.
class AppStatusCard extends StatelessWidget {
  const AppStatusCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.detail,
    this.detailMaxLines = 2,
    this.onTap,
    this.borderColor,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final Color tint;

  /// Always one line — the card's own title never wraps.
  final String title;

  final String detail;

  /// Two lines by default; the sync card passes 1, since its detail is
  /// written to fit on one.
  final int detailMaxLines;

  final VoidCallback? onTap;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SdCardV3(
    padding: SdContentPaddingV3.row,
    onTap: onTap,
    semanticLabel: semanticLabel,
    borderColor: borderColor,
    child: Row(
      children: <Widget>[
        SdIconTileV3(icon: icon, tint: tint),
        SizedBox(width: SdSpacingConstant.w12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SdSpacingConstant.h4),
              Text(
                detail,
                style: context.textTheme3.bodySmall!.copyWith(
                  color: context.sdTheme3.textSecondary,
                ),
                maxLines: detailMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onTap != null) ...<Widget>[
          SizedBox(width: SdSpacingConstant.w8),
          const AppRowChevron(),
        ],
      ],
    ),
  );
}
