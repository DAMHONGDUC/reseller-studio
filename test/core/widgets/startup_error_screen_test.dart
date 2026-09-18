import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/bootstrap/app_startup_failure.dart';
import 'package:reseller_studio/core/widgets/startup_error_screen.dart';

import '../../support/pump_app.dart';

/// A duplicate app is the failure this screen exists for: Firebase was brought
/// up twice, so the instance the app is holding is not the one this build
/// configured.
FirebaseException _duplicateApp() => FirebaseException(
  plugin: 'core',
  code: 'duplicate-app',
  message: 'A Firebase App named "[DEFAULT]" already exists',
);

void main() {
  group('StartupFailurePolicy', () {
    test('a duplicate app stops the launch', () {
      expect(StartupFailurePolicy.isFatal(_duplicateApp()), isTrue);
    });

    test('a Firebase that could not be reached does not', () {
      // The seller is standing in a store with no signal. They get the app.
      final FirebaseException offline = FirebaseException(
        plugin: 'core',
        code: 'unavailable',
      );

      expect(StartupFailurePolicy.isFatal(offline), isFalse);
      expect(StartupFailurePolicy.isFatal(StateError('billing')), isFalse);
    });
  });

  group('StartupErrorScreen', () {
    testWidgets('it says what happened and what to do about it', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        StartupErrorScreen(
          failure: AppStartupFailure(step: 'Firebase', error: _duplicateApp()),
        ),
      );

      expect(find.text("Reseller Studio couldn't start"), findsOneWidget);
      expect(
        find.textContaining('Close the app completely'),
        findsOneWidget,
      );
    });

    testWidgets('the failure itself is named, outside a release build', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        StartupErrorScreen(
          failure: AppStartupFailure(step: 'Firebase', error: _duplicateApp()),
        ),
      );

      // The step and the code together: 'Firebase' alone sends the reader to
      // the wrong half, and the code alone does not say when it was thrown.
      expect(find.textContaining('Firebase'), findsOneWidget);
      expect(find.textContaining('duplicate-app'), findsOneWidget);
    });
  });
}
