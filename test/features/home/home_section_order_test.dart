import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';

import '../../support/pump_app.dart';
import 'empty_business.dart';

/// The order of Home is a product decision, and this is what holds it.
///
/// Owner's rule: **Getting started sits directly under the shortcut row**,
/// then Needs Attention, then the numbers. See `lib/features/home/CLAUDE.md`,
/// which carries the whole order.
void main() {
  double topOf(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text).first).dy;

  testWidgets('Needs Attention comes before Performance and Flow overview', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());

    expect(
      topOf(tester, 'Needs Attention'),
      lessThan(topOf(tester, 'Performance')),
    );
    expect(
      topOf(tester, 'Performance'),
      lessThan(topOf(tester, 'Flow overview')),
    );
  });

  testWidgets('Getting started is above Needs Attention when it shows', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen(), overrides: emptyBusiness());

    expect(
      topOf(tester, 'Getting started'),
      lessThan(topOf(tester, 'Needs Attention')),
    );
  });

  testWidgets('the shortcut row is still first', (WidgetTester tester) async {
    await pumpScreen(tester, const HomeScreen());

    expect(
      topOf(tester, 'Quick Action'),
      lessThan(topOf(tester, 'Needs Attention')),
      reason: 'the three shortcut cards open the screen (owner\u2019s rule)',
    );
  });
}
