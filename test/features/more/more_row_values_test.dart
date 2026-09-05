import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/more/presentation/screens/more_screen/more_screen.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_allowance.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('More names the plan and the session without opening either', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const MoreScreen(),
      overrides: <Override>[
        isSignedInProvider.overrideWithValue(true),
        currentPlanProvider.overrideWithValue(SellerPlan.free),
      ],
    );

    final Finder scrollable = find.byType(Scrollable).first;
    final Finder planName = find.text(SellerPlan.free.label);

    await tester.scrollUntilVisible(planName, 300, scrollable: scrollable);

    expect(planName, findsOneWidget);
    expect(find.text('Signed in'), findsOneWidget);
  });

  testWidgets('signed out, the Settings row says so', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const MoreScreen(),
      overrides: <Override>[isSignedInProvider.overrideWithValue(false)],
    );

    expect(find.text('Not signed in'), findsOneWidget);
  });

  testWidgets('Free meters only the allowance that has a ceiling', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const MoreScreen(),
      overrides: <Override>[
        isSignedInProvider.overrideWithValue(true),
        currentPlanProvider.overrideWithValue(SellerPlan.free),
      ],
    );

    final Finder meters = find.byType(SdFreeLimitProgressV3);

    await tester.scrollUntilVisible(
      meters,
      300,
      scrollable: find.byType(Scrollable).first,
    );

    // Items and orders are unlimited on Free, so a meter for either would be
    // a bar that can never fill.
    expect(meters, findsOneWidget);
    expect(find.text(PlanAllowance.workspaces.label), findsOneWidget);
    expect(find.text(PlanAllowance.items.label), findsNothing);
    expect(find.text(PlanAllowance.orders.label), findsNothing);
  });

  testWidgets('Premium has no ceiling, so it draws no meter', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const MoreScreen(),
      overrides: <Override>[
        isSignedInProvider.overrideWithValue(true),
        currentPlanProvider.overrideWithValue(SellerPlan.premium),
      ],
    );

    final Finder scrollable = find.byType(Scrollable).first;

    // Nothing to scroll *to*, so the list is run to its end before the
    // absence means anything.
    for (int pass = 0; pass < 4; pass++) {
      await tester.fling(scrollable, const Offset(0, -1200), 1200);
      await tester.pumpAndSettle();
    }

    expect(find.text(SellerPlan.premium.label), findsOneWidget);
    expect(find.byType(SdFreeLimitProgressV3), findsNothing);
  });

  testWidgets('signed out, no meter claims anything about a business', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const MoreScreen(),
      overrides: <Override>[isSignedInProvider.overrideWithValue(false)],
    );

    expect(find.byType(SdFreeLimitProgressV3), findsNothing);
  });
}
