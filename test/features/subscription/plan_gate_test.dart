import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_limits.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_feature.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';

/// The gate decides what a plan may do, and the only interesting part of a
/// limit is its boundary — so that is what is asserted, not the middle.
///
/// The expected numbers are read from `PlanLimits`, never typed here: a test
/// that hardcodes 50 passes for the wrong reason the day the price changes.
void main() {
  group('item limit', () {
    final int freeItems = PlanLimits.of(SellerPlan.free).items!;

    test('the last item under the limit is allowed', () {
      expect(
        PlanGate.canAddItem(SellerPlan.free, currentItems: freeItems - 1),
        PlanBlock.none,
      );
    });

    test('holding exactly the limit blocks the next one', () {
      expect(
        PlanGate.canAddItem(SellerPlan.free, currentItems: freeItems),
        PlanBlock.itemLimit,
      );
    });

    test('a paid plan with no ceiling never blocks', () {
      expect(PlanLimits.of(SellerPlan.pro).items, isNull);
      expect(
        PlanGate.canAddItem(SellerPlan.pro, currentItems: 100000),
        PlanBlock.none,
      );
    });

    test('an empty workspace on the smallest plan is allowed', () {
      expect(
        PlanGate.canAddItem(SellerPlan.free, currentItems: 0),
        PlanBlock.none,
      );
    });
  });

  group('team', () {
    test('a one-person plan is blocked on the feature, not the seat count', () {
      // The honest message is "this plan has no team", and a seat-count block
      // would send the seller looking for a seat to free up.
      expect(
        PlanGate.canInviteMember(SellerPlan.free, currentMembers: 0),
        PlanBlock.featureLocked,
      );
      expect(
        PlanGate.canInviteMember(SellerPlan.pro, currentMembers: 0),
        PlanBlock.featureLocked,
      );
    });

    test('Business fills its seats and then blocks', () {
      final int seats = PlanLimits.of(SellerPlan.business).members!;

      expect(
        PlanGate.canInviteMember(
          SellerPlan.business,
          currentMembers: seats - 1,
        ),
        PlanBlock.none,
      );
      expect(
        PlanGate.canInviteMember(SellerPlan.business, currentMembers: seats),
        PlanBlock.memberLimit,
      );
    });
  });

  group('features', () {
    test('a plan includes everything the cheaper ones do', () {
      for (final PlanFeature feature in PlanFeature.values) {
        if (PlanGate.has(SellerPlan.pro, feature)) {
          expect(
            PlanGate.has(SellerPlan.business, feature),
            isTrue,
            reason: '${feature.name} is in Pro but not in Business',
          );
        }
      }
    });

    test('Free includes none of the gated ones', () {
      for (final PlanFeature feature in PlanFeature.values) {
        expect(
          PlanGate.has(SellerPlan.free, feature),
          isFalse,
          reason: '${feature.name} would be free',
        );
      }
    });
  });

  group('where a block sends the seller', () {
    test('nothing to upgrade to when nothing is blocked', () {
      expect(
        PlanGate.upgradeFor(PlanBlock.none, from: SellerPlan.free),
        isNull,
      );
    });

    test('a stock limit points at Pro, a team block at Business', () {
      expect(
        PlanGate.upgradeFor(PlanBlock.itemLimit, from: SellerPlan.free),
        SellerPlan.pro,
      );
      expect(
        PlanGate.upgradeFor(PlanBlock.featureLocked, from: SellerPlan.pro),
        SellerPlan.business,
      );
    });

    test('the top plan never points past itself', () {
      expect(
        PlanGate.upgradeFor(
          PlanBlock.marketplaceLimit,
          from: SellerPlan.business,
        ),
        SellerPlan.business,
      );
    });
  });
}
