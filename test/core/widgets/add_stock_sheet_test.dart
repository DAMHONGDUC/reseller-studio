import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/option_picker_sheet.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';

import '../../support/add_button_finder.dart';
import '../../support/pump_app.dart';

/// Inventory's create button opens the same Add stock sheet Home's shortcut
/// does, so the two cannot offer different ways in.
void main() {
  testWidgets('Inventory’s create button offers the three ways in', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await tester.tap(AddButtonFinder.named('Add stock'));
    await tester.pumpAndSettle();

    final Finder sheet = find.byType(OptionPickerSheet<String>);

    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Add stock')),
      findsOneWidget,
    );
    for (final String option in <String>[
      'Quick Add',
      'Scan',
      'Take stock in',
    ]) {
      expect(
        find.descendant(of: sheet, matching: find.text(option)),
        findsOneWidget,
        reason: '$option is not offered',
      );
    }
  });
}
