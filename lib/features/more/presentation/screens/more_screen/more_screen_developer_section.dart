part of 'more_screen.dart';

/// The Developer block, last on More so it sits below everything a seller uses.
///
/// Hidden unless `devModeEnabledProvider` says otherwise — every debug and
/// profile build, and the release builds whose account `app_config` names.
class _DeveloperSection extends ConsumerWidget {
  const _DeveloperSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(devModeEnabledProvider)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdSectionHeaderV3(
          title: context.l10n.settingsDeveloper,
          subtitle: context.l10n.settingsDeveloperNote,
        ),
        const _SeedDataCard(),
        SizedBox(height: SdSpacingConstant.h12),
        const _DeleteAllDataCard(),
      ],
    );
  }
}
