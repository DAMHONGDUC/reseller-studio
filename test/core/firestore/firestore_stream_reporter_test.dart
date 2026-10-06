import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/error/app_failure.dart';
import 'package:reseller_studio/core/firestore/firestore_stream_reporter.dart';
import 'package:system_design/common.dart';

/// **A failure that repeats is reported once, not once per retry.**
///
/// A Firestore listener retries underneath the app — an index that is still
/// building, a device with no signal — and each attempt arrives as the same
/// error again. `SdLogger.error` reports to Crashlytics, so before this the
/// five list screens turned one missing index into dozens of identical
/// non-fatals in a single launch and a console nobody could read past.
///
/// What must not change is what the reporter *throws*: every error is still
/// mapped and rethrown, so the stream carries all of them to its watcher and
/// nothing the UI decides depends on this.
class _RecordingReporter implements SdCrashReporter {
  final List<String> reasons = <String>[];

  @override
  void recordError(String reason, {Object? error, StackTrace? stackTrace}) {
    reasons.add(reason);
  }

  @override
  void recordFatal(String reason, {Object? error, StackTrace? stackTrace}) {}

  @override
  void log(String message) {}

  @override
  void setUserId(String? uid) {}
}

FirebaseException _indexBuilding() => FirebaseException(
  plugin: 'cloud_firestore',
  code: 'failed-precondition',
  message: 'The query requires an index.',
);

void main() {
  late _RecordingReporter crashes;
  late FirestoreStreamReporter reporter;

  setUp(() {
    SdLogger.enabled = false;
    crashes = _RecordingReporter();
    SdCrashReporter.attach(crashes);
    addTearDown(SdCrashReporter.detach);

    reporter = FirestoreStreamReporter('load inventory');
  });

  /// Every call throws — that is the contract, and it is what puts the error
  /// on the stream. The test is about what was *reported*.
  AppFailure report(Object error) {
    try {
      reporter.rethrowMapped(error, StackTrace.current);
    } on AppFailure catch (failure) {
      return failure;
    }
  }

  test('the same failure is reported once however often it repeats', () {
    final AppFailure first = report(_indexBuilding());
    final AppFailure second = report(_indexBuilding());
    final AppFailure third = report(_indexBuilding());

    // Every error is still mapped and thrown on to the watcher.
    expect(<AppFailure>[first, second, third], everyElement(isA<AppFailure>()));
    expect(first.kind, AppFailureKind.invalidData);

    expect(crashes.reasons, hasLength(1));
    expect(crashes.reasons.single, contains('Failed to load inventory'));
  });

  test('a different failure is reported on its own', () {
    report(_indexBuilding());
    report(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );

    expect(crashes.reasons, hasLength(2));
  });

  test('a recovery makes the next failure news again', () {
    report(_indexBuilding());
    reporter.recovered();
    report(_indexBuilding());

    expect(crashes.reasons, hasLength(2));
  });
}
