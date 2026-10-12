import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_tag_hue.dart';

/// How a rule's computed price is rounded.
///
/// Stored by [name], so a case is never renamed once written.
enum PriceRounding {
  /// The computed price, to the minor unit.
  none,

  /// Ends in .99 — `$23.40` becomes `$23.99`.
  ninetyNine,

  /// A whole unit — `$23.40` becomes `$24.00`.
  whole,
}

/// How a rounding reads and which hue its tag wears.
extension PriceRoundingDisplay on PriceRounding {
  String label(BuildContext context) => switch (this) {
    PriceRounding.none => context.l10n.pricingRuleRoundingNone,
    PriceRounding.ninetyNine => context.l10n.pricingRuleRoundingNinetyNine,
    PriceRounding.whole => context.l10n.pricingRuleRoundingWhole,
  };

  Color color(BuildContext context) => switch (this) {
    PriceRounding.none => AppTagHue.grey,
    PriceRounding.ninetyNine => AppTagHue.blue,
    PriceRounding.whole => AppTagHue.teal,
  }.of(context);
}
