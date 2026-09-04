import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_list_row.dart';
import 'package:reseller_studio/core/widgets/app_row_chevron.dart';
import 'package:reseller_studio/core/widgets/item_card.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **A row-shaped card is info at the start and an affordance at the end** —
/// owner's rule, in `docs/rules/DESIGN_SYSTEM.md`.
///
/// A tappable row with nothing at its end is one big tap target that says so
/// nowhere, and the seller learns the screen by poking at it. `AppListRow`
/// draws the chevron by default, so the way this goes wrong is a call site
/// passing `showChevron: false` while still passing an `onTap` — which is
/// what this reads the source for.
///
/// **Source rather than a pumped tree**, the way `quick_action_test.dart`
/// reads screens off disk: the rule is about every call site in the app, and
/// pumping every screen that holds a list would test a fraction of them and
/// call it all.
void main() {
  /// Every `AppListRow(...)` call in `lib/`, as source text.
  List<({String file, int line, String body})> rows() {
    final List<({String file, int line, String body})> found =
        <({String file, int line, String body})>[];

    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // The widget's own declaration is not a call site.
      if (entity.path.endsWith('app_list_row.dart')) continue;

      final String source = entity.readAsStringSync();

      for (final Match match in RegExp('AppListRow\\(').allMatches(source)) {
        int depth = 0;
        int i = match.end - 1;

        while (i < source.length) {
          if (source[i] == '(') {
            depth++;
          } else if (source[i] == ')') {
            depth--;
            if (depth == 0) break;
          }
          i++;
        }

        found.add((
          file: entity.path,
          line: '\n'.allMatches(source.substring(0, match.start)).length + 1,
          body: source.substring(match.start, i + 1),
        ));
      }
    }

    return found;
  }

  test('every AppListRow call site is found, or this test proves nothing', () {
    // A regex that matched nothing would pass the assertion below for the
    // worst possible reason.
    expect(rows().length, greaterThan(20));
  });

  test('a tappable row never hides its chevron without a trailing widget', () {
    final List<String> offenders = <String>[];

    for (final ({String file, int line, String body}) row in rows()) {
      final bool hidesChevron = row.body.contains('showChevron: false');
      final bool isTappable = RegExp(r'onTap:\s*(?!null\b)').hasMatch(row.body);
      final bool hasTrailing =
          row.body.contains('trailing:') || row.body.contains('trailingText:');

      if (hidesChevron && isTappable && !hasTrailing) {
        offenders.add('${row.file}:${row.line}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these rows open something and show nothing saying so — drop '
          '`showChevron: false`, or give the row a trailing widget that is '
          'itself the interaction:\n${offenders.join('\n')}',
    );
  });

  testWidgets('an inert row draws no chevron, whatever it was passed', (
    WidgetTester tester,
  ) async {
    // The older half of the rule, and it is enforced by the widget rather
    // than by a call site: an affordance that leads nowhere is worse than
    // none. Asserted on the rendered tree, so no inert row has to write
    // `showChevron: false` to be correct.
    await pumpScreen(
      tester,
      const AppListCard(
        children: <Widget>[AppListRow(title: 'A fact, not a door')],
      ),
    );

    expect(find.byType(AppRowChevron), findsNothing);
  });

  testWidgets('every end glyph in a card sits at the same inset', (
    WidgetTester tester,
  ) async {
    // The measurable half of "space between": a column of end glyphs that
    // does not line up reads as a mistake even to somebody who cannot say
    // which card is wrong. The item card's dots were 16 points short of the
    // chevrons, because a Material 3 `IconButton` centres its glyph in a 48pt
    // target and ignores the `constraints` asking it not to.
    await pumpScreen(tester, const InventoryScreen());

    final Rect itemCard = tester.getRect(find.byType(ItemCard).first);
    final Rect dots = tester.getRect(
      find
          .descendant(
            of: find.byType(ItemCard).first,
            matching: find.byType(SdIconV3),
          )
          .last,
    );

    await pumpScreen(tester, const OrdersScreen());

    final Finder chevron = find.byType(AppRowChevron).first;
    final Rect orderCard = tester.getRect(
      find.ancestor(of: chevron, matching: find.byType(SdCardV3)).first,
    );

    expect(
      itemCard.right - dots.right,
      moreOrLessEquals(
        orderCard.right - tester.getRect(chevron).right,
        epsilon: 0.5,
      ),
    );
  });

  testWidgets('a tappable row draws one', (WidgetTester tester) async {
    await pumpScreen(
      tester,
      AppListCard(
        children: <Widget>[AppListRow(title: 'A door', onTap: () {})],
      ),
    );

    expect(find.byType(AppRowChevron), findsOneWidget);
  });
}
