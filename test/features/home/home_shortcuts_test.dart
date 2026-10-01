import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reseller_studio/features/home/home_constant.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:reseller_studio/l10n/gen/app_localizations.dart';
import 'package:reseller_studio/reseller_studio_app.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_app.dart';
import 'premium_subscription.dart';

/// The three create actions in Home's shortcut row.
///
/// **Their value is one tap from the first screen**, directly under Needs
/// Attention — a shortcut a seller has to scroll to is one more row of a
/// dashboard (`lib/features/home/CLAUDE.md`).
void main() {
  setUpAll(loadAppFonts);

  /// The button, not the Quick Action row of the same name further down:
  /// only the shortcut is an `InkWell` inside a `Material` with a shape.
  Finder buttonFor(BuildContext context, QuickActionKind kind) => find
      .ancestor(
        of: find.text(QuickActionLabel.of(context, kind)),
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

    for (final QuickActionKind kind in HomeShortcutConstant.shortcuts) {
      final Finder button = buttonFor(context, kind);

      expect(button, findsOneWidget, reason: '${kind.name} is not on Home');
      expect(
        tester.getRect(button).bottom,
        lessThan(screenHeight),
        reason: '${kind.name} needs a scroll to reach',
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
      buttonFor(context, HomeShortcutConstant.shortcuts.first),
    );

    // Owner's rule: what needs attention opens the screen, the fast actions
    // follow it, and the figures come after both.
    expect(
      tester.getRect(find.text('Needs Attention')).bottom,
      lessThan(first.top),
    );

    await tester.scrollUntilVisible(find.text('Performance'), 200);

    expect(
      tester.getRect(find.text('Performance')).top,
      greaterThan(
        tester
            .getRect(buttonFor(context, HomeShortcutConstant.shortcuts.first))
            .bottom,
      ),
    );
  });

  testWidgets('each button opens its Quick Action row’s route', (
    WidgetTester tester,
  ) async {
    for (final QuickActionKind kind in HomeShortcutConstant.shortcuts) {
      final GoRouter router = await pumpRoutedScreen(
        tester,
        const HomeScreen(),
        overrides: premiumSubscription(),
      );
      final BuildContext context = tester.element(find.byType(HomeScreen));

      await tester.tap(buttonFor(context, kind));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.toString(),
        HomeShortcutConstant.actionFor(kind).route,
        reason: '${kind.name} went somewhere its row does not',
      );
    }
  });

  test('three shortcuts, each a Quick Action, none twice', () {
    expect(HomeShortcutConstant.shortcuts, hasLength(3));
    expect(
      HomeShortcutConstant.shortcuts.toSet(),
      hasLength(HomeShortcutConstant.shortcuts.length),
      reason: 'a kind is listed twice',
    );

    // `actionFor` throws on a kind Quick Action does not offer — the button
    // would have no route and no words of its own.
    for (final QuickActionKind kind in HomeShortcutConstant.shortcuts) {
      expect(HomeShortcutConstant.actionFor(kind).kind, kind);
    }
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

      for (final QuickActionKind kind in HomeShortcutConstant.shortcuts) {
        final String label = QuickActionLabel.of(context, kind);
        final RenderParagraph paragraph = tester.renderObject(
          find.descendant(
            of: buttonFor(context, kind),
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
