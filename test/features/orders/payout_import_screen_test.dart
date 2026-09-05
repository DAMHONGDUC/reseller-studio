import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/presentation/screens/import_payouts_screen/import_payouts_screen.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// Pasting a marketplace's export into the queue.
///
/// **Nothing is written until the seller has seen what matched.** An import
/// that saved on paste would put money in the books that nobody read — the
/// same failure as an estimated fee, arriving through a different door.
void main() {
  testWidgets('reads a pasted export and says which columns it used', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ImportPayoutsScreen());

    // The seed leaves ord-5 awaiting a payout under this platform number.
    await tester.enterText(
      find.byType(TextField),
      'Order ID,Buyer name,Order earnings\n'
      '11-13001-22187,someone,95.40\n'
      'NOT-A-SALE,someone else,10.00\n',
    );
    await tester.pumpAndSettle();

    expect(find.text('Sales matched'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Read from Order ID and Order earnings'), findsOneWidget);
    expect(find.text('Save 1 payout'), findsOneWidget);
  });

  testWidgets('saving writes only the rows that matched', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ImportPayoutsScreen());
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(ImportPayoutsScreen)),
    );

    expect(container.read(ordersAwaitingPayoutListProvider), hasLength(3));

    await tester.enterText(
      find.byType(TextField),
      'Order ID,Order earnings\n11-13001-22187,95.40\n',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save 1 payout'));
    await tester.pumpAndSettle();

    final List<Order> left = container.read(ordersAwaitingPayoutListProvider);

    expect(left, hasLength(2));
    expect(
      left.map((Order order) => order.externalOrderId),
      isNot(contains('11-13001-22187')),
    );
  });

  testWidgets('a file with no usable columns explains itself', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ImportPayoutsScreen());

    await tester.enterText(find.byType(TextField), 'Item,Price\nJacket,42\n');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No order number and payout columns found'),
      findsOneWidget,
    );
    expect(find.text('Save'), findsOneWidget);
  });
}
