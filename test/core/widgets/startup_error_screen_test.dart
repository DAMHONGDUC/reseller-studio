import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/bootstrap/app_startup_failure.dart';
import 'package:reseller_studio/core/widgets/startup_error_screen.dart';

import '../../support/pump_app.dart';

/// The one failure this screen exists for: a dev build holding the production
/// project, because `prepare-env` was last run for the other flavour. Nothing
/// is unreachable — the app would work, against the wrong Firestore.
FlavorConfigMismatch _mismatch() => const FlavorConfigMismatch(
  expected: 'reseller-studio-dev',
  actual: 'reseller-studio-prod',
);

void main() {
  group('StartupFailurePolicy', () {
    test('config whose two halves name different projects stops the launch', () {
      expect(StartupFailurePolicy.isFatal(_mismatch()), isTrue);
    });

    test('nothing else does', () {
      // The seller is standing in a store with no signal. They get the app.
      final FirebaseException offline = FirebaseException(
        plugin: 'core',
        code: 'unavailable',
      );

      expect(StartupFailurePolicy.isFatal(offline), isFalse);
      expect(StartupFailurePolicy.isFatal(StateError('billing')), isFalse);
    });

    test('it says which project each half named, and what to run', () {
      final String detail = AppStartupFailure(
        step: 'Firebase',
        error: _mismatch(),
      ).detail;

      expect(detail, contains('reseller-studio-dev'));
      expect(detail, contains('reseller-studio-prod'));
      expect(detail, contains('prepare-env'));
    });
  });

  group('StartupErrorScreen', () {
    testWidgets('it says what happened and what to do about it', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        StartupErrorScreen(
          failure: AppStartupFailure(step: 'Firebase', error: _mismatch()),
        ),
      );

      expect(find.text("Reseller Studio couldn't start"), findsOneWidget);
      expect(find.textContaining('Close the app completely'), findsOneWidget);
    });

    testWidgets('the failure itself is named, outside a release build', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        StartupErrorScreen(
          failure: AppStartupFailure(step: 'Firebase', error: _mismatch()),
        ),
      );

      // The step and the failure together: 'Firebase' alone sends the reader
      // to the wrong half, and the failure alone does not say when it landed.
      expect(find.textContaining('Firebase'), findsOneWidget);
      expect(find.textContaining('prepare-env'), findsOneWidget);
    });
  });
}
