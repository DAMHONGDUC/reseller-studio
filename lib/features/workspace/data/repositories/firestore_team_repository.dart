import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/callable_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../domain/entities/pending_invite.dart';
import '../../domain/repositories/team_repository.dart';
import '../dtos/invite_dto.dart';

/// Team management: reads from Firestore, writes through Cloud Functions.
///
/// **The split is not a style choice.** Every write here is one a rule cannot
/// authorise — the seat limit needs a count, the last-owner check needs a
/// count, and nobody may write their own membership document (hard rule 11).
/// The read is the one thing rules *can* express: an invitation is readable
/// by the address it names.
///
/// **No email is ever logged** (hard rule 9). The log lines carry the
/// workspace, the role and a count; the address is the one part of an invite
/// that identifies a person.
class FirestoreTeamRepository implements TeamRepository {
  const FirestoreTeamRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<PendingInvite>> watchMyInvites(String email) =>
      FirestoreStream.collection(
        _invites
            .where('email', isEqualTo: email.trim().toLowerCase())
            .where('status', isEqualTo: 'pending'),
        InviteDto.toEntity,
        operation: 'load invitations',
      );

  @override
  Future<String> invite({
    required String workspaceId,
    required String email,
    required MemberRole role,
  }) => FailureMapper.guard('invite a teammate', () async {
    SdLogger.action(LogTagConstant.team, 'Invite teammate', <String, Object>{
      'workspaceId': workspaceId,
      'role': role.name,
    });

    final HttpsCallableResult<Object?> result = await _functions
        .httpsCallable(CallableConstant.inviteMember)
        .call<Object?>(<String, Object?>{
          'workspaceId': workspaceId,
          'email': email.trim().toLowerCase(),
          'role': role.name,
        });

    final String inviteId = _stringField(result.data, 'inviteId');

    SdLogger.info(LogTagConstant.team, 'Teammate invited', <String, Object>{
      'workspaceId': workspaceId,
      'role': role.name,
    });

    return inviteId;
  });

  @override
  Future<String> acceptInvite(String inviteId) =>
      FailureMapper.guard('accept an invitation', () async {
        SdLogger.action(LogTagConstant.team, 'Accept invitation', <String, Object>{
          'inviteId': inviteId,
        });

        final HttpsCallableResult<Object?> result = await _functions
            .httpsCallable(CallableConstant.acceptInvite)
            .call<Object?>(<String, Object?>{'inviteId': inviteId});

        final String workspaceId = _stringField(result.data, 'workspaceId');

        SdLogger.action(LogTagConstant.team, 'Invitation accepted', <String, Object>{
          'workspaceId': workspaceId,
        });

        return workspaceId;
      });

  @override
  Future<void> removeMember({
    required String workspaceId,
    required String memberUid,
  }) => _member('remove a teammate', workspaceId, memberUid, null);

  @override
  Future<void> changeRole({
    required String workspaceId,
    required String memberUid,
    required MemberRole role,
  }) => _member('change a role', workspaceId, memberUid, role);

  /// One callable does both: passing a role changes it, omitting it removes
  /// the membership. The last-owner check is the same count either way, which
  /// is why the backend refuses to split them.
  Future<void> _member(
    String what,
    String workspaceId,
    String memberUid,
    MemberRole? role,
  ) => FailureMapper.guard(what, () async {
    SdLogger.action(LogTagConstant.team, what, <String, Object?>{
      'workspaceId': workspaceId,
      'memberUid': memberUid,
      'role': role?.name,
    });

    await _functions
        .httpsCallable(CallableConstant.removeMember)
        .call<Object?>(<String, Object?>{
          'workspaceId': workspaceId,
          'memberUid': memberUid,
          if (role != null) 'role': role.name,
        });

    SdLogger.info(LogTagConstant.team, 'Team updated', <String, Object?>{
      'workspaceId': workspaceId,
      'role': role?.name,
    });
  });

  /// A callable answers `Map<Object?, Object?>`, and a field that is missing
  /// is a backend the app does not understand — an empty string rather than a
  /// cast that throws where hard rule 6 says nothing technical may surface.
  static String _stringField(Object? data, String key) {
    if (data is Map && data[key] is String) return data[key] as String;

    return '';
  }

  CollectionReference<Map<String, Object?>> get _invites =>
      _firestore
          .collection('invites')
          .withConverter<Map<String, Object?>>(
            fromFirestore:
                (
                  DocumentSnapshot<Map<String, dynamic>> snapshot,
                  SnapshotOptions? _,
                ) => snapshot.data() ?? <String, Object?>{},
            toFirestore: (Map<String, Object?> data, SetOptions? _) =>
                data.map(
                  (String key, Object? value) =>
                      MapEntry<String, dynamic>(key, value),
                ),
          );
}
