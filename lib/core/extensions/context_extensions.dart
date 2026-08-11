import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';

/// Shorthand for the verbose `AppLocalizations.of(context)` form.
///
/// Theme accessors (`context.theme3`, `context.colorScheme3`,
/// `context.sdTheme3`) live in `package:system_design` — the design system
/// owns those, this app owns its strings. There is no `l10n` getter in the
/// package on purpose, and there is no theme getter here for the same reason.
extension BuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
