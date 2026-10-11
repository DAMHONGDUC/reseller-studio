/// A window of whole days the seller picked themselves — the Custom period.
///
/// Both ends are days, inclusive: 1–9 October covers all of the 9th.
class AnalyticsDateRange {
  const AnalyticsDateRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}
