import 'package:cloud_firestore/cloud_firestore.dart';

/// One flat table, scoped to one workspace.
///
/// **Every collection read starts at [query], which already carries the
/// `workspaceId` filter** — there is no accessor that hands out an unfiltered
/// collection, so a repository cannot write the query that reads another
/// seller's inventory. That guarantee used to be structural, held by the path
/// itself; hard rule 14 moved the tables flat, and this class is what replaced
/// it.
class WorkspaceTable {
  const WorkspaceTable(this._collection, this.workspaceId);

  /// The column every table carries, and the whole security boundary.
  static const String workspaceField = 'workspaceId';

  /// What separates the workspace from the record's own id in a document id.
  ///
  /// **An underscore, and the ids it joins never contain one.** UUIDs use
  /// hyphens and every seeded id is hyphenated (`royal-mail`), so splitting on
  /// the first underscore recovers both halves exactly.
  static const String idSeparator = '_';

  final CollectionReference<Map<String, Object?>> _collection;
  final String workspaceId;

  /// Every read of more than one row. Filtered before the caller can chain
  /// anything onto it.
  Query<Map<String, Object?>> get query =>
      _collection.where(workspaceField, isEqualTo: workspaceId);

  /// One row by its **local** id — the id the domain carries.
  ///
  /// The stored document id is `{workspaceId}_{id}`, which is how SQL spells
  /// a composite primary key. Without it every workspace's `ebay` marketplace,
  /// `usps` carrier and `{uid}` membership would be the same document
  /// (`docs/DATA_MODEL.md`).
  DocumentReference<Map<String, Object?>> doc(String id) =>
      _collection.doc(documentId(workspaceId, id));

  FirebaseFirestore get firestore => _collection.firestore;

  static String documentId(String workspaceId, String id) =>
      '$workspaceId$idSeparator$id';

  /// The record's own id, back out of a document id.
  ///
  /// **Splits on the first separator only.** The workspace id never contains
  /// one; a record id that somehow did would otherwise lose its tail.
  static String localId(String documentId) {
    final int cut = documentId.indexOf(idSeparator);

    return cut < 0 ? documentId : documentId.substring(cut + 1);
  }
}

/// Every Firestore table the app reads, scoped to one workspace id.
///
/// **The tables are flat and top-level** (hard rule 14): `items`, `orders`,
/// `members` and the rest are collections of their own, each row carrying a
/// `workspaceId` column, modelled the way SQL would model them so a move off
/// Firestore is an export rather than a reshape.
///
/// The class is what keeps that safe. A repository is handed one of these and
/// reaches a table only through [WorkspaceTable], whose every read is already
/// filtered and whose every write stamps the column — so neither the filter
/// nor the stamp is something a call site can forget.
class WorkspaceCollections {
  const WorkspaceCollections(this._firestore, this.workspaceId);

  final FirebaseFirestore _firestore;
  final String workspaceId;

  DocumentReference<Map<String, Object?>> get workspace =>
      _firestore.collection(_workspaces).doc(workspaceId);

  WorkspaceTable get members => _table('members');
  WorkspaceTable get items => _table('items');
  WorkspaceTable get listings => _table('listings');
  WorkspaceTable get orders => _table('orders');
  WorkspaceTable get offers => _table('offers');
  WorkspaceTable get purchases => _table('purchases');
  WorkspaceTable get sources => _table('sources');
  WorkspaceTable get expenses => _table('expenses');
  WorkspaceTable get categories => _table('categories');
  WorkspaceTable get locations => _table('locations');
  WorkspaceTable get marketplaces => _table('marketplaces');
  WorkspaceTable get carriers => _table('carriers');
  WorkspaceTable get activity => _table('activity');

  /// Every table this workspace owns rows in, for anything that has to sweep
  /// all of them — deleting a business, or migrating one.
  ///
  /// **A flat table has no parent to delete**, so the subtree delete the
  /// nested model got for free is now this list plus a query each. Adding a
  /// table means adding it here, or a deleted business leaves rows behind.
  static const List<String> tableNames = <String>[
    'members',
    'items',
    'listings',
    'orders',
    'offers',
    'purchases',
    'sources',
    'expenses',
    'categories',
    'locations',
    'marketplaces',
    'carriers',
    'activity',
  ];

  WorkspaceTable _table(String name) => WorkspaceTable(
    _firestore
        .collection(name)
        .withConverter<Map<String, Object?>>(
          fromFirestore:
              (
                DocumentSnapshot<Map<String, dynamic>> snapshot,
                SnapshotOptions? _,
              ) => snapshot.data() ?? <String, Object?>{},
          // **The stamp lives here and nowhere else.** Every write through
          // this class carries its `workspaceId`, so no DTO has to remember
          // the column and no write can land in another seller's table.
          toFirestore: (Map<String, Object?> data, SetOptions? _) =>
              <String, dynamic>{
                ...data,
                WorkspaceTable.workspaceField: workspaceId,
              },
        ),
    workspaceId,
  );

  static const String _workspaces = 'workspaces';

  /// The top-level collections that belong to nobody's business.
  ///
  /// `users` is the person rather than their workspace, and `workspaces` is
  /// the row a workspace itself is, so neither is reached through an instance.
  static CollectionReference<Map<String, dynamic>> users(
    FirebaseFirestore firestore,
  ) => firestore.collection('users');

  static CollectionReference<Map<String, dynamic>> workspaces(
    FirebaseFirestore firestore,
  ) => firestore.collection(_workspaces);
}
