import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// `Override` is not in the main entrypoint's `show` list.
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/router/app_router.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/core/router/splash_hold.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/time/app_clock.dart';
import 'package:reseller_studio/core/widgets/app_screen_util.dart';
import 'package:reseller_studio/core/widgets/app_shell.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/workspace/providers.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/index.dart';

import '../../support/fakes/fake_overrides.dart';
import '../../support/fakes/in_memory_repositories.dart';
import '../../support/fakes/mock_dataset.dart';
import '../../support/pump_app.dart';

/// **Signing in is one move to Home, not three.**
///
/// The signed-out shell renders at `/home` (hard rule 1), so signing in leaves
/// the shell for the splash and comes back to it — and go_router gives
/// `StatefulShellRoute` one `GlobalKey` for the life of the router. Left to
/// animate, the outgoing shell was still mounted when the next one was built,
/// which is two widgets holding one global key and a framework error on the
/// first frame of Home.
///
/// The second half is the owner's rule that the loading animation always
/// plays: an answer that lands in 80 milliseconds waits rather than flashing
/// past.
/// A hold that never holds, so the test below sees the page transition alone.
class _NeverHolds extends SplashHoldController {
  @override
  bool build() => false;
}

void main() {
  late ProviderContainer container;
  late GoRouter router;
  late bool? signedIn;
  late WorkspaceStatus status;

  Future<void> settle(WidgetTester tester, {int frames = 6}) async {
    // Never `pumpAndSettle`: the loading animation repeats forever, so it
    // would time out rather than settle.
    for (int i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    List<Override> extra = const <Override>[],
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_seen': true,
    });

    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWith((Ref ref) => FixedClock(testNow)),
        ...FakeOverrides.forStore(
          MockStore(MockDataset.seed(now: testNow)),
          except: <Object>{workspaceStatusProvider},
        ),
        isSignedInProvider.overrideWith((Ref ref) => signedIn),
        workspaceStatusProvider.overrideWith((Ref ref) => status),
        ...extra,
      ],
    );

    addTearDown(container.dispose);

    router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: AppScreenUtil(
          builder: (BuildContext context) => MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      ),
    );
    await settle(tester);
  }

  /// The container's own state changed, so the router is told the way the app
  /// tells it — `refreshListenable` does not fire for a provider a test
  /// invalidated by hand.
  Future<void> signIn(WidgetTester tester) async {
    signedIn = true;
    status = WorkspaceStatus.loading;
    container.invalidate(isSignedInProvider);
    container.invalidate(workspaceStatusProvider);
    router.refresh();

    // One frame: the shell page would still be animating out.
    await tester.pump();
  }

  Future<void> resolveWorkspace(WidgetTester tester) async {
    status = WorkspaceStatus.ready;
    container.invalidate(workspaceStatusProvider);
    router.refresh();

    await tester.pump();
  }

  setUp(() {
    signedIn = false;
    status = WorkspaceStatus.none;
  });

  testWidgets('signing in lands on Home with one shell', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    // Past the launch's own hold, to the signed-out shell hard rule 1 renders.
    await tester.pump(SplashHoldController.minimum);
    await settle(tester);

    expect(find.byType(AppShell), findsOneWidget);

    await signIn(tester);
    await resolveWorkspace(tester);
    await tester.pump(SplashHoldController.minimum);
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(router.routerDelegate.currentConfiguration.uri.path, AppRoutes.home);
    // Two of these is one GlobalKey in two places, which is the framework
    // error this pins.
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('the loading animation is watched before Home arrives', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await tester.pump(SplashHoldController.minimum);
    await settle(tester);
    await signIn(tester);
    await resolveWorkspace(tester);

    // The answer is already in. The seller is still watching the cradle.
    await settle(tester, frames: 4);

    expect(find.byType(SdLoadingV3Page), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.splash,
    );

    await tester.pump(SplashHoldController.minimum);
    await settle(tester);

    expect(router.routerDelegate.currentConfiguration.uri.path, AppRoutes.home);
  });

  testWidgets('the shell is not rebuilt while the old one is on screen', (
    WidgetTester tester,
  ) async {
    // With the hold out of the way, the only thing between the two shells is
    // the splash page's transition — which is why it has none.
    await pumpApp(
      tester,
      extra: <Override>[splashHoldProvider.overrideWith(_NeverHolds.new)],
    );
    await settle(tester);

    expect(find.byType(AppShell), findsOneWidget);

    await signIn(tester);
    await resolveWorkspace(tester);
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(AppShell), findsOneWidget);
  });
}
