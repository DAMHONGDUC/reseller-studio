import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/widgets/item_card.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/pricing/domain/services/profit_calculator.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The one move a row is asking for, as a button on the card: Reprice for
/// stale stock, List on… for stock listed nowhere.
void main() {
  late Item onHand;

  setUpAll(() async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    onHand = container
        .read(itemsProvider)
        .value!
        .firstWhere((Item item) => item.status == ItemStatus.inStock);
  });

  Future<List<String>> pumpCard(
    WidgetTester tester,
    Item item, {
    bool isSelecting = false,
  }) async {
    final List<String> taps = <String>[];

    await pumpScreen(
      tester,
      Scaffold(
        body: ItemCard(
          item: item,
          now: testNow,
          isSelecting: isSelecting,
          onReprice: () => taps.add('reprice'),
          onMarketPrices: () => taps.add('market'),
        ),
      ),
    );

    return taps;
  }

  Item listedDaysAgo(int days) =>
      onHand.copyWith(listedAt: testNow.subtract(Duration(days: days)));

  testWidgets('stale stock carries Reprice, and it reprices', (
    WidgetTester tester,
  ) async {
    final List<String> taps = await pumpCard(
      tester,
      listedDaysAgo(StaleInventoryPolicy.defaultThresholdDays + 5),
    );

    await tester.tap(find.widgetWithText(SdButtonV3, 'Reprice'));

    expect(taps, <String>['reprice']);
  });

  testWidgets('stock listed nowhere carries List on…, to the prices', (
    WidgetTester tester,
  ) async {
    final List<String> taps = await pumpCard(tester, listedDaysAgo(3));

    await tester.tap(find.widgetWithText(SdButtonV3, 'List on…'));

    expect(taps, <String>['market']);
  });

  testWidgets('no button while a selection is open', (
    WidgetTester tester,
  ) async {
    await pumpCard(
      tester,
      listedDaysAgo(StaleInventoryPolicy.defaultThresholdDays + 5),
      isSelecting: true,
    );

    expect(find.byType(SdButtonV3), findsNothing);
  });

  testWidgets('a draft asks for nothing', (WidgetTester tester) async {
    await pumpCard(tester, onHand.copyWith(status: ItemStatus.draft));

    expect(find.byType(SdButtonV3), findsNothing);
  });
}
