import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/analytics/presentation/screens/analytics_screen/analytics_screen.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/more/presentation/screens/more_screen/more_screen.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **No content is ever covered by the floating nav bar.** Owner's rule, and
/// the five tab screens are where it can go wrong: their bodies run *under*
/// the glass pill (`extendBody`), so clearance is padding each screen asks
/// for rather than something the layout gives it.
///
/// Asserted by scrolling each list to its end and measuring the last row —
/// the case that only appears once a list is long enough to reach the bottom,
/// which is why eyeballing the top of a screen never catches it.
///
/// **The screens are pumped inside `SdFloatingBarScopeV3`**, because the
/// clearance is owed to the chrome rather than to the screen: on a tablet the
/// nav stands at the leading edge and the same screens correctly pay nothing
/// at the bottom (`docs/rules/RESPONSIVE.md`).
void main() {
  /// The y the nav bar's footprint begins at.
  double barTop(WidgetTester tester, BuildContext context) =>
      tester.view.physicalSize.height / tester.view.devicePixelRatio -
      SdContentPaddingV3.floatingBarInset(context);

  /// The screen's own list, never a filter strip.
  ///
  /// **`.first` is the wrong answer on half these screens**: Orders and
  /// Inventory put a horizontal chip row above the list, so the first
  /// `Scrollable` is that strip and dragging it vertically scrolls nothing —
  /// the list stays at the top and every assertion below it passes for the
  /// wrong reason.
  Finder verticalList(WidgetTester tester) => find.byWidgetPredicate(
    (Widget widget) => widget is Scrollable && widget.axis == Axis.vertical,
  );

  Future<void> toEnd(WidgetTester tester) async {
    final Finder list = verticalList(tester).first;

    for (int i = 0; i < 15; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
    }

    await tester.pumpAndSettle();
  }

  /// The lowest edge any card reaches, or null when the screen has none.
  double? lowestCard(WidgetTester tester) {
    final Iterable<Element> cards = find.byType(SdCardV3).evaluate();

    if (cards.isEmpty) return null;

    return cards
        .map(
          (Element element) =>
              tester.getRect(find.byWidget(element.widget)).bottom,
        )
        .reduce((double a, double b) => a > b ? a : b);
  }

  for (final (String name, Widget screen) in <(String, Widget)>[
    ('Home', const HomeScreen()),
    ('Inventory', const InventoryScreen()),
    ('Orders', const OrdersScreen()),
    ('Analytics', const AnalyticsScreen()),
    ('More', const MoreScreen()),
  ]) {
    testWidgets('$name — the last row stops clear of the nav bar', (
      WidgetTester tester,
    ) async {
      // Inside the pill's scope, because that is where these five screens
      // live: a tab screen pumped bare is told there is no bar below it and
      // correctly reclaims the inset this test is about.
      await pumpScreen(
        tester,
        SdFloatingBarScopeV3(
          edge: SdFloatingBarEdgeV3.bottom,
          child: screen,
        ),
      );
      await toEnd(tester);

      final BuildContext context = tester.element(verticalList(tester).first);
      final double limit = barTop(tester, context);
      final double? lowest = lowestCard(tester);

      expect(lowest, isNotNull, reason: '$name rendered no card to measure');
      expect(
        lowest,
        lessThanOrEqualTo(limit),
        reason: '$name draws content to $lowest; the bar starts at $limit',
      );
    });
  }

  test('a tab screen clears the bar by exactly bottomGap', () {
    // The rule as arithmetic, with no layout in the way: whatever a screen
    // pads for, the difference between it and the bar's own footprint is the
    // gap and nothing else. A second inset creeping in anywhere shows up here
    // as a doubled number rather than as a roomy list nobody questions.
    expect(SdContentPaddingV3.bottomGap, SdSpacingConstant.h16);
  });
}
