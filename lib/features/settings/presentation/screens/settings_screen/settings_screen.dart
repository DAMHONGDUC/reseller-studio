import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/config/dev_flags.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/name_entry_sheet.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../auth/providers.dart';
import '../../../../mock_data/providers.dart';
import '../../../../workspace/country_label.dart';
import '../../../../workspace/country_picker.dart';
import '../../../../workspace/domain/entities/workspace.dart';
import '../../../../workspace/presentation/controllers/workspace_edit_controller.dart';
import '../../../../workspace/providers.dart';
import '../../../../workspace/workspace_constant.dart';
import '../../../../workspace/workspace_option_label.dart';
import '../../controllers/demo_seed_controller.dart';
import '../../controllers/theme_mode_controller.dart';

part 'settings_screen_account_card.dart';
part 'settings_screen_appearance_card.dart';
part 'settings_screen_demo_seed_card.dart';
part 'settings_screen_mock_data_card.dart';
part 'settings_screen_mock_summary.dart';
part 'settings_screen_setting_row.dart';
part 'settings_screen_workspace_card.dart';

/// Settings (plan §25).
///
/// **Sign out and delete account are here and they work.** Everything else the
/// plan lists — theme, notifications, date format, subscription — is either
/// waiting on a backend or is a preference nobody has asked for yet, and a
/// screen full of controls that do nothing is worse than a short one.
///
/// The Developer block is compiled out of a release build: `DevFlags` is a
/// `const` false there, so the tree-shaker removes the branch and everything
/// only it reached.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Workspace? workspace = ref.watch(currentWorkspaceProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.moreSettings),
      body: ListView(
        padding: SdContentPaddingV3.fullBleed(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          SdSectionHeaderV3(
            title: context.l10n.settingsAppearance,
            first: true,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: const _AppearanceCard(),
          ),
          SdSectionHeaderV3(title: context.l10n.settingsAccount),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: const _AccountCard(),
          ),
          SdSectionHeaderV3(
            title: context.l10n.settingsWorkspace,
            subtitle: workspace == null ? null : context.l10n.workspaceEditNote,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: workspace == null
                ? SdCardV3(
                    child: Text(
                      context.l10n.workspaceNoneLoaded,
                      style: context.textTheme3.bodyMedium!.muted3(context),
                    ),
                  )
                : _WorkspaceCard(workspace: workspace),
          ),
          SdSectionHeaderV3(title: context.l10n.settingsApp),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: AppListCard(
              children: <Widget>[
                AppListRow(
                  title: context.l10n.moreAbout,
                  subtitle: context.l10n.aboutTagline,
                  icon: Symbols.info_rounded,
                  onTap: () => context.push(AppRoutes.about),
                ),
              ],
            ),
          ),
          if (DevFlags.isDebugOrProfile) ...<Widget>[
            SdSectionHeaderV3(
              title: context.l10n.settingsDeveloper,
              subtitle: context.l10n.settingsDeveloperNote,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              child: const _MockDataCard(),
            ),
            SizedBox(height: SdSpacingConstant.h12),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              child: const _DemoSeedCard(),
            ),
          ],
        ],
      ),
    );
  }
}
