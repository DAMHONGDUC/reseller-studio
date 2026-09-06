import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/repositories/workspace_purge_repository.dart';

/// The sweep, in Firestore.
///
/// **A query per table, because the tables are flat** (hard rule 14). There is
/// no subtree under `workspaces/{id}` to recurse into, so the cascade is
/// `WorkspaceCollections.recordTableNames` plus a paged delete each — the same
/// shape `functions/src/workspace/teardown.ts` uses for the real thing, and
/// for the same reason.
///
/// **A client sweep rather than a callable**, unlike deleting the business:
/// `firestore.rules` already lets a member delete a row in every table this
/// touches, so the Admin SDK would be buying nothing. What it cannot reach is
/// exactly what this must not touch anyway — the audit log.
class FirestoreWorkspacePurgeRepository implements WorkspacePurgeRepository {
  const FirestoreWorkspacePurgeRepository(this._context);

  /// Rows per round trip. Under the 500-write cap a batch commits at, so one
  /// page is always one batch.
  static const int _pageSize = 400;

  final WorkspaceContext _context;

  @override
  Future<int> deleteAllRecords() => _sweepTables(
    'delete all data',
    'All workspace data deleted',
    WorkspaceCollections.recordTableNames,
  );

  @override
  Future<int> deleteRecordsExceptDefaults() => _sweepTables(
    'delete data before seeding',
    'Workspace data deleted, defaults kept',
    WorkspaceCollections.refillableTableNames,
  );

  Future<int> _sweepTables(
    String operation,
    String logMessage,
    List<String> tables,
  ) => FailureMapper.guard(operation, () async {
    int deleted = 0;

    for (final String table in tables) {
      deleted += await _sweep(table);
    }

    SdLogger.action(LogTagConstant.workspace, logMessage, <String, Object>{
      'workspaceId': _context.workspaceId,
      'documents': deleted,
      'tables': tables.length,
    });

    return deleted;
  });

  /// Every row this workspace owns in one table, a page at a time.
  ///
  /// **Paged rather than read whole**: a seller with thousands of items would
  /// otherwise load all of them into memory to delete them, and a batch caps
  /// at 500 writes regardless.
  Future<int> _sweep(String name) async {
    final WorkspaceTable rows = _context.collections.table(name);

    int deleted = 0;

    for (;;) {
      final QuerySnapshot<Map<String, Object?>> page = await rows.query
          .limit(_pageSize)
          .get();

      if (page.docs.isEmpty) return deleted;

      final WriteBatch batch = rows.firestore.batch();

      for (final QueryDocumentSnapshot<Map<String, Object?>> row in page.docs) {
        batch.delete(row.reference);
      }

      await batch.commit();
      deleted += page.docs.length;

      SdLogger.info(
        LogTagConstant.workspace,
        'Table page deleted',
        <String, Object>{'table': name, 'documents': page.docs.length},
      );

      if (page.docs.length < _pageSize) return deleted;
    }
  }
}
