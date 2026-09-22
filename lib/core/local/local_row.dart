/// One guest record, whatever entity it is.
///
/// **Hand-written and shared by every table** (`@UseRowClass`), rather than
/// one generated class per table. Drift would otherwise name them `Item`,
/// `Order`, `Listing` — every one of which is already a domain entity in this
/// app, and a local storage type that shadows a domain type is the import
/// mistake nobody catches in review.
///
/// It also gives the tables a common row type, which is what lets `LocalTable`
/// be written once instead of eleven times.
class LocalRow {
  const LocalRow({
    required this.id,
    required this.createdAt,
    required this.data,
  });

  /// The record's own id — the one the domain entity carries.
  final String id;

  /// Millis since epoch. Ordering only; the authoritative date is in [data].
  final int createdAt;

  /// The Firestore DTO's own map, JSON-encoded (`LocalJsonCodec`).
  final String data;
}
