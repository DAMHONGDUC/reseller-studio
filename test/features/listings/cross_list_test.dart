import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/domain/services/item_transition.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_actions_controller.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/listings/presentation/screens/cross_list_screen/cross_list_screen.dart';
import 'package:reseller_studio/features/listings/providers.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// Cross-listing (plan §13) — one item onto several marketplaces at once.
void main() {
  Item item({
    required String id,
    ItemStatus status = ItemStatus.inStock,
    Money? asking,
    DateTime? listedAt,
  }) => Item(
    id: id,
    title: 'Wool coat',
    quantity: 1,
    status: status,
    createdAt: testNow,
    askingPrice: asking,
    listedAt: listedAt,
  );

  group('what may be cross-listed', () {
    test('an item already listed may be — that is the whole point', () {
      // `check(item, listed)` refuses this one as `wrongStatus`, which is why
      // cross-listing has its own check: it is on eBay and the seller wants
      // Depop as well.
      expect(
        ItemTransition.crossListCheck(
          item(id: 'i-1', status: ItemStatus.listed),
        ).isAllowed,
        isTrue,
      );
    });

    test('an item with no price may be — the screen is where it is asked', () {
      expect(ItemTransition.crossListCheck(item(id: 'i-2')).isAllowed, isTrue);
    });

    test('one that has left inventory may not', () {
      for (final ItemStatus status in <ItemStatus>[
        ItemStatus.sold,
        ItemStatus.archived,
      ]) {
        expect(
          ItemTransition.crossListCheck(
            item(id: 'i-3', status: status),
          ).blocks,
          contains(ItemTransitionBlock.wrongStatus),
        );
      }
    });
  });

  group('publishing', () {
    Future<List<Listing>> listingsFor(
      ProviderContainer container,
      String itemId,
    ) async {
      container.listen<AsyncValue<List<Listing>>>(
        listingsForItemProvider(itemId),
        (AsyncValue<List<Listing>>? previous, AsyncValue<List<Listing>> next) {},
        fireImmediately: true,
      );

      await Future<void>.delayed(Duration.zero);

      return container.read(listingsForItemProvider(itemId)).value ??
          const <Listing>[];
    }

    test('writes one draft listing per marketplace, at one price', () async {
      final ProviderContainer container = mockContainer();
      final Item coat = item(id: 'x-1');

      await container.read(itemRepositoryProvider).save(coat);
      await container
          .read(itemActionsControllerProvider.notifier)
          .crossList(
            coat,
            marketplaces: <Marketplace>{Marketplace.ebay, Marketplace.depop},
            price: const Money(4500, 'USD'),
          );

      final List<Listing> listings = await listingsFor(container, 'x-1');

      expect(listings, hasLength(2));
      expect(
        listings.map((Listing l) => l.marketplace).toSet(),
        <Marketplace>{Marketplace.ebay, Marketplace.depop},
      );
      // Draft, not active: nothing is integrated, so nothing may claim to be
      // live on eBay.
      expect(
        listings.every((Listing l) => l.status == ListingStatus.draft),
        isTrue,
      );
      expect(
        listings.every((Listing l) => l.price == const Money(4500, 'USD')),
        isTrue,
      );
    });

    test('moves an in-stock item to listed and takes the price', () async {
      final ProviderContainer container = mockContainer();
      final Item coat = item(id: 'x-2');

      await container.read(itemRepositoryProvider).save(coat);
      await container
          .read(itemActionsControllerProvider.notifier)
          .crossList(
            coat,
            marketplaces: <Marketplace>{Marketplace.etsy},
            price: const Money(3000, 'USD'),
          );

      final Item? saved = await container
          .read(itemRepositoryProvider)
          .watchItem('x-2')
          .first;

      expect(saved!.status, ItemStatus.listed);
      expect(saved.askingPrice, const Money(3000, 'USD'));
      expect(saved.listedAt, isNotNull);
    });

    test('leaves an already-listed item where it is, including listedAt', () async {
      final ProviderContainer container = mockContainer();
      final DateTime firstListed = testNow.subtract(const Duration(days: 40));
      final Item coat = item(
        id: 'x-3',
        status: ItemStatus.listed,
        asking: const Money(5000, 'USD'),
        listedAt: firstListed,
      );

      await container.read(itemRepositoryProvider).save(coat);
      await container
          .read(itemActionsControllerProvider.notifier)
          .crossList(
            coat,
            marketplaces: <Marketplace>{Marketplace.poshmark},
            price: const Money(4000, 'USD'),
          );

      final Item? saved = await container
          .read(itemRepositoryProvider)
          .watchItem('x-3')
          .first;

      // Staleness is measured from the first time it went live anywhere, so
      // adding a marketplace must not reset the clock.
      expect(saved!.listedAt, firstListed);
      expect(saved.status, ItemStatus.listed);
      expect(saved.askingPrice, const Money(4000, 'USD'));
    });

    test('an empty selection writes nothing', () async {
      final ProviderContainer container = mockContainer();
      final Item coat = item(id: 'x-4');

      await container.read(itemRepositoryProvider).save(coat);
      await container
          .read(itemActionsControllerProvider.notifier)
          .crossList(
            coat,
            marketplaces: const <Marketplace>{},
            price: const Money(1000, 'USD'),
          );

      expect(await listingsFor(container, 'x-4'), isEmpty);
    });
  });

  group('the screen', () {
    // `itm-4` in the seeded dataset is listed on eBay and Depop already, at
    // an asking price of 185.00 — the exact shape cross-listing is for.
    testWidgets('marks the marketplaces the item is already on', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const CrossListScreen(itemId: 'itm-4'));

      expect(find.text('Already on'), findsNWidgets(2));
    });

    testWidgets('inherits the price and refuses to publish to nothing', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const CrossListScreen(itemId: 'itm-4'));

      expect(find.text('185.00'), findsOneWidget);

      // A price alone is not a cross-listing: §28 requires at least one
      // marketplace, and the button says so by being dead.
      final SdButtonV3 publish = tester.widget<SdButtonV3>(
        find.byType(SdButtonV3),
      );

      expect(publish.onPressed, isNull);
    });

    testWidgets('picking a marketplace reviews its fee and arms publish', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const CrossListScreen(itemId: 'itm-4'));

      await tester.tap(find.text('Etsy'));
      await tester.pumpAndSettle();

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Publish to 1 marketplace'), findsOneWidget);
      expect(
        tester.widget<SdButtonV3>(find.byType(SdButtonV3)).onPressed,
        isNotNull,
      );
    });
  });
}
