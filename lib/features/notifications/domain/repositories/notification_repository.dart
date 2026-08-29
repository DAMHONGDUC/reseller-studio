import '../entities/app_notification.dart';

/// Reading the inbox and marking it read. **There is no `save`.**
///
/// Entries come from Cloud Functions triggers, which is what stops a client
/// fabricating one — `firestore.rules` allows an update that touches `readAt`
/// and nothing else, so the only write here is the one the reader performs.
abstract interface class NotificationRepository {
  /// Most recent first, capped. The inbox is a recent-history view, not an
  /// archive, and the unread count is folded from the same page rather than
  /// asked for separately — a second query would need a composite index to
  /// answer a number this one already carries.
  Stream<List<AppNotification>> watchRecent({int limit});

  Future<void> markRead(String id);

  /// Clear the badge in one action. Takes the ids the screen is showing
  /// rather than "everything", because that is what the reader actually saw.
  Future<void> markAllRead(List<String> ids);
}
