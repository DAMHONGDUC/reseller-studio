import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
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
