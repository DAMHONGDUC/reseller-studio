import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/error/app_failure.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_offering.dart';
import 'package:reseller_studio/features/subscription/domain/entities/subscription_status.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_offering_catalogue.dart';
import 'package:reseller_studio/features/subscription/presentation/controllers/paywall_selection_controller.dart';
import 'package:reseller_studio/features/subscription/presentation/controllers/subscription_controller.dart';

import '../../support/fakes/in_memory_repositories.dart';
import '../../support/fakes/mock_dataset.dart';
import '../../support/pump_app.dart';

/// The paid path, from the controller's side (plan §25, §27).
///
/// **Nothing here handles a receipt.** What the app is allowed to know is an
/// entitlement, so what these pin is the shape around it: that a closed store
/// sheet is not an error, that a real failure still reaches the screen, and
/// that the busy flag the paywall spins on is always put back.
class _RefusingBilling implements SubscriptionRepository {
  _RefusingBilling(this.failure);

  final Object failure;

  @override
  Stream<SubscriptionStatus> watchStatus() =>
      Stream<SubscriptionStatus>.value(SubscriptionStatus.free);

  @override
  Future<List<PlanOffering>> offerings() async => throw failure;

  @override
  Future<SubscriptionStatus> purchase(PlanOffering offering) async =>
      throw failure;

  @override
  Future<SubscriptionStatus> restore() async => throw failure;

  @override
  Future<void> identify(String uid) async {}

  @override
  Future<void> forget() async {}
}

/// A purchase the seller backs out of: the store's sheet closes and the plan
/// is exactly what it was.
class _CancellingBilling extends InMemorySubscriptionRepository {
  _CancellingBilling(super.store);

  @override
  Future<SubscriptionStatus> purchase(PlanOffering offering) async =>
      SubscriptionStatus.free;
}

/// A purchase that does not finish until the test lets it.
class _SlowBilling extends InMemorySubscriptionRepository {
  _SlowBilling(super.store, this.gate);

  final Completer<SubscriptionStatus> gate;

  @override
  Future<SubscriptionStatus> purchase(PlanOffering offering) => gate.future;
}

void main() {
  MockStore store() => MockStore(MockDataset.seed(now: testNow));

  ProviderContainer billingWith(SubscriptionRepository billing) =>
      mockContainer(
        overrides: <Override>[
          subscriptionRepositoryProvider.overrideWithValue(billing),
        ],
        replaces: <Object>{subscriptionRepositoryProvider},
      );

  PlanOffering monthly() => InMemorySubscriptionRepository.catalogue.first;

  group('purchase', () {
    test('a completed purchase returns the new entitlement', () async {
      final ProviderContainer container = billingWith(
        InMemorySubscriptionRepository(store()),
      );

      final SubscriptionStatus status = await container
          .read(subscriptionControllerProvider.notifier)
          .purchase(monthly());

      expect(status.plan, SellerPlan.premium);
      expect(container.read(subscriptionControllerProvider), isFalse);
    });

    test('backing out of the store sheet is not an error', () async {
      final ProviderContainer container = billingWith(
        _CancellingBilling(store()),
      );

      // Unchanged status, no throw: the seller closed a sheet, the same rule
      // sign-in follows.
      final SubscriptionStatus status = await container
          .read(subscriptionControllerProvider.notifier)
          .purchase(monthly());

      expect(status.plan, SellerPlan.free);
    });

    test(
      'a failed purchase reaches the screen and stops the spinner',
      () async {
        final ProviderContainer container = billingWith(
          _RefusingBilling(const AppFailure(AppFailureKind.offline)),
        );

        await expectLater(
          container
              .read(subscriptionControllerProvider.notifier)
              .purchase(monthly()),
          throwsA(isA<AppFailure>()),
        );
        expect(container.read(subscriptionControllerProvider), isFalse);
      },
    );

    test('the paywall is busy only while the sheet is open', () async {
      final Completer<SubscriptionStatus> gate =
          Completer<SubscriptionStatus>();
      final ProviderContainer container = billingWith(
        _SlowBilling(store(), gate),
      );
      final Future<SubscriptionStatus> pending = container
          .read(subscriptionControllerProvider.notifier)
          .purchase(monthly());

      expect(container.read(subscriptionControllerProvider), isTrue);

      gate.complete(SubscriptionStatus.free);
      await pending;

      expect(container.read(subscriptionControllerProvider), isFalse);
    });
  });

  group('restore', () {
    test('restoring hands back what the store has', () async {
      final MockStore backing = store();
      final ProviderContainer container = billingWith(
        InMemorySubscriptionRepository(backing),
      );

      await container
          .read(subscriptionControllerProvider.notifier)
          .purchase(monthly());

      // App Store review requires this: a reinstall must get the plan back
      // without paying again.
      final SubscriptionStatus status = await container
          .read(subscriptionControllerProvider.notifier)
          .restore();

      expect(status.plan, SellerPlan.premium);
    });

    test('a failed restore is an error, not a silent downgrade', () async {
      final ProviderContainer container = billingWith(
        _RefusingBilling(const AppFailure(AppFailureKind.unknown)),
      );

      await expectLater(
        container.read(subscriptionControllerProvider.notifier).restore(),
        throwsA(isA<AppFailure>()),
      );
      expect(container.read(subscriptionControllerProvider), isFalse);
    });
  });

  group('offerings', () {
    test('what is on sale comes back as the store lists it', () async {
      final ProviderContainer container = billingWith(
        InMemorySubscriptionRepository(store()),
      );

      expect(
        await container
            .read(subscriptionControllerProvider.notifier)
            .loadOfferings(),
        hasLength(InMemorySubscriptionRepository.catalogue.length),
      );
    });

    test('a failed load is not an empty catalogue', () async {
      final ProviderContainer container = billingWith(
        _RefusingBilling(const AppFailure(AppFailureKind.offline)),
      );

      // An empty list is what "billing is not configured" means, and the
      // paywall renders its own message from it — so a failure must not
      // arrive looking like one.
      await expectLater(
        container.read(subscriptionControllerProvider.notifier).loadOfferings(),
        throwsA(isA<AppFailure>()),
      );
    });
  });

  group('paywall selection', () {
    test('the period the paywall opens on is the recommended one', () {
      final ProviderContainer container = mockContainer();

      expect(
        container.read(paywallSelectionProvider),
        PlanOfferingCatalogue.recommended,
      );
    });

    test('selecting a period holds it, and reselecting changes nothing', () {
      final ProviderContainer container = mockContainer();
      int notifications = 0;

      container.listen<BillingPeriod>(
        paywallSelectionProvider,
        (BillingPeriod? previous, BillingPeriod next) => notifications++,
      );

      container
          .read(paywallSelectionProvider.notifier)
          .select(BillingPeriod.monthly);
      container
          .read(paywallSelectionProvider.notifier)
          .select(BillingPeriod.monthly);

      expect(container.read(paywallSelectionProvider), BillingPeriod.monthly);
      expect(notifications, 1);
    });
  });
}
