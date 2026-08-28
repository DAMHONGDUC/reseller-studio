import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

/// The glyph at the end of a row-shaped card that opens something.
///
/// **Every row-shaped card is info at the start and an affordance at the
/// end** — owner's rule, in `docs/rules/DESIGN_SYSTEM.md`. A card that is one
/// big tap target with nothing saying so leaves the seller learning the screen
/// by poking at it.
///
/// **In `core/` because four places draw it.** `AppListRow` had it inline, and
/// the order card, the offer card and the receipt row each needed the same
/// thing — which is the point at which three of them would have picked three
/// sizes and two greys.
///
/// It is `textTertiary` at `SdIconV3.smallSize` on purpose: a hint, not
/// content. A chevron with the weight of the title competes with it.
class AppRowChevron extends StatelessWidget {
  const AppRowChevron({super.key});

  @override
  Widget build(BuildContext context) => SdIconV3(
    Symbols.chevron_right_rounded,
    size: SdIconV3.smallSize,
    color: context.sdTheme3.textTertiary,
  );
}
