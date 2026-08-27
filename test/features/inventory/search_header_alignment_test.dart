import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The docked search field and the actions beside it share one row.
///
/// Asserted on rendered rectangles, because "looks centred" is exactly the
/// judgement that goes wrong by three points and stays wrong for months.
void main() {
  /// Scrolls far enough for the header to reach `minExtent`.
  Future<void> dock(WidgetTester tester) async {
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('docked, the field and the actions share a centre line', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await dock(tester);

    final Rect field = tester.getRect(find.byType(SdSearchFieldV3));
    final Rect action = tester.getRect(find.byType(IconButton).last);

    expect(
      field.center.dy,
      moreOrLessEquals(action.center.dy, epsilon: 0.5),
      reason: 'field ${field.top}–${field.bottom}, '
          'action ${action.top}–${action.bottom}',
    );
  });

  testWidgets('docked, what is INSIDE the pill is centred too', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await dock(tester);

    final Rect action = tester.getRect(find.byType(IconButton).last);

    // The bug this test exists for: the pill's own rectangle was centred
    // while its text and magnifier sat ten points above the middle of it, so
    // an assertion on the box alone passed and the bar still looked wrong.
    expect(
      tester.getRect(find.byType(EditableText).first).center.dy,
      moreOrLessEquals(action.center.dy, epsilon: 0.5),
      reason: 'the search text is not on the actions centre line',
    );
    expect(
      tester.getRect(find.byIcon(Icons.search_rounded)).center.dy,
      moreOrLessEquals(action.center.dy, epsilon: 0.5),
      reason: 'the magnifier is not on the actions centre line',
    );
  });

  testWidgets('expanded, the content is centred in its own row', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    final Rect field = tester.getRect(find.byType(SdSearchFieldV3));

    expect(
      tester.getRect(find.byType(EditableText).first).center.dy,
      moreOrLessEquals(field.center.dy, epsilon: 0.5),
    );
    expect(
      tester.getRect(find.byIcon(Icons.search_rounded)).center.dy,
      moreOrLessEquals(field.center.dy, epsilon: 0.5),
    );
  });

  testWidgets('the magnifier sits half the height in from the edge', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());

    final Rect field = tester.getRect(find.byType(SdSearchFieldV3));
    final Rect magnifier = tester.getRect(find.byIcon(Icons.search_rounded));

    // Centred in the stadium's round cap. Also where the clear button's glyph
    // lands on the right, so the pill reads symmetrical at any height.
    //
    // The tolerance covers the border, which sits inside the measured rect
    // and pushes the content in by its own width.
    expect(
      magnifier.center.dx - field.left,
      moreOrLessEquals(field.height / 2, epsilon: 2),
    );
  });

  testWidgets('docked, the field is the same height as an action slot', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const InventoryScreen());
    await dock(tester);

    // One height for both controls is what makes them read as one row of
    // chrome rather than two things centred near each other.
    expect(
      tester.getRect(find.byType(SdSearchFieldV3)).height,
      moreOrLessEquals(SdAppBarActionV3.slot, epsilon: 0.5),
    );
  });
}
