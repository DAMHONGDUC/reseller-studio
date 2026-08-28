import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The current tab is marked the way iOS 26 marks it: the **glyph fills in**
/// and a **glass capsule slides under it**.
///
/// `FILL` is a variable-font axis, so weight is a real second signal alongside
/// colour — which colour alone must never be, least of all on glass with a
/// moving list showing through it. The capsule is the third signal, and it is
/// glass rather than a filled shape: a flat pill behind the icon is Material's
/// idiom and reads as a foreign control inside iOS chrome.
/// See `docs/rules/DECISIONS.md` § The tab bar's selected indicator came back.
void main() {
  const List<SdNavDestinationV3> destinations = <SdNavDestinationV3>[
    SdNavDestinationV3(icon: Icons.home, label: 'Home'),
    SdNavDestinationV3(icon: Icons.inventory_2, label: 'Inventory'),
    SdNavDestinationV3(icon: Icons.receipt_long, label: 'Orders'),
    SdNavDestinationV3(icon: Icons.bar_chart, label: 'Analytics'),
    SdNavDestinationV3(icon: Icons.menu, label: 'More'),
  ];

  Future<void> pumpBar(WidgetTester tester, int selected) => pumpScreen(
    tester,
    SdScaffoldV3(
      extendBody: true,
      body: const SizedBox.expand(),
      bottomNavigationBar: SdGlassNavBarV3(
        destinations: destinations,
        selectedIndex: selected,
        onSelected: (int _) {},
      ),
    ),
  );

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

    await pumpBar(tester, destinations.length - 1);

    expect(fills(tester).first, 0);
    expect(fills(tester).last, 1);
  });

  /// Where the capsule is aligned across the bar, and how wide a slot it
  /// covers.
  (Alignment, double) capsule(WidgetTester tester) {
    final AnimatedAlign align = tester.widget<AnimatedAlign>(
      find.descendant(
        of: find.byType(SdGlassNavBarV3),
        matching: find.byType(AnimatedAlign),
      ),
    );
    final FractionallySizedBox box = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byType(AnimatedAlign),
        matching: find.byType(FractionallySizedBox),
      ),
    );

    return (align.alignment as Alignment, box.widthFactor!);
  }

  testWidgets('one capsule covers exactly one destination slot', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    final (Alignment alignment, double widthFactor) = capsule(tester);

    expect(widthFactor, 1 / destinations.length);
    expect(alignment.x, -1);
  });

  testWidgets('the capsule slides to the selected destination', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, destinations.length - 1);

    // It travels rather than fading in and out — one shape moving is what
    // says the five destinations are a single row.
    expect(capsule(tester).$1.x, 1);

    await pumpBar(tester, 2);
    await tester.pumpAndSettle();

    expect(capsule(tester).$1.x, 0);
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
    // detail the indicator replaces.
    for (final SdNavDestinationV3 destination in destinations) {
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
