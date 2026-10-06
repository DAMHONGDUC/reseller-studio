import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';

import '../../support/pump_app.dart';
import 'empty_business.dart';
import 'premium_subscription.dart';

/// The order of Home is a product decision, and this is what holds it.
///
/// Owner's rule: **Needs Attention opens the screen**, the shortcut row sits
/// under it, Getting started under that, then the numbers. See
/// `lib/features/home/CLAUDE.md`, which carries the whole order.
void main() {
  /// The order [labels] appear in as Home is scrolled from the top.
  ///
  /// **Not pixel offsets.** Home was a lazy `ListView`, whose estimated extent
  /// made `position.pixels` a moving target and once reported the wrong order
  /// outright. It is built whole now, but reading the order things come into
  /// view in asks the same question without depending on how it is built.
  ///
  /// Labels that arrive in the same frame are sorted by their y within it,
  /// where positions *are* comparable — otherwise two sections that fit on
  /// one screen would always be reported in the order they were asked for.
  Future<List<String>> orderDownThePage(
    WidgetTester tester,
    List<String> labels,
  ) async {
    final ScrollableState scrollable = tester.state(
      find.byType(Scrollable).first,
    );
    final List<String> seen = <String>[];

    while (seen.length < labels.length) {
      final List<String> arrived =
          labels
              .where(
                (String label) =>
                    !seen.contains(label) &&
                    find.text(label).evaluate().isNotEmpty,
              )
              .toList()
            ..sort(
              (String a, String b) => tester
                  .getTopLeft(find.text(a).first)
                  .dy
                  .compareTo(tester.getTopLeft(find.text(b).first).dy),
            );

      seen.addAll(arrived);

      if (scrollable.position.pixels >= scrollable.position.maxScrollExtent) {
        break;
      }

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }

    return seen;
  }

  testWidgets('Needs Attention comes before Performance and Flow overview', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: premiumSubscription(),
    );

    expect(
      await orderDownThePage(tester, <String>[
        'Performance',
        'Flow overview',
        'Needs Attention',
      ]),
      <String>['Needs Attention', 'Performance', 'Flow overview'],
    );
  });

  testWidgets('Getting started sits under Needs Attention when it shows', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: [...emptyBusiness(), ...premiumSubscription()],
    );

    expect(
      await orderDownThePage(tester, <String>[
        'Getting started',
        'Needs Attention',
      ]),
      <String>['Needs Attention', 'Getting started'],
    );
  });

  testWidgets('Needs Attention opens the screen, the shortcut row follows', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      overrides: premiumSubscription(),
    );

    // `Add stock` is the first shortcut and appears nowhere else on Home.
    expect(
      await orderDownThePage(tester, <String>[
        'Add stock',
        'Needs Attention',
        'Performance',
      ]),
      <String>['Needs Attention', 'Add stock', 'Performance'],
      reason: 'what needs attention comes first (owner\u2019s rule)',
    );
  });
}
