import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/activity/presentation/screens/activity_screen/activity_screen.dart';
import 'package:reseller_studio/features/analytics/presentation/screens/analytics_categories_screen/analytics_categories_screen.dart';
import 'package:reseller_studio/features/analytics/presentation/screens/analytics_inventory_screen/analytics_inventory_screen.dart';
import 'package:reseller_studio/features/analytics/presentation/screens/analytics_marketplace_screen/analytics_marketplace_screen.dart';
import 'package:reseller_studio/features/analytics/presentation/screens/analytics_profit_screen/analytics_profit_screen.dart';
import 'package:reseller_studio/features/analytics/presentation/screens/analytics_sales_screen/analytics_sales_screen.dart';
import 'package:reseller_studio/features/app_config/presentation/screens/account_blocked_screen/account_blocked_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/intake_session_screen/intake_session_screen.dart';
import 'package:reseller_studio/features/listings/presentation/screens/listings_screen/listings_screen.dart';
import 'package:reseller_studio/features/onboarding/presentation/screens/onboarding_screen/onboarding_screen.dart';
import 'package:reseller_studio/features/reports/presentation/screens/books_screen/books_screen.dart';
import 'package:reseller_studio/features/search/presentation/screens/search_screen/search_screen.dart';
import 'package:reseller_studio/features/sourcing/presentation/screens/purchase_detail_screen/purchase_detail_screen.dart';
import 'package:reseller_studio/features/sourcing/presentation/screens/sourcing_screen/sourcing_screen.dart';
import 'package:reseller_studio/features/tax/presentation/screens/tax_screen/tax_screen.dart';

import '../support/pump_app.dart';

/// Every screen the rest of the suite never builds, rendered against the
/// seeded mock business.
///
/// This is deliberately shallow: it proves the screen builds, settles and
/// lays out on a phone-sized surface without throwing or overflowing. What
/// each one *says* is asserted in its own feature test — the point here is
/// that no screen ships having never been built by anything but a person
/// tapping through the app.
///
/// `pumpRoutedScreen` rather than `pumpScreen`: several of these push on
/// first frame or on a tap, and a screen with no router throws instead.
void main() {
  final Map<String, Widget Function()> screens = <String, Widget Function()>{
    'Activity': () => const ActivityScreen(),
    'Analytics — categories': () => const AnalyticsCategoriesScreen(),
    'Analytics — inventory': () => const AnalyticsInventoryScreen(),
    'Analytics — marketplace': () => const AnalyticsMarketplaceScreen(),
    'Analytics — profit': () => const AnalyticsProfitScreen(),
    'Analytics — sales': () => const AnalyticsSalesScreen(),
    'Account blocked': () => const AccountBlockedScreen(),
    'Books': () => const BooksScreen(),
    'Intake session': () => const IntakeSessionScreen(),
    'Listings': () => const ListingsScreen(),
    'Onboarding': () => const OnboardingScreen(),
    'Purchase detail': () => const PurchaseDetailScreen(purchaseId: 'pur-1'),
    'Search': () => const SearchScreen(),
    'Sourcing': () => const SourcingScreen(),
    'Tax': () => const TaxScreen(),
  };

  screens.forEach((String name, Widget Function() build) {
    testWidgets('$name builds against the seeded business', (
      WidgetTester tester,
    ) async {
      final Widget screen = build();

      await pumpRoutedScreen(tester, screen);
      await tester.pumpAndSettle();

      expect(find.byWidget(screen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
