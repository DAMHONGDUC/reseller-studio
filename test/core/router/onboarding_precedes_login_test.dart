import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/router/app_router.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/widgets/app_screen_util.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/onboarding/providers.dart';
import 'package:reseller_studio/features/workspace/providers.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
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
  late ProviderContainer lastContainer;
  late GoRouter lastRouter;

  Future<String> landingFor(
    WidgetTester tester, {
    required bool signedIn,
    required bool seenIntro,
    String? startAt,
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
        // Home now renders for a signed-out visitor, and it reads this on the
        // way to the business providers. Without the override it reaches
        // FirebaseAuth and throws.
        currentUidProvider.overrideWithValue(signedIn ? 'uid' : null),
        workspaceStatusProvider.overrideWithValue(WorkspaceStatus.ready),
      ],
    );

    addTearDown(container.dispose);

    final GoRouter router = container.read(routerProvider);

    lastContainer = container;
    lastRouter = router;

    if (startAt != null) router.go(startAt);

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

  testWidgets('once the intro is done the five tabs render, empty', (
    WidgetTester tester,
  ) async {
    expect(
      await landingFor(tester, signedIn: false, seenIntro: true),
      AppRoutes.home,
    );
  });

  testWidgets('finishing the intro leaves it — Skip is not a dead button', (
    WidgetTester tester,
  ) async {
    // **The trap this closes.** Finishing flips the status to `done`, and the
    // signed-out branch used to answer "stay" for every route it did not
    // name — so the seller was left on an intro whose Skip and Next did
    // nothing. The old shell got the bounce for free because `/onboarding`
    // sat outside `_previewRoutes`; unwrapping the tabs dropped it.
    expect(
      await landingFor(tester, signedIn: false, seenIntro: false),
      AppRoutes.onboarding,
    );

    await lastContainer.read(onboardingStatusProvider.notifier).complete();
    lastRouter.refresh();
    await tester.pumpAndSettle();

    expect(
      lastRouter.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.home,
    );
  });

  testWidgets('a signed-out visitor cannot reach workspace setup', (
    WidgetTester tester,
  ) async {
    // It needs an account to attach the business to, so it is bounced to Home
    // rather than rendered against nothing.
    expect(
      await landingFor(
        tester,
        signedIn: false,
        seenIntro: true,
        startAt: AppRoutes.workspaceSetup,
      ),
      AppRoutes.home,
    );
  });
}
