import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:seller_os/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **Every spacing refers to one value** — owner's rule.
///
/// A filter strip sits the same distance under the chrome above it on every
/// screen, and that distance is `topGap` plus the strip's own
/// `filterStripGap`. Two screens drifting apart here is what the rule exists
/// to stop: Inventory's chips sat 8 points lower than Orders' because the
/// search header reserved a gap for the strip *and* the screen placed one,
/// and neither file looked wrong on its own.
void main() {
  /// What the eye actually measures: the top of the chrome's last pixel to
  /// the top of the first chip.
  double gapToChip(WidgetTester tester, Finder above) =>
      tester.getRect(find.byType(SdFilterChipV3).first).top -
      tester.getRect(above).bottom;

  testWidgets('Orders sets the reference', (WidgetTester tester) async {
    await pumpScreen(tester, const OrdersScreen());

    expect(
      gapToChip(tester, find.byType(SdAppBarV3).first),
      moreOrLessEquals(
        SdContentPaddingV3.topGap + SdContentPaddingV3.filterStripGap,
        epsilon: 0.5,
      ),
    );
  });

  testWidgets('Inventory matches it, under a docking search header', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    // Measured from the search field rather than an app bar: Inventory has
    // no `appBar`, because `SdSearchHeaderV3` is a sliver that has to live in
    // the scroll view to dock as the list moves.
    expect(
      gapToChip(tester, find.byType(SdSearchFieldV3)),
      moreOrLessEquals(
        SdContentPaddingV3.topGap + SdContentPaddingV3.filterStripGap,
        epsilon: 0.5,
      ),
    );
  });

  testWidgets('the two screens agree to the pixel', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final double orders = gapToChip(tester, find.byType(SdAppBarV3).first);

    await pumpScreen(tester, const InventoryScreen());

    expect(
      gapToChip(tester, find.byType(SdSearchFieldV3)),
      moreOrLessEquals(orders, epsilon: 0.5),
    );
  });
}
