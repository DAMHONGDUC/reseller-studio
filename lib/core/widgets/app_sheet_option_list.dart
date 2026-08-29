import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// The rows of choices inside a bottom sheet, separated by a rule.
///
/// **Owner's rule: a sheet's options are separated by a divider, not by air.**
/// A column of same-weight rows with only a gap between them reads as one
/// block of text a seller has to parse before they can count the choices. One
/// widget owns it so an actions sheet, a picker and the workspace switcher
/// cannot each space their rows differently.
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

  /// The air either side of the rule.
  ///
  /// A hairline flush against a row is why this used to be a plain gap: a
  /// picker's chosen row draws a rounded ground, and a line running into that
  /// corner reads as two shapes fighting. The gap keeps them apart and the
  /// rule still does the separating.
  static double get dividerGap => SdSpacingConstant.h4;

  @override
  Widget build(BuildContext context) {
    final bool isCapped = maxHeight != null;

    final Widget list = ListView.separated(
      shrinkWrap: true,
      physics: isCapped ? null : const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (BuildContext context, int index) =>
          SdDividerV3(gap: dividerGap),
      itemBuilder: itemBuilder,
    );

    if (!isCapped) return list;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight!),
      child: list,
    );
  }
}
