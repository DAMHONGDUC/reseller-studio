import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';

/// Everything the app asks the FCM plugin for, behind one class.
///
/// **The only file in `lib/` that names `FirebaseMessaging`.** Swapping the
/// push vendor, or stubbing it in a test, is this file and its provider — the
/// same shape as `FirebaseCrashReporter` being the only file that imports
/// Crashlytics.
///
/// Every method here answers rather than throws: push is an enhancement, and
/// a permission dialog the seller dismissed, a simulator with no APNs token
/// or a build with no Firebase must all leave the app working. The `catch`
/// still logs (hard rule 8) — a silent null here would look exactly like a
/// seller who said no.
class PushMessaging {
  const PushMessaging();

  /// iOS shows the system dialog; Android 13+ shows its own. Answers whether
  /// pushes may be delivered at all.
  Future<bool> requestPermission() async {
    try {
      final NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission();
      final bool granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      SdLogger.info(
        LogTagConstant.notification,
        'Push permission resolved',
        <String, Object>{'status': settings.authorizationStatus.name},
      );

      return granted;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notification,
        'Push permission request failed',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  /// This device's token, or null when there is none to have yet.
  ///
  /// **Null is ordinary, not a failure**: an iOS Simulator has no APNs token
  /// at all, and a device that has just denied permission has none either.
  Future<String?> token() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notification,
        'Push token unavailable',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  /// A token is rotated by the platform, not only issued once. Missing this
  /// stream is how a device quietly stops receiving pushes months later.
  Stream<String> tokenRefreshes() =>
      FirebaseMessaging.instance.onTokenRefresh.handleError((
        Object error,
        StackTrace stackTrace,
      ) {
        SdLogger.error(
          LogTagConstant.notification,
          'Push token refresh failed',
          error: error,
          stackTrace: stackTrace,
        );
      });

  /// Taps on a push while the app was running in the background.
  Stream<RemoteMessage> opened() => FirebaseMessaging.onMessageOpenedApp;

  /// The tap that started the app from cold. **Consumed once** — asking twice
  /// answers the same message and would route the seller back there on every
  /// later launch.
  Future<RemoteMessage?> initialMessage() async {
    try {
      return await FirebaseMessaging.instance.getInitialMessage();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notification,
        'Initial push message unavailable',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  /// Sign-out invalidates the token device-wide, so the entry left behind on
  /// the old account is dead rather than transferable — the second half of
  /// the guard, after the device document is deleted.
  Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notification,
        'Push token not deleted',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// What the device document records. Not a capability check — it is how a
  /// support conversation tells an iPhone entry from an Android one.
  String get platform => Platform.isIOS ? 'ios' : 'android';
}
