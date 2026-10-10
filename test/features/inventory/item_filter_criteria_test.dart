import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/filters/date_range_filter.dart';
import 'package:reseller_studio/core/filters/presence_filter.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item_filter_criteria.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status_filter.dart';
import 'package:reseller_studio/features/inventory/item_filter_constant.dart';
import 'package:reseller_studio/features/pricing/domain/services/profit_calculator.dart';

/// What Inventory's filter sheet asks of an item, and what it tells the
/// seller it is asking.
void main() {
  final DateTime now = DateTime(2026, 8, 31);
  const Duration threshold = StaleInventoryPolicy.defaultThreshold;

  Item itemWith({
    ItemStatus status = ItemStatus.inStock,
    ItemCondition? condition,
    String? categoryId,
    String? locationId,
    String? sourceId,
    List<String> photoUrls = const <String>[],
    Money? purchasePrice,
    Money? askingPrice,
    DateTime? listedAt,
    DateTime? createdAt,
  }) => Item(
    id: 'itm-1',
    title: 'Jacket',
    quantity: 1,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 8, 1),
    condition: condition,
    categoryId: categoryId,
    locationId: locationId,
    sourceId: sourceId,
    photoUrls: photoUrls,
    purchasePrice: purchasePrice,
    listedAt: listedAt,
  );

  group('an empty criteria', () {
    test('matches every item and counts as no filters', () {
      expect(
        ItemFilterCriteria.none.matches(
          itemWith(),
          now: now,
          staleThreshold: threshold,
        ),
        isTrue,
      );
      expect(ItemFilterCriteria.none.activeCount, 0);
      expect(ItemFilterCriteria.none.isActive, isFalse);
    });
  });

  group('id groups', () {
    test('a ticked category keeps only items in it', () {
      const ItemFilterCriteria criteria = ItemFilterCriteria(
        categoryIds: <String>{'cat-1'},
      );

      expect(
        criteria.matches(
          itemWith(categoryId: 'cat-1'),
          now: now,
          staleThreshold: threshold,
        ),
        isTrue,
      );
      expect(
        criteria.matches(
          itemWith(categoryId: 'cat-2'),
          now: now,
          staleThreshold: threshold,
        ),
        isFalse,
      );
    });

    test('an item naming no category matches only Unassigned', () {
      const ItemFilterCriteria named = ItemFilterCriteria(
        categoryIds: <String>{'cat-1'},
      );
      const ItemFilterCriteria unassigned = ItemFilterCriteria(
        categoryIds: <String>{ItemFilterConstant.unassignedId},
      );

      expect(
        named.matches(itemWith(), now: now, staleThreshold: threshold),
        isFalse,
      );
      expect(
        unassigned.matches(itemWith(), now: now, staleThreshold: threshold),
        isTrue,
      );
    });
  });

  group('presence groups', () {
    test('a missing cost is found by asking for the absence', () {
      const ItemFilterCriteria missing = ItemFilterCriteria(
        cost: PresenceFilter.absent,
      );
      const ItemFilterCriteria recorded = ItemFilterCriteria(
        cost: PresenceFilter.present,
      );

      expect(
        missing.matches(itemWith(), now: now, staleThreshold: threshold),
        isTrue,
      );
      expect(
        recorded.matches(itemWith(), now: now, staleThreshold: threshold),
        isFalse,
      );
      expect(
        recorded.matches(
          itemWith(purchasePrice: const Money(1000, 'USD')),
          now: now,
          staleThreshold: threshold,
        ),
        isTrue,
      );
    });

    test('never listed reads listedAt, not the status', () {
      const ItemFilterCriteria never = ItemFilterCriteria(
        listed: PresenceFilter.absent,
      );

      expect(
        never.matches(itemWith(), now: now, staleThreshold: threshold),
        isTrue,
      );
      expect(
        never.matches(
          itemWith(listedAt: DateTime(2026, 7, 1)),
          now: now,
          staleThreshold: threshold,
        ),
        isFalse,
      );
    });

    test('photos are counted, not assumed from the record existing', () {
      const ItemFilterCriteria withPhotos = ItemFilterCriteria(
        photos: PresenceFilter.present,
      );

      expect(
        withPhotos.matches(itemWith(), now: now, staleThreshold: threshold),
        isFalse,
      );
      expect(
        withPhotos.matches(
          itemWith(photoUrls: const <String>['a.jpg']),
          now: now,
          staleThreshold: threshold,
        ),
        isTrue,
      );
    });
  });

  group('added range', () {
    test('counts whole days back from the clock, not from today', () {
      const ItemFilterCriteria lastWeek = ItemFilterCriteria(
        added: DateRangeFilter.last7Days,
      );

      expect(
        lastWeek.matches(
          itemWith(createdAt: DateTime(2026, 8, 30)),
          now: now,
          staleThreshold: threshold,
        ),
        isTrue,
      );
      expect(
        lastWeek.matches(
          itemWith(createdAt: DateTime(2026, 8, 1)),
          now: now,
          staleThreshold: threshold,
        ),
        isFalse,
      );
    });
  });

  group('status', () {
    test('every status is an option, and Stale is the one extra', () {
      expect(
        ItemStatusFilter.values
            .map((ItemStatusFilter option) => option.status)
            .whereType<ItemStatus>()
            .toSet(),
        ItemStatus.values.toSet(),
      );
      expect(ItemStatusFilter.stale.status, isNull);
    });

    test('Stale is stock listed long ago, never a draft unlisted', () {
      const ItemFilterCriteria stale = ItemFilterCriteria(
        statuses: <ItemStatusFilter>{ItemStatusFilter.stale},
      );

      expect(
        stale.matches(
          itemWith(listedAt: DateTime(2026, 5, 1)),
          now: now,
          staleThreshold: threshold,
        ),
        isTrue,
      );
      expect(
        stale.matches(
          itemWith(listedAt: DateTime(2026, 8, 20)),
          now: now,
          staleThreshold: threshold,
        ),
        isFalse,
      );
      expect(
        stale.matches(itemWith(), now: now, staleThreshold: threshold),
        isFalse,
      );
      expect(
        stale.matches(
          itemWith(status: ItemStatus.sold, listedAt: DateTime(2026, 5, 1)),
          now: now,
          staleThreshold: threshold,
        ),
        isFalse,
      );
    });

    test('Stale follows the business threshold, not the default', () {
      const ItemFilterCriteria stale = ItemFilterCriteria(
        statuses: <ItemStatusFilter>{ItemStatusFilter.stale},
      );
      // Listed 40 days before `now`: fresh at the 60-day default, stale for a
      // business that chose 30.
      final Item item = itemWith(listedAt: DateTime(2026, 7, 22));

      expect(stale.matches(item, now: now, staleThreshold: threshold), isFalse);
      expect(
        stale.matches(item, now: now, staleThreshold: const Duration(days: 30)),
        isTrue,
      );
    });

    test('options OR with each other, Stale included', () {
      const ItemFilterCriteria criteria = ItemFilterCriteria(
        statuses: <ItemStatusFilter>{
          ItemStatusFilter.draft,
          ItemStatusFilter.stale,
        },
      );

      expect(
        criteria.matches(
          itemWith(status: ItemStatus.draft),
          now: now,
          staleThreshold: threshold,
        ),
        isTrue,
      );
      expect(
        criteria.matches(
          itemWith(listedAt: DateTime(2026, 5, 1)),
          now: now,
          staleThreshold: threshold,
        ),
        isTrue,
      );
      expect(
        criteria.matches(itemWith(), now: now, staleThreshold: threshold),
        isFalse,
      );
    });

    test('a count ignores the status group but not the others', () {
      const ItemFilterCriteria criteria = ItemFilterCriteria(
        statuses: <ItemStatusFilter>{ItemStatusFilter.sold},
        categoryIds: <String>{'cat-1'},
      );
      final Map<ItemStatusFilter, int> counts = criteria.statusCounts(
        <Item>[
          itemWith(categoryId: 'cat-1'),
          itemWith(status: ItemStatus.draft, categoryId: 'cat-1'),
          itemWith(categoryId: 'cat-2'),
        ],
        query: '',
        now: now,
        staleThreshold: threshold,
      );

      expect(counts[ItemStatusFilter.inStock], 1);
      expect(counts[ItemStatusFilter.draft], 1);
      expect(counts[ItemStatusFilter.sold], 0);
    });
  });

  group('activeCount', () {
    test('counts groups, not chips', () {
      const ItemFilterCriteria criteria = ItemFilterCriteria(
        statuses: <ItemStatusFilter>{
          ItemStatusFilter.draft,
          ItemStatusFilter.inStock,
        },
        categoryIds: <String>{'cat-1', 'cat-2', 'cat-3'},
      );

      expect(criteria.activeCount, 2);
    });
  });
}
