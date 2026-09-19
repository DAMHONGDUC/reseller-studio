import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_config.dart';
import 'package:reseller_studio/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:reseller_studio/features/subscription/domain/entities/subscription_status.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// Hands the app one `app_config/current`, so a grant is read the way the app
/// reads it rather than by overriding the answer it is supposed to compute.
class _FixedConfig implements AppConfigRepository {
  const _FixedConfig(this.config);

  final AppConfig config;

  @override
  Stream<AppConfig> watch() => Stream<AppConfig>.value(config);
}

void main() {
  testWidgets('Free sees the compact Premium banner above shortcuts', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: <Override>[
        subscriptionStatusProvider.overrideWith(
          (Ref ref) =>
              Stream<SubscriptionStatus>.value(SubscriptionStatus.free),
        ),
      ],
    );

    expect(find.text('Go Premium'), findsOneWidget);
    final SdCardV3 banner = tester.widget<SdCardV3>(
      find.ancestor(
        of: find.text('Go Premium'),
        matching: find.byType(SdCardV3),
      ),
    );
    expect(banner.onTap, isNotNull);
    expect(
      tester.getTopLeft(find.text('Go Premium')).dy,
      lessThan(tester.getTopLeft(find.text('Quick Action').first).dy),
    );
  });

  testWidgets('Premium never sees its own upgrade banner', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: <Override>[
        subscriptionStatusProvider.overrideWith(
          (Ref ref) => Stream<SubscriptionStatus>.value(
            const SubscriptionStatus(
              plan: SellerPlan.premium,
              source: SubscriptionSource.appStore,
            ),
          ),
        ),
      ],
    );

    expect(find.text('Go Premium'), findsNothing);
  });

  testWidgets('a seller `app_config` grants Premium sees no upgrade banner', (
    WidgetTester tester,
  ) async {
    // The grant is the case a purchase check cannot see: nothing was bought,
    // so `subscriptionStatus` still reads Free while the seller is Premium.
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: <Override>[
        subscriptionStatusProvider.overrideWith(
          (Ref ref) =>
              Stream<SubscriptionStatus>.value(SubscriptionStatus.free),
        ),
        currentEmailProvider.overrideWithValue('owner@example.com'),
        appConfigRepositoryProvider.overrideWithValue(
          const _FixedConfig(
            AppConfig(premiumEmails: <String>{'owner@example.com'}),
          ),
        ),
      ],
    );

    expect(find.text('Go Premium'), findsNothing);
  });
}
