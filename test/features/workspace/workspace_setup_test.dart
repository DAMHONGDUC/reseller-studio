import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/config/app_env.dart';
import 'package:reseller_studio/core/error/app_failure.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/carriers/domain/entities/carrier.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item_category.dart';
import 'package:reseller_studio/features/marketplaces/domain/entities/marketplace.dart';
import 'package:reseller_studio/features/workspace/presentation/controllers/workspace_setup_controller.dart';
import 'package:reseller_studio/features/workspace/providers.dart';

import '../../support/fakes/in_memory_repositories.dart';
import '../../support/fakes/mock_dataset.dart';
import '../../support/pump_app.dart';

/// The last step of onboarding, and the gate to everything below it.
///
/// Nothing in the app is reachable without a workspace — every business
/// record carries its id (hard rule 14) — so what these pin is that the form
/// refuses to write a half-made one, and that a failure leaves the seller
/// looking at a form they can submit again rather than a dead spinner.
class _RefusingWorkspaces extends InMemoryWorkspaceRepository {
  _RefusingWorkspaces(super.store);

  @override
  Future<String> createWorkspace({
    required String name,
    required String country,
    required String currency,
    required String ownerId,
    String? ownerName,
    String? ownerEmail,
    String? businessType,
    required List<Marketplace> marketplaces,
    required List<ItemCategory> categories,
    required List<Carrier> carriers,
  }) async => throw const AppFailure(AppFailureKind.offline);
}

/// A create that records what the form handed it.
class _RecordingWorkspaces extends InMemoryWorkspaceRepository {
  _RecordingWorkspaces(super.store);

  String? name;
  String? country;
  String? currency;
  String? businessType;
  int calls = 0;

  @override
  Future<String> createWorkspace({
    required String name,
    required String country,
    required String currency,
    required String ownerId,
    String? ownerName,
    String? ownerEmail,
    String? businessType,
    required List<Marketplace> marketplaces,
    required List<ItemCategory> categories,
    required List<Carrier> carriers,
  }) async {
    calls++;
    this.name = name;
    this.country = country;
    this.currency = currency;
    this.businessType = businessType;

    return super.createWorkspace(
      name: name,
      country: country,
      currency: currency,
      ownerId: ownerId,
      marketplaces: marketplaces,
      categories: categories,
      carriers: carriers,
    );
  }
}

void main() {
  MockStore store() => MockStore(MockDataset.seed(now: testNow));

  ProviderContainer containerWith({
    required InMemoryWorkspaceRepository workspaces,
    String? uid = 'uid-1',
  }) => mockContainer(
    overrides: <Override>[
      workspaceRepositoryProvider.overrideWithValue(workspaces),
      currentUidProvider.overrideWithValue(uid),
    ],
    replaces: <Object>{workspaceRepositoryProvider},
  );

  WorkspaceSetupController form(ProviderContainer container) =>
      container.read(workspaceSetupControllerProvider.notifier);

  test('the form opens on the build defaults and refuses an empty name', () {
    final ProviderContainer container = containerWith(
      workspaces: _RecordingWorkspaces(store()),
    );
    final WorkspaceSetupState state = container.read(
      workspaceSetupControllerProvider,
    );

    expect(state.country, AppEnv.defaultCountry);
    expect(state.currency, AppEnv.defaultCurrency);
    expect(state.canSubmit, isFalse);

    // Whitespace is not a name.
    form(container).updateName('   ');

    expect(container.read(workspaceSetupControllerProvider).canSubmit, isFalse);

    form(container).updateName('Attic Finds');

    expect(container.read(workspaceSetupControllerProvider).canSubmit, isTrue);
  });

  test('submitting an empty form writes nothing', () async {
    final _RecordingWorkspaces workspaces = _RecordingWorkspaces(store());
    final ProviderContainer container = containerWith(workspaces: workspaces);

    expect(await form(container).submit(), isNull);
    expect(workspaces.calls, 0);
  });

  test('nobody signed in writes nothing either', () async {
    final _RecordingWorkspaces workspaces = _RecordingWorkspaces(store());
    final ProviderContainer container = containerWith(
      workspaces: workspaces,
      uid: null,
    );

    form(container).updateName('Attic Finds');

    // Hard rule 1: there is no workspace without an account to own it.
    expect(await form(container).submit(), isNull);
    expect(workspaces.calls, 0);
  });

  test('a submitted form writes what it was given and stops saving', () async {
    final _RecordingWorkspaces workspaces = _RecordingWorkspaces(store());
    final ProviderContainer container = containerWith(workspaces: workspaces);

    form(container)
      ..updateName('  Attic Finds  ')
      ..selectCountry('uk')
      ..selectCurrency('GBP')
      ..selectBusinessType('sole_trader');

    expect(await form(container).submit(), isNotNull);

    // Trimmed once, here, so nothing downstream stores the spaces.
    expect(workspaces.name, 'Attic Finds');
    expect(workspaces.country, 'uk');
    expect(workspaces.currency, 'GBP');
    expect(workspaces.businessType, 'sole_trader');
    expect(container.read(workspaceSetupControllerProvider).isSaving, isFalse);
  });

  test('a failed create leaves a form the seller can submit again', () async {
    final ProviderContainer container = containerWith(
      workspaces: _RefusingWorkspaces(store()),
    );

    form(container).updateName('Attic Finds');

    await expectLater(form(container).submit(), throwsA(isA<AppFailure>()));

    final WorkspaceSetupState state = container.read(
      workspaceSetupControllerProvider,
    );

    expect(state.isSaving, isFalse);
    expect(state.canSubmit, isTrue);
  });
}
