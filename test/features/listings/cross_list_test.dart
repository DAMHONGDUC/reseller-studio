import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
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
  }) => Item(
    id: id,
    title: 'Wool coat',
    quantity: 1,
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
      (
        AsyncValue<List<Listing>>? previous,
        AsyncValue<List<Listing>> next,
      ) {},
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

      expect(saved!.status, ItemStatus.listed);
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
          status: ItemStatus.listed,
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
        expect(saved.status, ItemStatus.listed);
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

      expect(find.text('List on marketplaces'), findsOneWidget);
      expect(find.text('Cross-list'), findsNothing);
    });

    test('the row is gated by crossListCheck, so it survives the first sale '
        'listing', () {
      // The deleted `List` sheet used `check(item, listed)`, which refuses an
      // item already on a marketplace — the exact item this flow exists for.
      final Item listed = item(id: 'i-listed', status: ItemStatus.listed);

      expect(ItemTransition.crossListCheck(listed).isAllowed, isTrue);
      expect(
        ItemTransition.check(listed, ItemStatus.listed).isAllowed,
        isFalse,
        reason: 'the old gate would have refused it, which was the bug',
      );
    });
  });

  group('a price per marketplace', () {
    CrossListState state({
      Set<Marketplace> selected = const <Marketplace>{},
      Money? price,
      Map<Marketplace, Money> overrides = const <Marketplace, Money>{},
    }) => CrossListState(
      selected: selected,
      price: price,
      overrides: overrides,
    );

    test('a platform with no price of its own takes the shared one', () {
      final CrossListState current = state(
        selected: <Marketplace>{Marketplace.ebay, Marketplace.depop},
        price: const Money(4500, 'USD'),
        overrides: const <Marketplace, Money>{
          Marketplace.depop: Money(4000, 'USD'),
        },
      );

      expect(current.priceFor(Marketplace.ebay), const Money(4500, 'USD'));
      expect(current.priceFor(Marketplace.depop), const Money(4000, 'USD'));
      expect(current.isOverridden(Marketplace.ebay), isFalse);
      expect(current.isOverridden(Marketplace.depop), isTrue);
    });

    test('an override alone is enough to publish to that platform', () {
      // The shared box is empty, so eBay has nothing — but Depop was priced
      // deliberately, and a form that refused it would be asking twice.
      expect(
        state(
          selected: <Marketplace>{Marketplace.depop},
          overrides: const <Marketplace, Money>{
            Marketplace.depop: Money(4000, 'USD'),
          },
        ).canPublish,
        isTrue,
      );
      expect(
        state(
          selected: <Marketplace>{Marketplace.depop, Marketplace.ebay},
          overrides: const <Marketplace, Money>{
            Marketplace.depop: Money(4000, 'USD'),
          },
        ).canPublish,
        isFalse,
        reason: 'eBay still has no price of its own and no default',
      );
    });

    test('unticking a platform drops the price it was given', () {
      final ProviderContainer container = mockContainer();
      final CrossListController controller = container.read(
        crossListControllerProvider.notifier,
      );

      controller.toggle(Marketplace.etsy);
      controller.setPriceFor(Marketplace.etsy, const Money(2500, 'USD'));

      expect(
        container.read(crossListControllerProvider).isOverridden(
          Marketplace.etsy,
        ),
        isTrue,
      );

      controller.toggle(Marketplace.etsy);

      // A hidden override that came back on the next tick is a number nobody
      // chose this time.
      expect(
        container.read(crossListControllerProvider).isOverridden(
          Marketplace.etsy,
        ),
        isFalse,
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
