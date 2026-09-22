import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/error/app_failure.dart';
import 'package:reseller_studio/core/local/local_database.dart';
import 'package:reseller_studio/core/local/local_providers.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/auth/domain/repositories/auth_repository.dart';
import 'package:reseller_studio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/notifications/presentation/controllers/push_controller.dart';
import 'package:reseller_studio/features/notifications/providers.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_offering.dart';
import 'package:reseller_studio/features/subscription/domain/entities/subscription_status.dart';
import 'package:reseller_studio/features/subscription/domain/repositories/subscription_repository.dart';

/// The billing SDK a seller actually hit: RevenueCat refuses to log out an
/// identity it never logged in, and threw that at a sign-out.
class _RefusingBilling implements SubscriptionRepository {
  @override
  Stream<SubscriptionStatus> watchStatus() =>
      Stream<SubscriptionStatus>.value(SubscriptionStatus.free);

  @override
  Future<List<PlanOffering>> offerings() async => const <PlanOffering>[];

  @override
  Future<SubscriptionStatus> purchase(PlanOffering offering) async =>
      SubscriptionStatus.free;

  @override
  Future<SubscriptionStatus> restore() async => SubscriptionStatus.free;

  @override
  Future<void> identify(String uid) async {}

  @override
  Future<void> forget() async => throw const AppFailure(AppFailureKind.unknown);
}

/// A device that cannot be unregistered — the other cleanup step, failing.
class _RefusingPush extends PushController {
  @override
  void build() {}

  @override
  Future<void> unregister() async =>
      throw const AppFailure(AppFailureKind.offline);
}

class _RecordingAuth implements AuthRepository {
  bool signedOut = false;

  @override
  Future<SignInResult> signInWithApple() async =>
      const SignInResult.cancelled();

  @override
  Future<SignInResult> signInWithGoogle() async =>
      const SignInResult.cancelled();

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  Future<void> deleteAccount() async {}
}

/// A delete that does not finish until the test lets it.
class _SlowAuth extends _RecordingAuth {
  _SlowAuth(this.gate);

  final Completer<void> gate;

  @override
  Future<void> deleteAccount() => gate.future;
}

class _RefusingAuth extends _RecordingAuth {
  @override
  Future<void> signOut() async =>
      throw const AppFailure(AppFailureKind.offline);
}

class _RefusingDelete extends _RecordingAuth {
  @override
  Future<void> deleteAccount() async =>
      throw const AppFailure(AppFailureKind.unauthenticated);
}

/// **Nothing between the seller and the way out, and nothing silent.**
///
/// Sign-out unregisters the device and clears the billing identity first, and
/// both of those talk to a third party that can fail — which is what happened:
/// RevenueCat threw on an anonymous log-out and the Firebase sign-out below it
/// never ran, so tapping "Sign out" did nothing at all.
///
/// The other half is that both actions say they are running. The delete waits
/// on a Cloud Function that walks every subcollection, and a card that did not
/// change was a card sellers tapped twice.
void main() {
  ProviderContainer containerWith(AuthRepository auth) {
    // Signing out wipes the guest store (`docs/rules/GUEST_MODE.md`), so the
    // controller needs one. In memory: the real provider opens a file through
    // `path_provider`, which has no platform channel behind it here.
    final LocalDatabase db = LocalDatabase.forTesting(NativeDatabase.memory());
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(auth),
        subscriptionRepositoryProvider.overrideWithValue(_RefusingBilling()),
        pushControllerProvider.overrideWith(_RefusingPush.new),
        localDatabaseProvider.overrideWithValue(db),
      ],
    );

    addTearDown(db.close);
    addTearDown(container.dispose);

    return container;
  }

  test('a failing cleanup step does not keep the seller signed in', () async {
    final _RecordingAuth auth = _RecordingAuth();
    final ProviderContainer container = containerWith(auth);

    await container.read(authControllerProvider.notifier).signOut();

    expect(auth.signedOut, isTrue);
  });

  test('the sign-out itself failing is still an error', () async {
    final ProviderContainer container = containerWith(_RefusingAuth());

    await expectLater(
      container.read(authControllerProvider.notifier).signOut(),
      throwsA(isA<AppFailure>()),
    );
  });

  test('the delete reports itself busy until it finishes', () async {
    final Completer<void> gate = Completer<void>();
    final ProviderContainer container = containerWith(_SlowAuth(gate));
    final Future<void> pending = container
        .read(authControllerProvider.notifier)
        .deleteAccount();

    expect(
      container
          .read(authControllerProvider)
          .isRunning(AccountAction.deleteAccount),
      isTrue,
    );
    expect(
      container.read(authControllerProvider).isRunning(AccountAction.signOut),
      isFalse,
    );

    gate.complete();
    await pending;

    expect(container.read(authControllerProvider).isBusy, isFalse);
  });

  test('a failed delete stops looking busy', () async {
    final ProviderContainer container = containerWith(_RefusingDelete());

    await expectLater(
      container.read(authControllerProvider.notifier).deleteAccount(),
      throwsA(isA<AppFailure>()),
    );
    expect(container.read(authControllerProvider).isBusy, isFalse);
  });
}
