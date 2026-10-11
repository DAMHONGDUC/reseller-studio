/// How recent a record must be for its row to animate in.
final class ListMotionConstant {
  /// A row whose record was made this recently fades in; anything older is
  /// drawn still, so scrolling never replays an arrival.
  static const Duration newRecordWindow = Duration(seconds: 3);
}
