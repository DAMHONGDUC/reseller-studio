import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/home/home_constant.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The three cards that open Home.
///
/// **Their value is being the first thing on the screen.** A shortcut a
/// seller has to scroll to is not a shortcut — it is one more row of a
/// dashboard they were trying to get past.
void main() {
  /// The card, not the section header of the same name: only the card is
  /// inside an `SdCardV3`.
  Finder cardFor(BuildContext context, HomeShortcutKind kind) => find.ancestor(
    of: find.text(HomeShortcutLabel.of(context, kind)),
    matching: find.byType(SdCardV3),
  );

  testWidgets('all three are on screen before anything is scrolled', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());

    final BuildContext context = tester.element(find.byType(HomeScreen));

    for (final HomeShortcut shortcut in HomeShortcutConstant.shortcuts) {
      expect(
        cardFor(context, shortcut.kind),
        findsOneWidget,
        reason: '${shortcut.kind.name} is not a card on Home',
      );
    }
  });

  testWidgets('they sit above every section of the dashboard', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());

    final BuildContext context = tester.element(find.byType(HomeScreen));

    // Owner's rule: ways *out* of Home come before Home's own content, and
    // that includes Needs Attention, which outranks everything else here.
    final double cardsBottom = tester
        .getRect(cardFor(context, HomeShortcutKind.quickAction))
        .bottom;

    expect(
      tester.getRect(find.text('Needs Attention')).top,
      greaterThanOrEqualTo(cardsBottom),
    );
  });

  testWidgets('the Quick Access card scrolls Home to Quick Access', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());

    final BuildContext context = tester.element(find.byType(HomeScreen));
    final ScrollableState scrollable = tester.state(
      find.byType(Scrollable).first,
    );

    expect(scrollable.position.pixels, 0);

    await tester.tap(cardFor(context, HomeShortcutKind.quickAction));
    await tester.pumpAndSettle();

    // Quick Access is the last section, so landing on it means landing on the
    // end — and a single animation pass would stop short of it, because a
    // lazy list only estimates its extent from what it has built.
    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
    expect(
      find.text(
        QuickActionLabel.of(context, QuickActionConstant.actions.last.kind),
      ),
      findsWidgets,
    );
  });

  test('every kind has a card, and every card a kind', () {
    // The enum and the list are two halves of the same fact; adding a case
    // without a card compiles.
    expect(
      HomeShortcutConstant.shortcuts.map((HomeShortcut s) => s.kind).toSet(),
      HomeShortcutKind.values.toSet(),
    );
    expect(
      HomeShortcutConstant.shortcuts.length,
      HomeShortcutKind.values.length,
      reason: 'a kind is listed twice',
    );
  });
}
