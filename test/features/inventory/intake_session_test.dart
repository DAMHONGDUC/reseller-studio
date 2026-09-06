import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/presentation/controllers/intake_session_controller.dart';
import 'package:reseller_studio/features/inventory/providers.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/purchase.dart';
import 'package:reseller_studio/features/sourcing/providers.dart';

import '../../support/pump_app.dart';

/// The flow that feeds every profit figure in the app.
///
/// A cost nobody entered makes profit unknowable (hard rule 5), and the only
/// moment a reseller knows what they paid for the jumper is the moment they
/// are standing in the shop. What these pin is that the loop writes as it
/// goes — so an abandoned trip still leaves the costs — and that it leaves no
/// purchase behind when the seller walks away mid-session.
void main() {
  const String usd = 'USD';

  Future<List<Item>> itemsIn(ProviderContainer container) async =>
      container.read(itemsProvider).value ?? const <Item>[];

  Future<List<Purchase>> purchasesIn(ProviderContainer container) async =>
      container.read(purchasesProvider).value ?? const <Purchase>[];

  test('each line is written as it is typed, not held in a basket', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final int before = (await itemsIn(container)).length;
    final IntakeSessionController controller = container.read(
      intakeSessionControllerProvider.notifier,
    );

    await controller.add(title: 'Levi 501', cost: Money(1200, usd));
    await controller.add(title: 'Nike windbreaker', cost: Money(500, usd));

    expect(await itemsIn(container), hasLength(before + 2));
    expect(container.read(intakeSessionControllerProvider).count, 2);
  });

  test('an abandoned session leaves the items and no purchase', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final int purchasesBefore = (await purchasesIn(container)).length;

    await container
        .read(intakeSessionControllerProvider.notifier)
        .add(title: 'Wool coat', cost: Money(800, usd));

    // The item is safe; the trip was never closed, so there is no record of
    // a trip. A purchase written up front would be a document about a visit
    // that did not happen.
    expect(
      (await itemsIn(container)).where((Item i) => i.title == 'Wool coat'),
      hasLength(1),
    );
    expect(await purchasesIn(container), hasLength(purchasesBefore));
  });

  test('finishing writes one purchase and points every item at it', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final int purchasesBefore = (await purchasesIn(container)).length;
    final IntakeSessionController controller = container.read(
      intakeSessionControllerProvider.notifier,
    );

    await controller.add(title: 'Cord jacket', cost: Money(1500, usd));
    await controller.add(title: 'Denim shirt');
    await controller.finish(receiptTotal: Money(2000, usd));
    // The mock repositories publish on a broadcast stream, so the provider
    // holds the previous value until the microtask queue drains.
    await Future<void>.delayed(Duration.zero);

    final List<Purchase> purchases = await purchasesIn(container);
    final Purchase written = purchases.firstWhere(
      (Purchase p) => p.itemCount == 2,
    );

    expect(purchases, hasLength(purchasesBefore + 1));
    // The receipt, not the sum of the lines. `Purchase.totalCost` is the one
    // field allowed to disagree with its items — a box lot apportioned by
    // judgement is the case it exists for.
    expect(written.totalCost, Money(2000, usd));

    final List<Item> linked = (await itemsIn(
      container,
    )).where((Item item) => item.purchaseId == written.id).toList();

    expect(linked, hasLength(2));
    expect(container.read(intakeSessionControllerProvider).isFinished, isTrue);
  });

  test('a line with no cost is unknown, never free', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final IntakeSessionController controller = container.read(
      intakeSessionControllerProvider.notifier,
    );

    await controller.add(title: 'Boots', cost: Money(2500, usd));
    await controller.add(title: 'Scarf');

    // The running total sums what is known and does not read the blank box
    // as zero — that would claim the scarf was free (hard rule 4).
    expect(
      container.read(intakeSessionControllerProvider).knownTotal,
      Money(2500, usd),
    );
    expect(
      (await itemsIn(
        container,
      )).firstWhere((Item i) => i.title == 'Scarf').purchasePrice,
      isNull,
    );
  });

  test('a blank title writes nothing', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final int before = (await itemsIn(container)).length;

    expect(
      await container
          .read(intakeSessionControllerProvider.notifier)
          .add(title: '   '),
      isFalse,
    );
    expect(await itemsIn(container), hasLength(before));
  });
}
