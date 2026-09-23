import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../constants/guest_constant.dart';
import '../error/failure_mapper.dart';
import 'local_table.dart';

/// One entity's worth of guest storage, behind the shape every repository in
/// this app already has.
///
/// **Written once for eleven repositories.** They differ only in which DTO
/// maps the record and which table holds it, so each guest repository is the
/// interface plus a field — and a behaviour the Firestore side has cannot go
/// missing from one of them.
///
/// It mirrors `FirestoreItemRepository` deliberately, down to the details that
/// look incidental:
/// - **soft deletes are filtered on read, not stored separately** (hard rule
///   15), so a row stays joinable by whatever points at it;
/// - **`workspaceId` is stamped here and nowhere else**, the same guarantee
///   `WorkspaceCollections` gives through its converter;
/// - **every failure goes through `FailureMapper.guard`** (hard rule 6), so a
///   guest sees the same message a signed-in seller would.
class LocalCollection<T> {
  const LocalCollection({
    required this.table,
    required this.fromMap,
    required this.toMap,
    required this.idOf,
    required this.createdAtOf,
    required this.logTag,
    required this.label,
    this.isDeleted,
  });

  // Public because Dart cannot name a private field as a named parameter —
  // the same constraint `WorkspaceContext` records, answered the same way.
  final LocalTable table;
  final T Function(String id, Map<String, Object?> data) fromMap;
  final Map<String, Object?> Function(T entity) toMap;
  final String Function(T entity) idOf;
  final DateTime Function(T entity) createdAtOf;
  final String logTag;

  /// What a log line calls this record — 'item', 'order'. Lower case: the
  /// message reads `Saved item`, and the flow tag already carries the shout.
  final String label;

  final bool Function(T entity)? isDeleted;

  /// Newest first, soft-deleted rows dropped.
  Stream<List<T>> watchAll() =>
      table.watchAll().map(_live).handleError(_rethrowMapped);

  Stream<T?> watchOne(String id) => table
      .watchOne(id)
      .map((LocalDocument? doc) => _entityOrNull(doc))
      .handleError(_rethrowMapped);

  Future<T?> findById(String id) =>
      FailureMapper.guard('find $label', () async {
        return _entityOrNull(await table.findById(id));
      });

  /// Every live row, for the callers that filter on a field of their own.
  ///
  /// A read of the whole table rather than a query: the Firestore side
  /// filters in memory too, and matching it is what stops a screen behaving
  /// one way signed out and another signed in.
  Stream<List<T>> watchWhere(bool Function(T entity) test) => table
      .watchAll()
      .map((List<LocalDocument> docs) => _live(docs).where(test).toList())
      .handleError(_rethrowMapped);

  Future<void> save(T entity) => FailureMapper.guard('save $label', () async {
    await table.put(idOf(entity), createdAtOf(entity), _stamped(entity));

    SdLogger.info(logTag, 'Saved $label locally', <String, Object>{
      'id': idOf(entity),
    });
  });

  Future<void> saveAll(List<T> entities) =>
      FailureMapper.guard('save ${label}s', () async {
        if (entities.isEmpty) return;

        await table.putAll(<LocalDocument>[
          for (final T entity in entities)
            LocalDocument(idOf(entity), _stamped(entity)),
        ], DateTime.now());

        SdLogger.info(logTag, 'Saved ${label}s locally', <String, Object>{
          'count': entities.length,
        });
      });

  /// Soft delete (hard rule 15) — the same two fields the Firestore side
  /// writes, merged into the record rather than replacing it.
  Future<void> softDelete(String id) =>
      FailureMapper.guard('delete $label', () async {
        final DateTime now = DateTime.now();

        await table.put(id, now, <String, Object?>{
          'deletedAt': Timestamp.fromDate(now),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        SdLogger.info(logTag, 'Soft-deleted $label locally', <String, Object>{
          'id': id,
        });
      });

  /// **Stamped here, never by a DTO.** `workspaceId` and `createdBy` are the
  /// two columns the drain restamps at sign-in, and a record that reached the
  /// table without them is one the drain cannot place.
  Map<String, Object?> _stamped(T entity) => <String, Object?>{
    ...toMap(entity),
    'workspaceId': GuestConstant.workspaceId,
    'createdBy': GuestConstant.uid,
  };

  /// Hard rule 6 for a stream, the same job `FirestoreStream` does.
  ///
  /// **`FailureMapper.guard` cannot help here**: it wraps a future, and a
  /// Drift stream fails long after the call that opened it returned — a row
  /// whose JSON a newer build wrote, a database that could not be reopened.
  ///
  /// No repeat-suppression, unlike the Firestore side: a local query does not
  /// retry underneath the app, so one failure is one log line rather than
  /// hundreds.
  Never _rethrowMapped(Object error, StackTrace stackTrace) {
    SdLogger.error(
      logTag,
      'Failed to read ${label}s locally',
      error: error,
      stackTrace: stackTrace,
    );

    throw FailureMapper.map(error);
  }

  T? _entityOrNull(LocalDocument? doc) =>
      doc == null ? null : fromMap(doc.id, doc.data);

  List<T> _live(List<LocalDocument> docs) {
    final List<T> entities = <T>[
      for (final LocalDocument doc in docs) fromMap(doc.id, doc.data),
    ];
    final bool Function(T entity)? deleted = isDeleted;

    if (deleted == null) return entities;

    return entities.where((T entity) => !deleted(entity)).toList();
  }
}
