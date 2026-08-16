import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The current tab is marked the way iOS marks it: the **glyph fills in**,
/// and nothing appears behind it.
///
/// A shape behind the icon is Material's idiom and reads as a foreign control
/// sitting inside iOS chrome. `FILL` is a variable-font axis, so weight is a
/// real second signal alongside colour — which colour alone must never be,
/// least of all on glass with a moving list showing through it.
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

  testWidgets('nothing is drawn behind the current glyph', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    // The Material indicator pill was tried and removed: iOS does not put a
    // shape behind a tab bar glyph, and one here read as a foreign control.
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
