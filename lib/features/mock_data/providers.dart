/// Riverpod wiring for the mock backend, and the switch between it and the
/// real one. Other features import this file, never anything under `data/`.
library;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/dev_flags.dart';
import '../../core/constants/prefs_key_constant.dart';
import '../../core/firestore/workspace_context.dart';
import '../../core/logging/app_logger.dart';
import '../../core/storage/file_uploader.dart';
import '../../core/storage/firebase_file_uploader.dart';
import '../../core/storage/local_file_uploader.dart';
import '../expenses/data/repositories/firestore_expense_repository.dart';
import '../expenses/domain/repositories/expense_repository.dart';
import '../inventory/data/repositories/firestore_catalog_repositories.dart';
import '../inventory/data/repositories/firestore_item_repository.dart';
import '../inventory/domain/repositories/catalog_repository.dart';
import '../inventory/domain/repositories/item_repository.dart';
import '../listings/data/repositories/firestore_listing_repository.dart';
import '../listings/domain/repositories/listing_repository.dart';
import '../orders/data/repositories/firestore_order_repository.dart';
import '../orders/domain/repositories/order_repository.dart';
import '../sourcing/data/repositories/firestore_sourcing_repositories.dart';
import '../sourcing/domain/repositories/sourcing_repository.dart';
import '../workspace/providers.dart';
import 'data/in_memory_repositories.dart';

/// Where the app's data comes from.
enum DataMode {
  /// Firestore. The real thing, and the only mode that ships.
  live,

  /// The seeded in-memory dataset. Every screen renders against a coherent
  /// fake business, and nothing touches the network.
  mock;

  bool get isMock => this == DataMode.mock;
}

/// Whether the app is reading mock data, persisted across restarts.
///
/// **Persisted, unlike the auth bypass**, and the difference is deliberate:
/// the bypass is a build-time flag because it must be impossible to enable in
/// a shipped binary, whereas this is a *setting* a developer toggles from
/// inside the running app and expects to still be set tomorrow.
///
/// That makes it the weaker of the two guarantees, so it carries its own:
/// **[build] refuses to return [DataMode.mock] in a release build**, whatever
/// is stored. A user who somehow had the flag set could otherwise be shown a
/// fake business as if it were theirs — which is worse than any crash.
class DataModeController extends Notifier<DataMode> {
  @override
  DataMode build() {
    final SharedPreferences? prefs = ref.watch(sharedPreferencesProvider).value;

    if (prefs == null) return _default;

    final bool stored = prefs.getBool(PrefsKeyConstant.dataModeMock) ?? DevFlags.mockDataDefault;

    return stored ? _guarded(DataMode.mock) : DataMode.live;
  }

  /// What mock mode starts as before anyone touches the switch.
  ///
  /// `DevFlags.mockDataDefault` follows the auth bypass unless the env file
  /// overrides it, because the two go together: a bypassed session has no
  /// Firebase project and no signed-in user, so live mode would show an empty
  /// app and a stream of permission errors. Turning both on at once is what
  /// makes `--dart-define-from-file=env/dev.json` produce something worth
  /// looking at.
  static DataMode get _default =>
      DevFlags.mockDataDefault ? DataMode.mock : DataMode.live;

  static DataMode _guarded(DataMode mode) {
    if (mode.isMock && !DevFlags.isDebugOrProfile) {
      AppLogger.warning('Mock data requested in a release build — ignoring');

      return DataMode.live;
    }

    return mode;
  }

  Future<void> setMode(DataMode mode) async {
    final DataMode resolved = _guarded(mode);

    state = resolved;

    final SharedPreferences? prefs = ref.read(sharedPreferencesProvider).value;

    if (prefs == null) {
      AppLogger.warning('Could not persist data mode — preferences not ready');

      return;
    }

    await prefs.setBool(PrefsKeyConstant.dataModeMock, resolved.isMock);
    AppLogger.action('Data mode changed', <String, String>{
      'mode': resolved.name,
    });
  }

  Future<void> toggle() =>
      setMode(state.isMock ? DataMode.live : DataMode.mock);
}

final NotifierProvider<DataModeController, DataMode> dataModeProvider =
    NotifierProvider<DataModeController, DataMode>(DataModeController.new);

/// `SharedPreferences`, as an async provider so nothing blocks startup on it.
final FutureProvider<SharedPreferences> sharedPreferencesProvider =
    FutureProvider<SharedPreferences>(
      (Ref ref) => SharedPreferences.getInstance(),
    );

/// The seeded store, built once and torn down with the provider.
///
/// `keepAlive` is not used: when the app leaves mock mode this disposes, and
/// coming back re-seeds from the current clock — which is what keeps the demo
/// data looking recent rather than slowly ageing into an abandoned business.
final Provider<MockStore> mockStoreProvider = Provider<MockStore>((Ref ref) {
  final MockStore store = MockStore.seeded();

  ref.onDispose(store.dispose);
  AppLogger.info('Mock dataset seeded', <String, int>{
    'items': store.items.length,
    'orders': store.orders.length,
  });

  return store;
});

/// What the seeded dataset contains, for the Settings card to display.
///
/// A value type rather than handing `MockStore` to the UI: the store is a
/// data-layer object with mutable lists and a stream controller, and a screen
/// that held one could write to it. Presentation gets counts.
class MockDataSummary {
  const MockDataSummary({
    required this.workspaceName,
    required this.items,
    required this.orders,
    required this.listings,
    required this.sources,
    required this.expenses,
  });

