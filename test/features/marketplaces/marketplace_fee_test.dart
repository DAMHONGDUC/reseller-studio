import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/marketplaces/domain/services/marketplace_fee_policy.dart';
import 'package:reseller_studio/features/marketplaces/presentation/screens/marketplaces_screen/marketplaces_screen.dart';
import 'package:reseller_studio/features/marketplaces/presentation/widgets/fee_entry_sheet.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';
import 'package:reseller_studio/features/orders/domain/services/payout_reconciliation.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

import '../../support/pump_app.dart';

/// A platform's published rate is a starting point, not the answer —
/// owner's rule.
///
/// A seller on a shop tier, in another country, or with a category discount
/// pays something else, and every after-fees figure in the app was quietly
/// wrong for them until they could say so.
void main() {
  Order order({Money? fees}) => Order(
    id: 'o-1',
    status: OrderStatus.delivered,
    marketplace: Marketplace.ebay,
    lines: const <OrderLine>[],
    salePrice: const Money(10000, 'USD'),
    orderedAt: testNow,
    fees: fees,
  );

  group('resolving a rate', () {
    test('a platform nobody corrected uses its published number', () {
      expect(
        MarketplaceFeePolicy.rateFor(Marketplace.ebay),
        Marketplace.ebay.estimatedFeeRate,
      );
      expect(MarketplaceFeePolicy.isOverridden(Marketplace.ebay), isFalse);
    });

    test('a correction wins, and only for the platform it names', () {
      const Map<String, double> overrides = <String, double>{'ebay': 0.08};

      expect(MarketplaceFeePolicy.rateFor(Marketplace.ebay, overrides: overrides), 0.08);
      expect(
        MarketplaceFeePolicy.rateFor(Marketplace.etsy, overrides: overrides),
        Marketplace.etsy.estimatedFeeRate,
      );
      expect(
        MarketplaceFeePolicy.isOverridden(Marketplace.ebay, overrides: overrides),
        isTrue,
      );
    });

    test('a rate outside 0–100% is a typo, not a fee', () {
      expect(MarketplaceFeePolicy.isValid(0), isTrue);
      expect(MarketplaceFeePolicy.isValid(0.13), isTrue);
      expect(MarketplaceFeePolicy.isValid(1), isTrue);
      expect(MarketplaceFeePolicy.isValid(-0.01), isFalse);
      expect(MarketplaceFeePolicy.isValid(1.5), isFalse);
    });
  });

  group('what the corrected rate reaches', () {
    test('an expected payout uses this business’s rate', () {
      // 100.00 less an 8% fee the seller told us about, rather than eBay's
      // published 13.25%.
      expect(
        PayoutReconciliation.expected(
          order(),
          feeRates: const <String, double>{'ebay': 0.08},
        ),
        const Money(9200, 'USD'),
      );
    });

    test('a fee the platform actually reported still wins', () {
      // The correction is a planning estimate. A real fee on the order is a
      // fact, and a fact is never overwritten by an estimate.
      expect(
        PayoutReconciliation.expected(
          order(fees: const Money(500, 'USD')),
          feeRates: const <String, double>{'ebay': 0.08},
        ),
        const Money(9500, 'USD'),
      );
    });
  });

  group('the published-rate toggle', () {
    testWidgets('every toggle names what it toggles', (
      WidgetTester tester,
    ) async {
      // A bare switch in a row's trailing slot reads as "turn this
      // marketplace off", which is not a thing this screen does.
      await pumpScreen(tester, const MarketplacesScreen());

      expect(
        find.text('Use published rate'),
        findsNWidgets(find.byType(Switch).evaluate().length),
      );
    });

    testWidgets('a platform nobody corrected shows the toggle on', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const MarketplacesScreen());

      final List<Switch> switches = tester
          .widgetList<Switch>(find.byType(Switch))
          .toList();

      expect(switches, isNotEmpty);
      expect(switches.every((Switch toggle) => toggle.value), isTrue);
    });

    testWidgets('while it is on the row cannot be edited', (
      WidgetTester tester,
    ) async {
      // A sheet that let the seller type a number the row would then ignore
      // is a control that lies.
      await pumpScreen(tester, const MarketplacesScreen());

      await tester.tap(find.text('eBay'));
      await tester.pumpAndSettle();

      expect(find.byType(FeeEntrySheet), findsNothing);
    });

    testWidgets('turning it off seeds the correction at the published rate', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const MarketplacesScreen());

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // "I want my own rate" and "my rate is 13.25%" now say the same thing,
      // so nothing renders a row that is neither.
      final Map<String, double> rates = ProviderScope.containerOf(
        tester.element(find.byType(MarketplacesScreen)),
      ).read(marketplaceFeeRatesProvider);

      expect(rates['ebay'], Marketplace.ebay.estimatedFeeRate);
    });

    testWidgets('with it off the row opens the fee sheet', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const MarketplacesScreen());

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('eBay'));
      await tester.pumpAndSettle();

      expect(find.byType(FeeEntrySheet), findsOneWidget);
    });
  });
}
