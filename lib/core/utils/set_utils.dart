/// Set operations the filter criteria share.
///
/// Its own class rather than a method on each criteria object: "tick this
/// value, untick it if it was already there" is one behaviour, and two copies
/// of it is how two filter sheets end up disagreeing about what a second tap
/// does.
final class SetUtils {
  /// [value] added when it is missing, removed when it is present.
  ///
  /// Returns a new set — the criteria objects are immutable, so mutating the
  /// one they hold would change state Riverpod cannot see.
  static Set<T> toggled<T>(Set<T> source, T value) {
    final Set<T> next = Set<T>.of(source);

    if (!next.remove(value)) next.add(value);

    return next;
  }
}
