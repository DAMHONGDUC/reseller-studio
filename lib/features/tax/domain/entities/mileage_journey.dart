/// One trip: how far, and when.
///
/// The two facts a deduction needs, and nothing else. Keeping this separate
/// from `Expense` is what lets `MileageCalculator` stay pure Dart over a pair
/// of primitives rather than importing another feature's entity.
class MileageJourney {
  const MileageJourney({required this.date, required this.distance});

  /// The day the journey was made, which is what picks its rate. Never today:
  /// a return filed in March deducts last year's miles at last year's rate.
  final DateTime date;

  final double distance;
}
