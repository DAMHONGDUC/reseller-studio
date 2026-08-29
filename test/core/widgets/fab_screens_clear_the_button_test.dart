import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/expenses/presentation/screens/expenses_screen/expenses_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/categories_screen/categories_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/locations_screen/locations_screen.dart';
import 'package:reseller_studio/features/sourcing/presentation/screens/purchases_screen/purchases_screen.dart';
import 'package:reseller_studio/features/sourcing/presentation/screens/sources_screen/sources_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The create screens reached from More and from Inventory.
///
/// They no longer carry the nav bar — every route under a tab is pushed above
/// the shell, which `test/core/router/detail_routes_leave_the_shell_test.dart`
/// enforces. **They still carry the add button**, which floats over the list,
/// so the last row has to clear it or it cannot be tapped.
///
/// Pumped bare rather than in the shell for exactly that reason: a harness
/// with a bar around them would be a geometry the app stopped building.
void main() {
  Finder verticalList() => find.byWidgetPredicate(
    (Widget widget) => widget is Scrollable && widget.axis == Axis.vertical,
  );

  Future<void> toEnd(WidgetTester tester) async {
    final Finder list = verticalList().first;

    for (int i = 0; i < 15; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
    }

    await tester.pumpAndSettle();
  }

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
    ('Expenses', const ExpensesScreen()),
    ('Categories', const CategoriesScreen()),
    ('Locations', const LocationsScreen()),
    ('Sources', const SourcesScreen()),
    ('Purchases', const PurchasesScreen()),
  ]) {
    testWidgets('$name — the last row stops clear of the add button', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, screen);
      await toEnd(tester);

      final Finder fab = find.byType(SdFabV3);

      expect(fab, findsOneWidget, reason: '$name lost its add button');

      final double? lowest = lowestCard(tester);

      if (lowest == null) return;

      expect(
        lowest,
        lessThanOrEqualTo(tester.getRect(fab).top),
        reason:
            '$name draws content to $lowest; the button starts at '
            '${tester.getRect(fab).top}',
      );
    });

    testWidgets('$name — and clear of the safe area under it', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, screen);
      await toEnd(tester);

      final BuildContext context = tester.element(verticalList().first);
      final double? lowest = lowestCard(tester);

      if (lowest == null) return;

      // Nothing floats here any more, so the floor is the device's own inset.
      expect(
        lowest,
        lessThanOrEqualTo(
          tester.view.physicalSize.height / tester.view.devicePixelRatio -
              SdContentPaddingV3.detailBottom(context),
        ),
      );
    });
  }
}
