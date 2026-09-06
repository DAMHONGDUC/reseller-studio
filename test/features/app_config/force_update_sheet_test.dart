import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_config.dart';
import 'package:reseller_studio/features/app_config/domain/entities/app_update_policy.dart';
import 'package:reseller_studio/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:reseller_studio/features/app_config/presentation/widgets/force_update_sheet.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';

import '../../support/pump_app.dart';

/// The sheet is the whole block — there is no route behind it any more — so
/// what has to hold is that nothing dismisses it. A seller who can swipe it
/// away is a seller running a build the owner already stopped.
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

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => ForceUpdateSheet.show(context),
        child: const Text('open'),
      ),
    ),
  );
}

void main() {
  Future<void> openSheet(WidgetTester tester) async {
    await pumpScreen(
      tester,
      const _Host(),
      overrides: <Override>[
        appConfigRepositoryProvider.overrideWithValue(
          const _FixedConfig(
            AppConfig(
              premiumEnabled: true,
              // Both stores carry the same block, so the test does not depend
              // on which platform the test binding reports.
              ios: _policy,
              android: _policy,
            ),
          ),
        ),
      ],
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('it names the version and offers the store', (
    WidgetTester tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Time to update'), findsOneWidget);
    expect(find.text('Version 1.4.0 is available.'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
  });

  testWidgets('the barrier does not dismiss it', (WidgetTester tester) async {
    await openSheet(tester);

    // Top-left corner: as far from the sheet as the screen goes.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('Time to update'), findsOneWidget);
  });

  testWidgets('back does not dismiss it', (WidgetTester tester) async {
    await openSheet(tester);

    final NavigatorState navigator = tester.state(find.byType(Navigator).first);

    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Time to update'), findsOneWidget);
  });

  testWidgets('there is no close button to find', (WidgetTester tester) async {
    await openSheet(tester);

    // Every other sheet in the app carries one; this is the exception, and it
    // is the exception on purpose — see `SdBottomSheetExitV3.blocked`.
    expect(find.byTooltip('Close'), findsNothing);
  });
}
