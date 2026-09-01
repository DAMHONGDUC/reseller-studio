import 'package:flutter/widgets.dart';

import '../extensions/context_extensions.dart';
import '../utils/date_time_utils.dart';

/// How far back a list is narrowed to — the same question Inventory asks of
/// "when was this added" and Orders asks of "when was this sold".
///
/// **Presets rather than two date pickers.** A seller filtering a list wants
/// "the last month", and picking two dates to express that is four taps and a
/// calendar for an answer they already had.
///
/// **A record with no date never matches a narrowed range.** The dates this
/// filters on are nullable, and a missing one is unknown — putting it in
/// "last 7 days" would be a guess (hard rule 5, applied to a filter).
enum DateRangeFilter {
  any,
  last7Days,
  last30Days,
  last90Days,
  thisYear;

  /// How many days back this reaches, or null for the ranges that are not a
  /// day count.
  int? get days => switch (this) {
    DateRangeFilter.any || DateRangeFilter.thisYear => null,
    DateRangeFilter.last7Days => 7,
    DateRangeFilter.last30Days => 30,
    DateRangeFilter.last90Days => 90,
  };

  bool matches(DateTime? value, {required DateTime now}) {
    if (this == DateRangeFilter.any) return true;
    if (value == null) return false;
    if (this == DateRangeFilter.thisYear) return value.year == now.year;

    return DateTimeUtils.isWithinLastDays(value, now: now, days: days!);
  }

  bool get isActive => this != DateRangeFilter.any;
}

/// **How a range is shown lives on the range** — owner's rule, the same shape
/// `ItemStatusDisplay` has. The words are the same wherever the filter is
/// offered, so they belong here rather than at two call sites.
extension DateRangeFilterDisplay on DateRangeFilter {
  String label(BuildContext context) => switch (this) {
    DateRangeFilter.any => context.l10n.filterAnyTime,
    DateRangeFilter.last7Days => context.l10n.filterLast7Days,
    DateRangeFilter.last30Days => context.l10n.filterLast30Days,
    DateRangeFilter.last90Days => context.l10n.filterLast90Days,
    DateRangeFilter.thisYear => context.l10n.filterThisYear,
  };
}
