import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/core/local/guest_workspace_service.dart';
import 'package:reseller_studio/core/local/local_database.dart';
import 'package:reseller_studio/core/local/local_providers.dart';
import 'package:reseller_studio/core/router/app_router.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/widgets/app_screen_util.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/carriers/domain/entities/carrier.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item_category.dart';
import 'package:reseller_studio/features/marketplaces/domain/entities/marketplace.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_design/index.dart';

/// **A guest gets the whole app** — hard rule 1, after
/// `docs/rules/GUEST_MODE.md` reversed it.
///
/// This replaces `signed_out_shell_test.dart`, which pinned the opposite: four
/// tabs behind one sign-in prompt and More offering Settings alone. What is
/// easy to erode now is the other direction — a screen that quietly demands an
/// account, or a More row that shows a guest something only a server can
/// write.
void main() {
  late LocalDatabase db;
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

    db = LocalDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await GuestWorkspaceService(db).ensureExists(
      marketplaces: const <Marketplace>[],
      categories: const <ItemCategory>[],
      carriers: const <Carrier>[],
    );

    container = ProviderContainer(
      overrides: <Override>[
        // Signed out, and no uid — the state a fresh install sits in.
        isSignedInProvider.overrideWithValue(false),
        currentUidProvider.overrideWithValue(null),
        localDatabaseProvider.overrideWithValue(db),
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

  testWidgets('the four business tabs render themselves, not a prompt', (
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
        router.routeInformationProvider.value.uri.path,
        route,
        reason: '$route must not bounce a guest',
      );
      expect(find.text('Sign in'), findsNothing, reason: route);
    }
  });

  testWidgets('More hides only what a server would have to write', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    await goTo(tester, AppRoutes.more);

    // Records the guest store holds: a guest may see all of them.
    for (final String shown in <String>['Theme', 'Sourcing', 'Listings']) {
      await tester.scrollUntilVisible(
        find.text(shown),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text(shown), findsOneWidget, reason: shown);
    }

    // Team addresses an email account; Activity is the audit log, written
    // only by Cloud Functions (hard rule 12); Notifications is the account's.
    expect(find.text('Team'), findsNothing);
    expect(find.text('Notifications'), findsNothing);
  });

  testWidgets('a create route is reachable without an account', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    for (final String create in <String>[
      AppRoutes.quickAdd,
      AppRoutes.addItem,
      AppRoutes.expenses,
    ]) {
      await goTo(tester, create);

      expect(
        router.routeInformationProvider.value.uri.path,
        create,
        reason: '$create is a guest\'s own record, not an account\'s',
      );
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
}
