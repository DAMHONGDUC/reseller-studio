import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/config/dev_flags.dart';
import '../../../../mock_data/providers.dart';
import '../../../../workspace/domain/entities/workspace.dart';
import '../../../../workspace/providers.dart';

/// Settings (plan §25).
///
/// Most of the plan's sections are not built yet. What is here is the
/// **Developer** block, and specifically the mock-data switch — the thing
/// that makes the whole app explorable before a Firebase project exists.
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
          const SdSectionHeaderV3(title: 'Workspace', first: true),
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
      ),
    );
  }
}

/// The mock-data switch.
///
/// **Hidden entirely in a release build** rather than shown disabled. A
/// greyed-out "use fake data" row in a shipped app is a support ticket at
/// best and a trust problem at worst; `DevFlags.isDebugOrProfile` is a
/// compile-time constant, so this whole subtree is tree-shaken out.
class _MockDataCard extends ConsumerWidget {
  const _MockDataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DevFlags.isDebugOrProfile) return const SizedBox.shrink();

    final DataMode mode = ref.watch(dataModeProvider);

    return SdCardV3(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SdIconV3(
                Symbols.science_rounded,
                color: mode.isMock
                    ? context.sdTheme3.warning
                    : context.sdTheme3.textSecondary,
              ),
              SizedBox(width: SdSpacingConstant.w12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Mock data',
                      style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                        color: context.sdTheme3.textPrimary,
                      ),
                    ),
                    Text(
                      mode.isMock
                          ? 'Showing a seeded demo business.'
                          : 'Reading live data.',
                      style: context.textTheme3.bodySmall!.muted3(context),
                    ),
                  ],
                ),
              ),
              Switch(
                value: mode.isMock,
                onChanged: (bool _) =>
                    ref.read(dataModeProvider.notifier).toggle(),
              ),
            ],
          ),
          if (mode.isMock) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h12),
            const _MockSummary(),
          ],
        ],
      ),
    );
  }
}

/// What the seeded dataset actually contains.
///
/// Shown so that "mock data is on" is a checkable statement rather than a
/// claim — the counts come from the live store, so if a screen disagrees with
/// this card, the screen is wrong.
class _MockSummary extends ConsumerWidget {
  const _MockSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MockDataSummary summary = ref.watch(mockDataSummaryProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SdSpacingConstant.w12),
      decoration: BoxDecoration(
        color: context.sdTheme3.surfaceSunken,
        borderRadius: SdRadiusV3.inputAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            summary.workspaceName,
            style: context.textTheme3.labelMedium!.semiBold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h4),
          Text(
            '${summary.items} items · ${summary.orders} orders · '
            '${summary.listings} listings · ${summary.sources} sources · '
            '${summary.expenses} expenses',
            style: context.textTheme3.bodySmall!.muted3(context),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            'Held in memory only. Restarting re-seeds it, so edits made here '
            'are never permanent.',
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h4),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
        ),
        Text(
          value,
          style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
      ],
    ),
  );
}
