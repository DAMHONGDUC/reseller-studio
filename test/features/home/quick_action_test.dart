import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/extensions/context_extensions.dart';
import 'package:reseller_studio/core/widgets/app_list_row.dart';
import 'package:reseller_studio/features/home/home_constant.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';

import '../../support/pump_app.dart';

/// Quick Action lists everything this app can create, and — last — About.
///
/// **Its whole value is being complete.** A section that shows six of the
/// eight create actions is worse than none: a seller who has learned to look
/// here stops finding what they need and cannot tell whether the action is
/// missing or the app cannot do it.
void main() {
  /// Quick Access sits at the bottom, so nothing in it is built until the
  /// list is scrolled there — `find.text` matches built widgets only.
  Future<void> toEnd(WidgetTester tester) async {
    for (int i = 0; i < 12; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pump();
    }

    await tester.pumpAndSettle();
  }

  testWidgets('every action in the list is on screen', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());
    await toEnd(tester);

    final BuildContext context = tester.element(find.byType(HomeScreen));

    for (final QuickAction action in QuickActionConstant.actions) {
      expect(
        find.text(QuickActionLabel.of(context, action.kind)),
        findsWidgets,
        reason: '${action.kind.name} is in the list but not on Home',
      );
    }
  });

  testWidgets('every action is a row, and they are the last thing on Home', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());
    await toEnd(tester);

    final BuildContext context = tester.element(find.byType(HomeScreen));

    // Owner's rule. Home answers "what needs attention today" first; a
    // launcher above the figures makes the screen open on the wrong thing.
    final double sectionTop = tester
        .getRect(
          find.text(
            QuickActionLabel.of(context, QuickActionConstant.actions.first.kind),
          ),
        )
        .top;

    for (final String earlier in <String>[
      'Needs Attention',
      'Performance',
      'Recent Activity',
    ]) {
      final Finder header = find.text(earlier);

      if (header.evaluate().isEmpty) continue;

      expect(
        tester.getRect(header).top,
        lessThan(sectionTop),
        reason: '$earlier is below Quick Access',
      );
    }

    // One `AppListRow` per action — rows, not tiles. Scoped to the card the
    // actions are in: Quick Access sits in a second card below it, and
    // counting both would pass whatever the split looked like.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text(
            QuickActionLabel.of(context, QuickActionConstant.actions.first.kind),
          ),
          matching: find.byType(AppListCard),
        ),
        matching: find.byType(AppListRow),
      ),
      findsNWidgets(QuickActionConstant.actions.length),
    );
  });

  testWidgets('About is in the list, and it is last', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());
    await toEnd(tester);

    final BuildContext context = tester.element(find.byType(HomeScreen));

    // Owner's rule: the two rows here that do not create something go at the
    // end — About last, Flow overview just above it — so a seller scanning for
    // "add" never steps over them.
    expect(QuickActionConstant.actions.last.kind, QuickActionKind.about);
    expect(
      QuickActionConstant.actions[QuickActionConstant.actions.length - 2].kind,
      QuickActionKind.flowOverview,
    );

    final double aboutTop = tester
        .getRect(find.text(context.l10n.moreAbout))
        .top;

    for (final QuickAction action in QuickActionConstant.actions) {
      if (action.kind == QuickActionKind.about) continue;

      expect(
        tester
            .getRect(find.text(QuickActionLabel.of(context, action.kind)))
            .top,
        lessThan(aboutTop),
        reason: '${action.kind.name} sits below About',
      );
    }
  });

  test('every kind has a tile, and every tile a kind', () {
    // The enum and the list are two halves of the same fact. Adding a case
    // without a tile compiles, and this is what stops it shipping.
    expect(
      QuickActionConstant.actions.map((QuickAction a) => a.kind).toSet(),
      QuickActionKind.values.toSet(),
    );
    expect(
      QuickActionConstant.actions.length,
      QuickActionKind.values.length,
      reason: 'a kind is listed twice',
    );
  });

  test('no tile points at a route that does not exist', () {
    for (final QuickAction action in QuickActionConstant.actions) {
      // Flow overview opens a sheet rather than a route (owner's rule), and
      // it is the only row allowed to.
      if (action.route == null) {
        expect(action.kind, QuickActionKind.flowOverview);

        continue;
      }

      expect(action.route, startsWith('/'));
      // A parameterised path cannot be pushed without its argument, so a
      // Quick Access tile must never be given one.
      expect(
        action.route,
        isNot(contains(':')),
        reason: '${action.kind.name} points at a parameterised route',
      );
    }
  });

  /// **The audit.** Every screen wearing `AppAddFabScaffold` is a screen that
  /// creates something, which is owner's rule for create actions — so every
  /// one of them has to be reachable from Quick Access.
  ///
  /// Read off the source rather than a hand-kept list, so a new create screen
  /// fails this the day it is written instead of quietly never appearing on
  /// Home.
  test('every screen with an add button is reachable from Quick Access', () {
    final List<String> screens = <String>[];

    for (final FileSystemEntity entity
        in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final String source = entity.readAsStringSync();

      if (!source.contains('AppAddFabScaffold(')) continue;

      screens.add(entity.path);
    }

    // Sanity: the audit is worthless if it found nothing to audit.
    expect(screens, isNotEmpty);

    final Set<String> routes = QuickActionConstant.actions
        .map((QuickAction action) => action.route)
        .nonNulls
        .toSet();

    // Each create screen's own route has to be one Quick Access opens, or the
    // action it owns cannot be started from Home.
    const Map<String, String> routeForScreen = <String, String>{
      'expenses_screen': '/more/expenses',
      'categories_screen': '/more/categories',
      'locations_screen': '/inventory/locations',
      'sources_screen': '/more/sourcing/sources',
      'purchases_screen': '/more/sourcing/purchases/new',
      'inventory_screen': '/inventory/quick-add',
      'team_screen': '/more/team',
    };

    for (final String path in screens) {
      final String? expected = routeForScreen.entries
          .where((MapEntry<String, String> entry) => path.contains(entry.key))
          .map((MapEntry<String, String> entry) => entry.value)
          .firstOrNull;

      expect(
        expected,
        isNotNull,
        reason: '$path has an add button that this audit does not know about '
            '— add it to Quick Access and to this map',
      );
      expect(
        routes,
        contains(expected),
        reason: '$path creates something Quick Access cannot start',
      );
    }
  });
}
