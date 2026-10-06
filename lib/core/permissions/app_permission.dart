import 'package:flutter/widgets.dart';

import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';

/// The operating-system permissions the app asks for.
///
/// [channelName] is what `system_permissions` sends to the native side, so a
/// rename here cannot quietly stop matching the Swift and Kotlin switches.
enum AppPermission {
  camera('camera'),
  photos('photos'),
  notifications('notifications');

  const AppPermission(this.channelName);

  final String channelName;
}

/// How a refused permission reads, kept on the enum so a new case breaks
/// these switches rather than falling through to the camera's copy.
extension AppPermissionDisplay on AppPermission {
  IconData get blockedIcon => switch (this) {
    AppPermission.camera => AppIconConstant.noPhotography,
    AppPermission.photos => AppIconConstant.photoLibrary,
    AppPermission.notifications => AppIconConstant.notificationsOff,
  };

  String blockedTitle(BuildContext context) => switch (this) {
    AppPermission.camera => context.l10n.permissionCameraTitle,
    AppPermission.photos => context.l10n.permissionPhotosTitle,
    AppPermission.notifications => context.l10n.permissionNotificationsTitle,
  };

  String blockedMessage(BuildContext context) => switch (this) {
    AppPermission.camera => context.l10n.permissionCameraMessage,
    AppPermission.photos => context.l10n.permissionPhotosMessage,
    AppPermission.notifications => context.l10n.permissionNotificationsMessage,
  };
}
