part of 'settings_screen.dart';

/// Theme and language — the two settings that belong to the device, not to a
/// business.
///
/// **This is why Settings is reachable without an account** (owner's rule):
/// neither reads a workspace, so refusing to show them until someone signs in
/// would be refusing for no reason.
///
/// Language defaults to the device and can be pinned to any shipping locale.
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

  /// A language is always named in itself, so a seller who landed in the
  /// wrong one can still find their own.
  static String _languageLabel(BuildContext context, Locale? locale) =>
      locale == null
      ? context.l10n.settingsLanguageSystem
      : lookupAppLocalizations(locale).settingsLanguageName;

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final Locale? current = ref.read(appLocaleProvider);
    // A sheet option cannot be null, so "follow the device" is the empty code.
    final String? picked = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.settingsLanguage,
      selected: current?.languageCode ?? '',
      options: <PickerOption<String>>[
        PickerOption<String>(value: '', label: _languageLabel(context, null)),
        for (final Locale locale in ResellerStudioApp.shippingLocales)
          PickerOption<String>(
            value: locale.languageCode,
            label: _languageLabel(context, locale),
          ),
      ],
    );

    if (picked == null) return;

    await ref
        .read(appLocaleProvider.notifier)
        .select(AppLocaleController.parse(picked));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final Locale? locale = ref.watch(appLocaleProvider);

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
          subtitle: _languageLabel(context, locale),
          icon: AppIconConstant.language,
          onTap: () => _pickLanguage(context, ref),
        ),
      ],
    );
  }
}
