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

/// Holds selection so a test follows the same tap path a seller does.
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

/// The bar is glyph-only: five equal segments, one icon each, and a fixed-width
/// tinted thumb sliding under the selected one. Labels remain semantics only.
void main() {
  Future<void> pumpBar(WidgetTester tester, int selected) =>
      pumpScreen(tester, _NavBarHost(initialIndex: selected));

  Finder glyph(int index) => find.byIcon(_NavDestinations.all[index].icon);

  Future<void> tapTab(WidgetTester tester, int index) async {
    await tester.tap(glyph(index));
    await tester.pumpAndSettle();
  }

  Rect segment(WidgetTester tester, int index) => tester.getRect(
    find
        .descendant(
          of: find.byType(SdGlassNavBarV3),
          matching: find.byType(InkWell),
        )
        .at(index),
  );

  List<double?> fills(WidgetTester tester) => tester
      .widgetList<Icon>(
        find.descendant(
          of: find.byType(SdGlassNavBarV3),
          matching: find.byType(Icon),
        ),
      )
      .map((Icon icon) => icon.fill)
      .toList();

  Rect capsule(WidgetTester tester) =>
      tester.getRect(find.byKey(SdGlassNavBarV3.selectedCapsuleKey));

  testWidgets('exactly one destination is filled in', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 2);

    expect(fills(tester).where((double? fill) => fill == 1), hasLength(1));
    expect(fills(tester)[2], 1);
  });

  testWidgets('the fill moves with the selection', (WidgetTester tester) async {
    await pumpBar(tester, 0);

    await tapTab(tester, _NavDestinations.all.length - 1);

    expect(fills(tester).first, 0);
    expect(fills(tester).last, 1);
  });

  testWidgets('all five segments have the same width', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 2);

    final double first = segment(tester, 0).width;

    for (int i = 1; i < _NavDestinations.all.length; i++) {
      expect(segment(tester, i).width, closeTo(first, 0.01));
    }
  });

  testWidgets('the pill is compact without shrinking its touch targets', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 2);

    final Rect first = segment(tester, 0);
    final Rect last = segment(tester, _NavDestinations.all.length - 1);
    final double screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;

    expect(
      first.height,
      closeTo(SdContentPaddingV3.floatingBarHeight, 0.01),
    );
    expect(first.height, greaterThanOrEqualTo(SdSpacingConstant.h48));
    expect(
      first.left,
      closeTo(SdContentPaddingV3.floatingBarHorizontal, 0.01),
    );
    expect(
      screenWidth - last.right,
      closeTo(SdContentPaddingV3.floatingBarHorizontal, 0.01),
    );
  });

  testWidgets('labels are not painted', (WidgetTester tester) async {
    await pumpBar(tester, 0);

    for (final SdNavDestinationV3 destination in _NavDestinations.all) {
      expect(find.text(destination.label), findsNothing);
    }
  });

  testWidgets('every destination still has a semantic label', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    final Iterable<Semantics> segments = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(SdGlassNavBarV3),
        matching: find.byType(Semantics),
      ),
    );

    for (final SdNavDestinationV3 destination in _NavDestinations.all) {
      expect(
        segments.where(
          (Semantics item) => item.properties.label == destination.label,
        ),
        isNotEmpty,
        reason: '${destination.label} is not announced',
      );
    }
  });

  testWidgets('the capsule is fixed to one selected segment', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 3);

    final Rect segmentRect = segment(tester, 3);
    final Rect capsuleRect = capsule(tester);

    expect(capsuleRect.center.dx, closeTo(segmentRect.center.dx, 0.01));
    expect(
      capsuleRect.width,
      closeTo(
        segmentRect.width - SdContentPaddingV3.selectedTabInset.horizontal,
        0.01,
      ),
    );
  });

  testWidgets('the fixed-width capsule travels rather than jumping', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    final Rect before = capsule(tester);

    await tester.tap(glyph(_NavDestinations.all.length - 1));
    await tester.pump();
    await tester.pump(SdMotionV3.normal ~/ 2);

    final Rect midFlight = capsule(tester);

    await tester.pumpAndSettle();

    expect(midFlight.center.dx, greaterThan(before.center.dx));
    expect(midFlight.center.dx, lessThan(capsule(tester).center.dx));
    expect(midFlight.width, moreOrLessEquals(before.width));
    expect(midFlight.height, moreOrLessEquals(before.height));
  });

  testWidgets('one visible tinted thumb marks the current segment', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    final DecoratedBox thumb = tester.widget<DecoratedBox>(
      find.byKey(SdGlassNavBarV3.selectedCapsuleKey),
    );
    final BoxDecoration decoration = thumb.decoration as BoxDecoration;
    final BuildContext context = tester.element(find.byType(SdGlassNavBarV3));

    expect(
      decoration.color,
      context.colorScheme3.primary.withValues(
        alpha: SdGlassNavBarV3.selectedThumbOpacity,
      ),
    );
  });

  testWidgets('the bar never fringes figures underneath it', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, 0);

    final BuildContext context = tester.element(find.byType(SdGlassNavBarV3));

    expect(SdGlassNavBarV3.barSettings(context).chromaticAberration, 0);
  });

  testWidgets('the bar sits in the depth band of a sheet', (
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

    expect(shadows, containsAll(SdElevationV3.modal(context)));
  });
}
