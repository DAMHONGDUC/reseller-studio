import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';
import '../money/money.dart';

/// Shorthand for the verbose `AppLocalizations.of(context)` form.
///
/// Theme accessors (`context.theme3`, `context.colorScheme3`,
/// `context.sdTheme3`) live in `package:system_design` — the design system
/// owns those, this app owns its strings. There is no `l10n` getter in the
/// package on purpose, and there is no theme getter here for the same reason.
extension BuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// The locale money and dates are formatted in.
  String get localeTag => Localizations.localeOf(this).toLanguageTag();

  /// Format an amount for display, rendering **`—` for null**.
  ///
  /// The one place the app turns a nullable `Money` into a string, so hard
  /// rule 5 is honoured by construction rather than by forty call sites each
  /// remembering. A screen that wants a zero must pass `Money.zero`, which is
  /// a different value with a different meaning.
  ///
  /// [compact] gives `$1.2K` for a dense tile — a full `$1,234,567.89` in a
  /// quarter-width card either overflows or shrinks to unreadable.
  String money(Money? amount, {bool compact = false}) {
    if (amount == null) return l10n.emptyValuePlaceholder;

    return compact
        ? amount.formatCompact(locale: localeTag)
        : amount.format(locale: localeTag);
  }

  /// Format a ratio as a percentage, rendering `—` for null.
  ///
  /// Takes the fraction (`0.125`), not the percentage, because that is what
  /// every calculation in `domain/` produces — converting at the boundary
  /// means nobody multiplies by 100 twice.
  String percent(double? ratio, {int decimals = 0}) {
    if (ratio == null) return l10n.emptyValuePlaceholder;

    return '${(ratio * 100).toStringAsFixed(decimals)}%';
  }
}
