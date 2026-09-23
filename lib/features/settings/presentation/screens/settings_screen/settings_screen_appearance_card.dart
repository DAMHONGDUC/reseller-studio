part of 'settings_screen.dart';

/// Theme and language — the two settings that belong to the device, not to a
/// business.
///
/// **This is why Settings is reachable without an account** (owner's rule):
/// neither reads a workspace, so refusing to show them until someone signs in
/// would be refusing for no reason.
///
/// Theme works. Language shows the one the device picked (hard rule 7) with a
/// "Soon" badge: an in-app override is not built, so the phone's own language
/// setting is still the only way to change it.
class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  static String _label(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.system => context.l10n.settingsThemeSystem,
    ThemeMode.light => context.l10n.settingsThemeLight,
    ThemeMode.dark => context.l10n.settingsThemeDark,
  };

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final ThemeMode? picked = await OptionPickerSheet.show<ThemeMode>(
      context,
      title: context.l10n.settingsTheme,
      selected: ref.read(themeModeProvider),
      options: <PickerOption<ThemeMode>>[
        for (final ThemeMode mode in ThemeMode.values)
          PickerOption<ThemeMode>(value: mode, label: _label(context, mode)),
      ],
    );

    if (picked == null) return;

    await ref.read(themeModeProvider.notifier).select(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);

    return AppListCard(
      children: <Widget>[
        AppListRow(
          title: context.l10n.settingsTheme,
          subtitle: _label(context, mode),
          icon: AppIconConstant.contrast,
          onTap: () => _pickTheme(context, ref),
        ),
        AppListRow(
          title: context.l10n.settingsLanguage,
          subtitle: context.l10n.settingsLanguageName,
          icon: AppIconConstant.language,
          trailing: const _SoonBadge(),
          showChevron: false,
        ),
      ],
    );
  }
}

/// Says "listed, not built" in the one place a seller looks for the control.
class _SoonBadge extends StatelessWidget {
  const _SoonBadge();

  @override
  Widget build(BuildContext context) => SdBadgeV3(
    label: context.l10n.settingsNotYet,
    tone: SdBadgeToneV3.neutral,
  );
}
