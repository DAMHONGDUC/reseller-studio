import 'package:drift/drift.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_row.dart';
import '../../domain/repositories/workspace_purge_repository.dart';

/// The sweep, in the guest's local store.
///
/// - the device holds one guest business, so every row in a table is its own
///   and there is no `workspaceId` to filter on
/// - `localWorkspaces` is never swept: the business survives, as on Firestore
class LocalWorkspacePurgeRepository implements WorkspacePurgeRepository {
  const LocalWorkspacePurgeRepository(this._db);

  final LocalDatabase _db;

  @override
  Future<int> deleteAllRecords() =>
      _sweepTables('delete all data', 'All guest data deleted', _db.drainOrder);

  /// Keeps marketplaces and carriers, the same pair
  /// `WorkspaceCollections.defaultTableNames` keeps on Firestore.
  @override
  Future<int> deleteRecordsExceptDefaults() => _sweepTables(
    'delete data before seeding',
    'Guest data deleted, defaults kept',
    _db.drainOrder
        .where(
          (TableInfo<LocalRows, LocalRow> table) =>
              table != _db.localMarketplaces && table != _db.localCarriers,
        )
        .toList(growable: false),
  );

  Future<int> _sweepTables(
    String operation,
    String logMessage,
    List<TableInfo<LocalRows, LocalRow>> tables,
  ) => FailureMapper.guard(operation, () async {
    final int deleted = await _db.transaction(() async {
      int total = 0;

      for (final TableInfo<LocalRows, LocalRow> table in tables) {
        total += await _db.delete(table).go();
      }

      return total;
    });

    SdLogger.action(LogTagConstant.workspace, logMessage, <String, Object>{
      'documents': deleted,
      'tables': tables.length,
    });

    return deleted;
  });
}
