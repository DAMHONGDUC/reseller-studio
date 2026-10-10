import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/presentation/screens/subscription_screen/subscription_screen.dart';
import 'package:reseller_studio/features/subscription/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **Subscription is the overview, and it meters every ceiling the plan
/// has** — none today: everything is free except export.
///
/// This used to be asserted against More, which carried the meters before it
/// was redesigned into a list of destinations. The assertions outlived the
/// screen and went on passing against nothing — so they are here now, on the
/// screen that actually draws them, and `more_row_values_test.dart` says
/// where they went.
void main() {
  Future<void> pumpSubscription(WidgetTester tester, SellerPlan plan) =>
      pumpScreen(
        tester,
        const SubscriptionScreen(),
        overrides: <Override>[
          isSignedInProvider.overrideWithValue(true),
          currentPlanProvider.overrideWithValue(plan),
        ],
      );

  for (final SellerPlan plan in SellerPlan.values) {
    testWidgets('${plan.label} has no ceiling, so it draws no meter', (
      WidgetTester tester,
    ) async {
      await pumpSubscription(tester, plan);

      // Nothing to scroll *to*, so the list is run to its end before the
      // absence means anything.
      for (int pass = 0; pass < 4; pass++) {
        await tester.fling(
          find.byType(Scrollable).first,
          const Offset(0, -1200),
          1200,
        );
        await tester.pumpAndSettle();
      }

      expect(find.byType(SdFreeLimitProgressV3), findsNothing);
    });
  }
}
