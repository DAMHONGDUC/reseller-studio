/// Riverpod wiring for the guest store (`docs/rules/GUEST_MODE.md`).
library;

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../features/auth/providers.dart';
import '../../features/carriers/providers.dart';
import '../../features/inventory/providers.dart';
import '../../features/marketplaces/providers.dart';
import '../../features/workspace/data/dtos/workspace_dto.dart';
import '../../features/workspace/domain/entities/workspace.dart';
import '../../features/workspace/providers.dart';
import '../account/account_kind.dart';
import '../constants/guest_constant.dart';
import '../firestore/workspace_collections.dart';
import '../fresh_install/app_fresh_install.dart';
import '../providers/repository_providers.dart';
import 'drain/drain_sink.dart';
import 'drain/guest_drain_service.dart';
import 'guest_reset_service.dart';
import 'guest_workspace_service.dart';
import 'local_database.dart';
import 'local_row.dart';
import 'local_table.dart';

/// The one guest database, open for the life of the app.
///
/// **Not disposed when the seller signs in.** The drain reads it after
/// sign-in, and sign-out empties it (`LocalDatabase.wipe`) rather than
/// closing it — a connection reopened per read would lose Drift's own
/// stream invalidation and every list would stop updating.
final Provider<LocalDatabase> localDatabaseProvider = Provider<LocalDatabase>((
  Ref ref,
) {
  final LocalDatabase db = LocalDatabase();

  ref.onDispose(db.close);

  return db;
});

/// The guest's own business, live.
///
/// Null until it has been created — the state the app spends its first
/// moments in, and the reason `GuestWorkspaceService` runs behind the splash.
final StreamProvider<Workspace?> guestWorkspaceProvider =
    StreamProvider<Workspace?>((Ref ref) {
      final LocalDatabase db = ref.watch(localDatabaseProvider);

      return LocalTable(db, db.localWorkspaces)
          .watchOne(GuestConstant.workspaceId)
          .map(
            (LocalDocument? doc) =>
                doc == null ? null : WorkspaceDto.fromMap(doc.id, doc.data),
          );
    });

/// Whether the guest business exists yet.
///
/// The app is unusable until it does — every repository would be reading an
/// empty store with no currency behind it — so the splash waits on this the
/// way it waits on the fresh-install check.
final Provider<bool> guestWorkspaceReadyProvider = Provider<bool>((Ref ref) {
  if (ref.watch(accountKindProvider) == AccountKind.linked) return true;

  return ref.watch(guestWorkspaceProvider).value != null;
});

/// Creates the guest business, once, behind the splash.
///
/// **After the fresh-install check, never before.** A reinstall or an
/// environment change wipes the device, and a business created above that
/// would be wiped with it — or worse, survive into the other environment.
/// Chaining the two here is what orders them.
///
/// A `FutureProvider` so it runs once per launch however many times the gate
/// rebuilds, the same reason `freshInstallProvider` is one.
final FutureProvider<void> guestBusinessProvider = FutureProvider<void>((
  Ref ref,
) async {
  final SdFreshInstallOutcome outcome = await ref.watch(
    freshInstallProvider.future,
  );
  final LocalDatabase db = ref.watch(localDatabaseProvider);

  // The design system's wipe knows nothing about this app's tables, so the
  // two outcomes that mean "start over" empty them here. Without it a build
  // pointed at the other environment opens on the previous one's stock.
  if (outcome == SdFreshInstallOutcome.reinstall ||
      outcome == SdFreshInstallOutcome.environmentChanged) {
    await db.wipe();
  }

  // Signed in, so the records are Firestore's and there is no guest business
  // to make. The drain is what creates one in the other direction.
  if (ref.read(accountKindProvider) == AccountKind.linked) return;

  await GuestWorkspaceService(db).ensureExists(
    marketplaces: ref.read(defaultMarketplacesProvider),
    categories: ref.read(defaultItemCategoriesProvider),
    carriers: ref.read(defaultCarriersProvider),
  );
});

/// Wipes the device back to a blank guest, for sign-out.
final Provider<GuestResetService> guestResetServiceProvider =
    Provider<GuestResetService>(
      (Ref ref) => GuestResetService(
        ref.watch(localDatabaseProvider),
        // Checked before the instance is touched, never after: watching it is
        // itself what throws when there is no Firebase app.
        ref.watch(firebaseReadyProvider)
            ? ref.watch(firebaseFirestoreProvider)
            : null,
      ),
    );

/// How many records the **seller** has written, ignoring the reference data a
/// new business is created with.
///
/// **Not [guestRowsOwedProvider].** That one counts everything the drain owes,
/// which includes the marketplaces, carriers and categories
/// `GuestWorkspaceService` seeds — so a business thirty seconds old already
/// answers non-zero, and the Home warning claimed the seller had something to
/// lose before they had typed a word.
final FutureProvider<int> guestSellerRowsProvider = FutureProvider<int>((
  Ref ref,
) async {
  final LocalDatabase db = ref.watch(localDatabaseProvider);

  int written = 0;

  for (final TableInfo<LocalRows, LocalRow> table in db.sellerTables) {
    written += (await LocalTable(db, table).getAll()).length;
  }

  return written;
});

/// Whether the device is still holding records nobody has pushed.
///
/// **A count, not a flag.** A drain interrupted half way leaves some rows
/// behind, and the app has to be able to tell "nothing to do" from "seven
/// items still owed" without a bookkeeping table to lie to it
/// (`docs/rules/GUEST_MODE.md`).
final FutureProvider<int> guestRowsOwedProvider = FutureProvider<int>((
  Ref ref,
) async {
  final LocalDatabase db = ref.watch(localDatabaseProvider);

  int owed = 0;

  for (final TableInfo<LocalRows, LocalRow> table in db.drainOrder) {
    owed += (await LocalTable(db, table).getAll()).length;
  }

  return owed;
});

/// Moves the guest store into the account that just signed in.
final Provider<GuestDrainService> guestDrainServiceProvider =
    Provider<GuestDrainService>(
      (Ref ref) => GuestDrainService(
        ref.watch(localDatabaseProvider),
        FirestoreDrainSink(
          WorkspaceCollections(
            ref.watch(firebaseFirestoreProvider),
            // Read, not watched: the destination is decided once, when the
            // seller signs in, and a rebuild must not retarget a drain
            // already in flight.
            ref.read(currentWorkspaceIdProvider) ?? GuestConstant.workspaceId,
          ),
        ),
        ref.watch(fileUploaderProvider),
      ),
    );
