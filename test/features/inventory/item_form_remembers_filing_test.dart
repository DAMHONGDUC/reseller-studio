import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/constants/prefs_key_constant.dart';
import 'package:reseller_studio/core/providers/shared_preferences_provider.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item_category.dart';
import 'package:reseller_studio/features/inventory/domain/entities/storage_location.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_form_controller.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/pump_app.dart';

/// A seller booking in twenty things from one haul picked the same bin twenty
/// times: the create form reset every picker, while the intake session had
/// already solved the same problem by asking for the source once a trip.
///
/// Prefilled, never required (hard rule 2) — both pickers are on screen.
void main() {
  /// A container whose preferences already hold [values], warmed so the
  /// category and location streams have emitted.
  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);

    final ProviderContainer container = mockContainer();

    await container.read(sharedPreferencesProvider.future);
    await warmUp(container);

    // `warmUp` starts the streams the figures are folded from; the form reads
    // two more to check a remembered id still names something.
    container.listen<AsyncValue<List<ItemCategory>>>(
      categoriesProvider,
      (AsyncValue<List<ItemCategory>>? _, AsyncValue<List<ItemCategory>> _) {},
      fireImmediately: true,
    );
    container.listen<AsyncValue<List<StorageLocation>>>(
      locationsProvider,
      (
        AsyncValue<List<StorageLocation>>? _,
        AsyncValue<List<StorageLocation>> _,
      ) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);

    return container;
  }

  test('a fresh create form opens on the last filing', () async {
    final ProviderContainer container = await containerWith(<String, Object>{
      PrefsKeyConstant.lastItemCategoryId: 'cat-outerwear',
      PrefsKeyConstant.lastItemLocationId: 'loc-shelf-a',
    });

    container.read(itemFormControllerProvider.notifier).startCreate();

    final ItemFormState state = container.read(itemFormControllerProvider);

    expect(state.categoryId, 'cat-outerwear');
    expect(state.locationId, 'loc-shelf-a');
  });

  test('nothing remembered leaves both pickers empty', () async {
    final ProviderContainer container = await containerWith(
      const <String, Object>{},
    );

    container.read(itemFormControllerProvider.notifier).startCreate();

    final ItemFormState state = container.read(itemFormControllerProvider);

    expect(state.categoryId, isNull);
    expect(state.locationId, isNull);
  });

  test('a bin that has since been deleted is dropped, not seeded', () async {
    final ProviderContainer container = await containerWith(<String, Object>{
      PrefsKeyConstant.lastItemCategoryId: 'cat-gone',
      PrefsKeyConstant.lastItemLocationId: 'loc-gone',
    });

    container.read(itemFormControllerProvider.notifier).startCreate();

    final ItemFormState state = container.read(itemFormControllerProvider);

    // A picker seeded with a value its own list cannot show would leave the
    // seller looking at a blank field they did not empty.
    expect(state.categoryId, isNull);
    expect(state.locationId, isNull);
  });

  test(
    'creating remembers where it went; editing an old item does not',
    () async {
      final ProviderContainer container = await containerWith(
        const <String, Object>{},
      );
      final ItemFormController controller = container.read(
        itemFormControllerProvider.notifier,
      );

      controller.startCreate();
      controller.selectCategory('cat-glassware');
      controller.selectLocation('loc-garage');
      await controller.submit(title: 'Pyrex bowl');

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      expect(
        prefs.getString(PrefsKeyConstant.lastItemCategoryId),
        'cat-glassware',
      );
      expect(
        prefs.getString(PrefsKeyConstant.lastItemLocationId),
        'loc-garage',
      );

      // Correcting one old item's bin is not a decision about the next twenty.
      controller.seed(
        Item(
          id: 'itm-old',
          title: 'Something filed months ago',
          quantity: 1,
          status: ItemStatus.inStock,
          createdAt: testNow,
          categoryId: 'cat-outerwear',
        ),
      );
      await controller.submit(title: 'Something filed months ago');

      expect(
        prefs.getString(PrefsKeyConstant.lastItemCategoryId),
        'cat-glassware',
      );
    },
  );
}
