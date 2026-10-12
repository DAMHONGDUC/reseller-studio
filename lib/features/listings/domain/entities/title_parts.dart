/// The pieces a listing title is assembled from (`TitleBuilder`).
///
/// Every piece is optional: a builder with only a product type still gives a
/// title, the same way Quick Add needs only one (hard rule 2).
class TitleParts {
  const TitleParts({
    this.brand,
    this.productType,
    this.attributes = const <String>[],
    this.color,
    this.size,
    this.condition,
  });

  final String? brand;

  /// What the thing is — "Running Shoes", "Denim Jacket".
  final String? productType;

  /// Model, material, style; most important first, because the last ones are
  /// the first dropped when the title is too long.
  final List<String> attributes;

  final String? color;
  final String? size;

  /// The condition as the seller wants it read — already localised by the
  /// caller, since this layer has no `BuildContext`.
  final String? condition;
}
