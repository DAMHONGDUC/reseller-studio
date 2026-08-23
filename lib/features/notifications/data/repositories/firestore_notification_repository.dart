import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/user_collections.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../dtos/notification_dto.dart';

/// The inbox, in Firestore, under the reader's own user document.
///
/// **Under `users/{uid}`, not under the workspace** — hard rule 14 is about
/// business records, and a notification is addressed to a person. Two members
/// of one business each get their own row, each marks their own read, and
/// neither can see the other's; a shared document with a `readBy` array would
/// mean every reader writing to a document every other reader is watching.
class FirestoreNotificationRepository implements NotificationRepository {
  const FirestoreNotificationRepository(this._collections);

  final UserCollections _collections;

  @override
  Stream<List<AppNotification>> watchRecent({int limit = 50}) =>
      FirestoreStream.collection(
        _collections.notifications
            .orderBy('createdAt', descending: true)
            .limit(limit),
        NotificationDto.toEntity,
        operation: 'load notifications',
      );

  @override
  Future<void> markRead(String id) =>
      FailureMapper.guard('mark notification read', () async {
        await _collections.notifications.doc(id).update(<String, Object?>{
          'readAt': FieldValue.serverTimestamp(),
        });

        SdLogger.action(
          LogTagConstant.notification,
          'Notification read',
          <String, Object>{'notificationId': id},
        );
      });

  /// **One batch, not a loop.** Twenty unread rows is twenty round trips
  /// otherwise, and a badge that clears a row at a time is one the seller
  /// watches count down.
  @override
  Future<void> markAllRead(List<String> ids) =>
      FailureMapper.guard('mark notifications read', () async {
        if (ids.isEmpty) return;

        final WriteBatch batch = _collections.firestore.batch();

        for (final String id in ids) {
          batch.update(_collections.notifications.doc(id), <String, Object?>{
            'readAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();

        SdLogger.action(
          LogTagConstant.notification,
          'Notifications read',
          <String, Object>{'count': ids.length},
        );
      });
}
