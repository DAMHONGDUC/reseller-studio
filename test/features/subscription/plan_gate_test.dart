import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_limits.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_feature.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';

/// Every boundary reads its expected ceiling from `PlanLimits`, so the test
/// cannot keep passing against a stale number copied into prose.
void main() {
  final PlanLimits free = PlanLimits.of(SellerPlan.free);

  test('Free counts items and orders, and the last slot is usable', () {
    // The boundary, not the number: off by one here makes the advertised last
    // item impossible to create. See `PlanLimits.byPlan` for why the ceilings
    // are back.
    expect(free.items, isNotNull);
    expect(free.orders, isNotNull);
    expect(
      PlanGate.canAddItem(SellerPlan.free, currentItems: free.items! - 1),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddItem(SellerPlan.free, currentItems: free.items!),
      PlanBlock.itemLimit,
    );
    expect(
      PlanGate.canAddOrder(SellerPlan.free, currentOrders: free.orders! - 1),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddOrder(SellerPlan.free, currentOrders: free.orders!),
      PlanBlock.orderLimit,
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
    // opens the app at year end or on payout day to do — and every one of
    // them is refused somewhere, which `paywall_promises_test.dart` pins.
    for (final PlanFeature capability in PlanFeature.values) {
      expect(PlanGate.has(SellerPlan.free, capability), isFalse);
      expect(PlanGate.has(SellerPlan.premium, capability), isTrue);
    }
  });
}
