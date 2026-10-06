import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/app_icon_constant.dart';
import 'package:reseller_studio/core/widgets/app_active_filter_bar.dart';
import 'package:reseller_studio/core/widgets/app_filter_chip_group.dart';
import 'package:reseller_studio/core/widgets/app_filter_strip.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/inventory_filter_sheet.dart';
import 'package:system_design/index.dart';

import '../../support/filter_sheet_finder.dart';
import '../../support/pump_app.dart';

/// A filtered list has to say it is filtered — and it is only filtered once
/// the seller says so.
///
/// The strip is the sheet laid out sideways: Filters opens every group, and
/// each chip after it opens one. What any of them ticks is a draft: the list
/// moves on Apply, and on nothing else.
void main() {
  Finder inSheet(String label) => find.descendant(
    of: find.byType(InventoryFilterSheet),
    matching: find.text(label),
  );

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tap(find.byIcon(AppIconConstant.close));
    await tester.pumpAndSettle();
  }

  testWidgets('the strip leads with Filters, then one chip per group', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    final List<String> labels = tester
        .widgetList<SdFilterChipV3>(
          find.descendant(
            of: find.byType(AppFilterStrip),
            matching: find.byType(SdFilterChipV3),
          ),
        )
        .map((SdFilterChipV3 chip) => chip.label)
        .toList();

    expect(labels.take(3), <String>['Filters', 'Show', 'Status']);
    expect(labels, contains('Category'));
    // The presets are a group now, not chips of their own on the strip.
    expect(labels, isNot(contains('Draft')));
    // The entry point left the app bar.
    expect(find.byIcon(AppIconConstant.filterAlt), findsNothing);
  });

  testWidgets('Filters opens every group, the preset first', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await FilterSheetFinder.tapStripChip(tester, 'Filters');

    expect(find.byType(InventoryFilterSheet), findsOneWidget);
    expect(inSheet('Show'), findsOneWidget);
    expect(inSheet('Stale'), findsOneWidget);
    expect(inSheet('Category'), findsOneWidget);
    expect(inSheet('Source'), findsOneWidget);
    // Ten groups, nine rules between them.
    expect(find.byType(AppFilterGroupDivider), findsNWidgets(9));
  });

  testWidgets('a ticked chip is pending, and closing applies nothing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await FilterSheetFinder.tapStripChip(tester, 'Filters');
    await tester.tap(inSheet('Archived'));
    await tester.pumpAndSettle();

    // The list behind the sheet has not moved — nothing is applied until
    // Apply — but the footer's Reset now has something to empty.
    expect(find.byType(AppActiveFilterBar), findsNothing);
    expect(FilterSheetFinder.resetEnabled(tester), isTrue);

    await tester.tap(FilterSheetFinder.reset());
    await tester.pumpAndSettle();

    expect(FilterSheetFinder.resetEnabled(tester), isFalse);

    // Ticked again and abandoned: closing the sheet leaves the list exactly
    // as the seller found it.
    await tester.tap(inSheet('Archived'));
    await tester.pumpAndSettle();
    await closeSheet(tester);

    expect(find.byType(AppActiveFilterBar), findsNothing);
  });

  testWidgets('Apply writes the draft and lights the chips; Reset undoes it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    expect(FilterSheetFinder.stripChipSelected(tester, 'Filters'), isFalse);

    await FilterSheetFinder.tapStripChip(tester, 'Filters');
    await tester.tap(inSheet('Archived'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // Applying closes the sheet, and the count follows the seller back to the
    // list rather than living in the sheet they just left.
    expect(find.byType(InventoryFilterSheet), findsNothing);
    expect(find.text('1 filter applied'), findsOneWidget);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Filters'), isTrue);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Status'), isTrue);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Show'), isFalse);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.byType(AppActiveFilterBar), findsNothing);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Filters'), isFalse);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Status'), isFalse);
  });

  testWidgets('a group’s chip opens that group alone', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await FilterSheetFinder.tapStripChip(tester, 'Status');

    // One group, so no rule, no second question, and its name once — as the
    // sheet's title, not again above the chips.
    expect(find.byType(AppFilterGroupDivider), findsNothing);
    expect(inSheet('Status'), findsOneWidget);
    expect(inSheet('Archived'), findsOneWidget);
    expect(inSheet('Category'), findsNothing);

    await tester.tap(inSheet('Archived'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('1 filter applied'), findsOneWidget);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Status'), isTrue);
  });

  testWidgets('a one-group Reset leaves every other group alone', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await FilterSheetFinder.tapStripChip(tester, 'Show');
    await tester.tap(inSheet('Draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    await FilterSheetFinder.tapStripChip(tester, 'Status');
    await tester.tap(inSheet('Archived'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('2 filters applied'), findsOneWidget);

    // Status's own sheet empties Status, and the preset stays on Draft.
    await FilterSheetFinder.tapStripChip(tester, 'Status');
    await tester.tap(FilterSheetFinder.reset());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('1 filter applied'), findsOneWidget);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Show'), isTrue);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Status'), isFalse);
  });

  testWidgets('the preset is a filter too, and Reset returns it to All', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await FilterSheetFinder.tapStripChip(tester, 'Show');
    await tester.tap(inSheet('Draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('1 filter applied'), findsOneWidget);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Filters'), isTrue);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('1 filter applied'), findsNothing);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Show'), isFalse);
  });
}
