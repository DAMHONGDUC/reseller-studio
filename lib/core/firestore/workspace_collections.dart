import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

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
      SdId.owned(workspaceId, id);

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

  WorkspaceTable get members => table('members');
  WorkspaceTable get items => table('items');
  WorkspaceTable get listings => table('listings');
  WorkspaceTable get orders => table('orders');
  WorkspaceTable get offers => table('offers');
  WorkspaceTable get purchases => table('purchases');
  WorkspaceTable get sources => table('sources');
  WorkspaceTable get expenses => table('expenses');
  WorkspaceTable get categories => table('categories');
  WorkspaceTable get locations => table('locations');
  WorkspaceTable get marketplaces => table('marketplaces');
  WorkspaceTable get carriers => table('carriers');
  WorkspaceTable get activity => table('activity');

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

  /// The tables holding records a sweep may empty — [tableNames] minus the two
  /// that must survive one.
  ///
  /// - **`members` is the ACL** (hard rule 11). Emptying it locks every seller
  ///   out of a business that still exists, and no rule would let them back
  ///   in: every permission is decided by the row that was just deleted.
  /// - **`activity` is append-only** (hard rule 12) and `firestore.rules`
  ///   refuses a client delete outright, so a sweep including it fails on the
  ///   first row rather than skipping it.
  ///
  /// Derived from [tableNames] rather than typed a second time: a table added
  /// there is swept without anyone remembering this list exists.
  static List<String> get recordTableNames => tableNames
      .where((String name) => !_keptTables.contains(name))
      .toList(growable: false);

  static const Set<String> _keptTables = <String>{'members', 'activity'};

  /// The tables a workspace is *created* with — written by workspace setup and
  /// by nothing else afterwards.
  static const Set<String> defaultTableNames = <String>{
    'marketplaces',
    'carriers',
  };

  /// [recordTableNames] minus [defaultTableNames] — what a sweep that intends
  /// to refill the business may empty.
  ///
  /// A seed writes no marketplaces and no carriers, so clearing them leaves a
  /// business with no platform to list on and no way back: only creating
  /// another workspace writes them again.
  static List<String> get refillableTableNames => recordTableNames
      .where((String name) => !defaultTableNames.contains(name))
      .toList(growable: false);

  /// One table by name, for anything that sweeps all of them.
  ///
  /// Public so [recordTableNames] can be walked; it hands out the same
  /// filtered, stamped [WorkspaceTable] the named getters do, so naming a
  /// table rather than reading a getter gives up none of hard rule 14's
  /// boundary.
  WorkspaceTable table(String name) => WorkspaceTable(
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
