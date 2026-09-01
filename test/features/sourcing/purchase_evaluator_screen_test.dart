import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/sourcing/presentation/screens/purchase_evaluator_screen/purchase_evaluator_screen.dart';

import '../../support/pump_app.dart';

/// The evaluator is used one-handed, in a shop, holding the item — so its one
/// action has to be where the thumb already is.
void main() {
  testWidgets('the scan action is pinned below the scroll, not in it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PurchaseEvaluatorScreen());

    final Finder scan = find.text('Scan a barcode');

    expect(scan, findsOneWidget);
    expect(
      find.ancestor(of: scan, matching: find.byType(Scrollable)),
      findsNothing,
    );
  });
}
