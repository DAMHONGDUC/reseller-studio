/// What kind of thing an item is — "Sneakers", "Vintage denim", "Vinyl".
///
/// **Named [ItemCategory], not `Category`**, because `ExpenseCategory` already
/// exists and means something else entirely: one classifies stock, the other
/// classifies costs, and a report that mixed them would be nonsense.
///
/// Only [name] is required (plan §28). [parentId] gives one level of nesting
/// so "Clothing → Denim" is possible without the screens having to render an
/// arbitrary tree.
class ItemCategory {
  const ItemCategory({
    required this.id,
    required this.name,
    required this.createdAt,
    this.parentId,
    this.description,
    this.deletedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? parentId;
  final String? description;

  /// Soft delete (hard rule 15) — items point at this, and hard-deleting it
  /// would leave them categorised as nothing with no way to tell that from
  /// never having been categorised.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  ItemCategory copyWith({
    String? name,
    String? parentId,
    String? description,
    DateTime? deletedAt,
  }) => ItemCategory(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt,
    parentId: parentId ?? this.parentId,
    description: description ?? this.description,
    deletedAt: deletedAt ?? this.deletedAt,
  );
}
