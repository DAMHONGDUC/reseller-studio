import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../pricing/domain/services/profit_calculator.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../dtos/workspace_dto.dart';

/// Workspaces, memberships and user profiles, in Firestore.
///
/// **Creation is three sequential writes, not one batch, and that is forced
/// by the security rules.** The membership rule has to read the workspace
/// document to check that the caller is its `ownerId`, and a rules `get()`
/// only sees committed data — so a batch containing both would be rejected on
/// the membership write. The order is therefore workspace → membership →
/// profile pointer, and a failure partway leaves a workspace the user is not
/// a member of: invisible to them, and re-running onboarding creates a clean
/// one. That is the recoverable failure of the three.
class FirestoreWorkspaceRepository implements WorkspaceRepository {
  const FirestoreWorkspaceRepository(this._firestore);

  static const Uuid _uuid = Uuid();

  final FirebaseFirestore _firestore;

  @override
  Stream<UserProfile?> watchProfile(String uid) => FirestoreStream.document(
    _users.doc(uid),
    UserProfileDto.toEntity,
    operation: 'load profile',
  );

  @override
  Stream<Workspace?> watchWorkspace(String workspaceId) =>
      FirestoreStream.document(
        _workspaces.doc(workspaceId),
        WorkspaceDto.toEntity,
        operation: 'load workspace',
      );

  @override
  Stream<List<Member>> watchMembers(String workspaceId) =>
      FirestoreStream.collection(
        WorkspaceCollections(_firestore, workspaceId).members,
        MemberDto.toEntity,
        operation: 'load team',
      );

  @override
  Future<void> ensureProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
  }) => FailureMapper.guard('create profile', () async {
    // Merged rather than created: called after every sign-in, so an account
    // whose first write failed still gets a profile, and one that already has
    // a workspace list does not lose it.
    await _users
        .doc(uid)
        .set(
          FirestoreMapper.pruned(<String, Object?>{
            'displayName': displayName,
            'email': email,
            'photoUrl': photoUrl,
            'updatedAt': FirestoreMapper.serverTimestamp,
          }),
          SetOptions(merge: true),
        );

    AppLogger.info('Profile ensured', <String, Object>{'uid': uid});
  });

  @override
  Future<String> createWorkspace({
    required String name,
    required String country,
    required String currency,
    required String ownerId,
    String? ownerName,
    String? ownerEmail,
    String? businessType,
  }) => FailureMapper.guard('create workspace', () async {
    final String id = _uuid.v4();
    final DateTime now = DateTime.now();

    await _workspaces
        .doc(id)
        .set(
          FirestoreMapper.pruned(<String, Object?>{
            'name': name,
            // Checked by the rules against the caller's uid, so a client cannot
            // create a workspace owned by somebody else.
            'ownerId': ownerId,
            'country': country,
            'currency': currency,
            'businessType': businessType,
            // The policy class owns this number — it is the algorithm the
            // threshold belongs to, not configuration about a workspace.
            'staleThresholdDays': StaleInventoryPolicy.defaultThreshold.inDays,
            'createdAt': FirestoreMapper.serverTimestamp,
            'updatedAt': FirestoreMapper.serverTimestamp,
            'createdBy': ownerId,
          }),
        );

    await WorkspaceCollections(_firestore, id).members
        .doc(ownerId)
        .set(
          MemberDto.toMap(
            Member(
              uid: ownerId,
              role: MemberRole.owner,
              joinedAt: now,
              displayName: ownerName,
              email: ownerEmail,
            ),
          ),
        );

    await _users.doc(ownerId).set(<String, Object?>{
      'workspaceIds': FieldValue.arrayUnion(<String>[id]),
      'lastWorkspaceId': id,
      'updatedAt': FirestoreMapper.serverTimestamp,
    }, SetOptions(merge: true));

    AppLogger.action('Workspace created', <String, Object>{
      'workspaceId': id,
      'currency': currency,
      'country': country,
    });

    return id;
  });

  @override
  Future<void> updateWorkspace(Workspace workspace) =>
      FailureMapper.guard('update workspace', () async {
        await _workspaces
            .doc(workspace.id)
            .set(WorkspaceDto.toUpdateMap(workspace), SetOptions(merge: true));

        AppLogger.info('Workspace updated', <String, Object>{
          'workspaceId': workspace.id,
        });
      });

  @override
  Future<void> setLastWorkspace({
    required String uid,
    required String workspaceId,
  }) => FailureMapper.guard('switch workspace', () async {
    await _users.doc(uid).set(<String, Object?>{
      'lastWorkspaceId': workspaceId,
      'updatedAt': FirestoreMapper.serverTimestamp,
    }, SetOptions(merge: true));

    AppLogger.action('Workspace switched', <String, Object>{
      'workspaceId': workspaceId,
    });
  });

  CollectionReference<Map<String, Object?>> get _users =>
      WorkspaceCollections.users(
        _firestore,
      ).withConverter(fromFirestore: _readMap, toFirestore: _writeMap);

  CollectionReference<Map<String, Object?>> get _workspaces =>
      WorkspaceCollections.workspaces(
        _firestore,
      ).withConverter(fromFirestore: _readMap, toFirestore: _writeMap);

  static Map<String, Object?> _readMap(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) => snapshot.data() ?? <String, Object?>{};

  static Map<String, dynamic> _writeMap(
    Map<String, Object?> data,
    SetOptions? _,
  ) => data.map(
    (String key, Object? value) => MapEntry<String, dynamic>(key, value),
  );
}
