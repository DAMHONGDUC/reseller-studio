import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/item_form_controller.dart';
import 'package:reseller_studio/features/inventory/providers.dart';

import '../../support/pump_app.dart';

/// **Quantity and status are independent** — owner's rule. The form writes
/// exactly what it was given: a count that moves no state, and a state that
/// leaves the count alone. What cannot both be true is drawn as an alert tag
/// (`item_warning_test.dart`), never corrected behind the seller.
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

  test('putting stock behind a sold item leaves it sold', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item sold = await saved(container, 'itm-1');

    expect(sold.status, ItemStatus.sold, reason: 'the fixture must start sold');

    final ItemFormController form = container.read(
      itemFormControllerProvider.notifier,
    );

    form.seed(sold);
    await form.submit(title: sold.title, quantity: '5');

    final Item edited = await saved(container, 'itm-1');

    // A count is one answer, not two: the row says something that cannot be
    // true, and the screen says so with a tag rather than picking a status.
    expect(edited.quantity, 5);
    expect(edited.status, ItemStatus.sold);
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
    form.selectStatus(ItemStatus.inStock);
    await form.submit(title: draft.title, quantity: '1');

    expect((await saved(container, 'itm-10')).status, ItemStatus.inStock);
  });

  test('a picked status is never refused, whatever the record says', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    // Nothing on the shelf and no price: every requirement the verbs check is
    // missing, and the form takes it anyway — owner's rule, because this is
    // the screen where a seller corrects what the app got wrong.
    final Item sold = await saved(container, 'itm-1');
    final ItemFormController form = container.read(
      itemFormControllerProvider.notifier,
    );

    form.seed(sold);
    form.selectStatus(ItemStatus.archived);
    await form.submit(title: sold.title, quantity: '0');

    expect((await saved(container, 'itm-1')).status, ItemStatus.archived);
  });

  test('sold can be set by hand, and leaves the count alone', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final Item onShelf = await saved(container, 'itm-11');
    final ItemFormController form = container.read(
      itemFormControllerProvider.notifier,
    );

    form.seed(onShelf);
    form.selectStatus(ItemStatus.sold);
    await form.submit(title: onShelf.title, quantity: '2');

    final Item sold = await saved(container, 'itm-11');

    // The status is what the seller picked and the count is what they typed:
    // the app writes both as given, and `ItemConsistency` is what points out
    // that they disagree.
    expect(sold.status, ItemStatus.sold);
    expect(sold.quantity, 2);
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
