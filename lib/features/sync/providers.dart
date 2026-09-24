import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/account/account_kind.dart';
import '../auth/providers.dart';
import 'data/repositories/firestore_sync_status_repository.dart';
import 'data/repositories/local_sync_status_repository.dart';
import 'domain/enums/sync_status.dart';
import 'domain/repositories/sync_status_repository.dart';

/// Local for a guest, Firestore's queue for an account — the same seam as
/// every repository (`docs/rules/GUEST_MODE.md`).
final Provider<SyncStatusRepository> syncStatusRepositoryProvider =
    Provider<SyncStatusRepository>((Ref ref) {
      final bool linked = ref.watch(accountKindProvider) == AccountKind.linked;

      // `FirebaseFirestore.instance` throws `[core/no-app]` without Firebase.
      if (!linked || !ref.watch(firebaseReadyProvider)) {
        return const LocalSyncStatusRepository();
      }

      return FirestoreSyncStatusRepository(FirebaseFirestore.instance);
    });

final StreamProvider<SyncStatus> syncStatusProvider =
    StreamProvider<SyncStatus>(
      (Ref ref) => ref.watch(syncStatusRepositoryProvider).watch(),
    );
