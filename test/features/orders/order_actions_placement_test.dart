import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/orders/presentation/screens/order_detail_screen/order_detail_screen.dart';
import 'package:reseller_studio/features/orders/presentation/widgets/order_actions_sheet.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **The next move is pinned and everything else is one tap away** — owner's
/// rule.
///
/// The verbs used to be a column of full-width buttons at the foot of the
/// screen, past four sections of content: a seller draining a To Ship queue
/// scrolled two screens to reach the one button they came for, and the rare
/// bookkeeping verb was as loud as the daily one.
void main() {
  testWidgets('a To Ship order pins Ship it, without scrolling', (
    WidgetTester tester,
  ) async {
    // `ord-4` is the seeded order still waiting to go out.
    await pumpScreen(tester, const OrderDetailScreen(orderId: 'ord-4'));

    expect(find.widgetWithText(SdButtonV3, 'Ship it'), findsOneWidget);
  });

  testWidgets('a finished order pins nothing', (WidgetTester tester) async {
    await pumpScreen(tester, const OrderDetailScreen(orderId: 'ord-1'));

    // Delivered: no next step, and a pinned bar holding a bookkeeping verb
    // would make the rare thing look like the expected one.
    expect(find.widgetWithText(SdButtonV3, 'Ship it'), findsNothing);
    expect(
      find.widgetWithText(SdButtonV3, 'Record fees and payout'),
      findsNothing,
    );
  });

  testWidgets('the rest of the verbs live in the actions sheet', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrderDetailScreen(orderId: 'ord-1'));

    await tester.tap(find.widgetWithText(SdButtonV3, 'Actions'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderActionsSheet), findsOneWidget);
    expect(find.text('Record fees and payout'), findsOneWidget);
    expect(find.text('Open a return'), findsOneWidget);
  });

  testWidgets('the sheet lists the move that is pinned as well', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrderDetailScreen(orderId: 'ord-4'));

    await tester.tap(find.widgetWithText(SdButtonV3, 'Actions'));
    await tester.pumpAndSettle();

    // The pinned button is the fast path; the sheet is the complete list, so
    // a verb added there cannot go missing from what a seller learned to open.
    expect(find.text('Ship it'), findsWidgets);
  });
}
