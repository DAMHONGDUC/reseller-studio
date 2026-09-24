import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/callable_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../../carriers/domain/entities/carrier.dart';
import '../../../inventory/domain/entities/item_category.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../marketplaces/domain/entities/marketplace.dart';
import '../../../pricing/domain/services/profit_calculator.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../dtos/workspace_dto.dart';

/// Workspaces, memberships and user profiles, in Firestore.
///
/// **Creation is two prerequisite writes and one final batch, forced by the
/// security rules.** A rules `get()` sees only committed data, so the order is
/// workspace → membership → batch(default records + profile pointer).
/// A failure before the last step leaves the workspace unreachable rather
/// than exposing a business with only part of its default marketplace list.
class FirestoreWorkspaceRepository implements WorkspaceRepository {
  const FirestoreWorkspaceRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;

  /// Only [deleteWorkspace] uses it. Everything else here is a document the
  /// rules already let the seller write; the cascade is the one thing they
  /// cannot do from the client at all.
  final FirebaseFunctions _functions;

  /// **Confirmed, not merely cached** — this is the document the router
  /// branches on. Firestore answers a listener from its cache first, and a
  /// device that has never held this profile answers "no such document",
  /// which `workspaceStatusProvider` can only read as "no business yet". That
  /// is what sent a returning seller to the create-business form for half a
  /// second after every sign-in.
  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      FirestoreStream.confirmedDocument(
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
        WorkspaceCollections(_firestore, workspaceId).members.query,
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

    SdLogger.info(LogTagConstant.workspace, 'Profile ensured', <String, Object>{
      'uid': uid,
    });
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
    required List<Marketplace> marketplaces,
    required List<ItemCategory> categories,
    required List<Carrier> carriers,
  }) => FailureMapper.guard('create workspace', () async {
    final String id = SdId.unique();
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
            'staleThresholdDays': StaleInventoryPolicy.defaultThresholdDays,
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

    final WriteBatch finalBatch = _firestore.batch();
    final WorkspaceCollections collections = WorkspaceCollections(
      _firestore,
      id,
    );

    for (final Marketplace marketplace in marketplaces) {
      finalBatch.set(
        collections.marketplaces.doc(marketplace.id),
        FirestoreMapper.pruned(<String, Object?>{
          'name': marketplace.name,
          'createdAt': FirestoreMapper.serverTimestamp,
          'updatedAt': FirestoreMapper.serverTimestamp,
          'createdBy': ownerId,
        }),
      );
    }

    for (final ItemCategory category in categories) {
      finalBatch.set(
        collections.categories.doc(category.id),
        FirestoreMapper.pruned(<String, Object?>{
          'name': category.name,
          'createdAt': FirestoreMapper.serverTimestamp,
          'updatedAt': FirestoreMapper.serverTimestamp,
          'createdBy': ownerId,
        }),
      );
    }

    for (final Carrier carrier in carriers) {
      finalBatch.set(
        collections.carriers.doc(carrier.id),
        FirestoreMapper.pruned(<String, Object?>{
          'name': carrier.name,
          'createdAt': FirestoreMapper.serverTimestamp,
          'updatedAt': FirestoreMapper.serverTimestamp,
          'createdBy': ownerId,
        }),
      );
    }

    finalBatch.set(_users.doc(ownerId), <String, Object?>{
      'workspaceIds': FieldValue.arrayUnion(<String>[id]),
      'lastWorkspaceId': id,
      'updatedAt': FirestoreMapper.serverTimestamp,
    }, SetOptions(merge: true));
    await finalBatch.commit();

    SdLogger.action(
      LogTagConstant.workspace,
      'Workspace created',
      <String, Object>{
        'workspaceId': id,
        'currency': currency,
        'country': country,
        'marketplaceCount': marketplaces.length,
        'categoryCount': categories.length,
        'carrierCount': carriers.length,
      },
    );

    return id;
  });

  @override
  Future<void> updateWorkspace(Workspace workspace) =>
      FailureMapper.guard('update workspace', () async {
        await _workspaces
            .doc(workspace.id)
            .set(WorkspaceDto.toUpdateMap(workspace), SetOptions(merge: true));

        SdLogger.info(
          LogTagConstant.workspace,
          'Workspace updated',
          <String, Object>{'workspaceId': workspace.id},
        );
      });

  /// **The function deletes the documents, and the app deletes nothing.**
  /// `workspaces/{id}` is `allow delete: if false` for clients, so a client
  /// delete would fail on the parent and leave every subcollection behind —
  /// invisible to the seller and still billed for.
  ///
  /// Nothing here switches workspace afterwards. The membership documents go
  /// with the business, `onMemberWritten` drops the id from every member's
  /// `workspaceIds`, and `resolvedWorkspaceId` falls back on its own (hard
  /// rule 11b) — a switch written here would be a second answer to the same
  /// question.
  @override
  Future<void> deleteWorkspace(String workspaceId) =>
      FailureMapper.guard('delete workspace', () async {
        SdLogger.action(
          LogTagConstant.workspace,
          'Delete workspace',
          <String, Object>{'workspaceId': workspaceId},
        );

        final HttpsCallableResult<Object?> result = await _functions
            .httpsCallable(CallableConstant.deleteWorkspace)
            .call<Object?>(<String, Object?>{'workspaceId': workspaceId});

        SdLogger.action(
          LogTagConstant.workspace,
          'Workspace deleted',
          <String, Object?>{'workspaceId': workspaceId, 'result': result.data},
        );
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

    SdLogger.action(
      LogTagConstant.workspace,
      'Workspace switched',
      <String, Object>{'workspaceId': workspaceId},
    );
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
