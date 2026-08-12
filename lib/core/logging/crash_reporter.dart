import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// The Crashlytics sink behind [AppLogger.error], and the app's only contact
/// with the Crashlytics SDK.
///
/// **It is a no-op until [attach] is called**, which `bootstrap` does after
/// `Firebase.initializeApp`. That is what lets `AppLogger` be called from a
/// pure-Dart unit test, a `domain/` service, or any code path that runs
/// before Firebase exists, without either crashing or silently initializing
/// the SDK. The default [instance] simply drops what it is given.
///
/// The indirection also keeps `firebase_crashlytics` out of every file that
/// wants to log: only this one imports it.
abstract class CrashReporter {
  /// The live reporter. Starts as a no-op; `bootstrap` swaps in the real one.
  static CrashReporter instance = const _NoopCrashReporter();

  /// Point [instance] at Crashlytics. Called once, from `bootstrap`.
  static void attach(FirebaseCrashlytics crashlytics) {
    instance = _FirebaseCrashReporter(crashlytics);
  }

  /// Reset to the no-op reporter. For tests, and for a build that has opted
  /// out of reporting.
  static void detach() {
    instance = const _NoopCrashReporter();
  }

  /// Record a non-fatal failure.
  void recordError(String reason, {Object? error, StackTrace? stackTrace});

  /// Tag every subsequent report with the signed-in user, so an issue can be
  /// traced to the account that hit it.
  ///
  /// Pass the Firebase UID and nothing else — never an email, a display name
  /// or a workspace name. The UID is already an opaque identifier; the others
  /// are personal data that would then live in a third-party dashboard.
  void setUserId(String? uid);
}

class _NoopCrashReporter implements CrashReporter {
  const _NoopCrashReporter();

  @override
  void recordError(String reason, {Object? error, StackTrace? stackTrace}) {}

  @override
  void setUserId(String? uid) {}
}

class _FirebaseCrashReporter implements CrashReporter {
  const _FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  void recordError(String reason, {Object? error, StackTrace? stackTrace}) {
    // Deliberately not awaited: reporting a failure must never make the
    // caller wait, and a failure to report is not worth a second failure.
    // `unawaited_futures` is satisfied by the explicit ignore below.
    _crashlytics
        .recordError(error ?? reason, stackTrace, reason: reason, fatal: false)
        .ignore();
  }

  @override
  void setUserId(String? uid) {
    _crashlytics.setUserIdentifier(uid ?? '').ignore();
  }
}
