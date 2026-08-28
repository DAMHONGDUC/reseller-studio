import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// One action in a bottom sheet: a glyph, a label, a tap target.
///
/// In `core/widgets/` because the item sheet and the member sheet had written
/// the same row twice, down to the same padding — and one of them had a corner
/// radius the other did not.
///
/// [isDestructive] tints both the glyph and the label, so the row that deletes
/// something is never told apart by colour alone at a glance: it is also the
/// last one in the sheet, by convention.
class AppSheetActionRow extends StatelessWidget {
  const AppSheetActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = isDestructive
        ? context.sdTheme3.danger
        : context.sdTheme3.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: SdRadiusV3.cardAll,
      child: Padding(
        padding: SdContentPaddingV3.row,
        child: Row(
          children: <Widget>[
            SdIconV3(icon, color: tint),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Text(
                label,
                style: context.textTheme3.bodyMedium!.copyWith(color: tint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