  final String workspaceName;
  final int items;
  final int orders;
  final int listings;
  final int sources;
  final int expenses;
}

final Provider<MockDataSummary> mockDataSummaryProvider =
    Provider<MockDataSummary>((Ref ref) {
      final MockStore store = ref.watch(mockStoreProvider);

      return MockDataSummary(
        workspaceName: store.dataset.workspace.name,
        items: store.items.length,
        orders: store.orders.length,
        listings: store.listings.length,
        sources: store.sources.length,
        expenses: store.expenses.length,
      );
    });

/// Thrown when a screen reads a repository in live mode before there is a
/// workspace to read from.
///
/// A named error rather than a null: the router keeps a user without a
/// workspace on the onboarding route, so reaching this means a screen is
/// mounted that should not be, and a message saying which repository and why
/// is the difference between a five-minute fix and an afternoon.
final class LiveRepositoryGuard {
  static Never noWorkspace(String repository) => throw StateError(
    '$repository was read with no active workspace. Sign in and finish '
    'workspace setup, or turn on mock data in More → Settings.',
  );
}

final Provider<ItemRepository> itemRepositoryProvider =
    Provider<ItemRepository>((Ref ref) {
      if (ref.watch(dataModeProvider).isMock) {
        return InMemoryItemRepository(ref.watch(mockStoreProvider));
      }

      final WorkspaceContext? context = ref.watch(workspaceContextProvider);

      if (context == null) LiveRepositoryGuard.noWorkspace('ItemRepository');

      return FirestoreItemRepository(context);
    });

final Provider<OrderRepository> orderRepositoryProvider =
    Provider<OrderRepository>((Ref ref) {
      if (ref.watch(dataModeProvider).isMock) {
        return InMemoryOrderRepository(ref.watch(mockStoreProvider));
      }

      final WorkspaceContext? context = ref.watch(workspaceContextProvider);

      if (context == null) LiveRepositoryGuard.noWorkspace('OrderRepository');

      return FirestoreOrderRepository(context);
    });

final Provider<ListingRepository> listingRepositoryProvider =
    Provider<ListingRepository>((Ref ref) {
      if (ref.watch(dataModeProvider).isMock) {
        return InMemoryListingRepository(ref.watch(mockStoreProvider));
      }

      final WorkspaceContext? context = ref.watch(workspaceContextProvider);

      if (context == null) {
        LiveRepositoryGuard.noWorkspace('ListingRepository');
      }

      return FirestoreListingRepository(context);
    });

final Provider<SourceRepository> sourceRepositoryProvider =
    Provider<SourceRepository>((Ref ref) {
      if (ref.watch(dataModeProvider).isMock) {
        return InMemorySourceRepository(ref.watch(mockStoreProvider));
      }

      final WorkspaceContext? context = ref.watch(workspaceContextProvider);

      if (context == null) LiveRepositoryGuard.noWorkspace('SourceRepository');

      return FirestoreSourceRepository(context);
    });

final Provider<PurchaseRepository> purchaseRepositoryProvider =
    Provider<PurchaseRepository>((Ref ref) {
      if (ref.watch(dataModeProvider).isMock) {
        return InMemoryPurchaseRepository(ref.watch(mockStoreProvider));
      }

      final WorkspaceContext? context = ref.watch(workspaceContextProvider);

      if (context == null) {
        LiveRepositoryGuard.noWorkspace('PurchaseRepository');
      }

      return FirestorePurchaseRepository(context);
    });

/// Where photos and receipts go.
///
/// Mock mode keeps the local path rather than uploading: there is no Firebase
/// project behind it, so a real upload would fail on the first byte.
final Provider<FileUploader> fileUploaderProvider = Provider<FileUploader>((
  Ref ref,
) {
  if (ref.watch(dataModeProvider).isMock) return const LocalFileUploader();

  final WorkspaceContext? context = ref.watch(workspaceContextProvider);

  if (context == null) LiveRepositoryGuard.noWorkspace('FileUploader');

  return FirebaseFileUploader(FirebaseStorage.instance, context.workspaceId);
});

final Provider<CategoryRepository> categoryRepositoryProvider =
    Provider<CategoryRepository>((Ref ref) {
      if (ref.watch(dataModeProvider).isMock) {
        return InMemoryCategoryRepository(ref.watch(mockStoreProvider));
      }

      final WorkspaceContext? context = ref.watch(workspaceContextProvider);

      if (context == null) {
        LiveRepositoryGuard.noWorkspace('CategoryRepository');
      }

      return FirestoreCategoryRepository(context);
    });

final Provider<LocationRepository> locationRepositoryProvider =
    Provider<LocationRepository>((Ref ref) {
      if (ref.watch(dataModeProvider).isMock) {
        return InMemoryLocationRepository(ref.watch(mockStoreProvider));
      }

      final WorkspaceContext? context = ref.watch(workspaceContextProvider);

      if (context == null) {
        LiveRepositoryGuard.noWorkspace('LocationRepository');
      }

      return FirestoreLocationRepository(context);
    });

final Provider<ExpenseRepository> expenseRepositoryProvider =
    Provider<ExpenseRepository>((Ref ref) {
      if (ref.watch(dataModeProvider).isMock) {
        return InMemoryExpenseRepository(ref.watch(mockStoreProvider));
      }

      final WorkspaceContext? context = ref.watch(workspaceContextProvider);

      if (context == null) {
        LiveRepositoryGuard.noWorkspace('ExpenseRepository');
      }

      return FirestoreExpenseRepository(context);
    });
