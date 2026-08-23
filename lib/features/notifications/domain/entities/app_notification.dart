import '../enums/notification_type.dart';

/// One line of the inbox (plan §22).
///
/// **Written only by Cloud Functions**, the same reasoning as the audit log:
/// a notification a client could create is one that could claim any business
/// made any sale. The repository has no `save`, and `firestore.rules` refuses
/// a client create outright.
///
/// **The push text is not on this entity, on purpose.** The stored document
/// carries an English title and body because that is what a push needs and a
/// function cannot know the reader's locale; the inbox renders its own words
/// from [type] and [count] through ARB (hard rule 7). Mapping the stored
/// strings in here is what would make the inbox permanently English.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.workspaceId,
    required this.route,
    required this.createdAt,
    this.entityId,
    this.count,
    this.readAt,
  });

  final String id;
  final NotificationType type;

  /// Which business it is about. A seller in three of them needs to know
  /// which one is asking, and tapping switches to it.
  final String workspaceId;

  /// Where tapping goes — an in-app route, never a URL.
  final String route;

  final DateTime createdAt;

  /// The record it names, or null for a digest.
  final String? entityId;

  /// How many rows a digest stands for. Null when it is about one record —
  /// **not zero**, which would read as a digest of nothing (hard rule 5).
  final int? count;

  /// When the reader marked it read. Null is unread.
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}
