import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/app_list_row.dart';
import 'package:reseller_studio/core/widgets/app_row_chevron.dart';

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

    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true)) {
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
      final bool isTappable = RegExp(
        r'onTap:\s*(?!null\b)',
      ).hasMatch(row.body);
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
