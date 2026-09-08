import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/error/app_failure.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/workspace/domain/entities/pending_invite.dart';
import 'package:reseller_studio/features/workspace/domain/repositories/team_repository.dart';
import 'package:reseller_studio/features/workspace/presentation/controllers/team_controller.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

import '../../support/pump_app.dart';

/// Inviting, promoting and removing (plan §24).
///
/// **Every one of these is a Cloud Function call**, because the seat limit
/// and the last-owner check each need a count of a collection and nobody may
/// edit their own membership (hard rule 11). The controller owns the sequence
/// and the logging; the checks are the backend's, so what these pin is that
/// the call is made against the workspace that is open, and that a build with
/// no team backend does nothing rather than throwing.
class _RecordingTeam implements TeamRepository {
  final List<String> calls = <String>[];
  String? workspaceIdSeen;
  MemberRole? roleSeen;

  @override
  Stream<List<PendingInvite>> watchMyInvites(String email) =>
      const Stream<List<PendingInvite>>.empty();

  @override
  Future<String> invite({
    required String workspaceId,
    required String email,
    required MemberRole role,
  }) async {
    calls.add('invite');
    workspaceIdSeen = workspaceId;
    roleSeen = role;

    return 'inv-1';
  }

  @override
  Future<String> acceptInvite(String inviteId) async {
    calls.add('accept');

    return 'ws-joined';
  }

  @override
  Future<void> removeMember({
    required String workspaceId,
    required String memberUid,
  }) async {
    calls.add('remove');
    workspaceIdSeen = workspaceId;
  }

  @override
  Future<void> changeRole({
    required String workspaceId,
    required String memberUid,
    required MemberRole role,
  }) async {
    calls.add('changeRole');
    workspaceIdSeen = workspaceId;
    roleSeen = role;
  }
}

/// The callable refusing, which is what a viewer who reached a control sees.
class _RefusingTeam extends _RecordingTeam {
  @override
  Future<void> removeMember({
    required String workspaceId,
    required String memberUid,
  }) async => throw const AppFailure(AppFailureKind.permissionDenied);
}

void main() {
  ProviderContainer containerWith(TeamRepository? team) => mockContainer(
    overrides: <Override>[teamRepositoryProvider.overrideWithValue(team)],
    replaces: <Object>{teamRepositoryProvider},
  );

  TeamController team(ProviderContainer container) =>
      container.read(teamControllerProvider.notifier);

  test('every action names the workspace that is open', () async {
    final _RecordingTeam repository = _RecordingTeam();
    final ProviderContainer container = containerWith(repository);
    final String? workspaceId = container.read(currentWorkspaceIdProvider);

    await team(
      container,
    ).invite(email: 'mate@example.com', role: MemberRole.admin);

    expect(repository.calls, <String>['invite']);
    expect(repository.workspaceIdSeen, workspaceId);
    expect(repository.roleSeen, MemberRole.admin);

    await team(
      container,
    ).changeRole(memberUid: 'uid-2', role: MemberRole.viewer);
    await team(container).remove('uid-2');

    expect(repository.calls, <String>['invite', 'changeRole', 'remove']);
    expect(container.read(teamControllerProvider), isFalse);
  });

  test(
    'a build with no team backend does nothing and does not throw',
    () async {
      final ProviderContainer container = containerWith(null);

      // The Team screen draws no add button without a backend; reaching the
      // controller anyway must be inert rather than an error.
      await team(
        container,
      ).invite(email: 'mate@example.com', role: MemberRole.admin);
      await team(container).remove('uid-2');

      expect(container.read(teamControllerProvider), isFalse);
    },
  );

  test('a refused call reaches the screen and stops the spinner', () async {
    final ProviderContainer container = containerWith(_RefusingTeam());

    await expectLater(
      team(container).remove('uid-2'),
      throwsA(isA<AppFailure>()),
    );
    expect(container.read(teamControllerProvider), isFalse);
  });

  test('accepting an invitation switches to what was joined', () async {
    final _RecordingTeam repository = _RecordingTeam();
    final ProviderContainer container = containerWith(repository);

    // Nobody accepts an invitation in order to keep looking at the business
    // they were already in.
    await team(container).acceptInvite('inv-1');

    expect(repository.calls, <String>['accept']);
    expect(container.read(teamControllerProvider), isFalse);
  });
}
