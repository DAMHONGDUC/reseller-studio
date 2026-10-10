import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/analytics/presentation/screens/analytics_screen/analytics_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The period strip windows the hero, the trend and the statement.
void main() {
  Finder chip(String label) => find.widgetWithText(SdFilterChipV3, label);

  testWidgets('opens on All, the figure Home shows', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const AnalyticsScreen());

    expect(tester.widget<SdFilterChipV3>(chip('All')).selected, isTrue);
    // The seeded all-time revenue, as the statement prints it.
    expect(find.text(r'$439.00'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('a shorter period changes the statement', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const AnalyticsScreen());

    await tester.tap(chip('7D'));
    await tester.pumpAndSettle();

    expect(tester.widget<SdFilterChipV3>(chip('7D')).selected, isTrue);
    expect(find.text(r'$439.00'), findsNothing);
  });
}
