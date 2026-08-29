import 'package:cloud_firestore/cloud_firestore.dart';

/// Every Firestore path in the app, built from one workspace id.
///
/// **Business records are nested under their workspace, never flat** (hard
/// rule 14, `docs/DATA_MODEL.md`). This class is what makes that structural
/// rather than a convention: a repository is handed one of these and cannot
/// name a collection outside the workspace it was built for, so there is no
/// query that could forget its `where` clause and read another seller's
/// inventory.
///
/// The type argument stays `Map<String, Object?>` rather than a `withConverter`
/// pair. The DTOs already own the mapping in both directions, and a converter
/// would put half of it here and half there.
class WorkspaceCollections {
  const WorkspaceCollections(this._firestore, this.workspaceId);

  final FirebaseFirestore _firestore;
  final String workspaceId;

  DocumentReference<Map<String, Object?>> get workspace =>
      _firestore.collection(_workspaces).doc(workspaceId);

  CollectionReference<Map<String, Object?>> get members => _sub('members');
  CollectionReference<Map<String, Object?>> get items => _sub('items');
  CollectionReference<Map<String, Object?>> get listings => _sub('listings');
  CollectionReference<Map<String, Object?>> get orders => _sub('orders');
  CollectionReference<Map<String, Object?>> get offers => _sub('offers');
  CollectionReference<Map<String, Object?>> get purchases => _sub('purchases');
  CollectionReference<Map<String, Object?>> get sources => _sub('sources');
  CollectionReference<Map<String, Object?>> get expenses => _sub('expenses');
  CollectionReference<Map<String, Object?>> get categories =>
      _sub('categories');
  CollectionReference<Map<String, Object?>> get locations => _sub('locations');
  CollectionReference<Map<String, Object?>> get marketplaces =>
      _sub('marketplaces');
  CollectionReference<Map<String, Object?>> get carriers => _sub('carriers');
  CollectionReference<Map<String, Object?>> get activity => _sub('activity');

  CollectionReference<Map<String, Object?>> _sub(String name) => workspace
      .collection(name)
      .withConverter<Map<String, Object?>>(
        fromFirestore:
            (
              DocumentSnapshot<Map<String, dynamic>> snapshot,
              SnapshotOptions? _,
            ) => snapshot.data() ?? <String, Object?>{},
        toFirestore: (Map<String, Object?> data, SetOptions? _) => data.map(
          (String key, Object? value) => MapEntry<String, dynamic>(key, value),
        ),
      );

  static const String _workspaces = 'workspaces';

  /// The top-level collections — the two that are not under a workspace.
  ///
  /// `users` is the person rather than their business, and `workspaces` is
  /// the root itself, so neither can be reached through an instance.
  static CollectionReference<Map<String, dynamic>> users(
    FirebaseFirestore firestore,
  ) => firestore.collection('users');

  static CollectionReference<Map<String, dynamic>> workspaces(
    FirebaseFirestore firestore,
  ) => firestore.collection(_workspaces);
}
