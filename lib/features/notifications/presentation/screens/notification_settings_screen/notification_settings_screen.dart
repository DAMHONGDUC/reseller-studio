import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/permissions/app_permission.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_status_card.dart';
import '../../../../../core/widgets/permission_settings_sheet.dart';
import '../../../domain/entities/notification_preferences.dart';
import '../../../domain/enums/notification_type.dart';
import '../../../providers.dart';

part 'notification_settings_screen_push_blocked.dart';
part 'notification_settings_screen_row.dart';

/// One switch per kind of reminder.
///
/// **This exists so the operating system's switch never has to be reached
/// for.** Without it a seller annoyed by one reminder has exactly one way to
/// stop it — turning the app's notifications off entirely — and that takes the
/// new-order push with it, which is the only one nobody wants to lose. It is
/// also why no type may be added before this screen can carry it: the list is
/// built from `NotificationType.configurable`, so a new value appears here on
/// its own.
///
/// **Muting silences the push, not the record.** The inbox row is still
/// written (`functions/src/notifications/notify.ts` drops the recipient before
/// either), so nothing is lost that a seller cannot come back and read.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotificationPreferences preferences =
        ref.watch(notificationPreferencesProvider).value ??
        const NotificationPreferences.everything();

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.notificationSettingsTitle),
      body: ListView(
        padding: SdContentPaddingV3.fullBleed(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: Text(
              context.l10n.notificationSettingsIntro,
              style: context.textTheme3.bodySmall!.muted3(context),
            ),
          ),
          SizedBox(height: SdSpacingConstant.h16),
          const _PushBlockedCard(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: AppListCard(
              children: <Widget>[
                for (final NotificationType type
                    in NotificationType.configurable)
                  _PreferenceRow(
                    type: type,
                    isEnabled: preferences.isEnabled(type),
                  ),
              ],
            ),
          ),
          SizedBox(height: SdContentPaddingV3.bottomGap),
        ],
      ),
    );
  }
}
