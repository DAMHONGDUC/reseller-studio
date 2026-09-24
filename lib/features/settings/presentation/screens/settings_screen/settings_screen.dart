import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_section.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../../reseller_studio_app.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../auth/providers.dart';
import '../../controllers/app_locale_controller.dart';
import '../../controllers/theme_mode_controller.dart';

part 'settings_screen_account_card.dart';
part 'settings_screen_appearance_card.dart';

/// Settings (plan §25).
///
/// **Sign out and delete account are here and they work.** Everything else the
/// plan lists — theme, notifications, date format, subscription — is either
/// waiting on a backend or is a preference nobody has asked for yet, and a
/// screen full of controls that do nothing is worse than a short one.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SdScaffoldV3(
    appBar: SdAppBarV3(title: context.l10n.moreSettings),
    body: ListView(
      padding: SdContentPaddingV3.screen(context),
      children: <Widget>[
        SizedBox(height: SdContentPaddingV3.topGap),
        const _AppearanceCard(),
        const _AccountCard(),
        AppSection.rows(
          title: context.l10n.settingsApp,
          children: <Widget>[
            AppListRow(
              title: context.l10n.notificationSettingsTitle,
              subtitle: context.l10n.notificationSettingsIntro,
              icon: AppIconConstant.notifications,
              onTap: () => context.push(AppRoutes.notificationSettings),
            ),
          ],
        ),
      ],
    ),
  );
}
