/// A shipping carrier one business uses.
class Carrier {
  const Carrier({
    required this.id,
    required this.name,
    required this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Carrier copyWith({String? name, DateTime? deletedAt}) => Carrier(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );
}
