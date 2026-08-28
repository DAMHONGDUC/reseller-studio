import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';

/// The words for a stored business-type key.
///
/// **Country and currency names are not here.** `CountryLabel` and
/// `CurrencyLabel` each own their own, because there are hundreds of each and
/// they would bury the four arms this file exists for.
///
/// `WorkspaceConstant` holds the codes and this holds the labels, because a
/// label is a user-facing string (hard rule 7) and a code is a record. A
/// workspace created in English and opened in Vietnamese must show the same
/// business type, in Vietnamese.
///
/// **An unknown code falls back to itself.** A workspace created on a build
/// with a longer list must still render rather than showing a blank row.
final class WorkspaceOptionLabel {
  static String businessType(BuildContext context, String key) => switch (key) {
    'soleTrader' => context.l10n.businessTypeSoleTrader,
    'partnership' => context.l10n.businessTypePartnership,
    'limitedCompany' => context.l10n.businessTypeLimitedCompany,
    'hobbySeller' => context.l10n.businessTypeHobbySeller,
    _ => key,
  };
}
