import 'package:cloud_firestore/cloud_firestore.dart';

/// Every Firestore path that hangs off one person rather than one business.
///
/// The sibling of `WorkspaceCollections`, and it exists for the same reason:
/// a repository handed one of these **cannot name another person's
/// collection**, so "read my notifications" has no spelling that reaches
/// somebody else's. Two collections live here today — the device tokens the
/// app registers, and the inbox the notification functions write.
///
/// Business records never go under a user (hard rule 14). What belongs here
/// is what is addressed to the person: a device is held by whoever holds it,
/// and a notification is addressed to a reader.
class UserCollections {
  const UserCollections(this.firestore, this.uid);

  final FirebaseFirestore firestore;
  final String uid;

  DocumentReference<Map<String, Object?>> get user =>
      firestore.collection(_users).doc(uid);

  CollectionReference<Map<String, Object?>> get devices => _sub('devices');
  CollectionReference<Map<String, Object?>> get notifications =>
      _sub('notifications');

  CollectionReference<Map<String, Object?>> _sub(String name) => user
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

  static const String _users = 'users';
}
