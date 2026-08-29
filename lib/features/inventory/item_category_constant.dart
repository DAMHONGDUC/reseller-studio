/// One of the item categories a new business starts with.
class ItemCategorySeed {
  const ItemCategorySeed({required this.id, required this.name});

  final String id;
  final String name;
}

/// The editable category records created for every new business.
final class ItemCategoryConstant {
  static const List<ItemCategorySeed> defaults = <ItemCategorySeed>[
    ItemCategorySeed(id: 'clothing', name: 'Clothing'),
    ItemCategorySeed(id: 'shoes', name: 'Shoes'),
    ItemCategorySeed(id: 'accessories', name: 'Accessories'),
  ];
}
