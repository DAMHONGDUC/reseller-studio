import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The current tab is marked by a **shape**, not only by a colour.
///
/// Hue alone is unreadable to a colour-blind seller, and this bar is glass
/// with a moving list showing through it — the one place in the app where a
/// tint has the least to work with. The indicator pill is what makes the
/// current tab findable at a glance.
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

  /// The pill behind each glyph, in destination order.
  List<Color?> indicators(WidgetTester tester) => tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .map(
        (AnimatedContainer container) =>
            (container.decoration! as BoxDecoration).color,
      )
      .toList();

  testWidgets('exactly one destination carries the pill', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 2);

    final List<Color?> filled = indicators(tester)
        .where((Color? color) => color != null && color.a > 0)
        .toList();

    expect(filled, hasLength(1));
  });

  testWidgets('the pill moves with the selection', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    expect(indicators(tester).first!.a, greaterThan(0));
    expect(indicators(tester).last!.a, 0);

    await pumpBar(tester, destinations.length - 1);

    expect(indicators(tester).first!.a, 0);
    expect(indicators(tester).last!.a, greaterThan(0));
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
