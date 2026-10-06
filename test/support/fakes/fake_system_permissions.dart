import 'package:reseller_studio/core/permissions/app_permission.dart';
import 'package:reseller_studio/core/permissions/system_permissions.dart';

/// The operating system, answered by the test: [blocked] is what it refuses
/// for good, and every Settings open is counted rather than performed.
class FakeSystemPermissions implements SystemPermissions {
  FakeSystemPermissions({this.blocked = const <AppPermission>{}});

  final Set<AppPermission> blocked;
  int settingsOpened = 0;

  @override
  Future<bool> isBlocked(AppPermission permission) async =>
      blocked.contains(permission);

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;

    return true;
  }
}
