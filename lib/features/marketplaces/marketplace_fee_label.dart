import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

/// A stored fee rate, as the percentage a seller reads.
///
/// **One place rounds it** — the rate is a fraction on the record and a
/// percentage on every screen, and two call sites doing the conversion is how
/// the same marketplace comes out 12.5% on one and 13% on the next.
final class MarketplaceFeeLabel {
  /// How many decimals a rate is shown to. One is enough to separate 12.5%
  /// from 12%, and two would print `12.50%` for almost every platform.
  static const int decimals = 1;

  static String percent(BuildContext context, double feeRate) => context.l10n
      .marketplaceFeePercent((feeRate * 100).toStringAsFixed(decimals));
}
