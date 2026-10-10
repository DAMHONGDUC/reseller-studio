import 'app_permission.dart';

/// The seller refused [permission] and the system will not ask again.
///
/// Thrown rather than returned so the pick-and-upload calls keep their
/// "null is cancelled" shape. **Not a failure**: it is logged as info where it
/// is raised, and the screen answers it with `PermissionSettingsSheet`.
class PermissionBlocked implements Exception {
  const PermissionBlocked(this.permission);

  final AppPermission permission;

  @override
  String toString() => 'PermissionBlocked(${permission.name})';
}
