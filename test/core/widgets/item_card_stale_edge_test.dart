import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/widgets/item_card.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/pricing/domain/services/profit_calculator.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// A stale card wears a warning edge beside its Stale badge, so stock that
/// has not moved stands out while a seller scans forty rows.
void main() {
  late Item onHand;

  setUpAll(() async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    onHand = container
        .read(itemsProvider)
        .value!
        .firstWhere((Item item) => item.status.isOnHand);
  });

  Future<SdCardV3> pumpCard(
    WidgetTester tester,
    Item item, {
    bool isSelected = false,
  }) async {
    await pumpScreen(
      tester,
      Scaffold(
        body: ItemCard(
          item: item,
          now: testNow,
          isSelected: isSelected,
          isSelecting: isSelected,
        ),
      ),
    );

    return tester.widget<SdCardV3>(find.byType(SdCardV3));
  }

  Item listedDaysAgo(int days) =>
      onHand.copyWith(listedAt: testNow.subtract(Duration(days: days)));

  testWidgets('stale stock gets the warning edge and the badge', (
    WidgetTester tester,
  ) async {
    final SdCardV3 card = await pumpCard(
      tester,
      listedDaysAgo(StaleInventoryPolicy.defaultThresholdDays + 5),
    );
    final BuildContext context = tester.element(find.byType(ItemCard));

    expect(card.borderColor, context.sdTheme3.warning);
    // Colour is never the only signal.
    expect(find.text('Stale'), findsOneWidget);
  });

  testWidgets('fresh stock has no edge', (WidgetTester tester) async {
    final SdCardV3 card = await pumpCard(tester, listedDaysAgo(3));

    expect(card.borderColor, isNull);
  });

  testWidgets('a selected card shows the selection, not the warning', (
    WidgetTester tester,
  ) async {
    final SdCardV3 card = await pumpCard(
      tester,
      listedDaysAgo(StaleInventoryPolicy.defaultThresholdDays + 5),
      isSelected: true,
    );
    final BuildContext context = tester.element(find.byType(ItemCard));

    expect(card.borderColor, context.colorScheme3.primary);
  });
}
