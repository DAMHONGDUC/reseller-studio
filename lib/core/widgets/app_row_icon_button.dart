import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import 'app_row_chevron.dart';

/// An icon-only control at the end of a row — the item card's actions dots, a
/// category's delete, a receipt's remove.
///
/// **It lays out at the glyph's width and overhangs for its target** — owner's
/// rule, in `docs/rules/DESIGN_SYSTEM.md`. A 44pt box that stops at the
/// content edge centres its glyph 12 points short of every plain chevron in
/// the app, so a column of end glyphs comes out of line. The `InkResponse`
/// overflows the laid-out box instead: the ink spreads over the card's own
/// inset, which nothing else is using, and the glyph holds the edge.
///
/// **The same size and colour as [AppRowChevron]**, because they are the same
/// promise in the same place — one opens a screen, the other a sheet of verbs.
class AppRowIconButton extends StatelessWidget {
  const AppRowIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tint,
    super.key,
  });

  final IconData icon;

  /// Also the semantics label: the glyph alone says nothing to a screen
  /// reader, and this is the only text the control has.
  final String tooltip;

  final VoidCallback onPressed;

  /// Overrides `SdThemeV3.textSecondary` — for a verb that carries a colour
  /// of its own, a destructive one above all.
  final Color? tint;

  /// The touch target, which is what Apple asks for and not what the button
  /// occupies in a row.
  static double get target => SdSpacingConstant.r44;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: AppRowChevron.size,
      height: AppRowChevron.size,
      child: OverflowBox(
        maxWidth: target,
        maxHeight: target,
        child: InkResponse(
          onTap: onPressed,
          radius: target / 2,
          containedInkWell: true,
          highlightShape: BoxShape.circle,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: target,
            child: Center(
              child: SdIconV3(
                icon,
                size: AppRowChevron.size,
                color: tint ?? context.sdTheme3.textSecondary,
                semanticLabel: tooltip,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
