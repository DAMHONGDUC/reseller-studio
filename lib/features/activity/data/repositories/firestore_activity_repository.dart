import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/entities/activity_entry.dart';
import '../../domain/repositories/activity_repository.dart';
import '../dtos/activity_dto.dart';

/// The audit log, in Firestore.
class FirestoreActivityRepository implements ActivityRepository {
  const FirestoreActivityRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<ActivityEntry>> watchRecent({int limit = 50}) =>
      FirestoreStream.collection(
        _context.collections.activity.query
            .orderBy('createdAt', descending: true)
            .limit(limit),
        (doc) => ActivityDto.toEntity(doc),
        operation: 'load activity',
      );
}
