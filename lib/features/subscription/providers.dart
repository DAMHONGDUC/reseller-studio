/// Riverpod wiring for `subscription` — what the seller is entitled to, and
/// what that lets them do (plan §27).
///
/// **Every gate reads from here, never from a repository.** A screen that
/// asked the billing SDK a question directly would be a screen that behaves
/// differently from the gates, and the whole point of the gates is that they
/// are the same code in both.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/time/app_clock.dart';
import '../app_config/providers.dart';
import '../inventory/domain/entities/item.dart';
import '../inventory/providers.dart';
import '../orders/domain/entities/order.dart';
import '../orders/providers.dart';
import '../workspace/domain/entities/workspace.dart';
import '../workspace/providers.dart';
import 'domain/entities/plan_limits.dart';
import 'domain/entities/plan_offering.dart';
import 'domain/entities/subscription_status.dart';
import 'domain/enums/plan_allowance.dart';
import 'domain/enums/plan_feature.dart';
import 'domain/enums/seller_plan.dart';
import 'domain/services/plan_gate.dart';
import 'domain/services/plan_offering_catalogue.dart';
import 'presentation/controllers/subscription_controller.dart';

final StreamProvider<SubscriptionStatus> subscriptionStatusProvider =
    StreamProvider<SubscriptionStatus>((Ref ref) {
      return ref.watch(subscriptionRepositoryProvider).watchStatus();
    });

/// What is on sale, in the order the paywall presents it.
///
/// **A provider, never screen state.** The `AsyncValue` is what gives the
/// sheet a loading, an error *and* a data case; the local `bool` this replaced
/// could not tell the last two apart, so a store that failed to answer
/// rendered as a sheet with nothing to buy. Retrying is
/// `ref.invalidate(planOfferingsProvider)`.
final FutureProvider<List<PlanOffering>> planOfferingsProvider =
    FutureProvider<List<PlanOffering>>((Ref ref) async {
      final List<PlanOffering> offerings = await ref
          .read(subscriptionControllerProvider.notifier)
          .loadOfferings();

      return PlanOfferingCatalogue.ordered(offerings);
    });

/// The plan every gate reads.
///
/// **Falls back to Free while the entitlement is still loading**, and that
/// direction is deliberate: showing a paying seller the free tier for a
/// moment is a cosmetic bug, whereas defaulting to Premium would hand the
/// whole app away on every cold start.
///
/// **With monetisation switched off it answers Premium for everyone**, and
/// that is the whole of the kill switch: every ceiling, capability and block
/// in the app already asks this one question, so turning the plan system off
/// is one answer changing rather than a flag threaded through forty call
/// sites. `subscriptionStatusProvider` stays the honest record of what the
/// seller actually bought — read that, never this, to say so on screen.
///
/// **An account `app_config` names is Premium without having bought it**, the
/// same one-answer trick aimed at one person rather than everybody: the
/// owner, a tester, a seller being made whole after a billing failure.
final Provider<SellerPlan> currentPlanProvider = Provider<SellerPlan>((
  Ref ref,
) {
  if (!ref.watch(premiumEnabledProvider)) return SellerPlan.premium;
  if (ref.watch(premiumGrantedByEmailProvider)) return SellerPlan.premium;

  return ref.watch(subscriptionStatusProvider).value?.plan ?? SellerPlan.free;
});

final Provider<PlanLimits> currentLimitsProvider = Provider<PlanLimits>((
  Ref ref,
) {
  return PlanLimits.of(ref.watch(currentPlanProvider));
});

/// Whether the current plan includes a capability.
// See `itemProvider` for why a family's type is inferred rather than written.
// ignore: type_annotate_public_apis
final hasFeatureProvider = Provider.family<bool, PlanFeature>((
  Ref ref,
  PlanFeature feature,
) {
  return PlanGate.has(ref.watch(currentPlanProvider), feature);
});

/// Items that count against the plan's ceiling.
///
/// **Every item ever created counts, sold and archived included** — owner's
/// rule, and it is the ceiling being a lifetime one rather than a stock level.
/// Deleting a row is the only thing that gives a slot back, which is honest:
/// a deleted row is gone from every screen too. The stream already drops
/// soft-deleted rows, so the length is exactly "what this business has
/// created and kept".
///
/// **`refreshUsage` in Functions counts the same set**, because the rules read
/// its verdict: two spellings of one ceiling is a client that offers what the
/// backend refuses.
final Provider<int> countedItemsProvider = Provider<int>((Ref ref) {
  final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];

  return items.where((Item item) => !item.isDeleted).length;
});

/// Orders inside the plan's rolling window.
///
/// **A month's trading, not a lifetime's** — owner's rule. Counting every
/// order ever recorded walled a seller in at their thirty-first sale with no
/// way to free a slot, which punished exactly the seller who used the app
/// properly. The window moves with the clock, so a sale that falls out of it
/// returns its slot without anyone doing anything.
///
/// Read through `clockProvider` because it is a derived figure, not a recorded
/// one: a test pins the boundary rather than hoping the suite runs on the
/// right day.
final Provider<int> countedOrdersProvider = Provider<int>((Ref ref) {
  final List<Order> orders = ref.watch(ordersProvider).value ?? const <Order>[];
  final DateTime since = ref
      .watch(clockProvider)
      .now()
      .subtract(PlanLimits.orderWindow);

  return orders.where((Order order) => order.orderedAt.isAfter(since)).length;
});

final Provider<int> countedWorkspacesProvider = Provider<int>((Ref ref) {
  final List<Workspace> workspaces = ref.watch(workspacesProvider);

  return workspaces.length;
});

/// How many of one allowance are in use, whichever allowance is asked for.
///
/// **The three counters above, reachable by enum**, so a screen that walks
/// `PlanAllowance.values` never has to name them one at a time.
// See `itemProvider` for why a family's type is inferred rather than written.
// ignore: type_annotate_public_apis
final countedAllowanceProvider = Provider.family<int, PlanAllowance>((
  Ref ref,
  PlanAllowance allowance,
) {
  return switch (allowance) {
    PlanAllowance.items => ref.watch(countedItemsProvider),
    PlanAllowance.orders => ref.watch(countedOrdersProvider),
    PlanAllowance.workspaces => ref.watch(countedWorkspacesProvider),
  };
});

/// Whether one more item may be created, and why not when it may not.
///
/// Read by Quick Add and the add form **before** the sheet opens: refusing a
/// seller after they have typed a title is the worst moment to mention a
/// limit.
final Provider<PlanBlock> addItemBlockProvider = Provider<PlanBlock>((Ref ref) {
  return PlanGate.canAddItem(
    ref.watch(currentPlanProvider),
    currentItems: ref.watch(countedItemsProvider),
  );
});

final Provider<PlanBlock> addOrderBlockProvider = Provider<PlanBlock>((
  Ref ref,
) {
  return PlanGate.canAddOrder(
    ref.watch(currentPlanProvider),
    currentOrders: ref.watch(countedOrdersProvider),
  );
});

final Provider<PlanBlock> addWorkspaceBlockProvider = Provider<PlanBlock>((
  Ref ref,
) {
  return PlanGate.canAddWorkspace(
    ref.watch(currentPlanProvider),
    currentWorkspaces: ref.watch(countedWorkspacesProvider),
  );
});
