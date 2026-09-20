import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  /// A screen pushed above the shell: the same screen, with no chrome beside
  /// it, which is what a detail route is.
  Future<void> pumpPushed(WidgetTester tester, {required Size surface}) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = surface * 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppScreenUtil(
        builder: (BuildContext context) =>
            MaterialApp(theme: AppTheme.light, home: screen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpChrome(
    WidgetTester tester, {
    required Size surface,
    required bool panel,
    bool expanded = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool disableAnimations = false,
    double topInset = 0,
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
    tester.view.padding = FakeViewPadding(top: topInset * 3);
    tester.view.viewPadding = FakeViewPadding(top: topInset * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppScreenUtil(
        builder: (BuildContext context) => MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: disableAnimations,
            ),
            child: child!,
          ),
          home: panel
              ? StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) =>
                      SdNavPanelV3(
                        isExpanded: expanded,
                        onExpansionChanged: (bool value) =>
                            setState(() => expanded = value),
                        expandLabel: 'Expand navigation',
                        collapseLabel: 'Collapse navigation',
                        destinations: destinations,
                        selectedIndex: 0,
                        onSelected: (_) {},
                        body: screen(),
                      ),
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

  testWidgets('sidebar animates both ways and reverses without overflow', (
    tester,
  ) async {
    await pumpChrome(tester, surface: TestSurface.tabletPortrait, panel: true);
    final panel = find.byKey(SdNavPanelV3.panelRegionKey);
    final content = find.byKey(SdNavPanelV3.contentRegionKey);
    final toggle = find.byKey(SdNavPanelToggleV3.toggleKey);
    final openWidth = tester.getSize(panel).width;
    final closeIcon = tester
        .widget<SdIconV3>(
          find.descendant(of: toggle, matching: find.byType(SdIconV3)),
        )
        .icon;
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(SdMotionV3.normal ~/ 2);
    final middle = tester.getSize(panel).width;
    expect(middle, greaterThan(0));
    expect(middle, lessThan(openWidth));
    expect(tester.getRect(content).left, tester.getRect(panel).right);
    final openIcon = tester
        .widget<SdIconV3>(
          find.descendant(of: toggle, matching: find.byType(SdIconV3)),
        )
        .icon;
    expect(openIcon, closeIcon);
    expect(find.byTooltip('Expand navigation'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(SdMotionV3.normal ~/ 2);
    expect(tester.getSize(panel).width, greaterThan(middle));
    expect(tester.getSize(panel).width, lessThan(openWidth));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.getSize(panel).width, openWidth);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(panel).width, 0);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(SdMotionV3.normal ~/ 2);
    expect(tester.getSize(panel).width, inExclusiveRange(0, openWidth));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion changes sidebar width immediately', (
    tester,
  ) async {
    await pumpChrome(
      tester,
      surface: TestSurface.tabletPortrait,
      panel: true,
      disableAnimations: true,
    );
    final panel = find.byKey(SdNavPanelV3.panelRegionKey);
    final openWidth = tester.getSize(panel).width;
    await tester.tap(find.byKey(SdNavPanelToggleV3.toggleKey));
    await tester.pump();
    expect(tester.getSize(panel).width, 0);
    await tester.tap(find.byKey(SdNavPanelToggleV3.toggleKey));
    await tester.pump();
    expect(tester.getSize(panel).width, openWidth);
  });

  testWidgets('collapsed, the reopen control is the app bar\'s leading', (
    WidgetTester tester,
  ) async {
    const double topInset = 24;

    await pumpChrome(
      tester,
      surface: TestSurface.tabletPortrait,
      panel: true,
      expanded: false,
      topInset: topInset,
    );

    final Finder toggle = find.byKey(SdNavPanelToggleV3.toggleKey);
    final Finder appBar = find.byType(AppBar);

    // Inside the bar, not in a strip above it — so the bar still pays the
    // status bar and the content starts exactly where it would with no
    // sidebar at all.
    expect(find.descendant(of: appBar, matching: toggle), findsOneWidget);
    expect(tester.getSize(appBar).height, SdAppBarV3.toolbarHeight + topInset);
    expect(
      tester.getSize(toggle).shortestSide,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
    expect(
      tester.getRect(toggle).left,
      lessThan(tester.getRect(appBar).left + SdNavPanelToggleV3.slot),
    );

    // Reopening hands it back to the sidebar, and the bar has no leading
    // again — one control, never two.
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.byKey(SdNavPanelToggleV3.toggleKey), findsOneWidget);
    expect(
      find.descendant(
        of: appBar,
        matching: find.byKey(SdNavPanelToggleV3.toggleKey),
      ),
      findsNothing,
    );
    expect(tester.getSize(appBar).height, SdAppBarV3.toolbarHeight + topInset);
  });

  testWidgets('a screen wearing the search header hosts it too', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();

    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = TestSurface.tabletPortrait * 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppScreenUtil(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light,
          home: SdNavPanelV3(
            isExpanded: false,
            onExpansionChanged: (_) {},
            expandLabel: 'Expand navigation',
            collapseLabel: 'Collapse navigation',
            destinations: const <SdNavDestinationV3>[
              SdNavDestinationV3(icon: Icons.home, label: 'Home'),
              SdNavDestinationV3(icon: Icons.inventory_2, label: 'Inventory'),
            ],
            selectedIndex: 1,
            onSelected: (_) {},
            // Inventory's shape: the header is a sliver and the screen wears
            // no `SdAppBarV3`, so this is the tab that would be stranded if
            // only the bar adopted the control.
            body: SdScaffoldV3(
              body: CustomScrollView(
                slivers: <Widget>[
                  SdSearchHeaderV3(
                    title: 'Inventory',
                    controller: controller,
                    hint: 'Search',
                    clearTooltip: 'Clear',
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 2000)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect toggle = tester.getRect(
      find.byKey(SdNavPanelToggleV3.toggleKey),
    );

    expect(find.byTooltip('Expand navigation'), findsOneWidget);
    // The title starts past the control rather than under it.
    expect(
      tester.getRect(find.text('Inventory')).left,
      greaterThan(toggle.right),
    );
    expect(tester.takeException(), isNull);
  });

  group('the margin', () {
    testWidgets('both states use exact shares and centred content', (
      WidgetTester tester,
    ) async {
      for (final Size surface in <Size>[
        const Size(600, 960),
        TestSurface.tabletPortrait,
        TestSurface.tabletLandscape,
      ]) {
        await pumpChrome(tester, surface: surface, panel: true);

        for (final bool expanded in <bool>[true, false, true]) {
          final Rect panel = tester.getRect(
            find.byKey(SdNavPanelV3.panelRegionKey),
          );
          final Rect content = tester.getRect(
            find.byKey(SdNavPanelV3.contentRegionKey),
          );
          final Rect card = tester.getRect(find.byKey(cardKey));

          expect(
            panel.width,
            closeTo(surface.width * (expanded ? 1 / 5 : 0), 0.01),
          );
          expect(
            content.width,
            closeTo(surface.width * (expanded ? 4 / 5 : 1), 0.01),
          );
          if (expanded) {
            final Rect surfaceRect = tester.getRect(
              find.byKey(SdNavPanelV3.panelSurfaceKey),
            );
            final Rect appBar = tester.getRect(find.byType(AppBar).first);
            expect(surfaceRect, panel);
            expect(surfaceRect.height, closeTo(surface.height, 0.01));
            expect(appBar.left, closeTo(surfaceRect.right, 0.01));
          } else {
            expect(find.byKey(SdNavPanelV3.panelSurfaceKey), findsNothing);
          }
          expect(panel.left, 0);
          expect(content.left, closeTo(panel.right, 0.01));
          expect(content.right, closeTo(surface.width, 0.01));
          expect(card.center.dx, closeTo(content.center.dx, 0.01));
          expect(
            card.left - content.left,
            closeTo(content.right - card.right, 0.01),
          );
          expect(find.byType(SdNavCellV3), findsNWidgets(expanded ? 5 : 0));
          expect(
            find.text('Inventory'),
            expanded ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);

          await tester.tap(find.byKey(SdNavPanelToggleV3.toggleKey));
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('a phone pays the gutter and nothing more', (
      WidgetTester tester,
    ) async {
      await pumpChrome(tester, surface: TestSurface.phone, panel: false);

      final Rect card = tester.getRect(find.byKey(cardKey));

      expect(card.left, closeTo(SdContentPaddingV3.horizontal, 0.5));
    });

    testWidgets('a pushed route fills the window it has to itself', (
      WidgetTester tester,
    ) async {
      // No chrome beside it, so nothing to leave room for: the gutter inside
      // the screen is the whole inset, at both tablet orientations.
      for (final Size surface in <Size>[
        TestSurface.tabletPortrait,
        TestSurface.tabletLandscape,
      ]) {
        await pumpPushed(tester, surface: surface);

        final Rect card = tester.getRect(find.byKey(cardKey));
        final Rect bar = tester.getRect(find.byType(AppBar).first);
        final double gutter = SdContentPaddingV3.horizontal;

        expect(bar.left, 0);
        expect(bar.right, closeTo(surface.width, 0.01));
        expect(card.left, closeTo(gutter, 0.5));
        expect(card.right, closeTo(surface.width - gutter, 0.5));
      }
    });

    testWidgets('the app bar shares the content edges', (
      WidgetTester tester,
    ) async {
      await pumpChrome(
        tester,
        surface: TestSurface.tabletLandscape,
        panel: true,
      );

      final Rect bar = tester.getRect(find.byType(AppBar).first);
      final Rect card = tester.getRect(find.byKey(cardKey));
      final double gutter = SdContentPaddingV3.horizontal;

      // The bar spans the margin; the card is the gutter further in.
      expect(card.left - bar.left, closeTo(gutter, 0.5));
      expect(bar.right - card.right, closeTo(gutter, 0.5));
    });

    testWidgets('a route with no chrome stays centred in the full window', (
      WidgetTester tester,
    ) async {
      await pumpChrome(
        tester,
        surface: TestSurface.tabletPortrait,
        panel: true,
      );

      // The same screen with nothing published above it — a sibling of the
      // shell rather than a child of a branch.
      await tester.pumpWidget(
        AppScreenUtil(
          builder: (BuildContext context) =>
              MaterialApp(theme: AppTheme.light, home: screen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(cardKey)).center.dx,
        closeTo(TestSurface.tabletPortrait.width / 2, 0.01),
      );
    });
  });

  group('what the panel leaves', () {
    testWidgets('the content column never reads narrower than a phone', (
      WidgetTester tester,
    ) async {
      await pumpChrome(tester, surface: TestSurface.phone, panel: false);

      final double onPhone = tester.getRect(find.byKey(cardKey)).width;

      // The panel is wide and a tablet held upright is not, so this is the
      // trade the panel is made against — and the direction it must never go.
      for (final Size tablet in <Size>[
        TestSurface.tabletPortrait,
        TestSurface.tabletLandscape,
      ]) {
        await pumpChrome(tester, surface: tablet, panel: true);

        expect(
          tester.getRect(find.byKey(cardKey)).width,
          greaterThan(onPhone),
          reason: '$tablet leaves less room than a phone',
        );
      }
    });
  });

  group('the panel', () {
    testWidgets(
      'reopen control stays accessible in dark theme with large text',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await pumpChrome(
          tester,
          surface: TestSurface.tabletPortrait,
          panel: true,
          expanded: false,
          brightness: Brightness.dark,
          textScale: 2,
        );

        expect(find.byTooltip('Expand navigation'), findsOneWidget);
        expect(find.byType(SdNavCellV3), findsNothing);
        await tester.tap(find.byKey(SdNavPanelToggleV3.toggleKey));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Inventory'), findsOneWidget);
        expect(find.text('Inventory'), findsOneWidget);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Inventory'))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(
          tester.getSize(find.byKey(SdNavPanelToggleV3.toggleKey)).shortestSide,
          greaterThanOrEqualTo(48),
        );
        await tester.tap(find.byKey(SdNavPanelToggleV3.toggleKey));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Expand navigation'), findsOneWidget);
        expect(find.byType(SdNavCellV3), findsNothing);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );

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
            home: SdNavPanelV3(
              isExpanded: true,
              onExpansionChanged: (_) {},
              expandLabel: 'Expand navigation',
              collapseLabel: 'Collapse navigation',
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
    testWidgets('is reserved under the pill and reclaimed under the panel', (
      WidgetTester tester,
    ) async {
      await pumpChrome(tester, surface: TestSurface.phone, panel: false);

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
        panel: true,
      );

      expect(
        SdContentPaddingV3.bottom(bodyContext, floatingNav: true),
        closeTo(SdContentPaddingV3.detailBottom(bodyContext), 0.5),
      );
    });
  });
}
