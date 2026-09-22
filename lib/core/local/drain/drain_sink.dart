import 'package:cloud_firestore/cloud_firestore.dart';

import '../../error/failure_mapper.dart';
import '../../firestore/workspace_collections.dart';

/// Where a drained row lands.
///
/// **An interface so the drain can be tested at all.** There is no fake
/// Firestore in this repo and adding one is a dependency decision, so the one
/// line that touches the SDK is behind this and everything above it — the
/// ordering, the restamp, the confirm-then-delete, the photo pass — is
/// exercised against a map.
///
/// It is deliberately narrow: a table name, an id and a document. The
/// `workspaceId` stamp and the composite key still belong to
/// `WorkspaceCollections`, which [FirestoreDrainSink] goes through rather
/// than around (hard rule 14).
abstract interface class DrainSink {
  Future<void> write({
    required String table,
    required String id,
    required Map<String, Object?> data,
  });
}

/// The real one: one `set` through the filtered, stamped collection.
class FirestoreDrainSink implements DrainSink {
  const FirestoreDrainSink(this._collections);

  final WorkspaceCollections _collections;

  @override
  Future<void> write({
    required String table,
    required String id,
    required Map<String, Object?> data,
  }) => FailureMapper.guard('sync a record', () async {
    // Merge, like every other write in this app: a row pushed twice by a
    // resumed drain must not lose what the first attempt already landed.
    await _collections.table(table).doc(id).set(data, SetOptions(merge: true));
  });
}
