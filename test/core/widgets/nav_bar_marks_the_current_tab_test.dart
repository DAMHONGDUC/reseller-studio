import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The five destinations under test.
final class _NavDestinations {
  static const List<SdNavDestinationV3> all = <SdNavDestinationV3>[
    SdNavDestinationV3(icon: Icons.home, label: 'Home'),
    SdNavDestinationV3(icon: Icons.inventory_2, label: 'Inventory'),
    SdNavDestinationV3(icon: Icons.receipt_long, label: 'Orders'),
    SdNavDestinationV3(icon: Icons.bar_chart, label: 'Analytics'),
    SdNavDestinationV3(icon: Icons.menu, label: 'More'),
  ];
}

/// Holds the selection so a test can change it **without** re-pumping.
///
/// `pumpScreen` ends in `pumpAndSettle`, so pumping the bar again with a new
/// index lands it already settled and every assertion about the travel would
/// pass without the travel ever happening. Tapping a destination here is also
/// the real path a seller takes.
class _NavBarHost extends StatefulWidget {
  const _NavBarHost({required this.initialIndex});

  final int initialIndex;

  @override
  State<_NavBarHost> createState() => _NavBarHostState();
}

class _NavBarHostState extends State<_NavBarHost> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    extendBody: true,
    body: const SizedBox.expand(),
    bottomNavigationBar: SdGlassNavBarV3(
      destinations: _NavDestinations.all,
      selectedIndex: _index,
      onSelected: (int index) => setState(() => _index = index),
    ),
  );
}

