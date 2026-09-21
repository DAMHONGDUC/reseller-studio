import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/providers/repository_providers.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_config.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_update_policy.dart';
import 'package:reseller_studio/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:reseller_studio/features/app_config/presentation/widgets/force_update_gate.dart';
import 'package:reseller_studio/features/app_config/providers.dart';

import '../../support/pump_app.dart';

/// The block is the whole thing — there is no route behind it and no route
/// carrying it — so what has to hold is that nothing takes it away: not a
/// tap, not back, and not the redirect that moves the app off the splash.
class _FixedConfig implements AppConfigRepository {
  const _FixedConfig(this.config);

  final AppConfig config;

  @override
  Stream<AppConfig> watch() => Stream<AppConfig>.value(config);
}

const AppUpdatePolicy _policy = AppUpdatePolicy(
  forceUpdateEnabled: true,
  buildNumber: 41,
  buildName: '1.4.0',
  storeLink: 'https://apps.apple.com/app/id0000000000',
);

void main() {
  Future<GoRouter> pumpBlocked(WidgetTester tester) => pumpRoutedScreen(
    tester,
    const Scaffold(body: SizedBox.shrink()),
    overrides: <Override>[
      appConfigRepositoryProvider.overrideWithValue(
        const _FixedConfig(
          AppConfig(
            // Both stores carry the same block, so the test does not depend
            // on which platform the test binding reports.
            ios: _policy,
            android: _policy,
          ),
        ),
      ),
      appBuildNumberProvider.overrideWith((Ref ref) async => 40),
    ],
    // Where the app mounts it: above the router's navigator, not in a route.
    builder: (BuildContext context, Widget? child) =>
        ForceUpdateGate(child: child ?? const SizedBox.shrink()),
  );

  testWidgets('it names the version and offers the store', (
    WidgetTester tester,
  ) async {
    await pumpBlocked(tester);

    expect(find.text('Time to update'), findsOneWidget);
    expect(find.text('Version 1.4.0 is available.'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
  });

  testWidgets('navigating does not take it away', (WidgetTester tester) async {
    // The regression: the block used to be a modal route hanging off the page
    // below it, so the first redirect after launch — splash to Home — threw
    // it away and nothing put it back.
    final GoRouter router = await pumpBlocked(tester);

    expect(find.text('Time to update'), findsOneWidget);

    router.go('/inventory');
    await tester.pumpAndSettle();

    expect(find.text('Time to update'), findsOneWidget);
  });

  testWidgets('the barrier does not dismiss it', (WidgetTester tester) async {
    await pumpBlocked(tester);

    // Top-left corner: as far from the sheet as the screen goes.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('Time to update'), findsOneWidget);
  });

  testWidgets('back does not dismiss it', (WidgetTester tester) async {
    await pumpBlocked(tester);

    final NavigatorState navigator = tester.state(find.byType(Navigator).first);

    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Time to update'), findsOneWidget);
  });

  testWidgets('there is no close button to find', (WidgetTester tester) async {
    await pumpBlocked(tester);

    // Every other sheet in the app carries one; this is the exception, and it
    // is the exception on purpose — see `SdBottomSheetExitV3.blocked`.
    expect(find.byTooltip('Close'), findsNothing);
  });
}
