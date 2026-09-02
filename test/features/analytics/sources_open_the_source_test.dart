import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/analytics/presentation/screens/analytics_sources_screen/analytics_sources_screen.dart';
import 'package:reseller_studio/features/analytics/presentation/widgets/metric_card.dart';

import '../../support/pump_app.dart';

/// The lifecycle's last step is a step, not a report.
///
/// `SOURCE → … → ANALYZE → SOURCE BETTER` ends by going back to the start, and
/// this screen is the only one that says where to go next Saturday. It listed
/// the shops and then stopped, so the seller read a name and had to go and
/// find it themselves.
void main() {
  testWidgets('every source breakdown opens the source it names', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const AnalyticsSourcesScreen());

    final Iterable<MetricCard> cards = tester.widgetList<MetricCard>(
      find.byType(MetricCard),
    );

    expect(cards, isNotEmpty);

    for (final MetricCard card in cards) {
      // The chevron and the tap arrive together, so there is never an
      // affordance leading nowhere.
      expect(card.onTap, isNotNull);
    }
  });

  testWidgets('the item count says what its two numbers are', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const AnalyticsSourcesScreen());

    // It used to be a hardcoded English string on the widget, which hard
    // rule 7 exists to stop.
    expect(find.text('Sold of bought'), findsWidgets);
  });
}
