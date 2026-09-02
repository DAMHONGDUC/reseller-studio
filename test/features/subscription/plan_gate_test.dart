import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_limits.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_feature.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';

/// Every boundary reads its expected ceiling from `PlanLimits`, so the test
/// cannot keep passing against a stale number copied into prose.
void main() {
  final PlanLimits free = PlanLimits.of(SellerPlan.free);

  test('Free no longer counts items or orders', () {
    // The ceiling used to stop a seller at 50 items — which is exactly where
    // sell-through, ROI by source and the tax pack start being worth
    // something, so it blocked the reason to pay. Premium sells the answers
    // instead; see `PlanLimits.byPlan`.
    expect(free.items, isNull);
    expect(free.orders, isNull);
    expect(
      PlanGate.canAddItem(SellerPlan.free, currentItems: 100000),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddOrder(SellerPlan.free, currentOrders: 100000),
      PlanBlock.none,
    );
  });

  test('a second business is still the one Free ceiling', () {
    expect(
      PlanGate.canAddWorkspace(
        SellerPlan.free,
        currentWorkspaces: free.workspaces! - 1,
      ),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddWorkspace(
        SellerPlan.free,
        currentWorkspaces: free.workspaces!,
      ),
      PlanBlock.workspaceLimit,
    );
  });

  test('Premium removes every usage ceiling', () {
    final PlanLimits premium = PlanLimits.of(SellerPlan.premium);

    expect(premium.items, isNull);
    expect(premium.orders, isNull);
    expect(premium.workspaces, isNull);
    expect(
      PlanGate.canAddItem(SellerPlan.premium, currentItems: 100000),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddOrder(SellerPlan.premium, currentOrders: 100000),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddWorkspace(SellerPlan.premium, currentWorkspaces: 100000),
      PlanBlock.none,
    );
  });

  test('every paid feature belongs to Premium', () {
    for (final PlanFeature feature in PlanFeature.values) {
      expect(PlanGate.has(SellerPlan.free, feature), isFalse);
      expect(PlanGate.has(SellerPlan.premium, feature), isTrue);
    }
  });

  test('every block points to Premium', () {
    for (final PlanBlock block in PlanBlock.values) {
      expect(
        PlanGate.upgradeFor(block, from: SellerPlan.free),
        block == PlanBlock.none ? isNull : SellerPlan.premium,
      );
    }
  });

  test('Premium is what buys the answers, not permission to type', () {
    // The paid line is a capability now. Every one of these is what a seller
    // opens the app at year end or on payout day to do.
    for (final PlanFeature capability in <PlanFeature>[
      PlanFeature.taxExport,
      PlanFeature.payoutReconciliation,
      PlanFeature.advancedAnalytics,
      PlanFeature.team,
    ]) {
      expect(PlanGate.has(SellerPlan.free, capability), isFalse);
      expect(PlanGate.has(SellerPlan.premium, capability), isTrue);
    }
  });
}
