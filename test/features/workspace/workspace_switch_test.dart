import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/error/app_failure.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

import '../../support/fakes/in_memory_repositories.dart';
import '../../support/fakes/mock_dataset.dart';
import '../../support/pump_app.dart';

/// Moving between businesses (hard rule 11b).
///
/// **Switching is a write, never local state.** It sets `lastWorkspaceId` on
/// the seller's own document; the profile stream carries it back and every
/// business provider is already watching that. A "currently selected"
/// variable held in a controller would be a second answer to the same
/// question, and a teammate removing you from a business could contradict it.
class _RecordingWorkspaces extends InMemoryWorkspaceRepository {
  _RecordingWorkspaces(super.store);

  final List<String> pointedAt = <String>[];
  String? uidSeen;

  @override
  Future<void> setLastWorkspace({
    required String uid,
    required String workspaceId,
  }) async {
    uidSeen = uid;
    pointedAt.add(workspaceId);
  }
}

class _RefusingWorkspaces extends _RecordingWorkspaces {
  _RefusingWorkspaces(super.store);

  @override
  Future<void> setLastWorkspace({
    required String uid,
    required String workspaceId,
  }) async => throw const AppFailure(AppFailureKind.offline);
}

void main() {
  MockStore store() => MockStore(MockDataset.seed(now: testNow));

  ProviderContainer containerWith(
    InMemoryWorkspaceRepository workspaces, {
    String? uid = 'uid-1',
  }) => mockContainer(
    overrides: <Override>[
      workspaceRepositoryProvider.overrideWithValue(workspaces),
      currentUidProvider.overrideWithValue(uid),
    ],
    replaces: <Object>{workspaceRepositoryProvider},
  );

  test('switching writes the pointer on the seller own document', () async {
    final _RecordingWorkspaces workspaces = _RecordingWorkspaces(store());
    final ProviderContainer container = containerWith(workspaces);

    await container
        .read(workspaceSwitchControllerProvider.notifier)
        .switchTo('ws-other');

    expect(workspaces.pointedAt, <String>['ws-other']);
    expect(workspaces.uidSeen, 'uid-1');
  });

  test('switching to the one already open writes nothing', () async {
    final _RecordingWorkspaces workspaces = _RecordingWorkspaces(store());
    final ProviderContainer container = containerWith(workspaces);
    final String open = container.read(currentWorkspaceIdProvider)!;

    await container
        .read(workspaceSwitchControllerProvider.notifier)
        .switchTo(open);

    expect(workspaces.pointedAt, isEmpty);
  });

  test('nobody signed in writes nothing', () async {
    final _RecordingWorkspaces workspaces = _RecordingWorkspaces(store());
    final ProviderContainer container = containerWith(workspaces, uid: null);

    await container
        .read(workspaceSwitchControllerProvider.notifier)
        .switchTo('ws-other');

    expect(workspaces.pointedAt, isEmpty);
  });

  test('a failed switch reaches the screen', () async {
    final ProviderContainer container = containerWith(
      _RefusingWorkspaces(store()),
    );

    await expectLater(
      container
          .read(workspaceSwitchControllerProvider.notifier)
          .switchTo('ws-other'),
      throwsA(isA<AppFailure>()),
    );
  });
}
