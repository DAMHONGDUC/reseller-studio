import '../../domain/enums/sync_status.dart';
import '../../domain/repositories/sync_status_repository.dart';

/// A guest's store has no server behind it, so there is nothing to wait for.
class LocalSyncStatusRepository implements SyncStatusRepository {
  const LocalSyncStatusRepository();

  @override
  Stream<SyncStatus> watch() => Stream<SyncStatus>.value(SyncStatus.deviceOnly);
}
