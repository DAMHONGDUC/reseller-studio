/// Riverpod wiring for the guest store (`docs/rules/GUEST_MODE.md`).
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/workspace/data/dtos/workspace_dto.dart';
import '../../features/workspace/domain/entities/workspace.dart';
import '../account/account_kind.dart';
import '../constants/guest_constant.dart';
import 'local_database.dart';
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
