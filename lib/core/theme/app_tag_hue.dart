import 'package:flutter/material.dart';

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
enum AppTagHue {
  green,
  blue,
  violet,
  indigo,
  teal,
  amber,
  red,
  grey;

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
