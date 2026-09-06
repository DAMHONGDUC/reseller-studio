import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/user_collections.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/enums/notification_type.dart';
import '../../domain/repositories/notification_preferences_repository.dart';

/// `users/{uid}.notificationPrefs` — a map of type name to whether it is on.
///
/// **Merged rather than replaced**, so a build that has not heard of a type
/// cannot erase a preference a newer one wrote, and so the write works on a
/// user document that does not exist yet.
class FirestoreNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  const FirestoreNotificationPreferencesRepository(this._collections);

  static const String _field = 'notificationPrefs';

  final UserCollections _collections;

  @override
  Stream<NotificationPreferences> watch() => _collections.user
      .snapshots()
      .map(
        (DocumentSnapshot<Map<String, Object?>> snapshot) =>
            _read(snapshot.data()?[_field]),
      );

  @override
  Future<void> setEnabled(NotificationType type, {required bool enabled}) =>
      FailureMapper.guard('save notification preference', () async {
        await _collections.user.set(<String, Object?>{
          _field: <String, Object?>{type.name: enabled},
        }, SetOptions(mergeFields: <String>['$_field.${type.name}']));

        SdLogger.action(
          LogTagConstant.notification,
          'Set notification preference',
          <String, Object>{'type': type.name, 'enabled': enabled},
        );
      });

  /// **An unknown key is dropped, never mapped to a neighbour** — a document
  /// written by a newer build must not silence whichever type happens to sit
  /// next to it in the list (`docs/rules/BACKEND.md`).
  static NotificationPreferences _read(Object? stored) {
    if (stored is! Map<String, Object?>) {
      return const NotificationPreferences.everything();
    }

    final Set<NotificationType> muted = <NotificationType>{};

    for (final MapEntry<String, Object?> entry in stored.entries) {
      if (entry.value != false) continue;

      for (final NotificationType type in NotificationType.values) {
        if (type.name == entry.key) muted.add(type);
      }
    }

    return NotificationPreferences(muted);
  }
}
