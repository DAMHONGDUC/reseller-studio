import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/app_icon_constant.dart';
import 'package:reseller_studio/core/widgets/app_active_filter_bar.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/inventory_filter_sheet.dart';

import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// A filtered list has to say it is filtered — and it is only filtered once
/// the seller says so.
///
/// The sheet's chips are behind a button, so an item missing from the list and
/// an item filtered out of it look identical without the count — and the
/// seller's only fix would be to reopen the sheet and hunt for what they
/// ticked. What the chips tick is a draft: the list moves on Apply, and on
/// nothing else.
void main() {
  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byIcon(AppIconConstant.filterAlt));
    await tester.pumpAndSettle();
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tap(find.byIcon(AppIconConstant.close));
    await tester.pumpAndSettle();
  }

  testWidgets('the chrome offers the sheet, and the sheet holds the groups', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await openSheet(tester);

    expect(find.byType(InventoryFilterSheet), findsOneWidget);
    // The five tabs are not repeated here; what is here has nowhere else to
    // be asked.
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    // Every group is chips now: the item carries no price of its own, so the
    // asking-price presence group and its range boxes went with the field.
    expect(find.text('Asking price'), findsNothing);
    expect(find.text('Asking price range'), findsNothing);
  });

  testWidgets('a ticked chip is pending, and closing applies nothing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await openSheet(tester);

    // Archived is a status with no tab of its own, so the text is unambiguous.
    await tester.tap(
      find.descendant(
        of: find.byType(InventoryFilterSheet),
        matching: find.text('Archived'),
      ),
    );
    await tester.pumpAndSettle();

    // Once, not twice: the sheet counts what the seller has ticked, and the
    // list behind it has not moved — nothing is applied until Apply.
    expect(find.text('1 filter applied'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('1 filter applied'), findsNothing);

    // Ticked again and abandoned: closing the sheet leaves the list exactly
    // as the seller found it.
    await tester.tap(
      find.descendant(
        of: find.byType(InventoryFilterSheet),
        matching: find.text('Archived'),
      ),
    );
    await tester.pumpAndSettle();
    await closeSheet(tester);

    expect(find.byType(AppActiveFilterBar), findsNothing);
  });

  testWidgets('Apply writes the draft to the list, and Reset undoes it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await openSheet(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(InventoryFilterSheet),
        matching: find.text('Archived'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // Applying closes the sheet, and the count follows the seller back to the
    // list rather than living in the sheet they just left.
    expect(find.byType(InventoryFilterSheet), findsNothing);
    expect(find.text('1 filter applied'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('1 filter applied'), findsNothing);
    expect(find.byType(AppActiveFilterBar), findsNothing);
  });

  testWidgets('the selected tab is a filter too, and Reset returns to All', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    // Draft rather than a tab further along the strip: five chips are wider
    // than a phone, so the ones at the end are only reachable after a scroll.
    await tester.tap(find.widgetWithText(SdFilterChipV3, 'Draft'));
    await tester.pumpAndSettle();

    expect(find.text('1 filter applied'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('1 filter applied'), findsNothing);
  });
}
