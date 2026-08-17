import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:system_design/common.dart';

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
