import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../analytics/app_analytics.dart';
import '../config/app_env.dart';
import '../logging/app_logger.dart';
import '../logging/crash_reporter.dart';

/// Everything that happens before `runApp`, so `main.dart` stays a list of
/// what happens rather than how.
///
/// **Every error path is already funnelled into [AppLogger]**, and the two
/// framework hooks are installed before anything else can throw:
///
/// - `FlutterError.onError` — errors raised inside the widget tree;
/// - `PlatformDispatcher.instance.onError` — errors from outside it, which is
///   where an un-awaited `Future` that failed ends up;
/// - the zone's own handler — anything the other two miss.
///
/// Miss any one and a whole class of crash reaches production with nobody
/// watching. Plan §31 asks for exactly this fork: the debug console while
/// developing, Crashlytics once shipped.
final class AppBootstrap {
  /// Starts the app inside a guarded zone.
  ///
  /// **Each step guards itself; there is no `try` around the whole method.**
  /// The concerns are independent, and one `try` around all of them lets the
  /// first failure skip everything after it — including the crash reporting
  /// that would have named it.
  ///
  /// **Firebase goes first** so Crashlytics is attached before anything else
  /// can fail. Everything here runs before `runApp`, where an unhandled throw
  /// does not show an error screen — it stops the app from starting at all —
  /// so every step needs a fallback that leaves the app usable.
  static Future<void> init(Widget Function() builder) async {
    await runZonedGuarded<Future<void>>(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await _initializeFirebase();

        await _initializeGoogleSignIn();

        await _goEdgeToEdge();

        _logEnvironment();

        _installErrorHooks();

        runApp(builder());
      },
      (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'Uncaught zone error',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  /// Let the app draw under the system bars.
  ///
  /// Android only in effect — iOS is already edge to edge. Without it the
  /// floating glass tab bar has an opaque system strip under it instead of the
  /// content it is supposed to refract, and `extendBody` buys nothing.
  ///
  /// The *style* of those bars is not set here: that is
  /// `AppTheme.statusBarStyle`, read through the theme, because a
  /// `SystemChrome` call made once at startup cannot follow a device switching
  /// between light and dark.
  static Future<void> _goEdgeToEdge() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      AppLogger.info('Edge-to-edge enabled');
    } catch (error, stackTrace) {
      // Cosmetic, so it must never stop the app starting — but a silent
      // failure here is a layout bug nobody can trace back (hard rule 8).
      AppLogger.error(
        'Failed to enable edge-to-edge',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Bring Firebase up, and attach Crashlytics if it comes up.
  ///
  /// Swallows its own failure on purpose: the app still starts,
  /// [CrashReporter] stays a no-op, and the user sees a working (offline) app
  /// rather than a white screen. A reseller standing in a store with no signal
  /// is a normal Tuesday, not an error state.
  static Future<void> _initializeFirebase() async {
    if (!AppEnv.hasFirebaseConfig) {
      // Distinct from a thrown init failure on purpose: "no project
      // configured" and "configured but unreachable" look identical from the
      // exception and want completely different responses.
      AppLogger.warning(
        'No Firebase config in this build — running without a backend. '
        'Fill the FIREBASE_* keys in env/${AppEnv.flavor.name}.json once '
        '`flutterfire configure` has been run.',
      );

      return;
    }

    try {
      await Firebase.initializeApp();

      final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

      // Nothing is collected in debug: a crash while developing is one the
      // developer is already looking at, and shipping it to the dashboard
      // buries the real ones from real users.
      await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);

      CrashReporter.attach(crashlytics);
      AppAnalytics.attach(FirebaseAnalytics.instance);

      AppLogger.info('Firebase initialized');
    } catch (error, stackTrace) {
      // Cannot use AppLogger.error's Crashlytics half — that is what just
      // failed. The console line is the whole report.
      AppLogger.warning(
        'Firebase failed to initialize — running without backend',
        <String, String>{'error': error.toString()},
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Configure Google Sign-In before any button can call it.
  ///
  /// `google_sign_in` 7 requires `initialize` to have completed before
  /// `authenticate`, and sign-in is one of only two ways into this app
  /// (`CLAUDE.md` hard rule 1) — so doing it lazily on the first tap would put
  /// a round trip in front of the seller at the worst moment.
  ///
  /// Guards itself like every other step: a failure here leaves the Google
  /// button broken and the Apple one working, which is a far better outcome
  /// than an app that does not start.
  static Future<void> _initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize(
        // Empty means "read it from the platform config file"
        // (`GoogleService-Info.plist` / `google-services.json`), which is what
        // `flutterfire configure` writes. The env keys exist to override that
        // for a build whose bundle id differs from the Firebase app's.
        clientId: AppEnv.googleSignInIosClientId.isEmpty
            ? null
            : AppEnv.googleSignInIosClientId,
        serverClientId: AppEnv.googleSignInServerClientId.isEmpty
            ? null
            : AppEnv.googleSignInServerClientId,
      );

      AppLogger.info('Google Sign-In initialized');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Google Sign-In failed to initialize',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log which configuration this build is running on.
  ///
  /// **Names keys, never values** — hard rule 9.
  static void _logEnvironment() {
    AppLogger.info('Environment', <String, String>{'config': AppEnv.summary});

    if (kReleaseMode && AppEnv.missingReleaseKeys.isNotEmpty) {
      // A release build with no Firebase config will fail on every screen.
      // Say so once, naming every missing key at once rather than one per
      // rebuild.
      AppLogger.warning(
        'Release build is missing required env keys',
        <String, String>{'keys': AppEnv.missingReleaseKeys.join(', ')},
      );
    }
  }

  /// Route the framework's two error channels into [AppLogger].
  static void _installErrorHooks() {
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppLogger.error(
        'Uncaught platform error',
        error: error,
        stackTrace: stack,
      );

      // True means "handled" — the process stays alive. It is already
      // reported, and killing the app would lose the user's unsaved work over
      // an error they may never have noticed.
      return true;
    };
  }
}
