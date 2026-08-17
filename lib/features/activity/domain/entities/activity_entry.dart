/// What kind of record an entry is about.
///
/// **An unknown code maps to [unknown], never to a neighbour** — a document
/// written by a newer build must render rather than claim to be the value that
/// happens to sit next to it in the list (`docs/rules/BACKEND.md`).
enum ActivityEntityType { item, order, listing, unknown }

/// What happened to it. The list is plan §23.
enum ActivityAction { created, updated, deleted, unknown }

/// One line of the audit log.
///
/// **Written only by Cloud Functions**, so `actorId` cannot be forged — that
/// is the whole reason `activity/` is `allow create: if false` for clients
/// (hard rule 12). Nothing in the app writes this entity; there is no `save`
/// on its repository and there should never be one.
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.createdAt,
    this.actorId,
  });

  final String id;
  final ActivityEntityType entityType;
  final String entityId;
  final ActivityAction action;
  final DateTime createdAt;

  /// Who did it, as a uid. **Null is a real answer**, not a gap to paper
  /// over: a record changed by a sync job or by a trigger has no human actor,
  /// and naming one would be a lie in the one place that must not lie.
  final String? actorId;
}
