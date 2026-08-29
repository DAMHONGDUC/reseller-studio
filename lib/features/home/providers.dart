import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../inventory/domain/entities/item.dart';
import '../inventory/providers.dart';
import '../listings/domain/entities/listing.dart';
import '../listings/providers.dart';
import '../orders/domain/entities/order.dart';
import '../orders/providers.dart';
import 'domain/enums/getting_started_step.dart';
import 'domain/enums/workspace_activity.dart';
import 'domain/services/getting_started_progress.dart';

/// Whether the workspace has ever held anything.
///
/// Items and orders both, because either one alone is a business that started:
/// a seller who imported orders has begun even with an empty item list.
///
/// **Both streams must have delivered before this answers.** `value ?? []`
/// would read a loading stream as an empty business and flash "start here" at
/// a seller with four hundred items — the same mistake as showing the login
/// form while auth resolves.
final Provider<WorkspaceActivity> workspaceActivityProvider =
    Provider<WorkspaceActivity>((Ref ref) {
      final AsyncValue<List<Item>> items = ref.watch(itemsProvider);
      final AsyncValue<List<Order>> orders = ref.watch(ordersProvider);

      if (!items.hasValue || !orders.hasValue) {
        return WorkspaceActivity.unknown;
      }

      return items.value!.isEmpty && orders.value!.isEmpty
          ? WorkspaceActivity.untouched
          : WorkspaceActivity.active;
    });

/// Which of the three first moves this workspace has made, or null while a
/// source is still loading.
///
/// **Null rather than an empty set**, for the reason `workspaceActivityProvider`
/// spells out: `value ?? []` would read a loading stream as a seller who has
/// done nothing, and Home would offer the checklist for a frame to somebody
/// who finished it months ago.
final Provider<Set<GettingStartedStep>?> gettingStartedProvider =
    Provider<Set<GettingStartedStep>?>((Ref ref) {
      final AsyncValue<List<Item>> items = ref.watch(itemsProvider);
      final AsyncValue<List<Listing>> listings = ref.watch(listingsProvider);
      final AsyncValue<List<Order>> orders = ref.watch(ordersProvider);

      if (!items.hasValue || !listings.hasValue || !orders.hasValue) {
        return null;
      }

      return GettingStartedProgress.completed(
        items: items.value!,
        listings: listings.value!,
        orders: orders.value!,
      );
    });
