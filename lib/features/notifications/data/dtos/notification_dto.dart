import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/enums/notification_type.dart';

/// How an [AppNotification] is stored. Read only — see the repository.
///
/// `title` and `body` are in the document and are deliberately **not**
/// mapped: they are the English text the push carried, and reading them into
/// the app would make the inbox permanently English whatever the ARB files
/// say (hard rule 7). The row is rendered from `type` and `count`.
final class NotificationDto {
  static AppNotification toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};

    return AppNotification(
      id: doc.id,
      type:
          FirestoreMapper.enumOrNull(NotificationType.values, data['type']) ??
          NotificationType.unknown,
      workspaceId: FirestoreMapper.stringOrNull(data['workspaceId']) ?? '',
      route: FirestoreMapper.stringOrNull(data['route']) ?? '',
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      entityId: FirestoreMapper.stringOrNull(data['entityId']),
      count: FirestoreMapper.intOrNull(data['count']),
      readAt: FirestoreMapper.dateOrNull(data['readAt']),
    );
  }
}
