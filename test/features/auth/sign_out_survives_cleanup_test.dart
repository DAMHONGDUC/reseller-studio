import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/error/app_failure.dart';
import 'package:reseller_studio/features/auth/domain/repositories/auth_repository.dart';
import 'package:reseller_studio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';
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
  Future<void> forget() async =>
      throw const AppFailure(AppFailureKind.unknown);
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

class _RefusingAuth extends _RecordingAuth {
  @override
  Future<void> signOut() async =>
      throw const AppFailure(AppFailureKind.offline);
}

/// **Nothing between the seller and the way out.**
///
/// Sign-out unregisters the device and clears the billing identity first, and
/// both of those talk to a third party that can fail — which is what happened:
/// RevenueCat threw on an anonymous log-out and the Firebase sign-out below it
/// never ran, so tapping "Sign out" did nothing at all.
void main() {
  ProviderContainer containerWith(AuthRepository auth) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(auth),
        subscriptionRepositoryProvider.overrideWithValue(_RefusingBilling()),
        pushControllerProvider.overrideWith(_RefusingPush.new),
      ],
    );

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
}
