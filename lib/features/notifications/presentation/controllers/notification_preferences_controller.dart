import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/enums/notification_type.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../../providers.dart';

/// Turning one kind of reminder on or off.
///
/// State is whether a write is in flight, so the screen can hold the switch
/// still rather than letting a second tap race the first.
class NotificationPreferencesController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> setEnabled(
    NotificationType type, {
    required bool enabled,
  }) async {
    final NotificationPreferencesRepository? repository = ref.read(
      notificationPreferencesRepositoryProvider,
    );

    // Signed out. The shell does not offer this screen, so this is a guard
    // rather than a case (hard rule 1).
    if (repository == null) return;

    state = true;

    try {
      await repository.setEnabled(type, enabled: enabled);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.notification,
        'Failed to save notification preference',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'type': type.name, 'enabled': enabled},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}
