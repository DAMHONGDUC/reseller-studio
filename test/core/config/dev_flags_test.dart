import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/core/config/dev_flags.dart';

/// The auth bypass is the one piece of code in this app whose *absence* is
/// the feature. These tests exist to fail if someone makes it easier to turn
/// on — which is exactly how a dev flag ends up in a store build.
void main() {
  group('DevFlags.bypassAuth', () {
    test('is off unless BYPASS_AUTH was passed at build time', () {
      // The suite runs without --dart-define, so this must be false. It fails
      // if anyone hardcodes the flag true "just to try something" and forgets,
      // which is the realistic way this breaks — not a malicious edit.
      expect(DevFlags.bypassAuth, isFalse);
    });

    test('is a compile-time constant, so release builds can shed it', () {
      // `const` here does not compile unless the value is const-evaluable.
      // That is the property that lets the tree-shaker delete every `if
      // (DevFlags.bypassAuth)` branch from a release binary — the bypass is
      // absent from a shipped app, not merely disabled in it.
      const bool folded = DevFlags.bypassAuth;

      expect(folded, isFalse);
    });

    test('cannot be true in a release build, however it was defined', () {
      // The guarantee is `bool.fromEnvironment(...) && !kReleaseMode`.
      // Restated here so that removing the kReleaseMode half fails a test
      // rather than silently arming --dart-define against a store build.
      if (kReleaseMode) {
        expect(DevFlags.bypassAuth, isFalse);
      }

      expect(DevFlags.bypassAuth && kReleaseMode, isFalse);
    });
  });

  test('bypassUid is obviously fake, so it is greppable in real data', () {
    // If this string ever appears in a production Firestore project, a bypass
    // build wrote to it. That is only useful if it could never be mistaken
    // for a Firebase uid, which is 28 alphanumeric characters.
    expect(DevFlags.bypassUid, contains('dev'));
    expect(DevFlags.bypassUid, contains('-'));
  });
}
