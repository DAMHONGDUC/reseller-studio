import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/widgets/money_field.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/domain/services/item_transition.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_actions_controller.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_card.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/listings/presentation/controllers/cross_list_controller.dart';
import 'package:reseller_studio/features/listings/presentation/screens/cross_list_screen/cross_list_screen.dart';
import 'package:reseller_studio/features/listings/providers.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// Listing (plan §13) — one item onto one or several marketplaces at once.
///
/// **There is one List row, not a `List` sheet beside a `Cross-list` row.**
/// The two read as the same verb, and the narrower one was gated on
/// `check(item, listed)` — which refuses an item already on a marketplace,
/// the exact item the other one existed for. So the first thing it did after
/// a seller's first listing was refuse and point at nothing.
void main() {
  Item item({
    required String id,
    ItemStatus status = ItemStatus.inStock,
    Money? asking,
    DateTime? listedAt,
    int quantity = 1,
  }) => Item(
    id: id,
    title: 'Wool coat',
    quantity: quantity,
    status: status,
    createdAt: testNow,
    askingPrice: asking,
    listedAt: listedAt,
  );

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

  group('what may be cross-listed', () {
    test('an item already listed may be — that is the whole point', () {
      // `check(item, listed)` refuses this one as `wrongStatus`, which is why
      // cross-listing has its own check: it is on eBay and the seller wants
      // Depop as well.
      expect(
        ItemTransition.crossListCheck(
          item(id: 'i-1', status: ItemStatus.inStock),
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
          ItemTransition.crossListCheck(item(id: 'i-3', status: status)).blocks,
          contains(ItemTransitionBlock.wrongStatus),
        );
      }
    });
  });

  group('publishing', () {
    test('writes one draft listing per marketplace, at one price', () async {
      final ProviderContainer container = mockContainer();
      final Item coat = item(id: 'x-1');

      await container.read(itemRepositoryProvider).save(coat);
      await container
          .read(itemActionsControllerProvider.notifier)
          .crossList(
            coat,
            prices: const <Marketplace, Money>{
              Marketplace.ebay: Money(4500, 'USD'),
              Marketplace.depop: Money(4500, 'USD'),
            },
            askingPrice: const Money(4500, 'USD'),
          );

      final List<Listing> listings = await listingsFor(container, 'x-1');

      expect(listings, hasLength(2));
      expect(listings.map((Listing l) => l.marketplace).toSet(), <Marketplace>{
        Marketplace.ebay,
        Marketplace.depop,
      });
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
            prices: const <Marketplace, Money>{
              Marketplace.etsy: Money(3000, 'USD'),
            },
            askingPrice: const Money(3000, 'USD'),
          );

      final Item? saved = await container
          .read(itemRepositoryProvider)
          .watchItem('x-2')
          .first;

      // Going live is not a status any more: what it changes is the clock,
      // and a draft becoming stock the seller is selling.
      expect(saved!.status, ItemStatus.inStock);
      expect(saved.askingPrice, const Money(3000, 'USD'));
      expect(saved.listedAt, isNotNull);
    });

    test(
      'leaves an already-listed item where it is, including listedAt',
      () async {
        final ProviderContainer container = mockContainer();
        final DateTime firstListed = testNow.subtract(const Duration(days: 40));
        final Item coat = item(
          id: 'x-3',
          status: ItemStatus.inStock,
          asking: const Money(5000, 'USD'),
          listedAt: firstListed,
        );

        await container.read(itemRepositoryProvider).save(coat);
        await container
            .read(itemActionsControllerProvider.notifier)
            .crossList(
              coat,
              prices: const <Marketplace, Money>{
                Marketplace.poshmark: Money(4000, 'USD'),
              },
              askingPrice: const Money(4000, 'USD'),
            );

        final Item? saved = await container
            .read(itemRepositoryProvider)
            .watchItem('x-3')
            .first;

        // Staleness is measured from the first time it went live anywhere, so
        // adding a marketplace must not reset the clock.
        expect(saved!.listedAt, firstListed);
        expect(saved.status, ItemStatus.inStock);
        expect(saved.askingPrice, const Money(4000, 'USD'));
      },
    );

    test('an empty selection writes nothing', () async {
      final ProviderContainer container = mockContainer();
      final Item coat = item(id: 'x-4');

      await container.read(itemRepositoryProvider).save(coat);
      await container
          .read(itemActionsControllerProvider.notifier)
          .crossList(
            coat,
            prices: const <Marketplace, Money>{},
            askingPrice: const Money(1000, 'USD'),
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

    testWidgets('the live listings arrive priced, and change nothing yet', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const CrossListScreen(itemId: 'itm-4'));

      // The shared seed plus a field on each of the two live rows.
      expect(find.byType(MoneyField), findsNWidgets(3));

      // Nothing has been added and no price has moved, so there is nothing to
      // save and the button says so by being dead.
      expect(
        tester.widget<SdButtonV3>(find.byType(SdButtonV3)).onPressed,
        isNull,
      );
    });

    testWidgets('picking a marketplace opens its own price field, seeded', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const CrossListScreen(itemId: 'itm-4'));

      await tester.tap(find.text('Etsy'));
      await tester.pumpAndSettle();

      expect(find.byType(MoneyField), findsNWidgets(4));
      expect(find.text('Save 1 marketplace'), findsOneWidget);
      expect(
        tester.widget<SdButtonV3>(find.byType(SdButtonV3)).onPressed,
        isNotNull,
        reason: 'the row was seeded from the shared price, so it can save',
      );
    });

    testWidgets('changing a live listing’s price arms save on its own', (
      WidgetTester tester,
    ) async {
      // Owner's rule: an item already on a marketplace comes here to have its
      // price changed, and that alone is a reason to save.
      await pumpScreen(tester, const CrossListScreen(itemId: 'itm-4'));

      // The last field on screen belongs to the second live row; typing into
      // it is a seller changing what that platform charges.
      await tester.enterText(
        find.descendant(
          of: find.byType(MoneyField).last,
          matching: find.byType(EditableText),
        ),
        '150',
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<SdButtonV3>(find.byType(SdButtonV3)).onPressed,
        isNotNull,
      );
      expect(find.text('Save 1 marketplace'), findsOneWidget);
    });

    testWidgets('a marketplace the item is already on is ticked', (
      WidgetTester tester,
    ) async {
      // `itm-4` is on eBay and Depop already. An empty circle beside a
      // platform the item is live on is simply wrong.
      await pumpScreen(tester, const CrossListScreen(itemId: 'itm-4'));

      final Finder ebayRow = find.ancestor(
        of: find.text('eBay'),
        matching: find.byType(Row),
      );

      expect(
        tester
            .widgetList<SdIconV3>(
              find.descendant(
                of: ebayRow.first,
                matching: find.byType(SdIconV3),
              ),
            )
            .any((SdIconV3 icon) => icon.fill == 1),
        isTrue,
      );
    });
  });

  group('one List row, not two verbs meaning the same thing', () {
    testWidgets('the actions sheet offers List and no Cross-list', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const InventoryScreen());
      await tester.tap(
        find
            .descendant(
              of: find.byType(ItemCard),
              matching: find.byTooltip('Actions'),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Marketplaces management'), findsOneWidget);
      expect(find.text('Cross-list'), findsNothing);
    });

    test('the row is gated by crossListCheck, so a sold row is the only one '
        'it refuses', () {
      final Item onShelf = item(id: 'i-listed', status: ItemStatus.inStock);
      final Item sold = item(
        id: 'i-sold',
        status: ItemStatus.sold,
        quantity: 0,
      );

      expect(ItemTransition.crossListCheck(onShelf).isAllowed, isTrue);
      expect(
        ItemTransition.crossListCheck(sold).isAllowed,
        isFalse,
        reason: 'an item that has left inventory cannot be put on a platform',
      );
    });
  });

  group('a price per marketplace', () {
    CrossListState state({
      Set<Marketplace> selected = const <Marketplace>{},
      Money? price,
      Map<Marketplace, Money> prices = const <Marketplace, Money>{},
    }) => CrossListState(selected: selected, price: price, prices: prices);

    test('a row not ticked yet reads the shared seed', () {
      final CrossListState current = state(
        price: const Money(4500, 'USD'),
        selected: <Marketplace>{Marketplace.depop},
        prices: const <Marketplace, Money>{
          Marketplace.depop: Money(4000, 'USD'),
        },
      );

      expect(current.priceFor(Marketplace.ebay), const Money(4500, 'USD'));
      expect(current.priceFor(Marketplace.depop), const Money(4000, 'USD'));
    });

    test('a ticked row with an emptied field holds publish closed', () {
      // Falling back to the seed here would list at a number the seller had
      // just deleted.
      expect(
        state(
          selected: <Marketplace>{Marketplace.depop},
          price: const Money(4500, 'USD'),
        ).canPublish,
        isFalse,
      );
      expect(
        state(
          selected: <Marketplace>{Marketplace.depop},
          price: const Money(4500, 'USD'),
          prices: const <Marketplace, Money>{
            Marketplace.depop: Money(4000, 'USD'),
          },
        ).canPublish,
        isTrue,
      );
    });

    test('ticking seeds the row from the shared price', () {
      final ProviderContainer container = mockContainer();
      final CrossListController controller = container.read(
        crossListControllerProvider.notifier,
      );

      controller.setPrice(const Money(4500, 'USD'));
      controller.toggle(Marketplace.etsy);

      // The common case — one number everywhere — must still be no typing.
      expect(
        container.read(crossListControllerProvider).prices[Marketplace.etsy],
        const Money(4500, 'USD'),
      );
    });

    test('unticking drops the price that row was given', () {
      final ProviderContainer container = mockContainer();
      final CrossListController controller = container.read(
        crossListControllerProvider.notifier,
      );

      controller.setPrice(const Money(4500, 'USD'));
      controller.toggle(Marketplace.etsy);
      controller.setPriceFor(Marketplace.etsy, const Money(2500, 'USD'));
      controller.toggle(Marketplace.etsy);
      controller.toggle(Marketplace.etsy);

      // Back on the shared seed, not on the 2500 nobody chose this time.
      expect(
        container.read(crossListControllerProvider).prices[Marketplace.etsy],
        const Money(4500, 'USD'),
      );
    });

    test('each listing is written at its own price', () async {
      final ProviderContainer container = mockContainer();
      final Item coat = item(id: 'x-5');

      await container.read(itemRepositoryProvider).save(coat);
      await container
          .read(itemActionsControllerProvider.notifier)
          .crossList(
            coat,
            prices: const <Marketplace, Money>{
              Marketplace.ebay: Money(4500, 'USD'),
              Marketplace.depop: Money(4000, 'USD'),
            },
            askingPrice: const Money(4500, 'USD'),
          );

      final Map<Marketplace, Money> written = <Marketplace, Money>{
        for (final Listing listing in await listingsFor(container, 'x-5'))
          listing.marketplace: listing.price,
      };

      expect(written, <Marketplace, Money>{
        Marketplace.ebay: const Money(4500, 'USD'),
        Marketplace.depop: const Money(4000, 'USD'),
      });
    });

    test('the item keeps the shared price, not one platform’s', () async {
      final ProviderContainer container = mockContainer();
      final Item coat = item(id: 'x-6');

      await container.read(itemRepositoryProvider).save(coat);
      await container
          .read(itemActionsControllerProvider.notifier)
          .crossList(
            coat,
            prices: const <Marketplace, Money>{
              Marketplace.ebay: Money(4500, 'USD'),
              Marketplace.depop: Money(4000, 'USD'),
            },
            askingPrice: const Money(4500, 'USD'),
          );

      final Item? saved = await container
          .read(itemRepositoryProvider)
          .watchItem('x-6')
          .first;

      // What the item is worth is not whichever platform was cheapest.
      expect(saved!.askingPrice, const Money(4500, 'USD'));
    });
  });
}
