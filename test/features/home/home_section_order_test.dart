import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/home/presentation/screens/home_screen/home_screen.dart';

import '../../support/pump_app.dart';

/// The order of Home is a product decision, and this is what holds it.
///
/// Owner's rule: **Performance sits directly under the shortcut row**, above
/// Flow overview and Needs Attention. It reverses the two rules that stood
/// before it — see `lib/features/home/CLAUDE.md`, which carries the whole
/// order and the reason it changed.
void main() {
  double topOf(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text).first).dy;

  testWidgets('Performance comes before Flow overview and Needs Attention', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());

    expect(
      topOf(tester, 'Performance'),
      lessThan(topOf(tester, 'Flow overview')),
    );
    expect(
      topOf(tester, 'Flow overview'),
      lessThan(topOf(tester, 'Needs Attention')),
    );
  });

  testWidgets('the shortcut row still opens the screen', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());

    expect(
      topOf(tester, 'Quick Action'),
      lessThan(topOf(tester, 'Performance')),
      reason: 'the three shortcut cards are still first (owner’s rule)',
    );
  });
}
