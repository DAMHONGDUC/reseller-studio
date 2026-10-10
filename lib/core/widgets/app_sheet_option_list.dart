import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// The rows of choices inside a bottom sheet: one card, a rule between rows.
///
/// **Owner's rule: a sheet's options are separated by a divider, not by air.**
/// A column of same-weight rows with only a gap between them reads as one
/// block of text a seller has to parse before they can count the choices. One
/// widget owns it so an actions sheet, a picker and the workspace switcher
/// cannot each space their rows differently.
///
/// **A card, the same one Home's lists sit in** (`AppListCard`). Loose rows
/// were inset a gutter past the sheet's title with rules running wider than
/// them; the card's edge lines up with the title and the rows inset from it.
///
/// Always a lazy list, so a picker holding every country builds the rows it
/// shows and not the two hundred it does not.
class AppSheetOptionList extends StatelessWidget {
  const AppSheetOptionList({
    required this.itemCount,
    required this.itemBuilder,
    this.maxHeight,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Caps the list so a long one scrolls inside the sheet instead of growing
  /// it past the top of the screen. Null lets a short list size itself and
  /// never scroll, which is what an actions sheet wants.
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final bool isCapped = maxHeight != null;

    final Widget list = ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: isCapped ? null : const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (BuildContext context, int index) =>
          const SdDividerV3(),
      itemBuilder: itemBuilder,
    );

    // The plain card layer: the modal already sits a step below it, and the
    // elevated one is the divider's own shade in dark, which hid every rule.
    return SdCardV3(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: SdRadiusV3.cardAll,
        // Ink paints on the nearest Material; this one keeps a chosen row's
        // ground and its ripple inside the clipped corners.
        child: Material(
          type: MaterialType.transparency,
          child: isCapped
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight!),
                  child: list,
                )
              : list,
        ),
      ),
    );
  }
}
