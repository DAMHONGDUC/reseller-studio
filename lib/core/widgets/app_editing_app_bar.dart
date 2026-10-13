import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';

/// The app bar a detail screen wears while one of its sections is open.
///
/// **It says a draft is waiting** (`docs/rules/SCREENS.md`): the title names
/// the open section, the record's title drops to the subtitle, the back arrow
/// becomes a close that cancels, and the actions control is gone.
///
/// The screen still owns the system back — it wraps itself in a `PopScope`
/// that cancels too, since this bar cannot see the route.
class AppEditingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppEditingAppBar({
    required this.section,
    required this.recordTitle,
    required this.onCancel,
    super.key,
  });

  /// The open section's own heading — "Pricing", "Shipping".
  final String section;

  final String recordTitle;

  /// Null while the save is in flight, matching the section's own Cancel.
  final VoidCallback? onCancel;

  @override
  Size get preferredSize =>
      Size.fromHeight(SdAppBarV3.toolbarHeight + SdAppBarV3.subtitleHeight);

  @override
  Widget build(BuildContext context) => SdAppBarV3(
    title: context.l10n.editingSectionTitle(section),
    subtitle: recordTitle,
    automaticallyImplyLeading: false,
    leading: Center(
      child: SdAppBarActionButtonV3(
        icon: AppIconConstant.close,
        tooltip: context.l10n.actionCancel,
        onPressed: onCancel,
      ),
    ),
  );
}
