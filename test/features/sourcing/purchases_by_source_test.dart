import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/router/app_routes.dart';
import 'package:reseller_studio/features/sourcing/presentation/screens/purchases_screen/purchases_screen.dart';

import '../../support/pump_app.dart';

/// Opening a source used to go nowhere: `/sources/:sourceId` was declared and
/// never wired, so Analytics' ROI rows and Search's source hits both landed
/// the seller back on Home by way of the router's unknown-route fallback.
///
/// A source has no screen of its own — what a seller asks about a shop is what
/// they bought there — so the destination is Purchases with one name on it.
void main() {
  test('the route names the source it filters on', () {
    final Uri uri = Uri.parse(AppRoutes.purchasesFrom('src-goodwill'));

    expect(uri.path, AppRoutes.purchases);
    expect(uri.queryParameters['source'], 'src-goodwill');
  });

  testWidgets('with no source it lists every buying trip', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PurchasesScreen());

    expect(find.textContaining('Goodwill — Riverside'), findsOneWidget);
    expect(find.textContaining('County Pallet Auction'), findsOneWidget);
  });

  testWidgets('on a source it shows that source alone, and names it', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PurchasesScreen(sourceId: 'src-goodwill'));

    // Once in the app bar subtitle, once on the row it kept.
    expect(find.textContaining('Goodwill — Riverside'), findsNWidgets(2));
    expect(find.textContaining('County Pallet Auction'), findsNothing);
  });

  testWidgets('a source with no purchases says so, not "none yet"', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const PurchasesScreen(sourceId: 'src-unknown'));

    // The business has purchases — from other shops — so the first-run copy
    // and its Record button would both be a lie here.
    expect(find.text('Nothing recorded from this source yet.'), findsOneWidget);
    expect(find.text('No purchases yet'), findsNothing);
  });
}
