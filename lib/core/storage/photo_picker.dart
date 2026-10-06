import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import '../permissions/app_permission.dart';
import '../permissions/permission_blocked.dart';
import '../permissions/system_permissions.dart';

/// The one call into `image_picker`, and what a refused permission turns into.
///
/// - **Null** when the seller cancelled, or refused in a dialog the system
///   will show again — both are a decision, not a failure.
/// - [PermissionBlocked] when the system will not ask again, so the screen
///   can offer the way to Settings instead of a generic error.
final class PhotoPicker {
  static const String _cameraDenied = 'camera_access_denied';
  static const String _photosDenied = 'photo_access_denied';

  static Future<XFile?> pick({
    required SystemPermissions permissions,
    required bool fromCamera,
    required double maxWidth,
    required int quality,
  }) async {
    try {
      return await ImagePicker().pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: maxWidth,
        imageQuality: quality,
      );
    } on PlatformException catch (error) {
      final AppPermission? permission = switch (error.code) {
        _cameraDenied => AppPermission.camera,
        _photosDenied => AppPermission.photos,
        _ => null,
      };

      // Anything but a refusal is a real failure, logged by the caller.
      if (permission == null) rethrow;

      final bool blocked = await permissions.isBlocked(permission);

      SdLogger.info(
        LogTagConstant.permission,
        'Photo permission refused',
        <String, Object>{'permission': permission.name, 'blocked': blocked},
      );

      if (blocked) throw PermissionBlocked(permission);

      return null;
    }
  }
}
