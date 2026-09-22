import 'package:drift/drift.dart';

import 'local_database.dart';
import 'local_json_codec.dart';
import 'local_row.dart';

/// One record, read back: its id and its decoded map.
///
/// **The same pair a `DocumentSnapshot` hands a DTO**, and deliberately so —
/// it is what lets one `fromMap` on each DTO serve both stores instead of the
/// local side growing a second mapping nobody keeps in step.
class LocalDocument {
  const LocalDocument(this.id, this.data);

  final String id;
  final Map<String, Object?> data;
}

/// One local table, read and written the only way a guest repository may.
///
/// **The local mirror of `WorkspaceTable`.** Written once and handed a table,
/// rather than once per entity: the eleven business tables have identical
/// shape, so eleven copies of these six methods would be eleven chances for
/// one of them to order a list the other way.
///
/// There is no `workspaceId` filter here and there does not need to be: a
/// device holds exactly one guest business, so the table *is* the scope. The
/// column still exists inside the record, because the drain restamps it.
class LocalTable {
  const LocalTable(this._db, this._table);

  final LocalDatabase _db;
  final TableInfo<LocalRows, LocalRow> _table;

  /// Newest first — the order every Firestore repository in this app reads in.
  Stream<List<LocalDocument>> watchAll() =>
      _newestFirst().map(_document).watch();

  Stream<LocalDocument?> watchOne(String id) =>
      (_db.select(_table)..where((LocalRows row) => row.id.equals(id)))
          .map(_document)
          .watchSingleOrNull();

  Future<LocalDocument?> findById(String id) =>
      (_db.select(_table)..where((LocalRows row) => row.id.equals(id)))
          .map(_document)
          .getSingleOrNull();

  Future<List<LocalDocument>> getAll() => _newestFirst().map(_document).get();

  /// Create, or merge into what is already there.
  ///
  /// **Merge, because every Firestore write in this app is
  /// `SetOptions(merge: true)`.** A local `put` that replaced the record
  /// instead would drop the fields a partial write leaves out — a soft delete
  /// sends two keys — and the two stores would disagree about what a save
  /// means.
  ///
  /// [createdAt] seeds the ordering column on a create and is ignored on a
  /// merge: a record does not change age when it is edited.
  Future<void> put(String id, DateTime createdAt, Map<String, Object?> data) =>
      _db.transaction(() async {
        final LocalRow? existing = await _rowOf(id);

        await _db
            .into(_table)
            .insert(
              _insertable(
                id,
                existing == null
                    ? createdAt
                    : DateTime.fromMillisecondsSinceEpoch(existing.createdAt),
                existing == null
                    ? data
                    : <String, Object?>{
                        ...LocalJsonCodec.decode(existing.data),
                        ...data,
                      },
              ),
              mode: InsertMode.insertOrReplace,
            );
      });

  /// One transaction for the whole batch — hard rule 16's local half.
  Future<void> putAll(List<LocalDocument> documents, DateTime createdAt) =>
      _db.transaction(() async {
        for (final LocalDocument document in documents) {
          await put(document.id, createdAt, document.data);
        }
      });

  /// **A real delete.** Soft delete is hard rule 15 and lives in the record's
  /// own `deletedAt` field, written by the repository — this is what the drain
  /// calls once a row is safely on the server.
  Future<void> remove(String id) =>
      (_db.delete(_table)..where((LocalRows row) => row.id.equals(id))).go();

  Future<LocalRow?> _rowOf(String id) => (_db.select(
    _table,
  )..where((LocalRows row) => row.id.equals(id))).getSingleOrNull();

  static LocalDocument _document(LocalRow row) =>
      LocalDocument(row.id, LocalJsonCodec.decode(row.data));

  RawValuesInsertable<LocalRow> _insertable(
    String id,
    DateTime createdAt,
    Map<String, Object?> data,
  ) => RawValuesInsertable<LocalRow>(<String, Expression<Object>>{
    'id': Variable<String>(id),
    'created_at': Variable<int>(createdAt.millisecondsSinceEpoch),
    'data': Variable<String>(LocalJsonCodec.encode(data)),
  });

  /// `createdAt` is declared on the shared supertype, so one ordering serves
  /// every table — and it is the same order the Firestore repositories read
  /// in, which is what stops a list reshuffling at sign-in.
  SimpleSelectStatement<LocalRows, LocalRow> _newestFirst() =>
      _db.select(_table)..orderBy(<OrderClauseGenerator<LocalRows>>[
        (LocalRows row) =>
            OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
      ]);
}
