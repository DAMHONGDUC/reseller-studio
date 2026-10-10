import 'package:cloud_firestore/cloud_firestore.dart';

import 'confirmed_stream.dart';
import 'firestore_maintenance.dart';
import 'firestore_stream_reporter.dart';

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
  }) {
    final FirestoreStreamReporter reporter = FirestoreStreamReporter(operation);

    return FirestoreMaintenance.listen(query.snapshots)
        .map((QuerySnapshot<Map<String, Object?>> snapshot) {
          reporter.recovered();

          return snapshot.docs.map(toEntity).toList();
        })
        .handleError(
          (Object error, StackTrace stackTrace) =>
              reporter.rethrowMapped(error, stackTrace),
        );
  }

  /// One live document, or null when it does not exist.
  ///
  /// Null rather than an error: the row may have been deleted by a teammate
  /// while the screen was open, which is not a failure.
  ///
  /// **A cache miss is reported as "does not exist", and for a screen that is
  /// right** — it renders an empty state a moment before the real row arrives.
  /// A document the app *routes* on cannot afford that guess: see
  /// [confirmedDocument].
  static Stream<T?> document<T>(
    DocumentReference<Map<String, Object?>> reference,
    T Function(DocumentSnapshot<Map<String, Object?>> doc) toEntity, {
    required String operation,
  }) => _entities(
    FirestoreMaintenance.listen(reference.snapshots),
    toEntity,
    operation,
  );

  /// The same, for a document whose *absence* changes where the app sends the
  /// seller.
  ///
  /// The first answer it carries is one the server confirmed, so a listener
  /// opened on a document this device has never cached stays silent rather
  /// than reporting nothing there. Whoever is watching sees "still loading",
  /// which is the truth. See [ConfirmedDocumentStream] for what it costs
  /// offline.
  static Stream<T?> confirmedDocument<T>(
    DocumentReference<Map<String, Object?>> reference,
    T Function(DocumentSnapshot<Map<String, Object?>> doc) toEntity, {
    required String operation,
  }) => _entities(
    ConfirmedStream.of(
      FirestoreMaintenance.listen(reference.snapshots),
      isUnconfirmed: (DocumentSnapshot<Map<String, Object?>> doc) =>
          doc.metadata.isFromCache,
    ),
    toEntity,
    operation,
  );

  static Stream<T?> _entities<T>(
    Stream<DocumentSnapshot<Map<String, Object?>>> snapshots,
    T Function(DocumentSnapshot<Map<String, Object?>> doc) toEntity,
    String operation,
  ) {
    final FirestoreStreamReporter reporter = FirestoreStreamReporter(operation);

    return snapshots
        .map((DocumentSnapshot<Map<String, Object?>> doc) {
          reporter.recovered();

          return doc.exists ? toEntity(doc) : null;
        })
        .handleError(
          (Object error, StackTrace stackTrace) =>
              reporter.rethrowMapped(error, stackTrace),
        );
  }
}
