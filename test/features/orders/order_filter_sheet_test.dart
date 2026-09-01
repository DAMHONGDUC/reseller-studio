import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/app_icon_constant.dart';
import 'package:reseller_studio/core/widgets/app_active_filter_bar.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:reseller_studio/features/orders/presentation/widgets/order_filter_sheet.dart';

import '../../support/pump_app.dart';

/// Orders answers the same two questions Inventory does: what is filtered, and
/// how to undo it.
void main() {
  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byIcon(AppIconConstant.filterAlt));
    await tester.pumpAndSettle();
  }

  testWidgets('the sheet holds the groups the tabs cannot ask', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());
    await openSheet(tester);

    expect(find.byType(OrderFilterSheet), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Payout'), findsOneWidget);
    // The two statuses no tab offers on its own.
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('the app bar\u2019s filter glyph fills once something is on', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    expect(
      tester.widget<Icon>(find.byIcon(AppIconConstant.filterAlt)).fill,
      isNull,
    );

    await openSheet(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(OrderFilterSheet),
        matching: find.text('Cancelled'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(tester.widget<Icon>(find.byIcon(AppIconConstant.filterAlt)).fill, 1);
  });

  testWidgets('a ticked chip is pending until Apply, and Reset undoes it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());
    await openSheet(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(OrderFilterSheet),
        matching: find.text('Cancelled'),
      ),
    );
    await tester.pumpAndSettle();

    // Once: the sheet counts what is ticked, the list behind it has not moved.
    expect(find.text('1 filter applied'), findsOneWidget);

    // Closing without applying leaves the list as the seller found it.
    await tester.tap(find.byIcon(AppIconConstant.close));
    await tester.pumpAndSettle();

    expect(find.byType(AppActiveFilterBar), findsNothing);

    await openSheet(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(OrderFilterSheet),
        matching: find.text('Cancelled'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderFilterSheet), findsNothing);
    expect(find.text('1 filter applied'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.byType(AppActiveFilterBar), findsNothing);
  });
}