/// The current tab is marked the way iOS 26 marks it: the **glyph fills in**
/// and a **glass capsule slides under it**, stretching along the way.
///
/// `FILL` is a variable-font axis, so weight is a real second signal alongside
/// colour — which colour alone must never be, least of all on glass with a
/// moving list showing through it. The capsule is the third signal, and it is
/// glass rather than a filled shape: a flat pill behind the icon is Material's
/// idiom and reads as a foreign control inside iOS chrome.
/// See `docs/rules/DECISIONS.md` § The tab bar's selected indicator came back.
void main() {
  Future<void> pumpBar(WidgetTester tester, int selected) =>
      pumpScreen(tester, _NavBarHost(initialIndex: selected));

  /// Tap a destination and let the capsule finish travelling.
  Future<void> tapTab(WidgetTester tester, int index) async {
    await tester.tap(find.text(_NavDestinations.all[index].label));
    await tester.pumpAndSettle();
  }

  /// How filled each destination's glyph is, in destination order.
  List<double?> fills(WidgetTester tester) => tester
      .widgetList<Icon>(
        find.descendant(
          of: find.byType(SdGlassNavBarV3),
          matching: find.byType(Icon),
        ),
      )
      .map((Icon icon) => icon.fill)
      .toList();

  /// The capsule's real rect. Measured rather than read off a widget's
  /// arguments: where it is and how wide it is mid-flight *are* layout.
  Rect capsule(WidgetTester tester) =>
      tester.getRect(find.byKey(SdGlassNavBarV3.selectedCapsuleKey));

  testWidgets('exactly one destination is filled in', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 2);

    expect(fills(tester).where((double? fill) => fill == 1), hasLength(1));
    expect(fills(tester)[2], 1);
  });

  testWidgets('the fill moves with the selection', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    expect(fills(tester).first, 1);
    expect(fills(tester).last, 0);

    await tapTab(tester, _NavDestinations.all.length - 1);

    expect(fills(tester).first, 0);
    expect(fills(tester).last, 1);
  });

  testWidgets('the capsule steps evenly and never reaches its neighbour', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    final List<double> centres = <double>[];

    for (int i = 0; i < _NavDestinations.all.length; i++) {
      await tapTab(tester, i);
      centres.add(capsule(tester).center.dx);
    }

    final double step = centres[1] - centres[0];

    // One destination's share of the bar, derived from the capsule's own
    // travel rather than re-deriving the bar's inner width in the test.
    for (int i = 1; i < centres.length; i++) {
      expect(centres[i] - centres[i - 1], closeTo(step, 0.01));
    }

    // The row of capsule positions is centred in the bar.
    final Rect bar = tester.getRect(find.byType(SdGlassNavBarV3));

    expect((centres.first + centres.last) / 2, closeTo(bar.center.dx, 0.01));

    // It keeps its inset, so two adjacent destinations never share an edge.
    expect(capsule(tester).width, lessThan(step));
  });

  testWidgets('the capsule travels rather than jumping', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    final double start = capsule(tester).center.dx;

    await tester.tap(find.text(_NavDestinations.all.last.label));
    await tester.pump();
    await tester.pump(SdMotionV3.normal ~/ 2);

    final double midFlight = capsule(tester).center.dx;

    await tester.pumpAndSettle();

    // One shape moving is what says the five destinations are a single row.
    expect(midFlight, greaterThan(start));
    expect(midFlight, lessThan(capsule(tester).center.dx));
  });

  testWidgets('the capsule stretches on the way and settles back', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    final Rect resting = capsule(tester);

    await tester.tap(find.text(_NavDestinations.all.last.label));
    await tester.pump();
    await tester.pump(SdMotionV3.normal ~/ 2);

    final Rect midFlight = capsule(tester);

    // Squash and stretch: pulled long and thin at the midpoint, which is what
    // makes the move read as one piece of glass being carried rather than a
    // shape being repositioned.
    expect(midFlight.width, greaterThan(resting.width));
    expect(midFlight.height, lessThan(resting.height));

    await tester.pumpAndSettle();

    expect(capsule(tester).size, resting.size);
  });

  testWidgets('a re-tap of the current tab stretches nothing', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 2);

    final Rect before = capsule(tester);

    await tester.tap(find.text(_NavDestinations.all[2].label));
    await tester.pump();
    await tester.pump(SdMotionV3.normal ~/ 2);

    // Nothing moved, so there is nothing to animate — a capsule that pulsed
    // on every re-tap of the current tab would read as a glitch.
    expect(capsule(tester), before);
  });

  testWidgets('nothing flat is painted behind the current glyph', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    // The mark is glass, never a filled shape: a tinted pill behind the icon
    // is Material's idiom and reads as a foreign control inside iOS chrome.
    final Iterable<BoxDecoration> painted = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(SdGlassNavBarV3),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((DecoratedBox box) => box.decoration as BoxDecoration);

    expect(
      painted.where(
        (BoxDecoration decoration) =>
            decoration.color != null && decoration.color!.a > 0,
      ),
      isEmpty,
    );
  });

  testWidgets('the bar never fringes the figures underneath it', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    final BuildContext context = tester.element(find.byType(SdGlassNavBarV3));

    // The bar sits over columns of money, and chromatic aberration on small
    // tabular figures is the fastest way to make a number hard to read.
    expect(SdGlassNavBarV3.barSettings(context).chromaticAberration, 0);
    expect(
      SdGlassNavBarV3.selectedCapsuleSettings(context).chromaticAberration,
      0,
    );
  });

  testWidgets('every destination still shows its label', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    // Five glyphs with no words is a memory test — the labels are not a
    // detail the capsule replaces.
    for (final SdNavDestinationV3 destination in _NavDestinations.all) {
      expect(find.text(destination.label), findsOneWidget);
    }
  });

  testWidgets('the bar sits in the depth band of a sheet, not of a card', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    final BuildContext context = tester.element(find.byType(SdGlassNavBarV3));
    final Iterable<BoxShadow> shadows = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(SdGlassNavBarV3),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((DecoratedBox box) => box.decoration as BoxDecoration)
        .expand(
          (BoxDecoration decoration) =>
              decoration.boxShadow ?? const <BoxShadow>[],
        );

    // Owner's call that the bar should read as more present: it never scrolls
    // away, so it does not belong at the same height as the cards it passes
    // over.
    expect(shadows, containsAll(SdElevationV3.modal(context)));
  });
}
