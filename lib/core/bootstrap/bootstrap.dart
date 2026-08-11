import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../logging/app_logger.dart';
import '../logging/crash_reporter.dart';

/// Starts the app with every error path already funnelled into [AppLogger].
///
/// **Everything runs inside one `runZonedGuarded`**, and the two framework
/// hooks are installed before anything else can throw:
///
/// - `FlutterError.onError` — errors raised inside the widget tree;
/// - `PlatformDispatcher.instance.onError` — errors from outside it, which is
///   where an un-awaited `Future` that failed ends up;
/// - the zone's own handler — anything the other two miss.
///
/// Miss any one and a whole class of crash reaches production with nobody
/// watching. Plan §31 asks for exactly this fork: the debug console while
/// developing, Crashlytics once shipped.
///
/// Firebase initializes here rather than in `main` so that a failure to reach
/// it is *caught* — the app still starts, `CrashReporter` stays a no-op, and
/// the user sees a working (offline) app rather than a white screen. A
/// reseller standing in a store with no signal is a normal Tuesday, not an
/// error state.
Future<void> bootstrap(Widget Function() builder) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await _initializeFirebase();

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
        // reported, and killing the app would lose the user's unsaved work
        // over an error they may never have noticed.
        return true;
      };

      runApp(builder());
    },
    (Object error, StackTrace stackTrace) {
      AppLogger.error('Uncaught zone error', error: error, stackTrace: stackTrace);
    },
  );
}

/// Bring Firebase up, and attach Crashlytics if it comes up.
///
/// Swallows its own failure on purpose — see [bootstrap]. The failure is
/// logged to the console, which is the only place it can go when the thing
/// that reports failures is what failed.
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();

    final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

    // Nothing is collected in debug: a crash while developing is a crash the
    // developer is already looking at, and shipping it to the dashboard
    // buries the real ones from real users.
    await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);

    CrashReporter.attach(crashlytics);

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
