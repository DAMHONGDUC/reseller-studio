import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/drain/drain_destination.dart';
import '../../../../core/local/local_providers.dart';
import '../../../auth/providers.dart';
import '../../../carriers/providers.dart';
import '../../../inventory/providers.dart';
import '../../../marketplaces/providers.dart';
import '../../domain/entities/workspace.dart';
import '../../providers.dart';
import '../../workspace_constant.dart';

/// Moving a guest's records into the account that just signed in.
///
/// **The seller is asked only when there is something to ask** — owner's
/// rule (`docs/rules/GUEST_MODE.md`). An account with no business takes the
/// guest one whole and nothing is put in the way; an account that already has
/// one is asked, because emptying a guest's stock into a business with real
/// books is a merge nobody can undo.
///
/// Nothing on screen waits on this. The rows go up behind the app, and the
/// seller carries on looking at them the whole time — they are still the same
/// records, read from the other store.
class GuestDrainController extends Notifier<bool> {
  /// True while a drain is running. Read only so a second trigger does not
  /// start one on top of the first.
  @override
  bool build() => false;

  /// What to do for the account now signed in, or null when the device holds
  /// nothing worth moving.
  Future<DrainDestination?> decide() async {
    final int owed = await ref.read(guestRowsOwedProvider.future);

    if (owed == 0) return null;

    final String? pending = await ref
        .read(guestDrainServiceProvider)
        .pendingDestination();

    // **A drain that was interrupted already has an answer.** Asking again
    // would put the dialog in front of the seller on every launch until it
    // finished, and a different answer the second time would split one
    // business's records across two.
    if (pending != null) return DrainIntoWorkspace(pending);

    return DrainDestination.forAccount(ref.read(workspacesProvider));
  }

  /// Create a business from the guest's own and push everything into it.
  ///
  /// The name, country and currency come from the local workspace rather than
  /// from a form: the seller already answered those, implicitly, by using the
  /// app — asking again would be the setup screen hard rule 2 exists to avoid.
  Future<void> intoNewWorkspace() async {
    final Workspace? guest = ref.read(guestWorkspaceProvider).value;
    final String? uid = ref.read(currentUidProvider);

    if (guest == null || uid == null) return;

    final String workspaceId = await ref
        .read(workspaceRepositoryProvider)
        .createWorkspace(
          name: guest.name,
          country: guest.country,
          currency: guest.currency,
          ownerId: uid,
          marketplaces: ref.read(defaultMarketplacesProvider),
          categories: ref.read(defaultItemCategoriesProvider),
          carriers: ref.read(defaultCarriersProvider),
        );

    await intoWorkspace(workspaceId);
  }

  /// Push everything into a business the account already has.
  Future<void> intoWorkspace(String workspaceId) async {
    if (state) return;

    state = true;

    try {
      final Workspace? guest = ref.read(guestWorkspaceProvider).value;
      final String? uid = ref.read(currentUidProvider);

      if (uid == null) return;

      SdLogger.action(
        LogTagConstant.workspace,
        'Sync guest records',
        <String, Object>{'workspaceId': workspaceId},
      );

      await ref
          .read(guestDrainServiceProvider)
          .run(
            workspaceId: workspaceId,
            uid: uid,
            currency: guest?.currency ?? WorkspaceConstant.fallbackCurrency,
          );

      ref.invalidate(guestRowsOwedProvider);
      AppAnalytics.instance.guestRecordsSynced();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.workspace,
        'Could not sync guest records',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'workspaceId': workspaceId},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<GuestDrainController, bool>
guestDrainControllerProvider = NotifierProvider<GuestDrainController, bool>(
  GuestDrainController.new,
);
