import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/app_icon_constant.dart';
import 'package:reseller_studio/core/widgets/app_filter_strip.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/offers/presentation/screens/offers_screen/offers_screen.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **A filter strip carries no gap of its own and fits its chips** — owner's
/// rule — **and the gap either side of it has exactly one owner.**
///
/// One boundary, one owner, one value. It was two: the strip had an internal
/// vertical inset *and* the screen placed a gap, which is how Inventory's
/// chips ended up sitting lower than Orders' with neither file looking wrong
/// on its own.
///
/// The owner differs by screen and that is the point: Orders' chips are drawn
/// by `SdFilterHeaderV3`, so the gap above them is the header's
/// (`stripGap`); everywhere else the strip sits in the body and the screen
/// places `topGap`. The gap *below* is the body's on every screen.
void main() {
  Rect stripRect(WidgetTester tester) =>
      tester.getRect(find.byType(AppFilterStrip));

  Rect chipRect(WidgetTester tester) =>
      tester.getRect(find.byType(SdFilterChipV3).first);

  /// The status bar the header was handed. Read off the view rather than
  /// assumed: a test surface with no notch would pass an inset bug at 0.
  double statusBar(WidgetTester tester) =>
      tester.view.viewPadding.top / tester.view.devicePixelRatio;

  /// Where the title row ends inside Orders' docking header — the line the
  /// chips sit under while the list is at the top.
  /// `SdFilterHeaderV3` itself is a sliver and has no box to measure —
  /// `SdDockingHeaderV3` is the chrome it draws, and the box that has one.
  double barBottom(WidgetTester tester) =>
      tester.getRect(find.byType(SdDockingHeaderV3)).top +
      statusBar(tester) +
      SdAppBarV3.toolbarHeight;

  /// Drags the list, not the strip: dragging a horizontal scrollable
  /// vertically moves nothing and every assertion here would pass for the
  /// wrong reason.
  Future<void> scrollList(WidgetTester tester) async {
    await tester.drag(
      find.byWidgetPredicate(
        (Widget widget) => widget is Scrollable && widget.axis == Axis.vertical,
      ),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
  }

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

  testWidgets('the header places stripGap above, the body topGap below', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final Rect strip = stripRect(tester);
    final Rect row = tester.getRect(find.byType(SdCardV3).first);

    expect(
      strip.top - barBottom(tester),
      moreOrLessEquals(SdFilterHeaderMetricsV3.stripGap, epsilon: 0.5),
    );
    // The header draws the chips, so it stops where they stop — everything
    // under that line is the body's, and this is the gap it places.
    expect(
      row.top - strip.bottom,
      moreOrLessEquals(SdContentPaddingV3.topGap, epsilon: 0.5),
    );
  });

  testWidgets('Inventory and Orders put their chips at the same distance', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final double orders = chipRect(tester).top - barBottom(tester);

    await pumpScreen(tester, const InventoryScreen());

    // Measured from the search field rather than an app bar: Inventory has no
    // `appBar`, because `SdSearchHeaderV3` is a sliver that has to live in the
    // scroll view to dock as the list moves.
    expect(
      chipRect(tester).top -
          tester.getRect(find.byType(SdSearchFieldV3)).bottom,
      moreOrLessEquals(orders, epsilon: 0.5),
    );
  });

  testWidgets('Inventory keeps its chips pinned while the list scrolls', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    final double before = stripRect(tester).top;

    await scrollList(tester);

    // Owner's rule: the chips stay reachable 300 rows down, the way Orders'
    // do. They move up as the search field docks, and then they stop.
    expect(find.byType(AppFilterStrip), findsOneWidget);
    expect(stripRect(tester).top, lessThan(before));

    final double pinned = stripRect(tester).top;

    await scrollList(tester);

    expect(stripRect(tester).top, moreOrLessEquals(pinned, epsilon: 0.5));
  });

  testWidgets('pinned, Inventory holds its chips where Orders holds theirs', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final double orders = stripRect(tester).top;

    await pumpScreen(tester, const InventoryScreen());
    await scrollList(tester);

    // Both are `topGap` under a full app-bar row — one screen reaches it by
    // docking a search field, the other was always there.
    expect(stripRect(tester).top, moreOrLessEquals(orders, epsilon: 0.5));
  });

  testWidgets('Orders docks its chips into the title row as it scrolls', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final double before = stripRect(tester).top;

    await scrollList(tester);

    final Rect header = tester.getRect(find.byType(SdDockingHeaderV3));
    final Rect strip = stripRect(tester);

    // Owner's rule: the chips go up into the app bar rather than away.
    expect(find.byType(AppFilterStrip), findsOneWidget);
    expect(strip.top, lessThan(before));
    // Centred in the title row, which is now all the header is.
    expect(
      header.bottom - strip.bottom,
      moreOrLessEquals(
        (SdAppBarV3.toolbarHeight - SdFilterChipV3.height) / 2,
        epsilon: 0.5,
      ),
    );
    expect(
      header.height,
      moreOrLessEquals(
        statusBar(tester) + SdAppBarV3.toolbarHeight,
        epsilon: 0.5,
      ),
    );
  });

  testWidgets('Orders keeps its app bar actions where they were', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    final Finder offers = find.byIcon(AppIconConstant.localOffer);
    final Finder shipping = find.byIcon(AppIconConstant.localShipping);
    final Rect offersRect = tester.getRect(offers);
    final Rect shippingRect = tester.getRect(shipping);

    await scrollList(tester);

    // Owner's rule: the strip docks *beside* the actions. An action that
    // moved as the page scrolled is one a seller has to aim at twice.
    expect(tester.getRect(offers), offersRect);
    expect(tester.getRect(shipping), shippingRect);
    expect(stripRect(tester).right, lessThanOrEqualTo(offersRect.left));
  });
}
