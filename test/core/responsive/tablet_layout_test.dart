import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/theme/app_theme.dart';
import 'package:reseller_studio/core/widgets/app_screen_util.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The rules that belong to no single screen: what the margin is, which
/// chrome is up, and what a tab screen reserves at the bottom.
///
/// Every assertion here has a phone half and a tablet half on purpose. The
/// phone half is the one that matters most — `docs/rules/RESPONSIVE.md` says
/// the whole of this is a no-op at phone width, and that invariant is what
/// makes it shippable without a person re-checking the phone build.
void main() {
  /// A card that pays the screen's own insets, so what a test measures is the
  /// edge a reader sees rather than the box around it.
  const Key cardKey = Key('responsive-test-card');

  /// Captured from inside the pumped tree: every token resolves through
  /// screenutil, so the expected values only exist once there is a context.
  late BuildContext bodyContext;

  Widget screen() => SdScaffoldV3(
    appBar: const SdAppBarV3(title: 'Responsive'),
    body: Builder(
      builder: (BuildContext context) {
        bodyContext = context;

        return Padding(
          padding: SdContentPaddingV3.screen(context, floatingNav: true),
          child: const SizedBox.expand(
            child: ColoredBox(key: cardKey, color: Color(0xFF000000)),
          ),
        );
      },
    ),
  );

  Future<void> pumpChrome(
    WidgetTester tester, {
    required Size surface,
    required bool rail,
  }) async {
    const List<SdNavDestinationV3> destinations = <SdNavDestinationV3>[
      SdNavDestinationV3(icon: Icons.home, label: 'Home'),
      SdNavDestinationV3(icon: Icons.inventory_2, label: 'Inventory'),
      SdNavDestinationV3(icon: Icons.receipt_long, label: 'Orders'),
      SdNavDestinationV3(icon: Icons.bar_chart, label: 'Analytics'),
      SdNavDestinationV3(icon: Icons.menu, label: 'More'),
    ];

    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = surface * 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppScreenUtil(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light,
          home: rail
              ? SdNavigationRailV3(
                  destinations: destinations,
                  selectedIndex: 0,
                  onSelected: (_) {},
                  body: screen(),
                )
              : SdBottomNavigationV3(
                  destinations: destinations,
                  selectedIndex: 0,
                  onSelected: (_) {},
                  body: screen(),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the margin', () {
    testWidgets('the three gaps on a tablet are one number', (
      WidgetTester tester,
    ) async {
      await pumpChrome(
        tester,
        surface: TestSurface.tabletPortrait,
        rail: true,
      );

      final Rect window = tester.getRect(find.byType(SdNavigationRailV3).last);
      final Rect rail = tester.getRect(
        find.byKey(SdNavigationRailV3.railSurfaceKey),
      );
      final Rect card = tester.getRect(find.byKey(cardKey));
      final double margin = SdContentPaddingV3.tabletMargin;

      // Edge to nav, nav to content, content to the far edge.
      expect(rail.left, closeTo(margin, 0.5), reason: 'edge to nav');
      expect(card.left - rail.right, closeTo(margin, 0.5), reason: 'nav to content');
      expect(
        window.right - card.right,
        closeTo(margin, 0.5),
        reason: 'content to the far edge',
      );
    });

    testWidgets('a phone pays the gutter and nothing more', (
      WidgetTester tester,
    ) async {
      await pumpChrome(tester, surface: TestSurface.phone, rail: false);

      final Rect card = tester.getRect(find.byKey(cardKey));

      expect(SdContentPaddingV3.pageMargin(bodyContext), 0);
      expect(card.left, closeTo(SdContentPaddingV3.horizontal, 0.5));
    });

    testWidgets('the app bar shares the content edges', (
      WidgetTester tester,
    ) async {
      await pumpChrome(
        tester,
        surface: TestSurface.tabletLandscape,
        rail: true,
      );

      final Rect bar = tester.getRect(find.byType(AppBar).first);
      final Rect card = tester.getRect(find.byKey(cardKey));
      final double gutter = SdContentPaddingV3.horizontal;

      // The bar spans the margin; the card is the gutter further in.
      expect(card.left - bar.left, closeTo(gutter, 0.5));
      expect(bar.right - card.right, closeTo(gutter, 0.5));
    });

    testWidgets('a route with no chrome lands on the same content width', (
      WidgetTester tester,
    ) async {
      await pumpChrome(
        tester,
        surface: TestSurface.tabletPortrait,
        rail: true,
      );

      final Rect card = tester.getRect(find.byKey(cardKey));
      final double withRail = card.width;

      // The same screen with nothing published above it — a sibling of the
      // shell rather than a child of a branch.
      await tester.pumpWidget(
        AppScreenUtil(
          builder: (BuildContext context) =>
              MaterialApp(theme: AppTheme.light, home: screen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byKey(cardKey)).width, closeTo(withRail, 1));
    });
  });

  group('the rail', () {
    testWidgets('is one thickness however the tablet is held', (
      WidgetTester tester,
    ) async {
      await pumpChrome(
        tester,
        surface: TestSurface.tabletPortrait,
        rail: true,
      );

      final Rect portrait = tester.getRect(
        find.byKey(SdNavigationRailV3.selectedCapsuleKey),
      );

      await pumpChrome(
        tester,
        surface: TestSurface.tabletLandscape,
        rail: true,
      );

      final Rect landscape = tester.getRect(
        find.byKey(SdNavigationRailV3.selectedCapsuleKey),
      );

      expect(landscape.width, closeTo(portrait.width, 0.5));
      expect(
        portrait.height,
        greaterThan(landscape.height),
        reason: 'the shorter window gets the shorter cell',
      );
    });

    testWidgets('every destination still switches', (
      WidgetTester tester,
    ) async {
      final List<int> taps = <int>[];

      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = TestSurface.tabletPortrait * 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        AppScreenUtil(
          builder: (BuildContext context) => MaterialApp(
            theme: AppTheme.light,
            home: SdNavigationRailV3(
              destinations: const <SdNavDestinationV3>[
                SdNavDestinationV3(icon: Icons.home, label: 'Home'),
                SdNavDestinationV3(icon: Icons.inventory_2, label: 'Inventory'),
                SdNavDestinationV3(icon: Icons.receipt_long, label: 'Orders'),
                SdNavDestinationV3(icon: Icons.bar_chart, label: 'Analytics'),
                SdNavDestinationV3(icon: Icons.menu, label: 'More'),
              ],
              selectedIndex: 0,
              onSelected: taps.add,
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final String label in <String>[
        'Home',
        'Inventory',
        'Orders',
        'Analytics',
        'More',
      ]) {
        await tester.tap(find.bySemanticsLabel(label));
        await tester.pump();
      }

      expect(taps, <int>[0, 1, 2, 3, 4]);
    });
  });

  group('the bottom inset', () {
    testWidgets('is reserved under the pill and reclaimed under the rail', (
      WidgetTester tester,
    ) async {
      await pumpChrome(tester, surface: TestSurface.phone, rail: false);

      final double underPill = SdContentPaddingV3.bottom(
        bodyContext,
        floatingNav: true,
      );

      expect(
        underPill,
        closeTo(
          SdContentPaddingV3.floatingBarInset(bodyContext) +
              SdContentPaddingV3.bottomGap,
          0.5,
        ),
      );

      await pumpChrome(
        tester,
        surface: TestSurface.tabletPortrait,
        rail: true,
      );

      expect(
        SdContentPaddingV3.bottom(bodyContext, floatingNav: true),
        closeTo(SdContentPaddingV3.detailBottom(bodyContext), 0.5),
      );
    });
  });
}
