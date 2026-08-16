import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/core/widgets/app_filter_strip.dart';
import 'package:seller_os/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:seller_os/features/offers/presentation/screens/offers_screen/offers_screen.dart';
import 'package:seller_os/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **A filter strip carries no gap of its own and fits its chips** — owner's
/// rule — **and the screen places `topGap` above it and the same below.**
///
/// One boundary, one owner, one value. It was two: the strip had an internal
/// vertical inset *and* the screen placed a gap, which is how Inventory's
/// chips ended up sitting lower than Orders' with neither file looking wrong
/// on its own.
void main() {
  Rect stripRect(WidgetTester tester) =>
      tester.getRect(find.byType(AppFilterStrip));

  Rect chipRect(WidgetTester tester) =>
      tester.getRect(find.byType(SdFilterChipV3).first);

  for (final (String name, Widget screen) in <(String, Widget)>[
    ('Inventory', const InventoryScreen()),
    ('Orders', const OrdersScreen()),
    ('Offers', const OffersScreen()),
  ]) {
    testWidgets('$name — the strip fits its chips, top and bottom', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, screen);

      final Rect strip = stripRect(tester);
      final Rect chip = chipRect(tester);

      // No daylight inside the strip. Anything here is a gap with a second
      // owner, and it stops being visible in either file.
      expect(
        chip.top - strip.top,
        moreOrLessEquals(0, epsilon: 0.5),
        reason: '$name has ${chip.top - strip.top} of padding above its chips',
      );
      expect(
        strip.bottom - chip.bottom,
        moreOrLessEquals(0, epsilon: 0.5),
        reason: '$name has ${strip.bottom - chip.bottom} below its chips',
      );
    });
  }

  testWidgets('the screen places topGap above the strip and below it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final Rect bar = tester.getRect(find.byType(SdAppBarV3).first);
    final Rect strip = stripRect(tester);
    final Rect list = tester.getRect(find.byType(ListView).first);

    expect(
      strip.top - bar.bottom,
      moreOrLessEquals(SdContentPaddingV3.topGap, epsilon: 0.5),
    );
    expect(
      list.top - strip.bottom,
      moreOrLessEquals(SdContentPaddingV3.topGap, epsilon: 0.5),
    );
  });

  testWidgets('Inventory and Orders put their chips at the same distance', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final double orders =
        chipRect(tester).top - tester.getRect(find.byType(SdAppBarV3).first).bottom;

    await pumpScreen(tester, const InventoryScreen());

    // Measured from the search field rather than an app bar: Inventory has no
    // `appBar`, because `SdSearchHeaderV3` is a sliver that has to live in the
    // scroll view to dock as the list moves.
    expect(
      chipRect(tester).top - tester.getRect(find.byType(SdSearchFieldV3)).bottom,
      moreOrLessEquals(orders, epsilon: 0.5),
    );
  });
}
