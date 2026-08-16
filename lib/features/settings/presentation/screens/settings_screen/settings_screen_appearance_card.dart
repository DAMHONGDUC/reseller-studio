part of 'settings_screen.dart';

/// Theme and language — the two settings that belong to the device, not to a
/// business.
///
/// **This is why Settings is reachable without an account** (owner's rule):
/// neither of these reads a workspace, so refusing to show them until someone
/// signs in would be refusing for no reason.
///
/// **Both are listed and neither is changeable yet.** They carry their current
/// value and a "Soon" badge rather than a chevron, because a row that opens a
/// picker which cannot save is worse than one that says plainly it is not
/// ready. `SellerOsApp` still pins `ThemeMode.system`, and English is the only
/// locale that ships until release (hard rule 7) — so the values below are the
/// truth today, not placeholders.
class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) => AppListCard(
    children: <Widget>[
      AppListRow(
        title: context.l10n.settingsTheme,
        subtitle: context.l10n.settingsThemeSystem,
        icon: Symbols.contrast_rounded,
        trailing: const _SoonBadge(),
        showChevron: false,
      ),
      AppListRow(
        title: context.l10n.settingsLanguage,
        subtitle: context.l10n.settingsLanguageEnglish,
        icon: Symbols.language_rounded,
        trailing: const _SoonBadge(),
        showChevron: false,
      ),
    ],
  );
}

/// Says "listed, not built" in the one place a seller is looking for the
/// control. Reuses the More screen's vocabulary for the same idea.
class _SoonBadge extends StatelessWidget {
  const _SoonBadge();

  @override
  Widget build(BuildContext context) => SdBadgeV3(
    label: context.l10n.settingsNotYet,
    tone: SdBadgeToneV3.neutral,
  );
}
