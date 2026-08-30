import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';

/// The unit a store measures an introductory offer in.
enum IntroPeriodUnit { day, week, month, year }

/// How a duration reads. The one place `domain/` may import Flutter, and it
/// carries the display half of the enum so a switch cannot drift from a
/// second copy elsewhere.
extension IntroPeriodUnitDisplay on IntroPeriodUnit {
  String label(BuildContext context, int count) => switch (this) {
    IntroPeriodUnit.day => context.l10n.commonDays(count),
    IntroPeriodUnit.week => context.l10n.commonWeeks(count),
    IntroPeriodUnit.month => context.l10n.commonMonths(count),
    IntroPeriodUnit.year => context.l10n.commonYears(count),
  };
}

/// What the store attached to a product before its normal price.
///
/// **Read, never decided here.** How long it runs, what it costs and who is
/// eligible are the store's answers; the app quotes them the way it quotes a
/// price (see `PlanOffering`).
class PlanIntroOffer {
  const PlanIntroOffer({
    required this.unit,
    required this.unitCount,
    required this.formattedPrice,
    required this.isFree,
  });

  final IntroPeriodUnit unit;
  final int unitCount;

  /// Store-formatted, e.g. `$0.00`.
  final String formattedPrice;

  /// A trial rather than a discounted first period. Only a free offer is sold
  /// as one — calling a cheaper first year a trial is how a charge surprises
  /// somebody.
  final bool isFree;

  String duration(BuildContext context) => unit.label(context, unitCount);
}
