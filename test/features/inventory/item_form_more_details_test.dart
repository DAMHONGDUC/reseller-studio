import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_form_screen/item_form_screen.dart';

import '../../support/pump_app.dart';

/// The create form asks for what every item needs and folds the rest
/// behind More details (`docs/UI_POLISH_PLAN.md`).
void main() {
  testWidgets('title and quantity first; More details opens the rest', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemFormScreen());

    expect(find.text('Quantity'), findsWidgets);
    expect(find.text('Cost'), findsNothing);

    await tester.tap(find.text('More details'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Cost'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Cost'), findsOneWidget);
  });

  testWidgets('a scanned barcode opens the details it filled', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const ItemFormScreen(initialBarcode: '0123456789012'),
    );

    expect(find.text('Fewer details'), findsOneWidget);
  });
}
