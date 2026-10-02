import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_pinned_action.dart';
import 'package:reseller_studio/core/widgets/mark_sold_sheet.dart';
import 'package:reseller_studio/core/widgets/price_entry_sheet.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// Mark as sold and Reprice hold the item detail's bottom edge while the
/// item is on hand, and nothing does once it has left.
void main() {
  testWidgets('stock on hand pins Mark as sold under Reprice', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-4'));

    final Finder bar = find.byType(AppPinnedAction);
    final Finder sold = find.descendant(
      of: bar,
      matching: find.widgetWithText(SdButtonV3, 'Mark as sold'),
    );
    final Finder reprice = find.descendant(
      of: bar,
      matching: find.widgetWithText(SdButtonV3, 'Reprice'),
    );

    expect(sold, findsOneWidget);
    expect(reprice, findsOneWidget);
    // The primary is lowest, under the resting thumb.
    expect(tester.getRect(sold).top, greaterThan(tester.getRect(reprice).top));
  });

  testWidgets('each button opens the sheet its row in Actions opens', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-4'));

    await tester.tap(find.widgetWithText(SdButtonV3, 'Mark as sold'));
    await tester.pumpAndSettle();

    expect(find.byType(MarkSoldSheet), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SdButtonV3, 'Reprice'));
    await tester.pumpAndSettle();

    // `RepriceSheet` asks through the shared price prompt.
    expect(find.byType(PriceEntrySheet), findsOneWidget);
  });

  testWidgets('a sold item pins nothing', (WidgetTester tester) async {
    // itm-1 is already sold in the seed.
    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-1'));

    expect(find.byType(AppPinnedAction), findsNothing);
  });
}
