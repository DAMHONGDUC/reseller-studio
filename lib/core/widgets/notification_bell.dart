import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../features/notifications/providers.dart';
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

  /// How far the dot is pulled past the glyph's corner. Intrinsic to this
  /// widget — what it *is*, not configuration about it. The diameter is
  /// `SdSpacingConstant.w8`, read at build time because it scales.
  static double get dotInset => -SdSpacingConstant.w2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      onPressed: () {
        // A signed-out visitor has an empty inbox by definition — the rows
        // live under their user document, and there is not one.
        if (!NavigationUtils.requireSignIn(context, ref)) return;

        context.push(AppRoutes.notifications);
      },
      tooltip: unread == 0
          ? context.l10n.notificationsTitle
          : context.l10n.notificationsUnread(unread),
      icon: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Icon(Symbols.notifications_rounded),
          if (unread > 0)
            Positioned(
              top: dotInset,
              right: dotInset,
              child: Container(
                width: SdSpacingConstant.w8,
                height: SdSpacingConstant.w8,
                decoration: BoxDecoration(
                  color: context.sdTheme3.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
