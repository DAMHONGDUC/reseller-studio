import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../providers.dart';

/// Marking the inbox read. **The only write the app performs on it** — the
/// rows themselves come from Cloud Functions, and `firestore.rules` allows an
/// update that touches `readAt` and nothing else.
class NotificationController extends Notifier<bool> {
  /// True while a write is in flight, so the screen can disable its action.
  @override
  bool build() => false;

  /// Reading one is a side effect of opening it, so this never blocks the
  /// navigation that follows: a failed write leaves the row unread, which is
  /// recoverable, while a swallowed tap is not.
  Future<void> markRead(AppNotification notification) async {
    if (!notification.isUnread) return;

    await _write('mark read', <String, Object>{'notificationId': notification.id},
        (NotificationRepository repository) => repository.markRead(notification.id));
  }

  Future<void> markAllRead(List<AppNotification> notifications) async {
    final List<String> unread = <String>[
      for (final AppNotification notification in notifications)
        if (notification.isUnread) notification.id,
    ];

    if (unread.isEmpty) return;

    await _write('mark all read', <String, Object>{'count': unread.length},
        (NotificationRepository repository) => repository.markAllRead(unread));
  }

  Future<void> _write(
    String what,
    Map<String, Object> data,
    Future<void> Function(NotificationRepository repository) write,
  ) async {
    final NotificationRepository? repository = ref.read(
      notificationRepositoryProvider,
    );

    if (repository == null) return;

    state = true;
    SdLogger.action(LogTagConstant.notification, 'Notification $what', data);

    try {
      await write(repository);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notification,
        'Failed to $what',
        error: error,
        stackTrace: stackTrace,
        data: data,
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}
