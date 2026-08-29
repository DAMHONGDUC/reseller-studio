import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../features/notifications/providers.dart';
import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';
import '../router/app_routes.dart';
import '../router/navigation_utils.dart';

/// The way into the inbox, and the only place unread is visible at a glance.
///
/// In `core/widgets/` rather than in the notifications feature: it is drawn by
/// Home, which may not reach into another feature's `presentation/`. Reading
/// that feature's `providers.dart` is the allowed direction.
///
/// **A dot, not a number.** The count is what the inbox is for; on the bell it
/// would be a figure the seller has to interpret before they can decide
/// whether to look. The tooltip carries it for anyone who wants it, and for a
/// screen reader.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(unreadNotificationCountProvider);

    return SdAppBarActionButtonV3(
      icon: AppIconConstant.notifications,
      tooltip: unread == 0
          ? context.l10n.notificationsTitle
          : context.l10n.notificationsUnread(unread),
      // The dot's size and where it sits on the glyph's corner belong to the
      // button — this widget only knows whether there is anything to mark.
      dotColor: unread > 0 ? context.sdTheme3.danger : null,
      onPressed: () {
        // A signed-out visitor has an empty inbox by definition — the rows
        // live under their user document, and there is not one.
        if (!NavigationUtils.requireSignIn(context, ref)) return;

        context.push(AppRoutes.notifications);
      },
    );
  }
}
