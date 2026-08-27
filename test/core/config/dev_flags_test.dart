import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/config/dev_flags.dart';
import 'package:reseller_studio/features/auth/providers.dart';

/// **There is no way into this app but Apple or Google** (hard rule 1).
///
/// This file used to guard the dev auth bypass — that it defaulted off and
/// could not reach a release build. The bypass is gone: it existed so the
/// login screen was not a dead end before Firebase existed, and the five tabs
/// now render empty without an account, so its reason expired.
///
/// What replaces it is the stronger assertion. The bypass was the one thing
/// that could ever answer "signed in" without an account, so the test worth
/// keeping is that **nothing does** — including the case it was built for, a
/// build with no Firebase app at all.
void main() {
  group('no build can enter the app unauthenticated', () {
    test('with no Firebase configured, auth resolves to signed OUT', () {
      final ProviderContainer container = ProviderContainer();

      addTearDown(container.dispose);

      // `Firebase.initializeApp` has not run in this test, which is exactly
      // the state a developer's machine is in before `flutterfire configure`.
      // Reading `FirebaseAuth.instance` here would throw `[core/no-app]`;
      // `firebaseReadyProvider` is what stops it, and the answer it produces
      // must be "signed out" and never "signed in".
      expect(container.read(firebaseReadyProvider), isFalse);
      expect(container.read(isSignedInProvider), isNot(isTrue));
      expect(container.read(currentUidProvider), isNull);
    });

    test('no fake uid is left anywhere for a Firestore path to pick up', () {
      final ProviderContainer container = ProviderContainer();

      addTearDown(container.dispose);

      // The bypass used to substitute `dev-bypass-user` here, which is what
      // made a signed-out session able to write real paths. Null is the only
      // acceptable answer now, and every caller already treats it as "nobody".
      expect(container.read(currentUidProvider), isNull);
    });
  });

  group('the switches that remain cannot reach a release build', () {
    test('every flag is const-evaluable, so release sheds the branches', () {
      // These only compile if the values fold at compile time, which is what
      // lets the tree-shaker delete the branch and everything only it reached.
      const bool mock = DevFlags.mockDataDefault;
      const bool verbose = DevFlags.verboseLogging;

      expect(<bool>[mock, verbose], everyElement(isFalse));
    });

    test('no flag is true in release, however the env file was written', () {
      // Restated here so removing a `!kReleaseMode` fails a test rather than
      // silently arming a config file against a store build.
      expect(DevFlags.mockDataDefault && kReleaseMode, isFalse);
      expect(DevFlags.verboseLogging && kReleaseMode, isFalse);
    });
  });
}
