import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import '../error/app_failure.dart';
import '../error/failure_mapper.dart';

/// One stream's error reporting, so a failure that repeats is reported once.
///
/// A Firestore listener retries underneath the app: an index that is still
/// building, a revoked permission, a device with no signal — each arrives as
/// the same error again every few seconds, for as long as it lasts.
/// `SdLogger.error` reports to Crashlytics, so logging every one turns a
/// single broken query into hundreds of identical non-fatals and a console
/// nobody can read past.
///
/// **The first one is always reported in full, and so is a different one.**
/// What is dropped is only the repeat of a failure already on the record; the
/// stream itself still carries every error to whoever is watching it, so
/// nothing the UI decides changes.
class FirestoreStreamReporter {
  FirestoreStreamReporter(this._operation);

  final String _operation;

  /// The failure already reported, or null while the stream is healthy.
  String? _reported;

  /// A snapshot arrived, so the next failure is news again.
  void recovered() => _reported = null;

  Never rethrowMapped(Object error, StackTrace stackTrace) {
    final AppFailure failure = FailureMapper.map(error);
    final String signature = '${failure.kind}/${failure.technicalMessage}';

    if (_reported == signature) {
      // Debug rather than error: still visible while developing, and it does
      // not reach Crashlytics a second time.
      SdLogger.debug(
        LogTagConstant.firestore,
        'Failed to $_operation, still',
        <String, String>{'kind': failure.kind.name},
      );

      throw failure;
    }
    _reported = signature;

    SdLogger.error(
      LogTagConstant.firestore,
      'Failed to $_operation',
      error: error,
      stackTrace: stackTrace,
    );

    throw failure;
  }
}
