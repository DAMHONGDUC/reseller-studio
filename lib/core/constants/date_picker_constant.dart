/// How far back each date picker in the app opens.
///
/// **One class rather than a `static const` on each sheet**, because the same
/// number was written four times across four features and had already drifted
/// into two values with no way to tell which was deliberate. A number a widget
/// does not itself *use* is not that widget's business — the widget lays out a
/// picker, it does not own the seller's filing habits.
///
/// The two values are different on purpose, and the reason is the difference:
/// a purchase is a tax record, a sale is a workflow.
final class DatePickerConstant {
  /// Records a reseller keeps for tax: a purchase, and the date an item was
  /// bought.
  static const int taxRecordYearsBack = 5;

  /// Things filed as they happen — an expense, a sale. Two years covers the
  /// current and previous tax year; anything older is a data-entry mistake
  /// rather than a workflow.
  static const int recentEntryYearsBack = 2;

  /// How far ahead a deadline may be set. A ship-by date is the one date in
  /// the app that belongs in the future, and no marketplace gives a seller
  /// longer than this to post something.
  static const int deadlineDaysAhead = 90;
}
