import '../enums/notification_type.dart';

/// Which reminders one person still wants.
///
/// **Only the mutes are stored**, the same shape `Workspace.marketplaceFeeRates`
/// uses and for the same reason: a map filled in with every type would make
/// "this person chose to keep it" indistinguishable from "nobody has said",
/// and a type added in a later build would arrive switched off for everybody
/// who upgraded into it.
///
/// The backend reads the same document and applies the same default —
/// `functions/src/notifications/notify.ts`.
class NotificationPreferences {
  const NotificationPreferences(this.muted);

  const NotificationPreferences.everything()
    : muted = const <NotificationType>{};

  /// The types this person turned off. Absent means on.
  final Set<NotificationType> muted;

  bool isEnabled(NotificationType type) => !muted.contains(type);

  /// How many reminders are currently silenced, for the settings row that
  /// summarises this screen without opening it.
  int get mutedCount => muted.length;
}
