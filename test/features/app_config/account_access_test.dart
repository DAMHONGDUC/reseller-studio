import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_config.dart';
import 'package:reseller_studio/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:reseller_studio/features/app_config/providers.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/providers.dart';

/// Three lists in one hand-edited document decide who is handed Premium, who
/// gets the developer affordances and who is refused the app — so the cases
/// worth pinning are the ones where a wrong answer is expensive: a list that
/// never arrived must not block anybody, and a list that did must not miss the
/// person on it over a capital letter.
class _FixedConfig implements AppConfigRepository {
  const _FixedConfig(this.config);

  final AppConfig config;

  @override
  Stream<AppConfig> watch() => Stream<AppConfig>.value(config);
}

void main() {
  ProviderContainer containerWith({
    required AppConfig config,
    required String? email,
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appConfigRepositoryProvider.overrideWithValue(_FixedConfig(config)),
        currentEmailProvider.overrideWithValue(email),
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

  AppConfig configWith({
    Set<String> premium = const <String>{},
    Set<String> devMode = const <String>{},
    Set<String> blocked = const <String>{},
  }) => AppConfig(
    premiumEnabled: true,
    premiumEmails: premium,
    devModeEmails: devMode,
    blockedEmails: blocked,
  );

  group('the fallback grants nothing and refuses nobody', () {
    test('every list is empty', () {
      expect(AppConfig.fallback.premiumEmails, isEmpty);
      expect(AppConfig.fallback.devModeEmails, isEmpty);
      expect(AppConfig.fallback.blockedEmails, isEmpty);
    });

    test('a config that never arrived blocks nobody', () {
      // The expensive direction: a failed read that refused the app would
      // lock a seller out of something they cannot fix from their side.
      final ProviderContainer container = containerWith(
        config: AppConfig.fallback,
        email: 'owner@example.com',
      );

      expect(container.read(accountBlockedProvider), isFalse);
      expect(container.read(premiumGrantedByEmailProvider), isFalse);
    });
  });

  test('nobody signed in matches no list', () async {
    final ProviderContainer container = containerWith(
      config: configWith(
        premium: <String>{'owner@example.com'},
        blocked: <String>{'owner@example.com'},
      ),
      email: null,
    );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(accountBlockedProvider), isFalse);
    expect(container.read(premiumGrantedByEmailProvider), isFalse);
  });

  test('the match ignores case and surrounding space', () {
    // The stored side is normalised by the DTO; this is the account's own
    // address, which arrives from a vendor SDK exactly as it was typed.
    final AppConfig config = configWith(premium: <String>{'owner@example.com'});

    expect(config.grantsPremium(' Owner@Example.COM '), isTrue);
    expect(config.grantsPremium('someone.else@example.com'), isFalse);
    expect(config.grantsPremium(''), isFalse);
  });

  test('a listed email is Premium without having bought it', () async {
    final ProviderContainer container = containerWith(
      config: configWith(premium: <String>{'owner@example.com'}),
      email: 'owner@example.com',
    );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentPlanProvider), SellerPlan.premium);
  });

  test('an unlisted email is whatever the seller actually has', () async {
    final ProviderContainer container = containerWith(
      config: configWith(premium: <String>{'owner@example.com'}),
      email: 'someone.else@example.com',
    );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentPlanProvider), SellerPlan.free);
  });

  test('a listed email is blocked', () async {
    final ProviderContainer container = containerWith(
      config: configWith(blocked: <String>{'banned@example.com'}),
      email: 'banned@example.com',
    );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(accountBlockedProvider), isTrue);
  });

  test('dev mode is on in a debug build whatever the list says', () async {
    // The test suite is a debug build, so the grant cannot be observed from
    // here — what is pinned is that the list never *removes* it.
    final ProviderContainer container = containerWith(
      config: configWith(devMode: const <String>{}),
      email: 'someone.else@example.com',
    );

    await Future<void>.delayed(Duration.zero);

    expect(container.read(devModeEnabledProvider), isTrue);
  });

  test('the grant itself is decided by the list', () {
    final AppConfig config = configWith(devMode: <String>{'dev@example.com'});

    expect(config.grantsDevMode('dev@example.com'), isTrue);
    expect(config.grantsDevMode('owner@example.com'), isFalse);
    expect(config.grantsDevMode(null), isFalse);
  });

  test('a log line carries counts, never addresses', () {
    // Hard rule 9: `SdLogger.error` reports to Crashlytics in release, so a
    // log line is the shortest path from a config document to a third-party
    // dashboard.
    final Map<String, Object?> data = configWith(
      premium: <String>{'owner@example.com'},
      blocked: <String>{'banned@example.com'},
    ).toLogData();

    expect(data['premiumEmails'], 1);
    expect(data['blockedEmails'], 1);
    expect(data.toString(), isNot(contains('@')));
  });
}
