import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../constants/log_tag_constant.dart';
import '../extensions/context_extensions.dart';
import '../permissions/app_permission.dart';
import '../permissions/system_permissions.dart';
import '../providers/system_permissions_provider.dart';

/// What a seller sees once the system will no longer ask for a permission.
///
/// Without it a refused camera reads as "Something went wrong" and the seller
/// has no way back but to find the app's page in Settings themselves. The
/// sheet names what is off, why the app wants it, and opens that page.
///
/// Shown only when the system has stopped asking — a refusal it will still
/// ask about again is the seller changing their mind, not a dead end.
class PermissionSettingsSheet extends ConsumerWidget {
  const PermissionSettingsSheet._({required this.permission});

  final AppPermission permission;

  static Future<void> show(
    BuildContext context, {
    required AppPermission permission,
  }) {
    SdLogger.action(
      LogTagConstant.permission,
      'Permission settings sheet shown',
      <String, Object>{'permission': permission.name},
    );

    return showSdBottomSheetV3<void>(
      context: context,
      builder: (BuildContext _) =>
          PermissionSettingsSheet._(permission: permission),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdBottomSheetV3(
    title: permission.blockedTitle(context),
    closeTooltip: context.l10n.commonClose,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SdIconTileV3(
              icon: permission.blockedIcon,
              tint: context.sdTheme3.warning,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Text(
                permission.blockedMessage(context),
                style: context.textTheme3.bodyMedium!.copyWith(
                  color: context.sdTheme3.textSecondary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h20),
        SdButtonV3(
          variant: SdButtonVariantV3.primary,
          label: context.l10n.permissionOpenSettings,
          expand: true,
          onPressed: () {
            final SystemPermissions permissions = ref.read(
              systemPermissionsProvider,
            );

            SdLogger.action(
              LogTagConstant.permission,
              'Open settings tapped',
              <String, Object>{'permission': permission.name},
            );
            // Pop first, so the seller comes back to their screen, not here.
            Navigator.of(context).pop();
            unawaited(permissions.openAppSettings());
          },
        ),
        SizedBox(height: SdSpacingConstant.h8),
        SdButtonV3(
          variant: SdButtonVariantV3.text,
          label: context.l10n.permissionNotNow,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
