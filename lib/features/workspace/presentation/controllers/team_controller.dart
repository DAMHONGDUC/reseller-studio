import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../domain/repositories/team_repository.dart';
import '../../providers.dart';

/// Inviting a teammate, changing what they may do, and letting them go
/// (plan §24).
///
/// **Every method here is a Cloud Function call and none of them could be a
/// client write** — the seat limit and the last-owner check each need a count
/// of a collection, and nobody may edit their own membership (hard rule 11).
/// The controller's job is the sequence and the logging; the checks are the
/// backend's.
///
/// **The screen decides nothing about permissions.** It greys out what an
/// admin cannot do because drawing a control that always fails is unkind, but
/// a viewer who reached one anyway is refused by the callable and sees the one
/// message hard rule 6 allows.
class TeamController extends Notifier<bool> {
  /// True while a call is in flight, so a sheet can disable its button.
  @override
  bool build() => false;

  Future<void> invite({required String email, required MemberRole role}) =>
      _run('invite a teammate', (TeamRepository repository, String workspaceId) async {
        await repository.invite(
          workspaceId: workspaceId,
          email: email,
          role: role,
        );
      }, <String, Object>{'role': role.name});

  Future<void> changeRole({
    required String memberUid,
    required MemberRole role,
  }) => _run('change a role', (
    TeamRepository repository,
    String workspaceId,
  ) async {
    await repository.changeRole(
      workspaceId: workspaceId,
      memberUid: memberUid,
      role: role,
    );
  }, <String, Object>{'role': role.name});

  Future<void> remove(String memberUid) =>
      _run('remove a teammate', (
        TeamRepository repository,
        String workspaceId,
      ) async {
        await repository.removeMember(
          workspaceId: workspaceId,
          memberUid: memberUid,
        );
      }, const <String, Object>{});

  /// Accepting is the one method that is not about the current workspace: the
  /// invitation names its own, and the seller is not a member of it yet.
  ///
  /// **It switches to what was just joined.** Nobody accepts an invitation in
  /// order to keep looking at the business they were already in.
  Future<void> acceptInvite(String inviteId) async {
    final TeamRepository? repository = ref.read(teamRepositoryProvider);

    if (repository == null) return;

    state = true;
    SdLogger.action(LogTagConstant.team, 'Accept invitation', <String, Object>{
      'inviteId': inviteId,
    });

    try {
      final String workspaceId = await repository.acceptInvite(inviteId);

      await ref
          .read(workspaceSwitchControllerProvider.notifier)
          .switchTo(workspaceId);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.team,
        'Failed to accept an invitation',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'inviteId': inviteId},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// The one path the three workspace-scoped methods share.
  ///
  /// **No email in the log data** (hard rule 9) — the workspace, the role and
  /// the uid are the shape; the address is what identifies a person.
  Future<void> _run(
    String what,
    Future<void> Function(TeamRepository repository, String workspaceId) call,
    Map<String, Object> data,
  ) async {
    final TeamRepository? repository = ref.read(teamRepositoryProvider);
    final String? workspaceId = ref.read(currentWorkspaceIdProvider);

    if (repository == null || workspaceId == null) return;

    state = true;
    SdLogger.action(LogTagConstant.team, what, <String, Object>{
      'workspaceId': workspaceId,
      ...data,
    });

    try {
      await call(repository, workspaceId);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.team,
        'Failed to $what',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'workspaceId': workspaceId, ...data},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<TeamController, bool> teamControllerProvider =
    NotifierProvider<TeamController, bool>(TeamController.new);
