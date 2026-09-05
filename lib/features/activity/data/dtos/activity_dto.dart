import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../domain/entities/activity_entry.dart';

/// How an [ActivityEntry] is stored. Read only — see the repository.
///
/// `before` and `after` are in the document (`docs/DATA_MODEL.md`) and are
/// deliberately **not** mapped: they are arbitrary record snapshots, the
/// screen shows what changed rather than the values, and pulling a buyer name
/// into the client through this path would be a leak nobody was looking for.
final class ActivityDto {
  static ActivityEntry toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};

    return ActivityEntry(
      id: WorkspaceTable.localId(doc.id),
      entityType:
          FirestoreMapper.enumOrNull(
            ActivityEntityType.values,
            data['entityType'],
          ) ??
          ActivityEntityType.unknown,
      entityId: FirestoreMapper.stringOrNull(data['entityId']) ?? '',
      action:
          FirestoreMapper.enumOrNull(ActivityAction.values, data['action']) ??
          ActivityAction.unknown,
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      actorId: FirestoreMapper.stringOrNull(data['actorId']),
    );
  }
}
