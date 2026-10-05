part of 'more_screen.dart';

/// Everything the Settings screen used to hold, first on More
/// (`lib/features/more/CLAUDE.md`).
///
/// - the account row and the two ways out only apply to an account, the same
///   split `MoreConstant.accountOnly` makes for destinations
/// - theme and language read no workspace, so a guest gets them too
class _GeneralSection extends ConsumerWidget {
  const _GeneralSection({required this.signedIn, required this.plan});

  final bool signedIn;
  final SellerPlan plan;

  Widget? _destination(MoreDestination destination) =>
      MoreConstant.isVisible(destination, signedIn)
      ? _MoreRow(destination: destination, plan: plan)
      : null;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _MoreRowsSection(
    title: context.l10n.moreSectionGeneral,
    rows: <Widget>[
      const _AccountRow(),
      ?_destination(MoreConstant.subscription),
      const _ThemeRow(),
      const _LanguageRow(),
      ?_destination(MoreConstant.notifications),
      ?_destination(MoreConstant.about),
      ?_destination(MoreConstant.contactSupport),
      if (ref.watch(devModeEnabledProvider)) ...<Widget>[
        const _SeedDataRow(),
        const _CrashlyticsTestRow(),
        const _DeleteAllDataRow(),
      ],
    ],
  );
}

/// Who is signed in; for a guest, the way in.
class _AccountRow extends ConsumerWidget {
  const _AccountRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool signedIn = ref.watch(isSignedInProvider) ?? false;

    if (!signedIn) {
      return _MoreRowTile(
        icon: AppIconConstant.login,
        label: context.l10n.workspaceSignInAction,
        value: context.l10n.settingsSignedOut,
        onTap: () => context.push(AppRoutes.login),
      );
    }

    // The value says only whether an account is signed in — never the email
    // or the name, which do not belong on a row nothing else on More prints.
    // The row opens the Account screen, where they do belong.
    return _MoreRowTile(
      icon: AppIconConstant.person,
      label: context.l10n.settingsAccount,
      value: context.l10n.settingsSignedIn,
      onTap: () => context.push(AppRoutes.account),
    );
  }
}

class _ThemeRow extends ConsumerWidget {
  const _ThemeRow();

  static String _label(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.system => context.l10n.settingsThemeSystem,
    ThemeMode.light => context.l10n.settingsThemeLight,
    ThemeMode.dark => context.l10n.settingsThemeDark,
  };

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
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
  Widget build(BuildContext context, WidgetRef ref) => _MoreRowTile(
    icon: AppIconConstant.contrast,
    label: context.l10n.settingsTheme,
    value: _label(context, ref.watch(themeModeProvider)),
    onTap: () => _pick(context, ref),
  );
}

/// Defaults to the device and can be pinned to any shipping locale.
class _LanguageRow extends ConsumerWidget {
  const _LanguageRow();

  /// A language is always named in itself, so a seller who landed in the
  /// wrong one can still find their own.
  static String _label(BuildContext context, Locale? locale) => locale == null
      ? context.l10n.settingsLanguageSystem
      : lookupAppLocalizations(locale).settingsLanguageName;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final Locale? current = ref.read(appLocaleProvider);
    // A sheet option cannot be null, so "follow the device" is the empty code.
    final String? picked = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.settingsLanguage,
      selected: current?.languageCode ?? '',
      options: <PickerOption<String>>[
        PickerOption<String>(value: '', label: _label(context, null)),
        for (final Locale locale in ResellerStudioApp.shippingLocales)
          PickerOption<String>(
            value: locale.languageCode,
            label: _label(context, locale),
          ),
      ],
    );

    if (picked == null) return;

    await ref
        .read(appLocaleProvider.notifier)
        .select(AppLocaleController.parse(picked));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => _MoreRowTile(
    icon: AppIconConstant.language,
    label: context.l10n.settingsLanguage,
    value: _label(context, ref.watch(appLocaleProvider)),
    onTap: () => _pick(context, ref),
  );
}
