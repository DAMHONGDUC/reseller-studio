import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// A row in a sheet that can be the chosen one.
///
/// **The shell only** — the ground and the hit target. It sits in an
/// `AppSheetOptionList`, whose card rounds the corners. What goes
/// inside is the caller's, because the two sheets that use it say "chosen" in
/// different words: the picker ticks the row, the workspace switcher fills its
/// icon tile. Both still need the same ground under them or the sheets stop
/// looking like the same app.
///
/// In `core/widgets/` because the second copy was being written when this was
/// extracted, which is the trigger the rules name.
class AppSelectableRow extends StatelessWidget {
  const AppSelectableRow({
    required this.isSelected,
    required this.onTap,
    required this.child,
    super.key,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Ink(
    // - the same tint strength the icon tiles use, so a selected row and the
    //   glyph beside it are visibly the same accent at the same weight
    // - square, and full-bleed: the card it sits in rounds the corners
    color: isSelected
        ? context.colorScheme3.primary.withValues(
            alpha: SdIconTileV3.backgroundOpacity,
          )
        : Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        // A one-line row is otherwise only as tall as its text, which is under
        // the 44pt Apple asks for — a mis-tap waiting to happen in a list
        // somebody is scanning quickly.
        constraints: BoxConstraints(minHeight: SdSpacingConstant.h48),
        child: Padding(padding: SdContentPaddingV3.row, child: child),
      ),
    ),
  );
}
