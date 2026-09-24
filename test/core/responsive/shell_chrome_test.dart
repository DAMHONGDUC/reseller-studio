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
// `Override` is not in the main entrypoint's `show` list; `misc.dart` is
// where hooks_riverpod exports it.

import '../../support/pump_app.dart';

/// Which chrome the shell builds at each width.
///
/// The shell renders before sign-in (hard rule 1), so this needs no account —
/// what is under test is the frame, not what it shows.
void main() {
  /// **The sweep sits on More, not Home** — a harness constraint, not a
  /// layout rule.
  ///
  /// This test pumps a whole new tree per width, each with its own
  /// `ScreenUtilInit`, and Home's cards overflow by a few points in the frame
  /// after the second one. **Home itself is fine at tablet width**: pumped on
  /// its own at 1180x820, and resized from phone to tablet on a mounted tree —
  /// which is what iPadOS Split View actually does — it reports nothing.
  ///
  /// So the overflow belongs to the sweep, and the sweep is about the nav
  /// chrome, which is identical whichever tab is selected. More is a plain
  /// list and does not put a layout question in front of a navigation test.
  ///
  /// Before hard rule 1 was reversed this did not arise: the four business
  /// tabs rendered one centred sign-in prompt, which cannot overflow.
  Future<void> pumpShell(
    WidgetTester tester,
    Size surface, {
    String route = AppRoutes.more,
  }) async {
    // Past the intro, or the router holds the app on it and nothing settles.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_seen': true,
    });

    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = surface * 3;
    tester.view.viewPadding = const FakeViewPadding(top: 177, bottom: 102);
    tester.view.padding = const FakeViewPadding(top: 177, bottom: 102);
    addTearDown(tester.view.reset);

    // The shell renders the real tabs signed out now (hard rule 1,
    // `docs/rules/GUEST_MODE.md`), so they read the guest store — which has
    // to be in memory here, and has to have a business in it, or every
    // screen renders against a workspace that does not exist.
    final LocalDatabase db = LocalDatabase.forTesting(NativeDatabase.memory());

    addTearDown(db.close);

    await GuestWorkspaceService(db).ensureExists(
      marketplaces: const <Marketplace>[],
      categories: const <ItemCategory>[],
      carriers: const <Carrier>[],
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        isSignedInProvider.overrideWithValue(false),
        currentUidProvider.overrideWithValue(null),
        localDatabaseProvider.overrideWithValue(db),
      ],
    );

    addTearDown(container.dispose);

    final GoRouter router = container.read(routerProvider);

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

    router.go(route);

    await tester.pumpAndSettle();
  }

  testWidgets('a phone gets the floating pill', (WidgetTester tester) async {
    await pumpShell(tester, TestSurface.phone);

    expect(find.byType(SdGlassNavBarV3), findsOneWidget);
    expect(find.byType(SdNavPanelV3), findsNothing);
    expect(find.byKey(SdNavPanelToggleV3.toggleKey), findsNothing);
  });

  testWidgets('a tablet stands the nav up, either way it is held', (
    WidgetTester tester,
  ) async {
    for (final Size tablet in <Size>[
      TestSurface.tabletPortrait,
      TestSurface.tabletLandscape,
    ]) {
      await pumpShell(tester, tablet);

      expect(find.byType(SdNavPanelV3), findsOneWidget, reason: '$tablet');
      expect(find.byType(SdGlassNavBarV3), findsNothing, reason: '$tablet');
    }
  });

  testWidgets('the five tabs are the same list at every width', (
    WidgetTester tester,
  ) async {
    const List<String> tabs = <String>[
      'Home',
      'Inventory',
      'Orders',
      'Analytics',
      'More',
    ];

    for (final (Size surface, Type chrome) in <(Size, Type)>[
      (TestSurface.phone, SdGlassNavBarV3),
      (TestSurface.tabletLandscape, SdNavPanelV3),
    ]) {
      await pumpShell(tester, surface);

      // Read off the cells rather than the screen: a screen may carry the
      // same word in its own title, and what is under test is the nav.
      final List<String> labels = tester
          .widgetList<SdNavCellV3>(
            find.descendant(
              of: find.byType(chrome),
              matching: find.byType(SdNavCellV3),
            ),
          )
          .map((SdNavCellV3 cell) => cell.destination.label)
          .toList();

      expect(labels, tabs, reason: '$chrome at $surface');
    }
  });
  testWidgets('toggle keeps the selected branch and all five destinations', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, TestSurface.tabletPortrait);
    await tester.tap(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is SdNavCellV3 && widget.destination.label == 'More',
      ),
    );
    await tester.pumpAndSettle();

    final Element more = tester.element(find.text('Sourcing').first);
    for (final bool expanded in <bool>[false, true, false]) {
      await tester.tap(find.byKey(SdNavPanelToggleV3.toggleKey));
      await tester.pumpAndSettle();
      final SdNavPanelV3 panel = tester.widget(find.byType(SdNavPanelV3));
      expect(panel.isExpanded, expanded);
      expect(panel.selectedIndex, 4);
      expect(tester.element(find.text('Sourcing').first), same(more));
      expect(find.byType(SdNavCellV3), findsNWidgets(expanded ? 5 : 0));
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(SdNavPanelToggleV3.toggleKey));
    await tester.pumpAndSettle();
    for (final (int index, String label) in <(int, String)>[
      (0, 'Home'),
      (1, 'Inventory'),
      (2, 'Orders'),
      (3, 'Analytics'),
      (4, 'More'),
    ]) {
      await tester.tap(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is SdNavCellV3 && widget.destination.label == label,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<SdNavPanelV3>(find.byType(SdNavPanelV3)).selectedIndex,
        index,
      );
      expect(
        tester.widget<SdNavPanelV3>(find.byType(SdNavPanelV3)).isExpanded,
        isTrue,
      );
    }
  });
}
