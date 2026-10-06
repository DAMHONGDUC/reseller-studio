import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../permissions/system_permissions.dart';

/// The permissions channel, behind a provider so a test can answer for the
/// operating system.
final Provider<SystemPermissions> systemPermissionsProvider =
    Provider<SystemPermissions>((Ref ref) => const SystemPermissions());
