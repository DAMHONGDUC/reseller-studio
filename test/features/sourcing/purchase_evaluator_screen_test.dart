import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_pinned_action.dart';
import 'package:reseller_studio/core/widgets/money_field.dart';
import 'package:reseller_studio/features/sourcing/presentation/screens/purchase_evaluator_screen/purchase_evaluator_screen.dart';

import '../../support/pump_app.dart';

/// The evaluator is used one-handed, in a shop, holding the item — so its one
/// action has to be where the thumb already is, and out of the way while the
/// seller types.
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

  testWidgets('the answer sits under the form', (WidgetTester tester) async {
    await pumpScreen(tester, const PurchaseEvaluatorScreen());

    final Finder lastField = find.byType(MoneyField).last;
    final Finder verdict = find.text(
      'Enter what it would sell for and this fills in.',
      skipOffstage: false,
    );

    expect(verdict, findsOneWidget);
    expect(
      tester.getRect(verdict).top,
      greaterThan(tester.getRect(lastField).bottom),
    );
  });

  testWidgets('the scan action hides while the keyboard is up', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PurchaseEvaluatorScreen());

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(find.byType(AppPinnedAction), findsNothing);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();

    expect(find.byType(AppPinnedAction), findsOneWidget);
  });
}
