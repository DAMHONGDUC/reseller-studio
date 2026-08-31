import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/presentation/screens/subscription_screen/subscription_screen.dart';
import 'package:reseller_studio/features/subscription/providers.dart';

import '../../support/pump_app.dart';

/// Subscription management never doubles as the purchase surface.
void main() {
  testWidgets('Free can open Premium plans without prices on this screen', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const SubscriptionScreen());

    expect(find.text('View Premium plans'), findsOneWidget);
    expect(find.textContaining('per month'), findsNothing);
    expect(find.textContaining('per year'), findsNothing);
    expect(find.text('Restore purchases'), findsNothing);
  });

  testWidgets('the plans button is pinned below the scroll, not in it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const SubscriptionScreen());

    expect(
      find.ancestor(
        of: find.text('View Premium plans'),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
      reason: 'the screen acts on what it shows, so the action holds the foot',
    );
  });

  testWidgets('the seller is told which plan is theirs', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const SubscriptionScreen());

    expect(find.text('Current'), findsOneWidget);
  });

  test('the demo business starts on the free tier', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);
    // Subscribing is what starts the stream; without it the provider reads
    // null and falls back to Free for the wrong reason.
    container.listen<SellerPlan>(
      currentPlanProvider,
      (SellerPlan? previous, SellerPlan next) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentPlanProvider), SellerPlan.free);
  });
}
