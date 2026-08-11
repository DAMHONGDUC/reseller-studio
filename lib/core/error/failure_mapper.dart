import 'dart:async';
import 'dart:io';

// `FirebaseException` and `FirebaseAuthException` both arrive through this
// one import — firebase_auth re-exports firebase_core's base type, and
// importing cloud_firestore/firebase_core as well is flagged as unnecessary.
import 'package:firebase_auth/firebase_auth.dart';

import '../logging/app_logger.dart';
import 'app_failure.dart';

/// Turns anything thrown by the Firebase SDKs into an [AppFailure].
///
/// **Every `data/` repository method funnels through [guard].** That is what
/// makes the boundary real: `domain/` and `presentation/` can then be written
/// as if `FirebaseException` does not exist, because past this line it does
/// not.
///
/// [guard] also logs. A caught error is invisible by construction — the code
/// that swallowed it holds the only copy of what actually happened — so the
/// log happens here, once, rather than at forty call sites that each might
/// forget.
abstract final class FailureMapper {
  /// Run [action], returning its value, and convert any throw into an
  /// [AppFailure].
  ///
  /// [operation] describes what was being attempted, in the imperative:
  /// `'load inventory'`, `'create listing'`. It becomes the log line and the
  /// Crashlytics issue title, so it must be specific enough to find later and
  /// must never contain user data.
  static Future<T> guard<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on AppFailure {
      // Already mapped by an inner guard — logged there, and re-wrapping it
      // would bury the specific kind under `unknown`.
      rethrow;
    } catch (error, stackTrace) {
      final AppFailure failure = map(error);

      AppLogger.error(
        'Failed to $operation',
        error: error,
        stackTrace: stackTrace,
      );

      throw failure;
    }
  }

  /// Classify a caught object. Public so a stream's `handleError` can use it
  /// without going through [guard].
  ///
  /// Catches by type rather than `on Exception`: `Error` subtypes — a
  /// `TypeError` from a document whose field came back the wrong shape, a
  /// `StateError` — are not `Exception`s, so `on Exception` would let exactly
  /// the unexpected failures through unmapped and unlogged.
  static AppFailure map(Object error) {
    if (error is AppFailure) return error;

    if (error is SocketException || error is TimeoutException) {
      return AppFailure.offline(technicalMessage: error.toString());
    }

    if (error is FirebaseAuthException) {
      return AppFailure(
        switch (error.code) {
          'network-request-failed' => AppFailureKind.offline,
          'user-not-found' ||
          'wrong-password' ||
          'invalid-credential' ||
          'user-disabled' ||
          'requires-recent-login' => AppFailureKind.unauthenticated,
          'invalid-email' || 'weak-password' => AppFailureKind.invalidData,
          _ => AppFailureKind.unknown,
        },
        technicalMessage: '${error.code}: ${error.message}',
        cause: error,
      );
    }

    if (error is FirebaseException) {
      return AppFailure(
        switch (error.code) {
          // Firestore reports both of these when the device is offline and
          // the operation cannot be served from cache.
          'unavailable' || 'deadline-exceeded' => AppFailureKind.offline,
          'permission-denied' => AppFailureKind.permissionDenied,
          'unauthenticated' => AppFailureKind.unauthenticated,
          'not-found' => AppFailureKind.notFound,
          'invalid-argument' || 'failed-precondition' =>
            AppFailureKind.invalidData,
          'resource-exhausted' => AppFailureKind.limitReached,
          _ => AppFailureKind.unknown,
        },
        technicalMessage: '${error.plugin}/${error.code}: ${error.message}',
        cause: error,
      );
    }

    return AppFailure.unknown(
      technicalMessage: error.toString(),
      cause: error,
    );
  }
}
