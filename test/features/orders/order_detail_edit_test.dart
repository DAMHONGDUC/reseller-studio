import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/orders/domain/entities/order.dart';
import 'package:reseller_studio/features/orders/presentation/controllers/order_detail_edit_controller.dart';

import '../../support/pump_app.dart';

/// Editing one block of an order in place (`docs/rules/SCREENS.md`).
///
/// **Every save re-reads the order and applies only its own section's
/// fields.** That is the whole point of the controller: a teammate shipping
/// an order while a profit draft sat open must not have that undone by the
/// save. These pin that, and the hard rule 5 half — a payout box left empty
/// is "nobody recorded it", never zero.
void main() {
  Future<ProviderContainer> withOrders() async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    return container;
  }

  Future<Order> reread(ProviderContainer container, String id) async =>
      (await container.read(orderRepositoryProvider).findById(id))!;

  OrderDetailEditController editor(ProviderContainer container) =>
      container.read(orderDetailEditControllerProvider.notifier);

  test('only one section is open at a time', () async {
    final ProviderContainer container = await withOrders();
    final Order order = await reread(container, 'ord-1');

    editor(container).edit(OrderDetailSection.order, order);

    expect(
      container
          .read(orderDetailEditControllerProvider)
          .isOpen(OrderDetailSection.order),
      isTrue,
    );

    editor(container).edit(OrderDetailSection.shipping, order);

    final OrderDetailEditState state = container.read(
      orderDetailEditControllerProvider,
    );

    expect(state.isOpen(OrderDetailSection.shipping), isTrue);
    expect(state.isOpen(OrderDetailSection.order), isFalse);

    editor(container).cancel();

    expect(container.read(orderDetailEditControllerProvider).editing, isNull);
  });

  test('saving the payout writes the measured figure and closes', () async {
    final ProviderContainer container = await withOrders();
    final Order order = await reread(container, 'ord-4');

    editor(container).edit(OrderDetailSection.profit, order);
    await editor(container).saveProfit(orderId: 'ord-4', payout: '80.00');

    expect((await reread(container, 'ord-4')).payout, const Money(8000, 'USD'));
    expect(container.read(orderDetailEditControllerProvider).editing, isNull);
  });

  test('an empty payout is unrecorded, never zero', () async {
    final ProviderContainer container = await withOrders();
    final Order order = await reread(container, 'ord-1');

    // ord-1 has been paid out. Clearing the box must leave "nobody recorded
    // it", so the statement renders `—` rather than claiming the platform
    // took the whole sale (hard rule 5).
    expect(order.payout, isNotNull);

    editor(container).edit(OrderDetailSection.profit, order);
    await editor(container).saveProfit(orderId: 'ord-1', payout: '');

    expect((await reread(container, 'ord-1')).payout, isNull);
  });

  test('a section save leaves the fields it does not own alone', () async {
    final ProviderContainer container = await withOrders();
    final Order before = await reread(container, 'ord-1');

    editor(container).edit(OrderDetailSection.profit, before);

    // A teammate ships it while the profit draft is open.
    await container
        .read(orderRepositoryProvider)
        .save(before.copyWith(trackingNumber: 'TEAMMATE-1'));

    await editor(container).saveProfit(orderId: 'ord-1', payout: '12.34');

    final Order after = await reread(container, 'ord-1');

    expect(after.payout, const Money(1234, 'USD'));
    expect(after.trackingNumber, 'TEAMMATE-1');
  });

  test('an unparseable sale price leaves the one the order carries', () async {
    final ProviderContainer container = await withOrders();
    final Order before = await reread(container, 'ord-1');

    editor(container).edit(OrderDetailSection.order, before);
    await editor(container).saveOrder(
      orderId: 'ord-1',
      buyerName: 'Someone',
      salePrice: 'not a number',
      externalOrderId: '',
    );

    // A sale with no price is not a sale.
    expect((await reread(container, 'ord-1')).salePrice, before.salePrice);
  });

  test('a save on an order that is gone closes the section quietly', () async {
    final ProviderContainer container = await withOrders();
    final Order order = await reread(container, 'ord-1');

    editor(container).edit(OrderDetailSection.profit, order);
    await editor(container).saveProfit(orderId: 'no-such-order', payout: '1');

    expect(container.read(orderDetailEditControllerProvider).editing, isNull);
    expect(container.read(orderDetailEditControllerProvider).isSaving, isFalse);
  });
}
