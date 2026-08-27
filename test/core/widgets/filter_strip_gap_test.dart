import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_filter_strip.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/offers/presentation/screens/offers_screen/offers_screen.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
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

  testWidgets('Inventory keeps its chips pinned while the list scrolls', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    final double before = stripRect(tester).top;

    // The list, not the strip: dragging a horizontal scrollable vertically
    // moves nothing and the assertion would pass for the wrong reason.
    await tester.drag(
      find.byWidgetPredicate(
        (Widget widget) => widget is Scrollable && widget.axis == Axis.vertical,
      ),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    // Owner's rule: the chips stay reachable 300 rows down, the way Orders'
    // do. They move up as the search field docks, and then they stop.
    expect(find.byType(AppFilterStrip), findsOneWidget);
    expect(stripRect(tester).top, lessThan(before));

    final double pinned = stripRect(tester).top;

    await tester.drag(
      find.byWidgetPredicate(
        (Widget widget) => widget is Scrollable && widget.axis == Axis.vertical,
      ),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(stripRect(tester).top, moreOrLessEquals(pinned, epsilon: 0.5));
  });

  testWidgets('pinned, Inventory holds its chips where Orders holds theirs', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final double orders = stripRect(tester).top;

    await pumpScreen(tester, const InventoryScreen());
    await tester.drag(
      find.byWidgetPredicate(
        (Widget widget) => widget is Scrollable && widget.axis == Axis.vertical,
      ),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    // Both are `topGap` under a full app-bar row — one screen reaches it by
    // docking a search field, the other was always there.
    expect(stripRect(tester).top, moreOrLessEquals(orders, epsilon: 0.5));
  });
}
