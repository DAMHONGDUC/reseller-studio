import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../domain/enums/sync_status.dart';
import '../../domain/repositories/sync_status_repository.dart';

/// Pending writes, read from Firestore's own offline queue.
///
/// - every listener event re-asks `waitForPendingWrites`, so a new local
///   write is noticed the moment a screen sees it
/// - it resolves only once the server confirms, so offline stays [SyncStatus.syncing]
/// - a check answered within [_grace] never shows syncing, so an idle app
///   does not flicker on every snapshot
class FirestoreSyncStatusRepository implements SyncStatusRepository {
  const FirestoreSyncStatusRepository(this._firestore);

  static const Duration _grace = Duration(milliseconds: 600);

  final FirebaseFirestore _firestore;

  @override
  Stream<SyncStatus> watch() {
    final StreamController<SyncStatus> controller =
        StreamController<SyncStatus>();
    StreamSubscription<void>? ticks;
    int generation = 0;

    Future<void> check() async {
      final int mine = ++generation;
      final Timer grace = Timer(_grace, () {
        if (mine == generation && !controller.isClosed) {
          controller.add(SyncStatus.syncing);
        }
      });

      try {
        await FailureMapper.guard(
          'wait for pending writes',
          _firestore.waitForPendingWrites,
        );
      } catch (error, stackTrace) {
        SdLogger.error(
          LogTagConstant.sync,
          'Pending-writes check failed',
          error: error,
          stackTrace: stackTrace,
        );

        return;
      } finally {
        grace.cancel();
      }

      if (mine != generation || controller.isClosed) return;

      controller.add(SyncStatus.synced);
      SdLogger.info(LogTagConstant.sync, 'All writes confirmed', <String, int>{
        'check': mine,
      });
    }

    controller
      ..onListen = () {
        unawaited(check());
        ticks = _firestore.snapshotsInSync().listen((_) => check());
      }
      ..onCancel = () async {
        await ticks?.cancel();
        await controller.close();
      };

    return controller.stream;
  }
}
