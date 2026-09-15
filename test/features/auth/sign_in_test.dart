import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/error/app_failure.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/auth/domain/repositories/auth_repository.dart';
import 'package:reseller_studio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

import '../../support/fakes/in_memory_repositories.dart';
import '../../support/fakes/mock_dataset.dart';
import '../../support/pump_app.dart';

/// The way in (hard rule 1), from the controller's side.
///
/// The sibling file covers the way out. What these pin is the half a seller
/// meets first: that backing out of a provider sheet is not an error, that a
/// real failure still reaches the screen, and that neither of the two
/// best-effort steps after a valid session can take that session away again.
class _FakeAuth implements AuthRepository {
  _FakeAuth({this.apple, this.google});

  /// What each provider answers. A thrown object is thrown from the call.
  final Object? apple;
  final Object? google;

  int appleCalls = 0;
  int googleCalls = 0;

  Future<SignInResult> _answer(Object? outcome) async {
    if (outcome is SignInResult) return outcome;

    // `Future.error` rather than `throw`: the field is an `Object?`, and a
    // throw of one is what `only_throw_errors` is for.
    return Future<SignInResult>.error(
      outcome ?? const AppFailure(AppFailureKind.unknown),
    );
  }

  @override
  Future<SignInResult> signInWithApple() {
    appleCalls++;

    return _answer(apple);
  }

  @override
  Future<SignInResult> signInWithGoogle() {
    googleCalls++;

    return _answer(google);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

/// A sign-in that does not finish until the test lets it.
class _SlowAuth implements AuthRepository {
  _SlowAuth(this.gate);

  final Completer<SignInResult> gate;

  @override
  Future<SignInResult> signInWithApple() => gate.future;

  @override
  Future<SignInResult> signInWithGoogle() => gate.future;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

/// The profile write, failing.
class _RefusingProfile extends InMemoryWorkspaceRepository {
  _RefusingProfile(super.store);

  @override
  Future<void> ensureProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
  }) async => throw const AppFailure(AppFailureKind.offline);
}

/// The billing identity, failing.
class _RefusingBilling extends InMemorySubscriptionRepository {
  _RefusingBilling(super.store);

  @override
  Future<void> identify(String uid) async =>
      throw const AppFailure(AppFailureKind.unknown);
}

void main() {
  ProviderContainer containerWith(
    AuthRepository auth, {
    List<Override> overrides = const <Override>[],
    Set<Object> replaces = const <Object>{},
  }) => mockContainer(
    overrides: <Override>[
      authRepositoryProvider.overrideWithValue(auth),
      ...overrides,
    ],
    replaces: replaces,
  );

  MockStore store() => MockStore(MockDataset.seed(now: testNow));

  test('backing out of the provider sheet is not an error', () async {
    final _FakeAuth auth = _FakeAuth(apple: const SignInResult.cancelled());
    final ProviderContainer container = containerWith(auth);

    final bool signedIn = await container
        .read(authControllerProvider.notifier)
        .signIn(AuthProviderKind.apple);

    // No throw, no message: the seller closed a sheet.
    expect(signedIn, isFalse);
    expect(auth.appleCalls, 1);
    expect(container.read(authControllerProvider).isBusy, isFalse);
  });

  test('a real failure reaches the screen and clears the spinner', () async {
    final ProviderContainer container = containerWith(
      _FakeAuth(google: const AppFailure(AppFailureKind.offline)),
    );

    await expectLater(
      container
          .read(authControllerProvider.notifier)
          .signIn(AuthProviderKind.google),
      throwsA(isA<AppFailure>()),
    );
    expect(container.read(authControllerProvider).isBusy, isFalse);
  });

  test('the tapped provider is the only one that looks busy', () async {
    final Completer<SignInResult> gate = Completer<SignInResult>();
    final ProviderContainer container = containerWith(_SlowAuth(gate));
    final Future<bool> pending = container
        .read(authControllerProvider.notifier)
        .signIn(AuthProviderKind.apple);

    final AuthFormState busy = container.read(authControllerProvider);

    expect(busy.isBusyWith(AuthProviderKind.apple), isTrue);
    expect(busy.isBusyWith(AuthProviderKind.google), isFalse);

    gate.complete(const SignInResult.signedIn('uid-1'));
    await pending;

    expect(container.read(authControllerProvider).isBusy, isFalse);
  });

  test('a failed profile write does not undo a valid session', () async {
    final ProviderContainer container = containerWith(
      _FakeAuth(apple: const SignInResult.signedIn('uid-1')),
      overrides: <Override>[
        workspaceRepositoryProvider.overrideWithValue(
          _RefusingProfile(store()),
        ),
      ],
      replaces: <Object>{workspaceRepositoryProvider},
    );

    // The session already exists. Blocking the seller at the login screen
    // over a document they never see would be the wrong trade — the next
    // sign-in retries it.
    expect(
      await container
          .read(authControllerProvider.notifier)
          .signIn(AuthProviderKind.apple),
      isTrue,
    );
  });

  test('an unreachable billing SDK does not undo a valid session', () async {
    final ProviderContainer container = containerWith(
      _FakeAuth(google: const SignInResult.signedIn('uid-1')),
      overrides: <Override>[
        subscriptionRepositoryProvider.overrideWithValue(
          _RefusingBilling(store()),
        ),
      ],
      replaces: <Object>{subscriptionRepositoryProvider},
    );

    expect(
      await container
          .read(authControllerProvider.notifier)
          .signIn(AuthProviderKind.google),
      isTrue,
    );
  });

  test('one provider is asked, never both', () async {
    final _FakeAuth auth = _FakeAuth(
      apple: const SignInResult.signedIn('uid-1'),
      google: const SignInResult.signedIn('uid-2'),
    );
    final ProviderContainer container = containerWith(auth);

    await container
        .read(authControllerProvider.notifier)
        .signIn(AuthProviderKind.google);

    expect(auth.googleCalls, 1);
    expect(auth.appleCalls, 0);
  });
}
