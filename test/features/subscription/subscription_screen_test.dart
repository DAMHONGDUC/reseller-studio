import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_limits.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/presentation/screens/subscription_screen/subscription_screen.dart';
import 'package:reseller_studio/features/subscription/providers.dart';

import '../../support/pump_app.dart';

/// The Subscription screen against the in-memory billing backend.
///
/// The demo business starts on Free, which is what a developer sees and what
/// the limits are written against.
void main() {
  testWidgets('Premium is offered monthly and yearly', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const SubscriptionScreen());

    expect(find.text('Free'), findsWidgets);
    expect(find.text('Premium'), findsOneWidget);

    // The mock catalogue prices, rendered as the store would hand them over —
    // a formatted string, never a Money this app formats itself.
    expect(find.textContaining(r'$9.99 per month'), findsOneWidget);
    expect(find.textContaining(r'$89.99 per year'), findsOneWidget);
  });

  testWidgets('the seller is told which plan is theirs', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const SubscriptionScreen());

    // Twice on purpose: the header card says what the seller is on, and the
    // tier they hold is marked in the list so they do not have to compare the
    // two by eye.
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Your plan'), findsOneWidget);

    // Free is what they already have, so it offers nothing to buy.
    expect(find.textContaining('per month'), findsOneWidget);
  });

  testWidgets('the free allowances come from PlanLimits, not from copy', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const SubscriptionScreen());

    final PlanLimits free = PlanLimits.of(SellerPlan.free);

    expect(find.text('${free.items} items'), findsOneWidget);
    expect(find.text('${free.orders} orders'), findsOneWidget);
    expect(find.text('${free.workspaces} business'), findsOneWidget);
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
