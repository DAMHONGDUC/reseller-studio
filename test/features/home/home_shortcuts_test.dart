import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/core/widgets/option_picker_sheet.dart';
import 'package:reseller_studio/features/home/home_constant.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:reseller_studio/reseller_studio_app.dart';
import 'package:system_design/index.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_app.dart';
import 'premium_subscription.dart';

/// Home's shortcut row: Add stock, Quick Action, Record sale.
///
/// **Their value is one tap from the first screen**, directly under Needs
/// Attention — a shortcut a seller has to scroll to is one more row of a
/// dashboard (`lib/features/home/CLAUDE.md`).
void main() {
  setUpAll(loadAppFonts);

  /// The button, not a Quick Action row or header of the same name further
  /// down: only the shortcut is an `InkWell` inside a `Material` with a shape.
  Finder buttonFor(BuildContext context, HomeShortcut shortcut) => find
      .ancestor(
        of: find.text(shortcut.label(context)),
        matching: find.byType(InkWell),
      )
      .first;

  testWidgets('all three are on screen before anything is scrolled', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: premiumSubscription(),
    );

    final BuildContext context = tester.element(find.byType(HomeScreen));
    final double screenHeight = tester.view.physicalSize.height / 3;

    for (final HomeShortcut shortcut in HomeShortcut.values) {
      final Finder button = buttonFor(context, shortcut);

      expect(button, findsOneWidget, reason: '${shortcut.name} is not on Home');
      expect(
        tester.getRect(button).bottom,
        lessThan(screenHeight),
        reason: '${shortcut.name} needs a scroll to reach',
      );
    }
  });

  testWidgets('they sit under Needs Attention and above the numbers', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: premiumSubscription(),
    );

    final BuildContext context = tester.element(find.byType(HomeScreen));
    final Rect first = tester.getRect(
      buttonFor(context, HomeShortcut.values.first),
    );

    // Owner's rule: what needs attention opens the screen, the fast actions
    // follow it, and the figures come after both.
    expect(
      tester.getRect(find.text('Needs Attention')).bottom,
      lessThan(first.top),
    );
    expect(
      tester.getRect(find.text('Performance')).top,
      greaterThan(first.bottom),
    );
  });

  testWidgets('Add stock opens the shared sheet with its three ways in', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: premiumSubscription(),
    );

    final BuildContext context = tester.element(find.byType(HomeScreen));

    await tester.tap(buttonFor(context, HomeShortcut.addStock));
    await tester.pumpAndSettle();

    final Finder sheet = find.byType(OptionPickerSheet<String>);

    expect(sheet, findsOneWidget);
    for (final String option in <String>[
      'Quick Add',
      'Scan',
      'Take stock in',
    ]) {
      expect(
        find.descendant(of: sheet, matching: find.text(option)),
        findsOneWidget,
        reason: '$option is not offered',
      );
    }
  });

  testWidgets('Quick Action scrolls Home to its section', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: premiumSubscription(),
    );

    final BuildContext context = tester.element(find.byType(HomeScreen));
    final Finder header = find.widgetWithText(
      SdSectionHeaderV3,
      'Quick Action',
    );
    final double viewport =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(tester.getRect(header).top, greaterThan(viewport));

    await tester.tap(buttonFor(context, HomeShortcut.quickAction));
    await tester.pumpAndSettle();

    expect(tester.getRect(header).top, lessThan(viewport));
  });

  testWidgets('Record sale and the app bar’s Scan open their screens', (
    WidgetTester tester,
  ) async {
    for (final (String what, String route) in <(String, String)>[
      ('record sale', AppRoutes.recordSale),
      ('scan', AppRoutes.scanner),
    ]) {
      final GoRouter router = await pumpRoutedScreen(
        tester,
        const HomeScreen(),
        overrides: premiumSubscription(),
      );
      final BuildContext context = tester.element(find.byType(HomeScreen));

      await tester.tap(
        what == 'scan'
            ? find.byTooltip('Scan')
            : buttonFor(context, HomeShortcut.recordSale),
      );
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), route, reason: '$what went astray');
    }
  });

  test('three shortcuts, Add stock first', () {
    expect(HomeShortcut.values, hasLength(3));
    expect(HomeShortcut.values.first, HomeShortcut.addStock);
  });

  // A label cut off mid-word is a content bug that only shows once
  // translated, so every shipping locale is pumped at phone width.
  for (final Locale locale in ResellerStudioApp.shippingLocales) {
    testWidgets('every label fits its button — ${locale.languageCode}', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l10n = lookupAppLocalizations(locale);

      await pumpScreen(
        tester,
        const HomeScreen(),
        overrides: premiumSubscription(),
        locale: locale,
      );

      final BuildContext context = tester.element(find.byType(HomeScreen));

      for (final HomeShortcut shortcut in HomeShortcut.values) {
        final String label = shortcut.label(context);
        final RenderParagraph paragraph = tester.renderObject(
          find.descendant(
            of: buttonFor(context, shortcut),
            matching: find.text(label),
          ),
        );

        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: '${l10n.localeName}: "$label"',
        );
      }
    });
  }
}
