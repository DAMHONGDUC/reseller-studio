import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:seller_os/core/router/app_router.dart';
import 'package:seller_os/core/router/app_routes.dart';
import 'package:seller_os/core/theme/app_theme.dart';
import 'package:seller_os/features/auth/providers.dart';
import 'package:seller_os/features/workspace/providers.dart';
import 'package:seller_os/l10n/gen/app_localizations.dart';
import 'package:seller_os/seller_os_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **The intro never becomes a way into the app** (hard rule 1).
///
/// Onboarding is the one screen that comes before the sign-in gate, so it is
/// also the one change that could accidentally open a hole in it. These cases
/// pin the order for a signed-out visitor: introduced first, then asked to
/// sign in, and never let past either.
///
/// The real controller and real preferences are exercised rather than a stub —
/// the bug this guards against is the flag being read wrongly, and a stubbed
/// status would read perfectly every time.
///
/// **The signed-in case is deliberately not here.** Landing it renders Home,
/// which reads Firestore, and with no Firebase app in a test that is a hang
/// rather than an assertion. It needs no test anyway: the onboarding branch
/// sits *inside* `if (!signedIn)` in the redirect, so a signed-in seller
/// cannot reach the intro by construction.
void main() {
  Future<String> landingFor(
    WidgetTester tester, {
    required bool signedIn,
    required bool seenIntro,
  }) async {
    // The default 800×600 test surface is shorter than any phone, so Home
    // overflows here for reasons that have nothing to do with the redirect.
    // Same device `pumpScreen` pins to.
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    tester.view.viewPadding = const FakeViewPadding(top: 177, bottom: 102);
    tester.view.padding = const FakeViewPadding(top: 177, bottom: 102);
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{
      if (seenIntro) 'onboarding_seen': true,
    });

    final ProviderContainer container = ProviderContainer(
      overrides: [
        // Overridden so the test never reaches FirebaseAuth, which throws
        // with no app configured.
        isSignedInProvider.overrideWithValue(signedIn),
        workspaceStatusProvider.overrideWithValue(WorkspaceStatus.ready),
      ],
    );

    addTearDown(container.dispose);

    final GoRouter router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: SellerOsApp.designSize,
          builder: (BuildContext context, Widget? _) => MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
            localizationsDelegates:
                const <LocalizationsDelegate<Object>>[
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    return router.routerDelegate.currentConfiguration.uri.path;
  }

  testWidgets('a fresh install is introduced before it is asked to sign in', (
    WidgetTester tester,
  ) async {
    expect(
      await landingFor(tester, signedIn: false, seenIntro: false),
      AppRoutes.onboarding,
    );
  });

  testWidgets('once the intro is done the gate is the login screen', (
    WidgetTester tester,
  ) async {
    expect(
      await landingFor(tester, signedIn: false, seenIntro: true),
      AppRoutes.login,
    );
  });

}
