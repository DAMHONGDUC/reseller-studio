import '../enums/sync_status.dart';

/// Whether this device's writes have reached the server, as it changes.
abstract interface class SyncStatusRepository {
  Stream<SyncStatus> watch();
}
