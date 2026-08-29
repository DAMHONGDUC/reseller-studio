import 'package:flutter/widgets.dart';
import 'package:system_design/index.dart';
import '../constants/app_icon_constant.dart';

/// The glyph at the end of a row-shaped card that opens something.
///
/// **Every row-shaped card is info at the start and an affordance at the
/// end** — owner's rule, in `docs/rules/DESIGN_SYSTEM.md`. A card that is one
/// big tap target with nothing saying so leaves the seller learning the screen
/// by poking at it.
///
/// **In `core/` because nothing draws one inline.** `AppListRow` had it
/// inline, and so did Home's attention row, its flow entry, its premium
/// banner, the More row and the item card's money band — three sizes and two
/// greys of the same promise, which is what a seller met scrolling one screen.
///
/// It is `textSecondary` at [SdIconV3.defaultSize] — owner's rule, reversing
/// `textTertiary` at `smallSize`. An affordance is the instruction, read
/// before the content beside it; at 16 points in the faintest grey the app
/// has, it was the mark sellers did not see.
class AppRowChevron extends StatelessWidget {
  const AppRowChevron({this.semanticLabel, super.key});

  /// Set only where the glyph opens something the row's own text does not
  /// already name — the item card's arrow into marketplace prices.
  final String? semanticLabel;

  /// What one occupies in a row, so a card with nothing to open can hold the
  /// same space and keep its end glyphs in one column.
  static double get size => SdIconV3.defaultSize;

  @override
  Widget build(BuildContext context) => SdIconV3(
    AppIconConstant.chevronRight,
    size: size,
    color: context.sdTheme3.textSecondary,
    semanticLabel: semanticLabel,
  );
}
