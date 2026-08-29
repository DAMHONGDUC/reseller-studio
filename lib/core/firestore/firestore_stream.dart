import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import '../error/failure_mapper.dart';

/// Turning Firestore's snapshot streams into streams of entities.
///
/// **`FailureMapper.guard` cannot help here.** It wraps a `Future`, and a
/// snapshot listener fails at any point in its life — a permission that is
/// revoked ten minutes in arrives as an error *on the stream*, long after the
/// call that opened it returned. So the same two jobs guard does, log and
/// map, happen here instead: every stream in `data/` goes through one of
/// these, and nothing past this line ever sees a `FirebaseException`
/// (hard rule 6).
final class FirestoreStream {
  /// A live list, newest-first ordering left to the caller's query.
  static Stream<List<T>> collection<T>(
    Query<Map<String, Object?>> query,
    T Function(DocumentSnapshot<Map<String, Object?>> doc) toEntity, {
    required String operation,
  }) => query
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, Object?>> snapshot) =>
            snapshot.docs.map(toEntity).toList(),
      )
      .handleError(
        (Object error, StackTrace stackTrace) =>
            _rethrowMapped(error, stackTrace, operation),
      );

  /// One live document, or null when it does not exist.
  ///
  /// Null rather than an error: the row may have been deleted by a teammate
  /// while the screen was open, which is not a failure.
  static Stream<T?> document<T>(
    DocumentReference<Map<String, Object?>> reference,
    T Function(DocumentSnapshot<Map<String, Object?>> doc) toEntity, {
    required String operation,
  }) => reference
      .snapshots()
      .map(
        (DocumentSnapshot<Map<String, Object?>> doc) =>
            doc.exists ? toEntity(doc) : null,
      )
      .handleError(
        (Object error, StackTrace stackTrace) =>
            _rethrowMapped(error, stackTrace, operation),
      );

  static Never _rethrowMapped(
    Object error,
    StackTrace stackTrace,
    String operation,
  ) {
    SdLogger.error(
      LogTagConstant.firestore,
      'Failed to $operation',
      error: error,
      stackTrace: stackTrace,
    );

    throw FailureMapper.map(error);
  }
}
