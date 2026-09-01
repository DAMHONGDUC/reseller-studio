import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/filters/date_range_filter.dart';
import 'package:reseller_studio/core/filters/presence_filter.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item_filter_criteria.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/item_filter_constant.dart';

/// What Inventory's filter sheet asks of an item, and what it tells the
/// seller it is asking.
void main() {
  final DateTime now = DateTime(2026, 8, 31);

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
      expect(ItemFilterCriteria.none.matches(itemWith(), now: now), isTrue);
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
        criteria.matches(itemWith(categoryId: 'cat-1'), now: now),
        isTrue,
      );
      expect(
        criteria.matches(itemWith(categoryId: 'cat-2'), now: now),
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

      expect(named.matches(itemWith(), now: now), isFalse);
      expect(unassigned.matches(itemWith(), now: now), isTrue);
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

      expect(missing.matches(itemWith(), now: now), isTrue);
      expect(recorded.matches(itemWith(), now: now), isFalse);
      expect(
        recorded.matches(
          itemWith(purchasePrice: const Money(1000, 'USD')),
          now: now,
        ),
        isTrue,
      );
    });

    test('never listed reads listedAt, not the status', () {
      const ItemFilterCriteria never = ItemFilterCriteria(
        listed: PresenceFilter.absent,
      );

      expect(never.matches(itemWith(), now: now), isTrue);
      expect(
        never.matches(itemWith(listedAt: DateTime(2026, 7, 1)), now: now),
        isFalse,
      );
    });

    test('photos are counted, not assumed from the record existing', () {
      const ItemFilterCriteria withPhotos = ItemFilterCriteria(
        photos: PresenceFilter.present,
      );

      expect(withPhotos.matches(itemWith(), now: now), isFalse);
      expect(
        withPhotos.matches(
          itemWith(photoUrls: const <String>['a.jpg']),
          now: now,
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
        lastWeek.matches(itemWith(createdAt: DateTime(2026, 8, 30)), now: now),
        isTrue,
      );
      expect(
        lastWeek.matches(itemWith(createdAt: DateTime(2026, 8, 1)), now: now),
        isFalse,
      );
    });
  });

  group('activeCount', () {
    test('counts groups, not chips', () {
      const ItemFilterCriteria criteria = ItemFilterCriteria(
        statuses: <ItemStatus>{ItemStatus.draft, ItemStatus.inStock},
        categoryIds: <String>{'cat-1', 'cat-2', 'cat-3'},
      );

      expect(criteria.activeCount, 2);
    });
  });
}
