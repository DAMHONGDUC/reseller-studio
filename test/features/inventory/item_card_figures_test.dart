import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_card.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// What the row says about money and about time.
///
/// The figures are the reason the card is worth its height: an inventory list
/// a seller cannot judge from is a list they open forty times.
void main() {
  Item itemWith({
    Money? cost,
    Money? asking,
    ItemStatus status = ItemStatus.inStock,
  }) => Item(
    id: 'itm-1',
    title: 'Vintage jacket',
    quantity: 1,
    status: status,
    createdAt: testNow.subtract(const Duration(days: 40)),
    listedAt: testNow.subtract(const Duration(days: 21)),
    purchasePrice: cost,
    askingPrice: asking,
  );

  testWidgets('the band leads with how many are left', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(cost: const Money(4500, 'USD')),
        now: testNow,
      ),
    );

    expect(find.text('Qty'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('a sold item has none left, and says so as a zero', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(status: ItemStatus.sold),
        now: testNow,
      ),
    );

    // A known zero, not a missing figure: the em dashes beside it are the
    // amounts nobody entered.
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('the band states cost and asking price, and no profit', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(
          cost: const Money(4500, 'USD'),
          asking: const Money(18500, 'USD'),
        ),
        now: testNow,
      ),
    );

    // Label at the card's left edge, figure at its right, so the two amounts
    // line up in a column whatever their labels measure.
    expect(find.text('Cost'), findsOneWidget);
    expect(find.text(r'$45.00'), findsOneWidget);
    expect(find.text('Asking'), findsOneWidget);
    expect(find.text(r'$185.00'), findsOneWidget);
    // Expected profit is the detail screen's, not the row's.
    expect(find.text('Profit'), findsNothing);
    expect(find.text(r'$140.00'), findsNothing);
  });

  testWidgets('a Quick Add row says the figures are missing, never zero', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: itemWith(status: ItemStatus.draft),
        now: testNow,
      ),
    );

    // Hard rule 5: both figures render an em dash rather than a zero, which
    // would tell the seller the item was free.
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('the row does not show state age', (WidgetTester tester) async {
    await pumpScreen(tester, ItemCard(item: itemWith(), now: testNow));

    expect(find.text('3w'), findsNothing);
    expect(find.widgetWithText(SdBadgeV3, 'In stock'), findsOneWidget);
  });
}
