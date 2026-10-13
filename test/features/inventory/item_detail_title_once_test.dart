import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The item's title is on screen once (`docs/rules/SCREENS.md`): the bar
/// reads "Item" over the summary block and takes the title once the block
/// has scrolled away.
void main() {
  const String title = 'Nike windbreaker — XL';

  Finder inBar(String text) =>
      find.descendant(of: find.byType(SdAppBarV3), matching: find.text(text));

  testWidgets('the bar takes the title only after the summary scrolls away', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-11'));

    expect(inBar('Item'), findsOneWidget);
    expect(inBar(title), findsNothing);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(inBar(title), findsOneWidget);
    expect(inBar('Item'), findsNothing);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 800));
    await tester.pumpAndSettle();

    expect(inBar('Item'), findsOneWidget);
  });
}
