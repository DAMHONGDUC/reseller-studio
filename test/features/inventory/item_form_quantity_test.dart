import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/domain/services/item_transition.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_form_controller.dart';
import 'package:reseller_studio/features/inventory/providers.dart';

import '../../support/pump_app.dart';

/// **Quantity is what decides whether a record is sold** — owner's rule. The
/// form is the other half of it: a sold row given stock again is a seller
/// saying they have the thing.
void main() {
  Future<Item> saved(ProviderContainer container, String id) async {
    // The repository writes to a broadcast stream, so the list has to be read
    // after the write has been given a turn.
    await Future<void>.delayed(Duration.zero);

    return container
        .read(itemsProvider)
        .value!
        .firstWhere((Item item) => item.id == id);
  }

  test('putting stock behind a sold item puts it back on the shelf', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item sold = await saved(container, 'itm-1');

    expect(sold.status, ItemStatus.sold, reason: 'the fixture must start sold');

    final ItemFormController form = container.read(
      itemFormControllerProvider.notifier,
    );

    form.seed(sold);
    await form.submit(title: sold.title, quantity: '5');

    final Item restocked = await saved(container, 'itm-1');

    expect(restocked.status, ItemStatus.inStock);
    expect(restocked.quantity, 5);
    // The sale is undone with it: a row on the shelf carrying a sold date is
    // one every export reads as sold.
    expect(restocked.soldAt, isNull);
  });

  test('the seller can put a draft on the shelf from the form', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item draft = await saved(container, 'itm-10');
    final ItemFormController form = container.read(
      itemFormControllerProvider.notifier,
    );

    expect(draft.status, ItemStatus.draft, reason: 'the fixture starts draft');

    form.seed(draft);

    expect(form.checkStatus(ItemStatus.inStock, quantity: '1').isAllowed, true);

    form.selectStatus(ItemStatus.inStock);
    await form.submit(title: draft.title, quantity: '1');

    expect((await saved(container, 'itm-10')).status, ItemStatus.inStock);
  });

  test('an empty shelf cannot be moved anywhere', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item sold = await saved(container, 'itm-1');
    final ItemFormController form = container.read(
      itemFormControllerProvider.notifier,
    );

    form.seed(sold);

    // Nothing to move: the same requirement the actions sheet enforces, and
    // the reason Restock exists — it puts stock behind the row first.
    expect(
      form.checkStatus(ItemStatus.archived, quantity: '0').blocks,
      contains(ItemTransitionBlock.noQuantity),
    );
  });

  test('sold can be set by hand, and takes the count with it', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item onShelf = await saved(container, 'itm-11');
    final ItemFormController form = container.read(
      itemFormControllerProvider.notifier,
    );

    form.seed(onShelf);

    expect(
      form
          .checkStatus(ItemStatus.sold, quantity: '2', askingPrice: '42.00')
          .isAllowed,
      isTrue,
    );

    form.selectStatus(ItemStatus.sold);
    await form.submit(title: onShelf.title, quantity: '2', askingPrice: '42');

    final Item sold = await saved(container, 'itm-11');

    // Sold means sold out however it was reached, so the count goes with the
    // status — otherwise the card would offer two left of something gone.
    expect(sold.status, ItemStatus.sold);
    expect(sold.quantity, 0);
    expect(sold.soldAt, isNotNull);
  });

  test('editing an item keeps the timestamps it was not asked about', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item listed = await saved(container, 'itm-4');
    final ItemFormController form = container.read(
      itemFormControllerProvider.notifier,
    );

    expect(listed.listedAt, isNotNull);

    form.seed(listed);
    await form.submit(title: 'Renamed', quantity: '${listed.quantity}');

    final Item edited = await saved(container, 'itm-4');

    // `submit` builds a whole item, so a timestamp the form does not carry is
    // one that fixing a typo erases — the staleness clock with it.
    expect(edited.title, 'Renamed');
    expect(edited.listedAt, listed.listedAt);
    expect(edited.status, listed.status);
  });
}
