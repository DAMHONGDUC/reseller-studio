import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/app_icon_constant.dart';
import 'package:reseller_studio/core/widgets/app_active_filter_bar.dart';
import 'package:reseller_studio/core/widgets/app_filter_chip_group.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:reseller_studio/features/orders/presentation/widgets/order_filter_sheet.dart';

import 'package:system_design/index.dart';

import '../../support/filter_sheet_finder.dart';
import '../../support/pump_app.dart';

/// Orders answers the same two questions Inventory does: what is filtered, and
/// how to undo it — from the whole sheet or from one group's chip.
void main() {
  Finder inSheet(String label) => find.descendant(
    of: find.byType(OrderFilterSheet),
    matching: find.text(label),
  );

  testWidgets('Filters opens every group, Status first', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());

    // The entry point left the app bar for the head of the strip.
    expect(find.byIcon(AppIconConstant.filterAlt), findsNothing);

    await FilterSheetFinder.tapStripChip(tester, 'Filters');

    expect(find.byType(OrderFilterSheet), findsOneWidget);
    expect(inSheet('Show'), findsNothing);
    expect(inSheet('Marketplace'), findsOneWidget);
    expect(inSheet('Payout'), findsOneWidget);
    expect(inSheet('Cancelled'), findsOneWidget);
    // Six chip groups and the sale range: seven blocks, six rules.
    expect(find.byType(AppFilterGroupDivider), findsNWidgets(6));
  });

  testWidgets('a ticked chip is pending until Apply, and Reset undoes it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());
    await FilterSheetFinder.tapStripChip(tester, 'Filters');
    await tester.tap(inSheet('Cancelled'));
    await tester.pumpAndSettle();

    // Pending: the footer can reset it, the list behind it has not moved.
    expect(FilterSheetFinder.resetEnabled(tester), isTrue);
    expect(find.byType(AppActiveFilterBar), findsNothing);

    // Closing without applying leaves the list as the seller found it.
    await tester.tap(find.byIcon(AppIconConstant.close));
    await tester.pumpAndSettle();

    expect(find.byType(AppActiveFilterBar), findsNothing);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Filters'), isFalse);

    await FilterSheetFinder.tapStripChip(tester, 'Filters');
    await tester.tap(inSheet('Cancelled'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderFilterSheet), findsNothing);
    expect(find.text('1 filter applied'), findsOneWidget);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Filters'), isTrue);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Status'), isTrue);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.byType(AppActiveFilterBar), findsNothing);
  });

  testWidgets('Status is the raw statuses, each with its count', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());
    await FilterSheetFinder.tapStripChip(tester, 'Status');

    // What the old presets grouped is ticked status by status now.
    expect(inSheet('To Ship'), findsNothing);
    expect(inSheet('Cancelled'), findsOneWidget);
    expect(
      tester
          .widget<SdFilterChipV3>(
            find.descendant(
              of: find.byType(OrderFilterSheet),
              matching: find.widgetWithText(SdFilterChipV3, 'Cancelled'),
            ),
          )
          .count,
      isNotNull,
    );
  });

  testWidgets('a one-group Reset leaves every other group alone', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const OrdersScreen());
    await FilterSheetFinder.tapStripChip(tester, 'Tracking');
    await tester.tap(inSheet('With tracking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    await FilterSheetFinder.tapStripChip(tester, 'Status');
    await tester.tap(inSheet('Cancelled'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('2 filters applied'), findsOneWidget);

    await FilterSheetFinder.tapStripChip(tester, 'Status');
    await tester.tap(FilterSheetFinder.reset());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('1 filter applied'), findsOneWidget);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Tracking'), isTrue);
    expect(FilterSheetFinder.stripChipSelected(tester, 'Status'), isFalse);
  });
}
