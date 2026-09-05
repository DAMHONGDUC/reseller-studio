import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/analytics/providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/presentation/controllers/order_actions_controller.dart';
import 'package:reseller_studio/features/orders/presentation/screens/record_payouts_screen/record_payouts_screen.dart';
import 'package:reseller_studio/features/orders/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The queue that makes the payout-first model survivable.
///
/// Nothing is estimated any more (hard rule 3), so a sale with no payout has
/// no profit at all — which turns "the seller forgot to record one" from an
/// accuracy nit into a hole in Analytics. These pin that the app gathers those
/// sales, takes them in bulk (hard rule 16), and that filling them in closes
/// the hole.
void main() {
  group('the queue', () {
    test('holds every sale still owed a figure, oldest first', () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      final List<Order> queue = container.read(
        ordersAwaitingPayoutListProvider,
      );

      // The seed settles three of its six sales; the rest are the work.
      expect(queue, hasLength(3));
      expect(queue.every((Order order) => order.needsPayout), isTrue);
      expect(
        queue.first.orderedAt.isBefore(queue.last.orderedAt),
        isTrue,
        reason: 'the oldest is the one most likely to have been missed',
      );
    });

    test('recording them all empties it and completes the profit', () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      final List<Order> queue = container.read(
        ordersAwaitingPayoutListProvider,
      );

      expect(
        container.read(analyticsSummaryProvider).isProfitComplete,
        isFalse,
      );

      await container
          .read(orderActionsControllerProvider.notifier)
          .recordManySettlements(queue, <String, Money>{
            for (final Order order in queue)
              order.id: order.salePrice.applyRate(0.85),
          });
      await Future<void>.delayed(Duration.zero);

      expect(container.read(ordersAwaitingPayoutListProvider), isEmpty);
      expect(container.read(analyticsSummaryProvider).isProfitComplete, isTrue);
    });
  });

  group('the bulk screen', () {
    testWidgets('lists the queue and stays disabled until something is '
        'typed', (WidgetTester tester) async {
      await pumpScreen(tester, const RecordPayoutsScreen());

      // Nothing typed, so there is nothing to save.
      expect(find.text('Save'), findsOneWidget);
      expect(
        tester.widget<SdButtonV3>(find.byType(SdButtonV3).last).onPressed,
        isNull,
      );

      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pumpAndSettle();

      expect(find.text('Save 1 payout'), findsOneWidget);
    });

    testWidgets('a typed figure says what the platform kept', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const RecordPayoutsScreen());

      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pumpAndSettle();

      expect(find.textContaining('Platform kept'), findsOneWidget);
    });
  });
}
