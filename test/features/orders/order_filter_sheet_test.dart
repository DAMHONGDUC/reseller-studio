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

  testWidgets('a ticked chip is counted, and Reset drops it', (
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

    // The sheet's row and the screen's behind it are one widget in two places.
    expect(find.text('1 filter applied'), findsNWidgets(2));

    await tester.tap(find.byIcon(AppIconConstant.close));
    await tester.pumpAndSettle();

    expect(find.text('1 filter applied'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.byType(AppActiveFilterBar), findsNothing);
  });
}
