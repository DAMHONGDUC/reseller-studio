import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';

/// The words for a stored currency, country or business-type code.
///
/// `WorkspaceConstant` holds the codes and this holds the labels, because a
/// label is a user-facing string (hard rule 7) and a code is a record. A
/// workspace created in English and opened in Vietnamese must show the same
/// currency, in Vietnamese.
///
/// **An unknown code falls back to itself.** A workspace created on a build
/// with a longer list must still render rather than showing a blank row.
final class WorkspaceOptionLabel {
  static String currency(BuildContext context, String code) => switch (code) {
    'USD' => context.l10n.currencyUsd,
    'EUR' => context.l10n.currencyEur,
    'GBP' => context.l10n.currencyGbp,
    'VND' => context.l10n.currencyVnd,
    'AUD' => context.l10n.currencyAud,
    'CAD' => context.l10n.currencyCad,
    'JPY' => context.l10n.currencyJpy,
    'SGD' => context.l10n.currencySgd,
    _ => code,
  };

  static String country(BuildContext context, String code) => switch (code) {
    'US' => context.l10n.countryUs,
    'GB' => context.l10n.countryGb,
    'VN' => context.l10n.countryVn,
    'AU' => context.l10n.countryAu,
    'CA' => context.l10n.countryCa,
    'DE' => context.l10n.countryDe,
    'FR' => context.l10n.countryFr,
    'JP' => context.l10n.countryJp,
    'SG' => context.l10n.countrySg,
    _ => code,
  };

  static String businessType(BuildContext context, String key) => switch (key) {
    'soleTrader' => context.l10n.businessTypeSoleTrader,
    'partnership' => context.l10n.businessTypePartnership,
    'limitedCompany' => context.l10n.businessTypeLimitedCompany,
    'hobbySeller' => context.l10n.businessTypeHobbySeller,
    _ => key,
  };
}
