import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_config.dart';
import 'package:reseller_studio/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:reseller_studio/features/app_config/providers.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_allowance.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_feature.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';
import 'package:reseller_studio/features/subscription/providers.dart';

/// One flag decides whether the plan system applies at all, and every gate in
/// the app already asks `currentPlanProvider` — so this pins that the switch
/// reaches them through that one answer rather than through a flag threaded
/// into each of them.
class _FixedConfig implements AppConfigRepository {
  const _FixedConfig({required this.premiumEnabled});

  final bool premiumEnabled;

  @override
  Stream<AppConfig> watch() =>
      Stream<AppConfig>.value(
        AppConfig(premiumEnabled: premiumEnabled),
      );
}

void main() {
  ProviderContainer containerWith({required bool premiumEnabled}) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appConfigRepositoryProvider.overrideWithValue(
          _FixedConfig(premiumEnabled: premiumEnabled),
        ),
      ],
    );

    addTearDown(container.dispose);
    container.listen<AsyncValue<AppConfig>>(
      appConfigProvider,
      (AsyncValue<AppConfig>? previous, AsyncValue<AppConfig> next) {},
      fireImmediately: true,
    );

    return container;
  }

  test('the fallback keeps monetisation on', () {
    // Nothing overridden: no document, no stream, no signal — every one of
    // those lands on the fallback, and the fallback must not give the app
    // away.
    final ProviderContainer container = ProviderContainer();

    addTearDown(container.dispose);

    expect(AppConfig.fallback.premiumEnabled, isTrue);
    expect(container.read(premiumEnabledProvider), isTrue);
  });

  test('switched off, every seller reads as Premium', () async {
    final ProviderContainer container = containerWith(premiumEnabled: false);

    await Future<void>.delayed(Duration.zero);

    expect(container.read(premiumEnabledProvider), isFalse);
    expect(container.read(currentPlanProvider), SellerPlan.premium);
  });

  test('switched off, no ceiling blocks and no capability is locked', () async {
    final ProviderContainer container = containerWith(premiumEnabled: false);

    await Future<void>.delayed(Duration.zero);

    final SellerPlan plan = container.read(currentPlanProvider);

    for (final PlanAllowance allowance in PlanAllowance.values) {
      expect(
        allowance.ceilingIn(container.read(currentLimitsProvider)),
        isNull,
        reason: '${allowance.name} must have no ceiling with the switch off',
      );
    }

    for (final PlanFeature feature in PlanFeature.values) {
      expect(
        PlanGate.has(plan, feature),
        isTrue,
        reason: '${feature.name} must be included with the switch off',
      );
    }
  });

  test('switched on, the plan is whatever the seller actually has', () async {
    final ProviderContainer container = containerWith(premiumEnabled: true);

    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentPlanProvider), SellerPlan.free);
    expect(container.read(currentLimitsProvider).items, isNotNull);
  });
}
