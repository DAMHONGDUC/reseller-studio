import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// The horizontal row of chips that filters a list.
///
/// **It carries no vertical gap of its own and fits its chips exactly** —
/// owner's rule. It used to be a fixed-height box with an internal vertical
/// inset, which meant the daylight above a chip was built from two numbers
/// owned by two files: the screen's `topGap` and the strip's own padding.
/// That is how Inventory's chips ended up sitting lower than Orders' with
/// neither file looking wrong. A `Row` inside a horizontal scroll view has
/// exactly the height of the tallest chip and no opinion about what is above
/// or below it.
///
/// **The screen places `SdContentPaddingV3.topGap` above it and the same
/// below** — owner's rule, and the reason this widget has no margin: the gap
/// belongs to the screen on both sides, so there is one owner and one value.
///
/// A `Row` rather than a `ListView.separated`: a filter strip is four to nine
/// chips, laziness buys nothing, and a `ListView` needs a bounded height —
/// which is the fixed box this rule exists to remove.
class AppFilterStrip extends StatelessWidget {
  const AppFilterStrip({required this.children, super.key});

  /// The chips, in the order they are offered. Pass `SdFilterChipV3`s.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
    child: Row(
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i != 0) SizedBox(width: SdSpacingConstant.w8),
          children[i],
        ],
      ],
    ),
  );
}
