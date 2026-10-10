import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/price_entry_sheet.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The item has no price of its own, so a reprice moves every listing — and
/// the sheet says so before the seller presses.
void main() {
  testWidgets('the item reprice warns that every marketplace moves', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-4'));

    await tester.tap(find.widgetWithText(SdButtonV3, 'Reprice'));
    await tester.pumpAndSettle();

    final Finder warning = find.text(
      'The new price replaces the price on every marketplace this item is '
      'listed on.',
    );

    expect(find.byType(PriceEntrySheet), findsOneWidget);
    expect(warning, findsOneWidget);
    expect(
      tester.widget<Text>(warning).style?.color,
      tester.element(warning).sdTheme3.danger,
    );
  });
}
