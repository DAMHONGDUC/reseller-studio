import 'package:system_design/common.dart';

import '../../constants/log_tag_constant.dart';
import '../../error/failure_mapper.dart';
import '../../storage/file_uploader.dart';
import '../local_database.dart';
import '../local_table.dart';
import 'drain_sink.dart';
import 'drain_table.dart';

/// Moves the guest store into the account that just signed in.
///
/// **This is the whole of "sync" in this app** (`docs/rules/GUEST_MODE.md`),
/// and it runs once. There is no pull, no merge and no second pass: the local
/// store is drained and dropped, and from then on Firestore is the record.
///
/// Four properties hold it together, and each one is load-bearing:
///
/// - **Parents before children.** `DrainTable.all` is ordered, and a row that
///   landed before the record it points at would be a dangling reference in a
///   store that cannot check one.
/// - **A row is deleted locally only once the server confirms it.** That is
///   what makes the drain resumable with no bookkeeping — what is left is
///   exactly what is still owed — and what makes a kill mid-drain cost a
///   re-push rather than a record.
/// - **Rows before photos.** Rows are small and finish in a moment; a few
///   hundred uploads on a phone connection do not, and nothing waits on
///   either.
/// - **One row's failure does not stop the drain.** It is left on the device
///   for the next attempt, because a seller with 400 items must not lose 399
///   of them to one bad photo path.
class GuestDrainService {
  // Positional, because Dart cannot name a private field as a named
  // parameter and these three are different enough that a swap would not
  // compile — the same answer `FirebaseFileUploader` gives.
  const GuestDrainService(this._db, this._sink, this._uploader);

  /// The field every photo-bearing record keeps its files in.
  static const String photoField = 'photoUrls';

  final LocalDatabase _db;
  final DrainSink _sink;
  final FileUploader _uploader;

  /// Push everything the device holds into [workspaceId], as [uid].
  ///
  /// Returns how many rows went up, which is what the log line reports and
  /// what a test asserts on.
  Future<int> run({
    required String workspaceId,
    required String uid,
    required String currency,
  }) => FailureMapper.guard('sync your records', () async {
    await _rememberDestination(workspaceId);

    int pushed = 0;
    int left = 0;

    for (final DrainTable table in DrainTable.all(_db)) {
      final (int sent, int owed) = await _drainTable(table, uid, currency);

      pushed += sent;
      left += owed;
    }

    // **Only when nothing is owed.** Clearing it while rows are still on the
    // device would throw away the one fact a resumed drain cannot work out
    // for itself — which business the seller chose.
    if (left == 0) await _db.delete(_db.drainStates).go();

    SdLogger.action(
      LogTagConstant.workspace,
      'Guest records synced',
      <String, Object>{
        'workspaceId': workspaceId,
        'rows': pushed,
        'left': left,
      },
    );

    return pushed;
  });

  /// The one fact a resumed drain cannot work out from the rows that are
  /// left: which business the seller chose.
  Future<void> _rememberDestination(String workspaceId) => _db
      .into(_db.drainStates)
      .insertOnConflictUpdate(
        DrainStatesCompanion.insert(
          key: LocalDatabase.drainStateKey,
          destinationWorkspaceId: workspaceId,
        ),
      );

  /// Where an interrupted drain was heading, or null if none was.
  Future<String?> pendingDestination() async {
    final DrainState? state =
        await (_db.select(_db.drainStates)..where(
              (DrainStates row) => row.key.equals(LocalDatabase.drainStateKey),
            ))
            .getSingleOrNull();

    return state?.destinationWorkspaceId;
  }

  /// How many rows went up, and how many are still owed.
  Future<(int, int)> _drainTable(
    DrainTable table,
    String uid,
    String currency,
  ) async {
    final LocalTable local = LocalTable(_db, table.rows);
    final List<LocalDocument> rows = await local.getAll();

    int pushed = 0;

    for (final LocalDocument row in rows) {
      try {
        final Map<String, Object?> document = table.rebuild(
          row.id,
          row.data,
          currency,
          uid,
        );

        await _sink.write(
          table: table.name,
          id: row.id,
          data: await _withUploadedPhotos(document, row.id),
        );

        // Confirmed, so it is no longer owed. Deleting before the write
        // would make a failure cost the record.
        await local.remove(row.id);
        pushed++;
      } catch (error, stackTrace) {
        // Left on the device on purpose: the next attempt picks it up, and
        // one bad row must not strand the other 399.
        SdLogger.error(
          LogTagConstant.workspace,
          'Could not sync a ${table.name} row — left on the device',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object>{'table': table.name, 'id': row.id},
        );
      }
    }

    SdLogger.info(LogTagConstant.workspace, 'Table synced', <String, Object>{
      'table': table.name,
      'pushed': pushed,
      'left': rows.length - pushed,
    });

    return (pushed, rows.length - pushed);
  }

  /// Uploads any photo the guest kept on disk and swaps in the URL.
  ///
  /// **A record whose photo has not gone up yet keeps its local path**, and
  /// that is not a bug to design around: `AppPhoto` renders either form, so
  /// the seller sees their picture the whole way through
  /// (`docs/rules/GUEST_MODE.md`). An upload that fails leaves the path
  /// alone rather than dropping the photo from the record.
  Future<Map<String, Object?>> _withUploadedPhotos(
    Map<String, Object?> document,
    String recordId,
  ) async {
    final Object? photos = document[photoField];

    if (photos is! List || photos.isEmpty) return document;

    final List<String> uploaded = <String>[];

    for (final Object? photo in photos) {
      if (photo is! String) continue;

      uploaded.add(await _uploadedOrKept(photo, recordId));
    }

    return <String, Object?>{...document, photoField: uploaded};
  }

  Future<String> _uploadedOrKept(String photo, String recordId) async {
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }

    try {
      return await _uploader.upload(
        folder: FileFolder.items,
        recordId: recordId,
        filePath: photo,
      );
    } catch (error, stackTrace) {
      // The file's own name is never logged — it can carry a customer's name
      // off a scanned receipt (hard rule 9).
      SdLogger.error(
        LogTagConstant.storage,
        'Could not upload a guest photo — the record keeps its local copy',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'recordId': recordId},
      );

      return photo;
    }
  }
}
