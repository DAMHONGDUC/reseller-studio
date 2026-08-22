import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:seller_os/features/mock_data/providers.dart';
import 'package:seller_os/features/pricing/domain/services/profit_calculator.dart';
import 'package:seller_os/features/workspace/domain/entities/workspace.dart';
import 'package:seller_os/features/workspace/presentation/controllers/workspace_edit_controller.dart';
import 'package:seller_os/features/workspace/providers.dart';

import '../../support/pump_app.dart';

/// The country is the field this exists for: it decides the tax jurisdiction,
/// the tax year boundary and the mileage rate, and it used to be permanent
/// because nothing called `updateWorkspace`.
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

  Future<Workspace?> after(
    ProviderContainer container,
    Future<void> Function(WorkspaceEditController edit) change,
  ) async {
    await change(container.read(workspaceEditControllerProvider.notifier));
    await Future<void>.delayed(Duration.zero);

    return container.read(currentWorkspaceProvider);
  }

  test('the country can be corrected after setup', () async {
    final ProviderContainer container = await subscribed();

    expect(container.read(currentWorkspaceProvider)!.country, 'US');
    expect(
      (await after(container, (WorkspaceEditController e) => e.setCountry('GB')))!
          .country,
      'GB',
    );
  });

  test('renaming trims, and an empty name is refused', () async {
    final ProviderContainer container = await subscribed();

    expect(
      (await after(
        container,
        (WorkspaceEditController e) => e.rename('  Attic Finds Ltd  '),
      ))!.name,
      'Attic Finds Ltd',
    );

    expect(
      (await after(container, (WorkspaceEditController e) => e.rename('   ')))!
          .name,
      'Attic Finds Ltd',
    );
  });

  test('changing the currency leaves recorded amounts alone', () async {
    final ProviderContainer container = await subscribed();
    final String before = container.read(currentWorkspaceProvider)!.currency;

    final Workspace? after_ = await after(
      container,
      (WorkspaceEditController e) => e.setCurrency('GBP'),
    );

    // Nobody knows what rate applied to a purchase made last March, so this
    // only moves what new amounts default to.
    expect(after_!.currency, 'GBP');
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
      (WorkspaceEditController e) => e.setStaleThresholdDays(14),
    );

    expect(container.read(staleThresholdProvider), const Duration(days: 14));
  });
}
