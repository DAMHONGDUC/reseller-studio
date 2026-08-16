/// Riverpod wiring for `subscription` — what the seller is entitled to, and
/// what that lets them do (plan §27).
///
/// **Every gate reads from here, never from a repository.** A screen that
/// asked the billing SDK a question directly would be a screen that behaves
/// differently in mock mode, and the whole point of the gates is that they
/// are the same code in both.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../inventory/domain/entities/item.dart';
import '../inventory/domain/enums/item_status.dart';
import '../inventory/providers.dart';
import '../listings/domain/entities/listing.dart';
import '../listings/providers.dart';
import '../mock_data/providers.dart';
import 'domain/entities/plan_limits.dart';
import 'domain/entities/subscription_status.dart';
import 'domain/enums/plan_feature.dart';
import 'domain/enums/seller_plan.dart';
import 'domain/services/plan_gate.dart';

final StreamProvider<SubscriptionStatus> subscriptionStatusProvider =
    StreamProvider<SubscriptionStatus>((Ref ref) {
      return ref.watch(subscriptionRepositoryProvider).watchStatus();
    });

/// The plan every gate reads.
///
/// **Falls back to Free while the entitlement is still loading**, and that
/// direction is deliberate: showing a paying seller the free tier for a
/// moment is a cosmetic bug, whereas defaulting to Business would hand the
/// whole app away on every cold start.
final Provider<SellerPlan> currentPlanProvider = Provider<SellerPlan>((
  Ref ref,
) {
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
/// **Sold and archived rows do not count.** The limit is about how much stock
/// a seller is holding, not how much they have ever typed in — counting
/// history would mean a Free seller who runs the app properly for a year is
/// locked out by their own success at selling.
final Provider<int> countedItemsProvider = Provider<int>((Ref ref) {
  final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];

  return items
      .where(
        (Item item) =>
            !item.isDeleted &&
            item.status != ItemStatus.sold &&
            item.status != ItemStatus.archived,
      )
      .length;
});

final Provider<int> countedListingsProvider = Provider<int>((Ref ref) {
  final List<Listing> listings =
      ref.watch(listingsProvider).value ?? const <Listing>[];

  return listings.where((Listing listing) => listing.status.isLive).length;
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

final Provider<PlanBlock> listItemBlockProvider = Provider<PlanBlock>((
  Ref ref,
) {
  return PlanGate.canListItem(
    ref.watch(currentPlanProvider),
    currentActiveListings: ref.watch(countedListingsProvider),
  );
});
