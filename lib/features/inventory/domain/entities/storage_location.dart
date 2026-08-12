/// Where a physical item actually is (plan §7).
///
/// ```text
/// Warehouse
/// ├── Shelf
/// │   ├── Bin
/// │   └── Bin
/// └── Shelf
/// ```
///
/// One entity for all three levels, with [kind] saying which and [parentId]
/// joining them. Three entities would be three repositories, three screens and
/// three sets of rules for the same question — "where is it?".
///
/// [barcode] is what the scanner matches: a seller scanning a label on a bin
/// gets that bin's contents, which is the whole reason locations exist rather
/// than a free-text note on the item.
class StorageLocation {
  const StorageLocation({
    required this.id,
    required this.name,
    required this.kind,
    required this.createdAt,
    this.parentId,
    this.address,
    this.barcode,
    this.notes,
    this.deletedAt,
  });

  final String id;

  /// Required at every level (plan §28) — a name or a code.
  final String name;

  final LocationKind kind;
  final DateTime createdAt;

  /// Required for a shelf and a bin, null for a warehouse. Not enforced by
  /// the type: a seller who deletes a warehouse should not lose the shelves
  /// under it, and an orphan is recoverable where a crash is not.
  final String? parentId;

  final String? address;
  final String? barcode;
  final String? notes;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  StorageLocation copyWith({
    String? name,
    LocationKind? kind,
    String? parentId,
    String? address,
    String? barcode,
    String? notes,
    DateTime? deletedAt,
  }) => StorageLocation(
    id: id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    createdAt: createdAt,
    parentId: parentId ?? this.parentId,
    address: address ?? this.address,
    barcode: barcode ?? this.barcode,
    notes: notes ?? this.notes,
    deletedAt: deletedAt ?? this.deletedAt,
  );
}

/// The three levels of the storage tree.
enum LocationKind {
  warehouse,
  shelf,
  bin;

  /// What may sit inside this one. A bin holds items, not more locations.
  bool get canHaveChildren => this != LocationKind.bin;
}
