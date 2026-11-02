import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/account/account_kind.dart';
import 'package:reseller_studio/core/local/drain/drain_destination.dart';
import 'package:reseller_studio/features/workspace/domain/entities/user_profile.dart';
import 'package:reseller_studio/features/workspace/presentation/controllers/guest_drain_controller.dart';
import 'package:reseller_studio/features/workspace/presentation/widgets/guest_drain_gate.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

/// Records what the gate asked for, so the test reads the decision rather
/// than running a drain against Firestore.
class _RecordingDrain extends GuestDrainController {
  int newWorkspaceCalls = 0;

  @override
  Future<DrainDestination?> decide() async => const DrainIntoNewWorkspace();

  @override
  Future<void> intoNewWorkspace() async => newWorkspaceCalls++;
}

/// **The first sign-in drains, with no business to wait for.**
///
/// App Review's "loaded indefinitely" on Sign in with Apple: the gate only
/// fired once the account had a business, a new account has none until the
/// drain creates it, and the splash held for both forever.
void main() {
  late _RecordingDrain drain;

  Future<void> pumpGate(
    WidgetTester tester,
    AsyncValue<UserProfile?> profile,
  ) async {
    drain = _RecordingDrain();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          accountKindProvider.overrideWithValue(AccountKind.linked),
          userProfileProvider.overrideWithValue(profile),
          guestDrainControllerProvider.overrideWith(() => drain),
        ],
        child: const MaterialApp(home: GuestDrainGate(child: SizedBox())),
      ),
    );
    await tester.pump();
  }

  testWidgets('a new account with no business starts the drain', (
    WidgetTester tester,
  ) async {
    await pumpGate(
      tester,
      const AsyncData<UserProfile?>(
        UserProfile(uid: 'uid-1', workspaceIds: <String>[]),
      ),
    );

    expect(drain.newWorkspaceCalls, 1);
  });

  testWidgets('a profile still loading starts nothing', (
    WidgetTester tester,
  ) async {
    await pumpGate(tester, const AsyncLoading<UserProfile?>());

    expect(drain.newWorkspaceCalls, 0);
  });
}
