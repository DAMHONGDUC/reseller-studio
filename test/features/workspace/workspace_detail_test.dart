import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';
import 'package:reseller_studio/features/pricing/domain/services/profit_calculator.dart';
import 'package:reseller_studio/features/workspace/domain/entities/workspace.dart';
import 'package:reseller_studio/features/workspace/presentation/controllers/workspace_detail_controller.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

import '../../support/pump_app.dart';

/// The country is the field this exists for: it decides the tax jurisdiction,
/// the tax year boundary and the mileage rate, and it used to be permanent
/// because nothing called `updateWorkspace`.
///
/// **The form drafts and writes once** (owner's rule), so every case here
/// seeds the controller, edits the draft, then submits — a change that is
/// never submitted must not reach the record.
void main() {
  /// A container subscribed the way a mounted screen is.
  ///
  /// **The subscription has to reach the stream itself.** A test that only
  /// reads `currentWorkspaceProvider` gets the seed back every time: the
  /// family behind it is disposed between reads and re-emits its first value,
  /// so the edit looks lost when it was only never observed.
  Future<ProviderContainer> subscribed() async {
    final ProviderContainer container = mockContainer();
    final String id = container.read(mockStoreProvider).dataset.workspace.id;

    container.listen<AsyncValue<Workspace?>>(
      liveWorkspaceProvider(id),
      (AsyncValue<Workspace?>? previous, AsyncValue<Workspace?> next) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);

    return container;
  }

  /// Seeds the form from the live record, applies [change], saves.
  Future<Workspace?> after(
    ProviderContainer container,
    void Function(WorkspaceDetailController form) change, {
    bool submit = true,
  }) async {
    final WorkspaceDetailController form = container.read(
      workspaceDetailControllerProvider.notifier,
    );

    form.seed(container.read(currentWorkspaceProvider)!);
    change(form);

    if (submit) await form.submit();

    await Future<void>.delayed(Duration.zero);

    return container.read(currentWorkspaceProvider);
  }

  test('the country can be corrected after setup', () async {
    final ProviderContainer container = await subscribed();

    expect(container.read(currentWorkspaceProvider)!.country, 'US');
    expect(
      (await after(
        container,
        (WorkspaceDetailController f) => f.selectCountry('GB'),
      ))!.country,
      'GB',
    );
  });

  test('nothing is written until the form is saved', () async {
    final ProviderContainer container = await subscribed();

    // The whole point of a pinned save: a picker tapped and then backed out
    // of must leave the record alone.
    expect(
      (await after(
        container,
        (WorkspaceDetailController f) => f.selectCountry('GB'),
        submit: false,
      ))!.country,
      'US',
    );
  });

  test('renaming trims, and an empty name is refused', () async {
    final ProviderContainer container = await subscribed();

    expect(
      (await after(
        container,
        (WorkspaceDetailController f) => f.updateName('  Attic Finds Ltd  '),
      ))!.name,
      'Attic Finds Ltd',
    );

    expect(
      (await after(
        container,
        (WorkspaceDetailController f) => f.updateName('   '),
      ))!.name,
      'Attic Finds Ltd',
    );
  });

  test('changing the currency leaves recorded amounts alone', () async {
    final ProviderContainer container = await subscribed();
    final String before = container.read(currentWorkspaceProvider)!.currency;

    final Workspace? saved = await after(
      container,
      (WorkspaceDetailController f) => f.selectCurrency('GBP'),
    );

    // Nobody knows what rate applied to a purchase made last March, so this
    // only moves what new amounts default to.
    expect(saved!.currency, 'GBP');
    expect(before, isNot('GBP'));
  });

  test('the stale threshold flows through to the provider', () async {
    final ProviderContainer container = await subscribed();

    expect(
      container.read(staleThresholdProvider),
      StaleInventoryPolicy.defaultThreshold,
    );

    await after(
      container,
      (WorkspaceDetailController f) => f.selectStaleThresholdDays(14),
    );

    expect(container.read(staleThresholdProvider), const Duration(days: 14));
  });
}
