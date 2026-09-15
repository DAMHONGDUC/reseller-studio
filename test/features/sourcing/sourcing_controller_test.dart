import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item_category.dart';
import 'package:reseller_studio/features/inventory/domain/entities/storage_location.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/catalog_controller.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/purchase.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/source.dart';
import 'package:reseller_studio/features/sourcing/presentation/controllers/sourcing_controller.dart';

import '../../support/pump_app.dart';

/// `Source → Purchase → Item`, and the reference data the forms file against.
///
/// **Only the name is required on a source, only the date on a purchase**
/// (hard rule 2) — a seller adding a shop mid-hunt types one box and moves
/// on. What these pin is that the minimum is really the minimum, that an
/// empty box is stored as "not entered" rather than as an empty string, and
/// that the purchase total is taken from the receipt rather than derived.
void main() {
  Future<ProviderContainer> ready() async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    return container;
  }

  SourcingController sourcing(ProviderContainer container) =>
      container.read(sourcingControllerProvider.notifier);

  CatalogController catalog(ProviderContainer container) =>
      container.read(catalogControllerProvider.notifier);

  Future<List<Source>> sources(ProviderContainer container) async =>
      container.read(sourceRepositoryProvider).watchSources().first;

  Future<List<Purchase>> purchases(ProviderContainer container) async =>
      container.read(purchaseRepositoryProvider).watchPurchases().first;

  group('sources', () {
    test('a name is enough, and the rest stays unentered', () async {
      final ProviderContainer container = await ready();

      final String? id = await sourcing(
        container,
      ).saveSource(name: '  Camden car boot  ', address: '   ', notes: '');

      final Source saved = (await sources(
        container,
      )).firstWhere((Source source) => source.id == id);

      expect(saved.name, 'Camden car boot');
      // An empty box is "not entered", which is null — never an empty string
      // that every screen then has to test for.
      expect(saved.address, isNull);
      expect(saved.notes, isNull);
      expect(saved.type, isNull);
      expect(container.read(sourcingControllerProvider), isFalse);
    });

    test('a blank name writes nothing at all', () async {
      final ProviderContainer container = await ready();
      final int before = (await sources(container)).length;

      expect(await sourcing(container).saveSource(name: '   '), isNull);
      expect(await sources(container), hasLength(before));
    });

    test('saving an existing id edits rather than duplicates', () async {
      final ProviderContainer container = await ready();
      final Source first = (await sources(container)).first;
      final int before = (await sources(container)).length;

      await sourcing(container).saveSource(id: first.id, name: 'Renamed');

      final List<Source> after = await sources(container);

      expect(after, hasLength(before));
      expect(
        after.firstWhere((Source source) => source.id == first.id).name,
        'Renamed',
      );
    });
  });

  group('purchases', () {
    test('a date is enough, and an empty total is unknown', () async {
      final ProviderContainer container = await ready();
      final DateTime date = DateTime(2026, 5, 4);

      final String? id = await sourcing(
        container,
      ).savePurchase(purchaseDate: date);

      final Purchase saved = (await purchases(
        container,
      )).firstWhere((Purchase purchase) => purchase.id == id);

      expect(saved.purchaseDate, date);
      // Not zero: nobody has entered what left the seller's pocket, and a
      // zero would claim the trip was free (hard rule 5).
      expect(saved.totalCost, isNull);
      expect(saved.sourceId, isNull);
    });

    test(
      'the total is read from the receipt, in the workspace currency',
      () async {
        final ProviderContainer container = await ready();

        final String? id = await sourcing(container).savePurchase(
          purchaseDate: DateTime(2026, 5, 4),
          totalCost: '40.00',
          sourceId: 'src-1',
        );

        final Purchase saved = (await purchases(
          container,
        )).firstWhere((Purchase purchase) => purchase.id == id);

        expect(saved.totalCost, const Money(4000, 'USD'));
        expect(saved.sourceId, 'src-1');
      },
    );

    test('an unreadable total is unknown, not zero', () async {
      final ProviderContainer container = await ready();

      final String? id = await sourcing(container).savePurchase(
        purchaseDate: DateTime(2026, 5, 4),
        totalCost: 'about forty quid',
      );

      expect(
        (await purchases(
          container,
        )).firstWhere((Purchase purchase) => purchase.id == id).totalCost,
        isNull,
      );
    });
  });

  group('categories and locations', () {
    test('a category needs a name and nothing else', () async {
      final ProviderContainer container = await ready();

      await catalog(container).saveCategory(name: '  Sunglasses  ');

      final List<ItemCategory> saved = await container
          .read(categoryRepositoryProvider)
          .watchCategories()
          .first;

      expect(
        saved.where((ItemCategory row) => row.name == 'Sunglasses'),
        hasLength(1),
      );
      expect(container.read(catalogControllerProvider), isFalse);
    });

    test('a blank name writes no category', () async {
      final ProviderContainer container = await ready();
      final int before =
          (await container
                  .read(categoryRepositoryProvider)
                  .watchCategories()
                  .first)
              .length;

      await catalog(container).saveCategory(name: '  ');

      expect(
        await container
            .read(categoryRepositoryProvider)
            .watchCategories()
            .first,
        hasLength(before),
      );
    });

    test('an empty barcode on a location is unentered', () async {
      final ProviderContainer container = await ready();

      await catalog(
        container,
      ).saveLocation(name: 'Bin 9', kind: LocationKind.bin, barcode: '   ');

      final StorageLocation saved =
          (await container
                  .read(locationRepositoryProvider)
                  .watchLocations()
                  .first)
              .firstWhere((StorageLocation row) => row.name == 'Bin 9');

      expect(saved.barcode, isNull);
      expect(saved.kind, LocationKind.bin);
    });
  });
}
