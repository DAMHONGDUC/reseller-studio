import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item_category.dart';
import 'package:reseller_studio/features/inventory/providers.dart';

void main() {
  test('a new business receives the three default categories', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final List<ItemCategory> defaults = container.read(
      defaultItemCategoriesProvider,
    );

    expect(defaults.map((ItemCategory category) => category.name), <String>[
      'Clothing',
      'Shoes',
      'Accessories',
    ]);
    expect(
      defaults.map((ItemCategory category) => category.id).toSet(),
      <String>{'clothing', 'shoes', 'accessories'},
    );
  });
}
