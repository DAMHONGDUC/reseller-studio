/// How a Custom period chooses the width of its trend bars.
final class AnalyticsPeriodConstant {
  /// Up to this many days, one bar per day.
  static const int dayGrainMaxDays = 14;

  /// Up to this many days, one bar per week; beyond it, one per month.
  static const int weekGrainMaxDays = 120;
}
