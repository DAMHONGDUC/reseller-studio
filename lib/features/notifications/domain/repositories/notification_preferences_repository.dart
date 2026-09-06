import '../entities/notification_preferences.dart';
import '../enums/notification_type.dart';

/// Reading and writing which reminders one person wants.
///
/// **It hangs off the person, not the business** (`docs/DATA_MODEL.md`): two
/// people sharing a shop do not want the same reminders, and a preference
/// stored on the workspace would let one of them silence the other.
abstract interface class NotificationPreferencesRepository {
  Stream<NotificationPreferences> watch();

  Future<void> setEnabled(NotificationType type, {required bool enabled});
}
