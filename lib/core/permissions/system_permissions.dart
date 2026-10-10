import 'package:flutter/services.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import 'app_permission.dart';

/// The Dart half of `ios/Runner/SystemPermissionsPlugin.swift` and of the
/// channel in `MainActivity.kt`.
///
/// Three questions only: is a permission allowed, will the system still ask
/// for it, and open this app's page in Settings. The plugins (`image_picker`, `mobile_scanner`,
/// FCM) still do the asking — this is what comes after they were told no.
///
/// Every method answers rather than throws: a channel that fails must leave
/// the seller where they were, not on an error screen about a permission.
class SystemPermissions {
  const SystemPermissions();

  static const MethodChannel _channel = MethodChannel(
    'app.dd.reseller.studio/system_permissions',
  );

  /// Whether [permission] is refused and the system will not ask again.
  ///
  /// **Ask only after a refusal.** Android cannot tell "never asked" from
  /// "refused for good", so before the first request this reads as blocked.
  Future<bool> isBlocked(AppPermission permission) async {
    try {
      final bool blocked =
          await _channel.invokeMethod<bool>('isBlocked', <String, String>{
            'permission': permission.channelName,
          }) ??
          false;

      SdLogger.info(
        LogTagConstant.permission,
        'Permission state read',
        <String, Object>{'permission': permission.name, 'blocked': blocked},
      );

      return blocked;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.permission,
        'Permission state unavailable',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'permission': permission.name},
      );

      return false;
    }
  }

  /// Whether [permission] is allowed right now. **Never shows a dialog**, so
  /// it is safe to call on every resume.
  Future<bool> isGranted(AppPermission permission) async {
    try {
      final bool granted =
          await _channel.invokeMethod<bool>('isGranted', <String, String>{
            'permission': permission.channelName,
          }) ??
          false;

      SdLogger.info(
        LogTagConstant.permission,
        'Permission grant read',
        <String, Object>{'permission': permission.name, 'granted': granted},
      );

      return granted;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.permission,
        'Permission grant unavailable',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'permission': permission.name},
      );

      return false;
    }
  }

  /// Opens this app's page in the system Settings, answering whether it did.
  Future<bool> openAppSettings() async {
    try {
      final bool opened =
          await _channel.invokeMethod<bool>('openAppSettings') ?? false;

      SdLogger.info(
        LogTagConstant.permission,
        'App settings opened',
        <String, Object>{'opened': opened},
      );

      return opened;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.permission,
        'App settings did not open',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }
}
