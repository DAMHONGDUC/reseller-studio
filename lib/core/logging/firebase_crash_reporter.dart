import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:system_design/common.dart';

import 'crashlytics_test_exception.dart';

/// The Crashlytics half of [SdCrashReporter], and the app's only contact with
/// the Crashlytics SDK.
///
/// The contract and the no-op live in `system_design` so any app can log
/// without owning a vendor; this file is what makes the reports actually go
/// somewhere, and `AppBootstrap` hands it over with `SdCrashReporter.attach`
/// once Firebase is up. Swapping vendors is this file and that one line.
final class FirebaseCrashReporter implements SdCrashReporter {
  const FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  /// The reporter `AppBootstrap` attached, or null in a build with no Firebase.
  static FirebaseCrashReporter? get attached {
    final SdCrashReporter reporter = SdCrashReporter.instance;

    return reporter is FirebaseCrashReporter ? reporter : null;
  }

  /// Records one non-fatal test report and uploads it now.
  ///
  /// Debug keeps collection off, so the report is stored on the device and
  /// [FirebaseCrashlytics.sendUnsentReports] pushes it; in release it goes on
  /// its own and that call is a no-op. The stored backlog is deleted first:
  /// it is every debug-session error the bootstrap deliberately keeps out of
  /// the dashboard, and the test must not be what lets it in.
  Future<void> sendTestReport() async {
    await _crashlytics.deleteUnsentReports();
    await _crashlytics.recordError(
      const CrashlyticsTestException(),
      StackTrace.current,
      reason: 'Crashlytics test report',
    );
    await _crashlytics.sendUnsentReports();
  }

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
  void recordFatal(String reason, {Object? error, StackTrace? stackTrace}) {
    _crashlytics
        .recordError(error ?? reason, stackTrace, reason: reason, fatal: true)
        .ignore();
  }

  @override
  void log(String message) {
    _crashlytics.log(message).ignore();
  }

  @override
  void setUserId(String? uid) {
    _crashlytics.setUserIdentifier(uid ?? '').ignore();
  }
}
