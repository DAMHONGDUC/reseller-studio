import 'package:flutter/widgets.dart';

import '../../../../core/extensions/context_extensions.dart';

/// The window Analytics reports over.
///
/// **All time is the default and the first option**, because it is what
/// Home's hero shows — opening Analytics on a different number than the one
/// that brought the seller there would read as a contradiction.
enum AnalyticsPeriod { all, days7, days30, days90, yearToDate }

/// How finely a period's trend is bucketed.
enum TrendGrain { day, week, month }

/// What a period reads as on the selector.
extension AnalyticsPeriodDisplay on AnalyticsPeriod {
  String label(BuildContext context) => switch (this) {
    AnalyticsPeriod.all => context.l10n.analyticsPeriodAll,
    AnalyticsPeriod.days7 => context.l10n.analyticsPeriod7d,
    AnalyticsPeriod.days30 => context.l10n.analyticsPeriod30d,
    AnalyticsPeriod.days90 => context.l10n.analyticsPeriod90d,
    AnalyticsPeriod.yearToDate => context.l10n.analyticsPeriodYtd,
  };
}
