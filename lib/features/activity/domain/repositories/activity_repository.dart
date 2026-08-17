import '../entities/activity_entry.dart';

/// Reading the audit log. **Read-only by design.**
///
/// There is no `save`, and adding one would be a bug rather than a feature:
/// an entry a client can write can name any actor it likes, which is what
/// makes an audit log worth having (hard rule 12).
abstract interface class ActivityRepository {
  /// Most recent first, capped — the screen is a recent-history view, not an
  /// export. A workspace with two years of edits must not pull all of them
  /// down to show the last twenty.
  Stream<List<ActivityEntry>> watchRecent({int limit});
}
