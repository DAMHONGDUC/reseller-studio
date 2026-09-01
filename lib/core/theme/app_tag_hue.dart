import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import 'app_colors.dart';

/// The hues a tag can wear, named rather than numbered.
///
/// **A colour is chosen by name, never by index** — owner's rule.
/// `ItemStatus.draft => 7` said nothing about what 7 was, and the reader had
/// to count entries in a list to find out; `AppTagHue.grey` says it.
///
/// **These are not the semantic tokens.** `success`, `warning` and `danger`
/// say what a state *means*; these only have to differ, because the sets that
/// use them — four item statuses, seven condition grades — need more hues
/// than there are meanings. Reusing `warning` for a middling condition grade
/// would tell the seller something is wrong with it.
///
/// Ordered light-to-serious, so a set that runs best-to-worst reads correctly
/// by following the list.
///
/// **A seller picks one of these too** — a marketplace carries a hue
/// (`lib/features/marketplaces/AGENTS.md`), which is why the enum grew a
/// [label] and a [fromName]. One named palette for both, rather than a second
/// list that has to be kept looking like this one.
enum AppTagHue {
  green,
  blue,
  violet,
  indigo,
  teal,
  amber,
  red,
  grey;

  /// The hue a stored name refers to.
  ///
  /// **An unknown or missing name is [grey], never a throw.** A record written
  /// by a later build with a hue this one has never heard of still has to
  /// render — the same reason `CountryLabel` falls back to the code.
  static AppTagHue fromName(String? name) =>
      AppTagHue.values.where((AppTagHue hue) => hue.name == name).firstOrNull ??
      AppTagHue.grey;

  /// What this hue is called, for the picker and for a screen reader.
  String label(BuildContext context) => switch (this) {
    AppTagHue.green => context.l10n.hueGreen,
    AppTagHue.blue => context.l10n.hueBlue,
    AppTagHue.violet => context.l10n.hueViolet,
    AppTagHue.indigo => context.l10n.hueIndigo,
    AppTagHue.teal => context.l10n.hueTeal,
    AppTagHue.amber => context.l10n.hueAmber,
    AppTagHue.red => context.l10n.hueRed,
    AppTagHue.grey => context.l10n.hueGrey,
  };

  /// The hue in the palette currently on screen.
  Color of(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (this) {
      AppTagHue.green => isDark ? AppColors.tagGreenDark : AppColors.tagGreen,
      AppTagHue.blue => isDark ? AppColors.tagBlueDark : AppColors.tagBlue,
      AppTagHue.violet =>
        isDark ? AppColors.tagVioletDark : AppColors.tagViolet,
      AppTagHue.indigo =>
        isDark ? AppColors.tagIndigoDark : AppColors.tagIndigo,
      AppTagHue.teal => isDark ? AppColors.tagTealDark : AppColors.tagTeal,
      AppTagHue.amber => isDark ? AppColors.tagAmberDark : AppColors.tagAmber,
      AppTagHue.red => isDark ? AppColors.tagRedDark : AppColors.tagRed,
      AppTagHue.grey => isDark ? AppColors.tagGreyDark : AppColors.tagGrey,
    };
  }
}
