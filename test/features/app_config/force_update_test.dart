import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_config.dart';
import 'package:reseller_studio/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:reseller_studio/features/app_config/providers.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';

/// The forced update is the one gate that sits above every other redirect, so
/// the cases worth pinning are the ones where it must **not** fire: a build
/// nobody has ruled out, a config that never arrived, a field somebody typed
/// wrong. Locking a seller out is not recoverable from their side.
class _FixedConfig implements AppConfigRepository {
  const _FixedConfig(this.config);

  final AppConfig config;

  @override
  Stream<AppConfig> watch() => Stream<AppConfig>.value(config);
}

void main() {
  ProviderContainer containerWith({
    required int minimumBuild,
    required int build,
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appConfigRepositoryProvider.overrideWithValue(
          _FixedConfig(
            AppConfig(premiumEnabled: true, minimumBuild: minimumBuild),
          ),
        ),
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

  test('the fallback forces nothing', () {
    // No document, no signal, no answer — all of them land here, and none of
    // them may lock anybody out.
    expect(AppConfig.fallback.minimumBuild, 0);
    expect(AppConfig.fallback.forcesUpdate(1), isFalse);
  });

  test('nothing is forced while the config has not arrived', () {
    final ProviderContainer container = ProviderContainer();

    addTearDown(container.dispose);

    // Read before anything resolves: the gate must answer, and answer no.
    expect(container.read(forceUpdateRequiredProvider), isFalse);
  });

  test('a build under the ceiling is stopped', () async {
    final ProviderContainer container = containerWith(
      minimumBuild: 12,
      build: 11,
    );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(forceUpdateRequiredProvider), isTrue);
  });

  test('the advertised minimum itself still runs', () async {
    // Off by one here stops the very build the owner just shipped.
    final ProviderContainer container = containerWith(
      minimumBuild: 12,
      build: 12,
    );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(forceUpdateRequiredProvider), isFalse);
  });

  test('a build the platform could not name is never stopped', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appConfigRepositoryProvider.overrideWithValue(
          const _FixedConfig(
            AppConfig(premiumEnabled: true, minimumBuild: 999999),
          ),
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
