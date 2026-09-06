import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_config.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_update_policy.dart';
import 'package:reseller_studio/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:reseller_studio/features/app_config/providers.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';

/// The forced update is the one thing in the app that can stop a seller
/// working, so the cases worth pinning are the ones where it must **not**
/// fire: a build nobody has ruled out, a config that never arrived, a field
/// somebody typed wrong, a switch nobody turned on. Locking a seller out is
/// not recoverable from their side.
class _FixedConfig implements AppConfigRepository {
  const _FixedConfig(this.config);

  final AppConfig config;

  @override
  Stream<AppConfig> watch() => Stream<AppConfig>.value(config);
}

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  ProviderContainer containerWith({required AppConfig config, int build = 1}) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appConfigRepositoryProvider.overrideWithValue(_FixedConfig(config)),
        appBuildNumberProvider.overrideWith((Ref ref) async => build),
      ],
    );

    addTearDown(container.dispose);
    container.listen<AsyncValue<AppConfig>>(
      appConfigProvider,
      (AsyncValue<AppConfig>? previous, AsyncValue<AppConfig> next) {},
      fireImmediately: true,
    );
    container.listen<AsyncValue<int>>(
      appBuildNumberProvider,
      (AsyncValue<int>? previous, AsyncValue<int> next) {},
      fireImmediately: true,
    );

    return container;
  }

  AppConfig iosConfig({required bool enabled, required int buildNumber}) =>
      AppConfig(
        premiumEnabled: true,
        ios: AppUpdatePolicy(
          forceUpdateEnabled: enabled,
          buildNumber: buildNumber,
          buildName: '1.4.0',
          storeLink: 'https://apps.apple.com/app/id0000000000',
        ),
      );

  test('the fallback forces nothing', () {
    // No document, no signal, no answer — all of them land here, and none of
    // them may lock anybody out.
    expect(AppUpdatePolicy.none.forceUpdateEnabled, isFalse);
    expect(AppUpdatePolicy.none.forcesUpdate(1), isFalse);
    expect(AppConfig.fallback.ios.forcesUpdate(1), isFalse);
    expect(AppConfig.fallback.android.forcesUpdate(1), isFalse);
  });

  test('nothing is forced while the config has not arrived', () {
    final ProviderContainer container = ProviderContainer();

    addTearDown(container.dispose);

    // Read before anything resolves: the gate must answer, and answer no.
    expect(container.read(forceUpdateRequiredProvider), isFalse);
  });

  test('the switch is checked before the number', () async {
    // The whole point of having both: the owner keeps the build numbers
    // current as a matter of routine, and nobody is stopped until the block
    // is turned on deliberately.
    final ProviderContainer container = containerWith(
      config: iosConfig(enabled: false, buildNumber: 41),
      build: 11,
    );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(forceUpdateRequiredProvider), isFalse);
  });

  test('a build under the store, with the switch on, is stopped', () async {
    final ProviderContainer container = containerWith(
      config: iosConfig(enabled: true, buildNumber: 41),
      build: 40,
    );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(forceUpdateRequiredProvider), isTrue);
  });

  test('the store build itself still runs', () async {
    // Off by one here stops the very build the owner just shipped.
    final ProviderContainer container = containerWith(
      config: iosConfig(enabled: true, buildNumber: 41),
      build: 41,
    );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(forceUpdateRequiredProvider), isFalse);
  });

  test('each platform reads its own block', () async {
    // A build number is only meaningful next to the store that issued it, so
    // an iOS block must not stop an Android build on the same number.
    final AppConfig config = AppConfig(
      premiumEnabled: true,
      ios: const AppUpdatePolicy(forceUpdateEnabled: true, buildNumber: 41),
      android: AppUpdatePolicy.none,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final ProviderContainer android = containerWith(config: config, build: 40);

    await Future<void>.delayed(Duration.zero);

    expect(android.read(forceUpdateRequiredProvider), isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final ProviderContainer ios = containerWith(config: config, build: 40);

    await Future<void>.delayed(Duration.zero);

    expect(ios.read(forceUpdateRequiredProvider), isTrue);
  });

  test('the sheet reads the running platform, not both', () async {
    final ProviderContainer container = containerWith(
      config: iosConfig(enabled: true, buildNumber: 41),
      build: 40,
    );

    await Future<void>.delayed(Duration.zero);

    final AppUpdatePolicy policy = container.read(currentUpdatePolicyProvider);

    expect(policy.buildName, '1.4.0');
    expect(policy.storeLink, isNotNull);
  });

  test('a build the platform could not name is never stopped', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appConfigRepositoryProvider.overrideWithValue(
          _FixedConfig(iosConfig(enabled: true, buildNumber: 999999)),
        ),
      ],
    );

    addTearDown(container.dispose);
    container.listen<AsyncValue<AppConfig>>(
      appConfigProvider,
      (AsyncValue<AppConfig>? previous, AsyncValue<AppConfig> next) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);

    // The plugin never answered, so the build reads as newer than any ceiling
    // — a seller is not locked out over an error they cannot see.
    expect(container.read(forceUpdateRequiredProvider), isFalse);
  });
}
