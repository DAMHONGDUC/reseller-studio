/// Values the Inventory filter uses that are not ids of anything.
///
/// Its own class rather than a `static const` on `ItemFilterCriteria`: a
/// sentinel is configuration about the filter, not a field of it (owner's
/// rule on where constants live).
final class ItemFilterConstant {
  /// The id standing for "no category / no location / no source recorded".
  ///
  /// **A sentinel rather than a null in the set**, because the chip that
  /// selects it is a chip like any other, and a `Set<String?>` would make
  /// every group's type awkward to say "one of these is not an id".
  ///
  /// Prefixed and suffixed so it can never collide with a Firestore document
  /// id, which is what would silently hide a real category behind it.
  static const String unassignedId = '__unassigned__';
}
