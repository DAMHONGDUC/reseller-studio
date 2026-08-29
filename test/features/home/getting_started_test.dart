import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/home/domain/enums/getting_started_step.dart';
import 'package:reseller_studio/features/home/domain/services/getting_started_progress.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/domain/enums/order_status.dart';

import '../../support/pump_app.dart';

/// The checklist is a progress report, so a later step ticks the earlier ones.
///
/// A seller can reach a sale this app never saw listed — marked sold straight
/// off the shelf, or an order imported — and "sale recorded" sitting above an
/// unticked "list it" reads as a broken checklist rather than a flexible one.
void main() {
  Item item(ItemStatus status, {DateTime? listedAt}) => Item(
    id: 'i-1',
    title: 'A jacket',
    status: status,
    quantity: 1,
    createdAt: testNow,
    listedAt: listedAt,
  );

  Order order() => Order(
    id: 'o-1',
    status: OrderStatus.delivered,
    marketplace: Marketplace.ebay,
    lines: const <OrderLine>[],
    salePrice: const Money(4500, 'USD'),
    orderedAt: testNow,
  );

  Set<GettingStartedStep> progress({
    List<Item> items = const <Item>[],
    List<Listing> listings = const <Listing>[],
    List<Order> orders = const <Order>[],
  }) => GettingStartedProgress.completed(
    items: items,
    listings: listings,
    orders: orders,
  );

  test('an untouched workspace has done none of it', () {
    expect(progress(), isEmpty);
  });

  test('a draft item ticks only the first step', () {
    expect(
      progress(items: <Item>[item(ItemStatus.draft)]),
      <GettingStartedStep>{GettingStartedStep.addItem},
    );
  });

  test('an item that reached a marketplace ticks the first two', () {
    expect(
      // `listed` stopped being a status; the clock it left behind is the
      // proof that the item reached a platform.
      progress(items: <Item>[item(ItemStatus.inStock, listedAt: testNow)]),
      <GettingStartedStep>{
        GettingStartedStep.addItem,
        GettingStartedStep.listItem,
      },
    );
  });

  test('a sold item counts as listed, even with no listing document', () {
    expect(progress(items: <Item>[item(ItemStatus.sold)]), <GettingStartedStep>{
      GettingStartedStep.addItem,
      GettingStartedStep.listItem,
    });
  });

  test('an order ticks everything, however the seller got there', () {
    expect(
      progress(orders: <Order>[order()]),
      GettingStartedStep.values.toSet(),
      reason: 'a business with a sale is past the checklist entirely',
    );
  });
}
