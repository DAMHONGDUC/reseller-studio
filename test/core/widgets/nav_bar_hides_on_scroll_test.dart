import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/app_icon_constant.dart';
import 'package:reseller_studio/features/analytics/presentation/screens/analytics_screen/analytics_screen.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/more/presentation/screens/more_screen/more_screen.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **On every tab the bar slides away while the list scrolls down, and comes
/// back when it scrolls up** — owner's rule (`docs/rules/DESIGN_SYSTEM.md`).
/// A tab change always brings it back, and the add button never moves.
void main() {
  const List<SdNavDestinationV3> destinations = <SdNavDestinationV3>[
    SdNavDestinationV3(icon: AppIconConstant.home, label: 'One'),
    SdNavDestinationV3(icon: AppIconConstant.menu, label: 'Two'),
  ];

  Finder verticalList() => find.byWidgetPredicate(
    (Widget widget) => widget is Scrollable && widget.axis == Axis.vertical,
  );

  double windowHeight(WidgetTester tester) =>
      tester.view.physicalSize.height / tester.view.devicePixelRatio;

  /// The pill's top edge — at or past the window's bottom once it is hidden.
  double barTop(WidgetTester tester) =>
      tester.getRect(find.byType(SdGlassNavBarV3)).top;

  Future<void> scroll(WidgetTester tester, double dy) async {
    await tester.drag(verticalList().first, Offset(0, dy));
    await tester.pumpAndSettle();
  }

  Future<void> pumpInShell(WidgetTester tester, Widget screen) => pumpScreen(
    tester,
    SdBottomNavigationV3(
      body: screen,
      destinations: destinations,
      selectedIndex: 0,
      onSelected: (_) {},
    ),
  );

  for (final (String name, Widget screen) in <(String, Widget)>[
    ('Home', const HomeScreen()),
    ('Inventory', const InventoryScreen()),
    ('Orders', const OrdersScreen()),
    ('Analytics', const AnalyticsScreen()),
    ('More', const MoreScreen()),
  ]) {
    testWidgets('$name — down hides the bar, up brings it back', (
      WidgetTester tester,
    ) async {
      await pumpInShell(tester, screen);

      final double restingTop = barTop(tester);

      expect(restingTop, lessThan(windowHeight(tester)));

      await scroll(tester, -300);

      expect(barTop(tester), greaterThanOrEqualTo(windowHeight(tester)));

      await scroll(tester, 120);

      expect(barTop(tester), restingTop);
    });
  }

  testWidgets('the bar follows the finger, then settles', (
    WidgetTester tester,
  ) async {
    await pumpInShell(tester, const InventoryScreen());

    final double restingTop = barTop(tester);
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(verticalList().first),
    );

    // Past the touch slop first, then a short move the bar must track.
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump(const Duration(milliseconds: 16));

    // Part-way, not snapped: a timed slide would be at one end or racing.
    expect(barTop(tester), greaterThan(restingTop));
    expect(barTop(tester), lessThan(windowHeight(tester)));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      barTop(tester) == restingTop || barTop(tester) >= windowHeight(tester),
      isTrue,
      reason: 'a released bar ends fully shown or fully hidden',
    );
  });

  testWidgets('Orders — a short scroll up brings the bar back', (
    WidgetTester tester,
  ) async {
    await pumpInShell(tester, const OrdersScreen());

    final double restingTop = barTop(tester);

    await scroll(tester, -300);

    expect(barTop(tester), greaterThanOrEqualTo(windowHeight(tester)));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(verticalList().first),
    );

    // Past the touch slop, then a few points — far less than half the bar.
    // Settling to the nearer end left it hidden here: the bar was stuck.
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 6));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(barTop(tester), restingTop);
  });

  testWidgets('iOS — a bounce at the end leaves the bar hidden', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpInShell(tester, const OrdersScreen());

    // Far past the end, so the list overscrolls and bounces back. The bounce
    // settling up was read as a scroll up and brought the bar back.
    await scroll(tester, -3000);

    expect(barTop(tester), greaterThanOrEqualTo(windowHeight(tester)));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iOS — a list that fits on screen never moves the bar', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpInShell(
      tester,
      ListView(
        children: const <Widget>[
          SizedBox(height: 80, child: Text('One', style: TextStyle())),
          SizedBox(height: 80, child: Text('Two', style: TextStyle())),
        ],
      ),
    );

    final double restingTop = barTop(tester);
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(verticalList().first),
    );

    // Held mid-drag: the rubber band dragged the bar part way and left it.
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump();

    expect(barTop(tester), restingTop);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(barTop(tester), restingTop);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the add button keeps its place', (WidgetTester tester) async {
    await pumpInShell(tester, const InventoryScreen());

    final Rect resting = tester.getRect(find.byType(SdFabV3));

    // Mid-scroll, and again once the bar has settled out of the way.
    await tester.drag(verticalList().first, const Offset(0, -300));
    await tester.pump();

    expect(tester.getRect(find.byType(SdFabV3)), resting);

    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(SdFabV3)), resting);
  });

  testWidgets('a tab change brings the bar back', (WidgetTester tester) async {
    late StateSetter setShell;
    int index = 0;

    await pumpScreen(
      tester,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          setShell = setState;

          return SdBottomNavigationV3(
            body: index == 0 ? const InventoryScreen() : const HomeScreen(),
            destinations: destinations,
            selectedIndex: index,
            onSelected: (_) {},
          );
        },
      ),
    );

    final double restingTop = barTop(tester);

    await scroll(tester, -300);

    expect(barTop(tester), greaterThanOrEqualTo(windowHeight(tester)));

    setShell(() => index = 1);
    await tester.pumpAndSettle();

    expect(barTop(tester), restingTop);
  });
}
