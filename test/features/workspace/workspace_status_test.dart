import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/workspace/domain/entities/user_profile.dart';
import 'package:reseller_studio/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

/// **A profile that is loading is loading, retained value or not.**
///
/// Signing in rebuilds `userProfileProvider` for the new uid, and Riverpod
/// carries the signed-out state — `AsyncData(null)` — forward as the previous
/// value while the real profile loads. Reading that null as "no workspace"
/// sent every returning seller to the create-business form for a frame before
/// Home, which is the most visible way to get the router wrong.
UserProfile _profile({List<String> workspaceIds = const <String>['ws-1']}) =>
    UserProfile(
      uid: 'uid-1',
      workspaceIds: workspaceIds,
      lastWorkspaceId: workspaceIds.isEmpty ? null : workspaceIds.first,
    );

WorkspaceStatus _statusFor(AsyncValue<UserProfile?> profile) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[userProfileProvider.overrideWithValue(profile)],
  );

  addTearDown(container.dispose);

  return container.read(workspaceStatusProvider);
}

/// A repository whose profile stream never emits, so the transition can be
/// read at exactly the moment sign-in passes through it.
class _SilentWorkspaceRepository extends Fake implements WorkspaceRepository {
  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      const Stream<UserProfile?>.empty().asBroadcastStream();
}

void main() {
  test('a first load with nothing yet is loading', () {
    expect(
      _statusFor(const AsyncLoading<UserProfile?>()),
      WorkspaceStatus.loading,
    );
  });

  test('signing in is loading, not "no workspace"', () async {
    // The bug this pins, reproduced through the real chain rather than by
    // hand-building an AsyncValue: signed out resolves to `AsyncData(null)`,
    // then the uid changes and Riverpod carries that null forward as the
    // previous value while the real profile loads. Reading it as "no
    // workspace" sent every returning seller to the create-business form.
    String? uid;
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        currentUidProvider.overrideWith((Ref ref) => uid),
        workspaceRepositoryProvider.overrideWithValue(
          _SilentWorkspaceRepository(),
        ),
      ],
    );

    addTearDown(container.dispose);

    // Listened to, so the previous value is retained across the rebuild —
    // which is the whole condition being tested.
    container.listen(userProfileProvider, (_, _) {});

    // Signed out: `Stream.value(null)` resolves on a microtask.
    await container.read(userProfileProvider.future);

    expect(container.read(workspaceStatusProvider), WorkspaceStatus.none);

    uid = 'uid-1';
    container.invalidate(currentUidProvider);

    expect(container.read(workspaceStatusProvider), WorkspaceStatus.loading);
  });

  test('a resolved profile with a workspace is ready', () {
    expect(
      _statusFor(AsyncData<UserProfile?>(_profile())),
      WorkspaceStatus.ready,
    );
  });

  test('a resolved profile with no workspace is none', () {
    expect(
      _statusFor(
        AsyncData<UserProfile?>(_profile(workspaceIds: const <String>[])),
      ),
      WorkspaceStatus.none,
    );
  });

  test('a failed read is none, not a splash that never resolves', () {
    // The user gets a screen they can act on instead of waiting forever.
    expect(
      _statusFor(
        AsyncError<UserProfile?>(Exception('denied'), StackTrace.empty),
      ),
      WorkspaceStatus.none,
    );
  });
}
