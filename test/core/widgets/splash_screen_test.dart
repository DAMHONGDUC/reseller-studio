import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/fresh_install/app_fresh_install.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/widgets/splash_screen.dart';
import 'package:system_design/index.dart';

/// **Nothing below the splash is built until the wipe finishes.**
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
/// indefinite spinner, so `pumpAndSettle` never returns while it is doing its
/// job.
Future<void> _pumpSplash(
  WidgetTester tester,
  Future<SdFreshInstallOutcome> Function(Ref ref) check, {
  Widget? child,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: <Override>[freshInstallProvider.overrideWith(check)],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (BuildContext context, Widget? _) => MaterialApp(
        theme: AppTheme.light,
        home: SplashScreen(child: child),
      ),
    ),
  ),
);

Future<SdFreshInstallOutcome> _running(Ref ref) =>
    Completer<SdFreshInstallOutcome>().future;

Future<SdFreshInstallOutcome> _done(Ref ref) async =>
    SdFreshInstallOutcome.normalLaunch;

void main() {
  testWidgets('holds the app back while the wipe runs', (
    WidgetTester tester,
  ) async {
    await _pumpSplash(tester, _running, child: const _Marker());
    await tester.pump();

    expect(find.byType(SdLoadingV3Page), findsOneWidget);
    expect(find.byType(_Marker), findsNothing);
  });

  testWidgets('lets the app through once the wipe has finished', (
    WidgetTester tester,
  ) async {
    await _pumpSplash(tester, _done, child: const _Marker());
    await tester.pump();
    await tester.pump();

    expect(find.byType(_Marker), findsOneWidget);
    expect(find.byType(SdLoadingV3Page), findsNothing);
  });

  testWidgets('the router route has no child and just keeps loading', (
    WidgetTester tester,
  ) async {
    // `/splash` is already inside the tree this screen gates, so there the
    // check has long finished and the screen is covering an unresolved auth
    // state instead.
    await _pumpSplash(tester, _done);
    await tester.pump();
    await tester.pump();

    expect(find.byType(SdLoadingV3Page), findsOneWidget);
  });
}
