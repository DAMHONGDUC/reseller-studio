import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/widgets/item_card.dart';
import 'package:reseller_studio/core/widgets/mark_sold_sheet.dart';
import 'package:reseller_studio/core/widgets/sale_recorded_view.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/providers.dart';

import '../../support/pump_app.dart';

/// Saving a sale turns the sheet into its success view instead of closing
/// behind a snackbar — and the caller still learns the sale happened,
/// however the seller leaves (`MarkSoldSheet.show`).
void main() {
  /// A button that opens the sheet for itm-4 and keeps what `show` returns.
  Widget opener(void Function(bool?) onResult) => Consumer(
    builder: (BuildContext context, WidgetRef ref, Widget? child) {
      final Item? item = ref
          .watch(itemsProvider)
          .value
          ?.where((Item i) => i.id == 'itm-4')
          .firstOrNull;

      // Watched so a test can read the orders the sale wrote.
      ref.watch(ordersProvider);

      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: item == null
                ? null
                : () async =>
                      onResult(await MarkSoldSheet.show(context, <Item>[item])),
            child: const Text('open'),
          ),
        ),
      );
    },
  );

  Future<void> recordSale(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record the sale'));
    await tester.pumpAndSettle();
  }

  testWidgets('saving shows the success view, never a profit', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, opener((_) {}));
    await recordSale(tester);

    expect(find.byType(SaleRecordedView), findsOneWidget);
    expect(find.text('Sold on eBay'), findsOneWidget);
    expect(
      find.text('Vintage Levi 501 — 34x32, redline selvedge'),
      findsOneWidget,
    );
    // No payout entered, so the last step says why profit is not known yet
    // rather than printing an estimate (hard rule 3).
    expect(find.text('Record the payout'), findsOneWidget);
    expect(
      find.text('Profit is exact once the platform pays you'),
      findsOneWidget,
    );
  });

  testWidgets('the order is written before the view appears', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, opener((_) {}));
    await recordSale(tester);

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(SaleRecordedView)),
    );
    final List<Order> orders = container.read(ordersProvider).value!;

    expect(
      orders.any(
        (Order order) => order.lines.any((line) => line.itemId == 'itm-4'),
      ),
      isTrue,
    );
  });

  for (final (String exit, Finder Function() control)
      in <(String, Finder Function())>[
        ('Done', () => find.text('Done')),
        ('the close button', () => find.byTooltip('Close')),
      ]) {
    testWidgets('leaving by $exit still reports the sale', (
      WidgetTester tester,
    ) async {
      bool? result;

      await pumpScreen(tester, opener((bool? value) => result = value));
      await recordSale(tester);
      await tester.tap(control());
      await tester.pumpAndSettle();

      expect(find.byType(SaleRecordedView), findsNothing);
      // The record-sale screen pops itself on true; a null here would leave
      // the seller on a picker for a sale that already happened.
      expect(result, isTrue);
    });
  }

  testWidgets('dismissing before saving still reports nothing', (
    WidgetTester tester,
  ) async {
    bool? result = true;

    await pumpScreen(tester, opener((bool? value) => result = value));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.byType(ItemCard), findsNothing);
  });
}
