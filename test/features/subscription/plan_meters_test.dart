import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_allowance.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/presentation/screens/subscription_screen/subscription_screen.dart';
import 'package:reseller_studio/features/subscription/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **Subscription is the overview, and it meters every ceiling the plan
/// has.**
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

  testWidgets('Free meters every allowance that has a ceiling', (
    WidgetTester tester,
  ) async {
    await pumpSubscription(tester, SellerPlan.free);

    await tester.scrollUntilVisible(
      find.text(PlanAllowance.workspaces.meterTitle(SellerPlan.free)),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.byType(SdFreeLimitProgressV3),
      findsNWidgets(PlanAllowance.values.length),
    );

    for (final PlanAllowance allowance in PlanAllowance.values) {
      expect(
        find.text(allowance.meterTitle(SellerPlan.free)),
        findsOneWidget,
        reason: 'Free caps ${allowance.name}, so the overview meters it',
      );
    }
  });

  testWidgets('Premium has no ceiling, so it draws no meter', (
    WidgetTester tester,
  ) async {
    await pumpSubscription(tester, SellerPlan.premium);

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
