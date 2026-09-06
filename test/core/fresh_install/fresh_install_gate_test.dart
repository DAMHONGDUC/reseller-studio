import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/fresh_install/app_fresh_install.dart';
import 'package:reseller_studio/core/fresh_install/fresh_install_gate.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/widgets/splash_screen.dart';
import 'package:system_design/common.dart';

/// **Nothing below the gate is built until the check finishes.**
///
/// The wipe calls Firestore's `clearPersistence`, which throws
/// `failed-precondition` once that client is running — so a child that built
/// alongside it (`ForceUpdateGate` reading `app_config`, above all) would start
/// the very client the wipe has to terminate, and the cache would survive.
class _Marker extends StatelessWidget {
  const _Marker();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Pumped by hand rather than through `pumpScreen`: the splash draws an
/// indefinite spinner, so `pumpAndSettle` never returns while the gate is
/// doing its job.
Future<void> _pumpGate(
  WidgetTester tester,
  Future<SdFreshInstallOutcome> Function(Ref ref) check,
) => tester.pumpWidget(
  ProviderScope(
    overrides: <Override>[freshInstallProvider.overrideWith(check)],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (BuildContext context, Widget? child) => MaterialApp(
        theme: AppTheme.light,
        home: const FreshInstallGate(child: _Marker()),
      ),
    ),
  ),
);

void main() {
  testWidgets('holds the app on the splash while the check runs', (
    WidgetTester tester,
  ) async {
    // Never completes: the gate is asked what it draws mid-wipe.
    await _pumpGate(
      tester,
      (Ref ref) => Completer<SdFreshInstallOutcome>().future,
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(_Marker), findsNothing);
  });

  testWidgets('lets the app through once it has finished', (
    WidgetTester tester,
  ) async {
    await _pumpGate(
      tester,
      (Ref ref) async => SdFreshInstallOutcome.normalLaunch,
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(_Marker), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}
