import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/router/app_router.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/widgets/app_screen_util.dart';
import 'package:reseller_studio/core/widgets/signed_out_view.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/index.dart';

/// **Four tabs share one signed-out view; More does not** — owner's rule.
///
/// The rule is easy to erode in either direction: a new tab added without the
/// wrapper would render a real empty list and tell the seller they have no
/// orders, and wrapping More would hide the theme and language settings that
/// deliberately need no account. Both are pinned here.
void main() {
  late ProviderContainer container;
  late GoRouter router;

  Future<void> pumpShell(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_seen': true,
    });

    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    tester.view.viewPadding = const FakeViewPadding(top: 177, bottom: 102);
    tester.view.padding = const FakeViewPadding(top: 177, bottom: 102);
    addTearDown(tester.view.reset);

    container = ProviderContainer(
      overrides: [
        // Signed out, and no uid — the state a fresh install sits in before
        // Firebase is even configured.
        isSignedInProvider.overrideWithValue(false),
        currentUidProvider.overrideWithValue(null),
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
    await tester.pumpAndSettle();
  }

  Future<void> goTo(WidgetTester tester, String route) async {
    router.go(route);
    await tester.pumpAndSettle();
  }

  testWidgets('the four business tabs share one view with a sign-in button', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    for (final String route in <String>[
      AppRoutes.home,
      AppRoutes.inventory,
      AppRoutes.orders,
      AppRoutes.analytics,
    ]) {
      await goTo(tester, route);

      expect(
        find.byType(SignedOutView),
        findsOneWidget,
        reason: '$route must not render its own empty state signed out',
      );
      expect(find.text('Sign in'), findsOneWidget, reason: route);
    }
  });

  testWidgets('More stays itself and offers Settings alone', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    await goTo(tester, AppRoutes.more);

    expect(find.byType(SignedOutView), findsNothing);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Every other destination is a view onto a business nobody has named.
    for (final String hidden in <String>['Sourcing', 'Listings', 'Team']) {
      expect(find.text(hidden), findsNothing, reason: hidden);
    }
  });

  testWidgets('swiping the shell moves to the adjacent branch', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    await goTo(tester, AppRoutes.home);

    await tester.drag(
      find.byKey(SdBottomNavigationV3.swipeSurfaceKey),
      Offset(-SdBottomNavigationV3.swipeDistance * 2, 0),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.inventory);
  });

  testWidgets('no create route is reachable, so no action needs guarding', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    // The reason `NavigationUtils.requireSignIn` never fires today: every
    // screen with a create button sits behind `AuthedTab` or outside
    // `_previewRoutes`, so a signed-out visitor cannot reach one to tap it.
    for (final String create in <String>[
      AppRoutes.quickAdd,
      AppRoutes.addItem,
      AppRoutes.expenses,
      AppRoutes.search,
    ]) {
      await goTo(tester, create);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.home,
        reason: '$create must not open without an account',
      );
    }
  });

  testWidgets('Settings opens without an account and carries Appearance', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    await goTo(tester, AppRoutes.settings);

    // Theme and language belong to the device, not to a business — which is
    // the whole reason this route is reachable signed out.
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    // And the account block says what is true rather than offering a sign-out
    // to somebody who was never signed in.
    expect(find.text('Not signed in'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });
}
