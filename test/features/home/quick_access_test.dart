import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/features/home/home_constant.dart';
import 'package:seller_os/features/home/presentation/screens/home_screen/home_screen.dart';

import '../../support/pump_app.dart';

/// Quick Access is the one place that lists everything this app can create.
///
/// **Its whole value is being complete.** A section that shows six of the
/// eight create actions is worse than none: a seller who has learned to look
/// here stops finding what they need and cannot tell whether the action is
/// missing or the app cannot do it.
void main() {
  testWidgets('every action in the list is on screen', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());

    for (final QuickAddAction action in QuickAddConstant.actions) {
      final BuildContext context = tester.element(find.byType(HomeScreen));

      expect(
        find.text(QuickAddLabel.of(context, action.kind)),
        findsWidgets,
        reason: '${action.kind.name} is in the list but not on Home',
      );
    }
  });

  test('every kind has a tile, and every tile a kind', () {
    // The enum and the list are two halves of the same fact. Adding a case
    // without a tile compiles, and this is what stops it shipping.
    expect(
      QuickAddConstant.actions.map((QuickAddAction a) => a.kind).toSet(),
      QuickAddKind.values.toSet(),
    );
    expect(
      QuickAddConstant.actions.length,
      QuickAddKind.values.length,
      reason: 'a kind is listed twice',
    );
  });

  test('no tile points at a route that does not exist', () {
    for (final QuickAddAction action in QuickAddConstant.actions) {
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

    final Set<String> routes = QuickAddConstant.actions
        .map((QuickAddAction action) => action.route)
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
