import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/config/dev_flags.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../auth/providers.dart';
import '../../../../mock_data/providers.dart';
import '../../../../workspace/domain/entities/workspace.dart';
import '../../../../workspace/providers.dart';

part 'settings_screen_account_card.dart';
part 'settings_screen_mock_data_card.dart';
part 'settings_screen_mock_summary.dart';
part 'settings_screen_setting_row.dart';

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
      appBar: const SdAppBarV3(title: 'Settings'),
      body: ListView(
        padding: SdContentPaddingV3.fullBleed(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          const SdSectionHeaderV3(title: 'Account', first: true),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: const _AccountCard(),
          ),
          const SdSectionHeaderV3(title: 'Workspace'),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: SdCardV3(
              child: workspace == null
                  ? Text(
                      'No workspace loaded.',
                      style: context.textTheme3.bodyMedium!.muted3(context),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SettingRow(label: 'Name', value: workspace.name),
                        _SettingRow(label: 'Country', value: workspace.country),
                        _SettingRow(
                          label: 'Currency',
                          value: workspace.currency,
                        ),
                        _SettingRow(
                          label: 'Stale after',
                          value: '${workspace.staleThresholdDays} days',
                        ),
                      ],
                    ),
            ),
          ),
          if (DevFlags.isDebugOrProfile) ...<Widget>[
            const SdSectionHeaderV3(
              title: 'Developer',
              subtitle: 'Debug builds only — not present in a release build.',
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              child: const _MockDataCard(),
            ),
          ],
        ],
      ),
    );
  }
}
