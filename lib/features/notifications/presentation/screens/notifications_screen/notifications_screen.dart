import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/enums/notification_type.dart';
import '../../../providers.dart';

part 'notifications_screen_row.dart';

/// The inbox (plan §22) — what the app told you while you were not looking.
///
/// **The push and this screen are the same notification, not two features.**
/// A push is best-effort: permission may be off, the phone may be in a field
/// with no signal, the seller may have swiped it away half-read. The Firestore
/// row is the durable half, and it is what this screen reads — which is why a
/// seller who never grants permission still has a working notification centre.
///
/// **Read-only apart from the tick.** Rows are written by Cloud Functions
/// (`firestore.rules` refuses a client create), and the only write the app
/// makes is `readAt`.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> notifications,
  ) async {
    try {
      await ref
          .read(notificationControllerProvider.notifier)
          .markAllRead(notifications);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AppNotification> notifications =
        ref.watch(notificationsProvider).value ?? const <AppNotification>[];
    final int unread = ref.watch(unreadNotificationCountProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: context.l10n.notificationsTitle,
        actions: <Widget>[
          // Only while there is something to clear. A control that does
          // nothing is worse than no control.
          if (unread > 0)
            SdAppBarActionButtonV3(
              icon: AppIconConstant.markEmailRead,
              tooltip: context.l10n.notificationsMarkAllRead,
              onPressed: () => _markAllRead(context, ref, notifications),
            ),
          SizedBox(width: SdSpacingConstant.w8),
        ],
      ),
      body: notifications.isEmpty
          ? SdEmptyStateV3(
              icon: AppIconConstant.notifications,
              title: context.l10n.notificationsEmptyTitle,
              message: context.l10n.notificationsEmptyMessage,
            )
          : ListView.separated(
              padding: SdContentPaddingV3.fullBleed(context),
              itemCount: notifications.length,
              separatorBuilder: (BuildContext context, int _) =>
                  const SdDividerV3(),
              itemBuilder: (BuildContext context, int index) =>
                  _NotificationRow(notification: notifications[index]),
            ),
    );
  }
}
