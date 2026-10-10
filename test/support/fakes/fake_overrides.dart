// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/account/account_kind.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/core/providers/system_permissions_provider.dart';
import 'package:reseller_studio/features/workspace/domain/entities/workspace.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

import 'fake_system_permissions.dart';
import 'in_memory_repositories.dart';
import 'passthrough_file_uploader.dart';

/// Points every repository at an in-memory store, for tests.
///
/// **This is what replaced the mock-data switch, and the difference is where
/// it lives.** The app used to carry both backends and choose between them at
/// runtime, which meant a fake business was one stale preference away from
/// being shown to a seller as if it were theirs. The fakes are test code now:
/// the app has exactly one backend, and what fills a real workspace is
/// `SeedDataSeeder` writing real documents through the real repositories.
///
/// The workspace providers are overridden rather than faked because they read
/// auth, which a widget test has none of — the store's own workspace is handed
/// straight to them.
final class FakeOverrides {
  /// [except] names the providers the caller overrides itself.
  ///
  /// Riverpod refuses two overrides of one provider in the same container, so
  /// a test wanting its own subscription repository has to say so — listing it
  /// after these throws at pump time rather than simply winning.
  /// `appConfigRepositoryProvider` is deliberately absent: `Firebase.apps` is
  /// empty in a widget test, so the real provider already hands back
  /// `FallbackAppConfigRepository` — the same `AppConfig.fallback` a fake
  /// would. Faking it here would only collide with the tests that supply their
  /// own config.
  static List<Override> forStore(
    MockStore store, {
    Set<Object> except = const <Object>{},
  }) {
    final Map<Object, Override> fakes = <Object, Override>{
      itemRepositoryProvider: itemRepositoryProvider.overrideWithValue(
        InMemoryItemRepository(store),
      ),
      orderRepositoryProvider: orderRepositoryProvider.overrideWithValue(
        InMemoryOrderRepository(store),
      ),
      offerRepositoryProvider: offerRepositoryProvider.overrideWithValue(
        InMemoryOfferRepository(store),
      ),
      listingRepositoryProvider: listingRepositoryProvider.overrideWithValue(
        InMemoryListingRepository(store),
      ),
      marketplaceRepositoryProvider: marketplaceRepositoryProvider
          .overrideWithValue(InMemoryMarketplaceRepository(store)),
      carrierRepositoryProvider: carrierRepositoryProvider.overrideWithValue(
        InMemoryCarrierRepository(store),
      ),
      sourceRepositoryProvider: sourceRepositoryProvider.overrideWithValue(
        InMemorySourceRepository(store),
      ),
      purchaseRepositoryProvider: purchaseRepositoryProvider.overrideWithValue(
        InMemoryPurchaseRepository(store),
      ),
      categoryRepositoryProvider: categoryRepositoryProvider.overrideWithValue(
        InMemoryCategoryRepository(store),
      ),
      locationRepositoryProvider: locationRepositoryProvider.overrideWithValue(
        InMemoryLocationRepository(store),
      ),
      expenseRepositoryProvider: expenseRepositoryProvider.overrideWithValue(
        InMemoryExpenseRepository(store),
      ),
      subscriptionRepositoryProvider: subscriptionRepositoryProvider
          .overrideWithValue(InMemorySubscriptionRepository(store)),
      workspacePurgeRepositoryProvider: workspacePurgeRepositoryProvider
          .overrideWithValue(InMemoryWorkspacePurgeRepository(store)),
      workspaceRepositoryProvider: workspaceRepositoryProvider
          .overrideWithValue(InMemoryWorkspaceRepository(store)),
      // No upload without a Firebase project behind it: a real one would fail
      // on the first byte.
      fileUploaderProvider: fileUploaderProvider.overrideWithValue(
        const PassthroughFileUploader(),
      ),
      // No platform channel in a widget test; nothing is refused unless a
      // test says so.
      systemPermissionsProvider: systemPermissionsProvider.overrideWithValue(
        FakeSystemPermissions(),
      ),
      // Team management needs a live backend, and the screen draws no add
      // button rather than offering one that cannot work.
      teamRepositoryProvider: teamRepositoryProvider.overrideWithValue(null),
      // The workspace answers a widget test cannot get from auth.
      currentWorkspaceIdProvider: currentWorkspaceIdProvider.overrideWithValue(
        store.dataset.workspace.id,
      ),
      hasWorkspaceProvider: hasWorkspaceProvider.overrideWithValue(true),
      // **A widget test is a signed-in seller with a fake backend.** Without
      // this the account kind resolves to guest, every repository reaches for
      // the real Drift database, and the first test to pump a screen opens a
      // file on a device that is not there.
      accountKindProvider: accountKindProvider.overrideWithValue(
        AccountKind.linked,
      ),
      workspaceStatusProvider: workspaceStatusProvider.overrideWithValue(
        WorkspaceStatus.ready,
      ),
      workspacesProvider: workspacesProvider.overrideWithValue(<Workspace>[
        store.dataset.workspace,
      ]),
      workspaceMembersProvider: workspaceMembersProvider.overrideWithValue(
        store.dataset.members,
      ),
    };

    for (final Object provider in except) {
      fakes.remove(provider);
    }

    return fakes.values.toList();
  }
}
