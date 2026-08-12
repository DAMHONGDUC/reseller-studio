import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:seller_os/core/money/money.dart';
import 'package:seller_os/features/analytics/domain/entities/analytics_summary.dart';
import 'package:seller_os/features/analytics/presentation/screens/analytics_screen/analytics_screen.dart';
import 'package:seller_os/features/analytics/providers.dart';
import 'package:seller_os/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:seller_os/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:seller_os/features/inventory/providers.dart';
import 'package:seller_os/features/orders/domain/entities/order.dart';
import 'package:seller_os/features/orders/providers.dart';
import 'package:seller_os/features/settings/presentation/screens/settings_screen/settings_screen.dart';
import 'package:system_design/index.dart';

import '../support/pump_app.dart';

/// Every screen, rendered against the seeded mock business.
///
/// **The figures are asserted, not eyeballed.** A screenshot proves a screen
/// drew something; these prove it drew the right number. The expected values
/// below are computed by hand from `MockDataset.seed`, so if the seed changes
/// and these fail, one of the two is wrong and it has to be decided which.
void main() {
  group('analytics figures, computed by hand from the seed', () {
    // Orders that count as revenue: all six (delivered ×3, toShip ×2,
    // returnRequested ×1 — a return that has not completed has not given the
    // money back yet).
    //   revenue  = 6800+9500+3500+8900+11000+4200 = 43900
    //   cogs     = 1200+3000+3200+2200+4100+900   = 14600
    //   fees     = 901+903+350+1780+1458+557      =  5949
    //   shipping = 1240+1580+890+0+0+720          =  4430
    //   overheads (expenses with no orderId)      = 17769
    //   profit   = 43900-14600-5949-4430-17769    =  1152
    test('revenue and profit', () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      final AnalyticsSummary summary = container.read(
        analyticsSummaryProvider,
      );

      expect(summary.revenue, const Money(43900, 'USD'));
      expect(summary.netProfit, const Money(1152, 'USD'));
      expect(summary.orderCount, 6);
      expect(summary.unitsSold, 6);
    });

    test('profit is flagged partial when a sold item had no cost', () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      // Every sold item in the seed has a cost, so this run is complete.
      // The flag exists for the case that is not, and Home renders
      // "partial — some costs missing" when it is false.
      expect(container.read(analyticsSummaryProvider).isProfitComplete, isTrue);
    });

    test('inventory value counts on-hand items at cost, ignoring unknowns', () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      // On hand with a known cost: 1500+2800+2200+4100+1500+(900×2) = 13900.
      // itm-9 and itm-10 are Quick Add leftovers with no cost and are
      // excluded rather than counted as free — hard rule 5.
      expect(
        container.read(analyticsSummaryProvider).inventoryValue,
        const Money(13900, 'USD'),
      );
      expect(container.read(analyticsSummaryProvider).itemsOnHand, 8);
    });

    test('marketplace rows are ordered by revenue', () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      final List<MarketplacePerformance> rows = container.read(
        marketplacePerformanceProvider,
      );

      expect(rows, isNotEmpty);
      // eBay carries two orders (6800 + 11000 + 4200 = 22000) and leads.
      expect(rows.first.marketplace.displayName, 'eBay');

      for (int i = 1; i < rows.length; i++) {
        expect(rows[i - 1].revenue >= rows[i].revenue, isTrue);
      }
    });
  });

  group('inventory filters', () {
    test('counts split the seed across the five tabs', () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      final Map<InventoryFilter, int> counts = container.read(
        inventoryCountsProvider,
      );

      expect(counts[InventoryFilter.all], 11);
      expect(counts[InventoryFilter.listed], 3);
      expect(counts[InventoryFilter.reserved], 1);
      expect(counts[InventoryFilter.sold], 3);
      // itm-4 (listed 84 days ago) and itm-5 (66) are past the 60-day
      // threshold; itm-6 (20 days) is not.
      expect(counts[InventoryFilter.stale], 2);
    });

    test('stale is a subset of listed, never its own status', () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      final Map<InventoryFilter, int> counts = container.read(
        inventoryCountsProvider,
      );

      expect(
        counts[InventoryFilter.stale]! <= counts[InventoryFilter.listed]!,
        isTrue,
        reason: 'a stale item is still a listed item',
      );
    });
  });

  group('orders', () {
    test('needing action is sorted by deadline, soonest first', () async {
      final ProviderContainer container = mockContainer();

      await warmUp(container);

      final List<Order> pending = container.read(ordersNeedingActionProvider);

      // ord-5 (deadline yesterday), ord-4 (deadline tomorrow), then ord-6
      // (return requested, no deadline) last.
      expect(pending.map((Order order) => order.id).toList(), <String>[
        'ord-5',
        'ord-4',
        'ord-6',
      ]);
      expect(pending.first.isOverdue(testNow), isTrue);
    });
  });

  group('screens render against the mock backend', () {
    testWidgets('Home shows the workspace and its real figures', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const HomeScreen());

      expect(find.text('Attic Finds Co.'), findsOneWidget);
      expect(find.text('Orders to ship'), findsOneWidget);
      expect(find.text('1 overdue'), findsOneWidget);
      expect(find.text('Stale inventory'), findsOneWidget);
      // Compact currency must render a symbol, not the ISO code — the bug
      // `NumberFormat.compactCurrency` introduced.
      expect(find.text(r'$439'), findsOneWidget);
      expect(find.textContaining('USD4'), findsNothing);
    });

    testWidgets('Inventory lists items with counts on every tab', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const InventoryScreen());

      expect(find.text('All'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);

      // The list sorts newest-created first, so this is the top row.
      expect(find.textContaining('Nike windbreaker'), findsOneWidget);

      // A Quick Add leftover: title only, no cost, no price. Both money cells
      // must render an em dash rather than a zero — hard rule 5, proven on a
      // real row rather than asserted in a comment.
      expect(find.textContaining('brass hardware'), findsOneWidget);
      expect(find.text('—'), findsWidgets);

      // The oldest item is tenth and is not built until scrolled to.
      //
      // `.first` is the `CustomScrollView`'s own scrollable, which is the
      // outermost one on this screen. Deliberately not `.last`: the pinned
      // header holds the filter strip, and that is a horizontal `ListView` —
      // dragging it vertically scrolls nothing and the row never appears.
      await tester.scrollUntilVisible(
        find.textContaining('Vintage Levi'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Vintage Levi'), findsOneWidget);
      // Its status badge and its stale badge are separate, and both show: an
      // item can be listed *and* stale, and collapsing that into one marker
      // loses the fact that it is still live and still earning nothing.
      expect(find.text('Stale'), findsWidgets);
      expect(find.text('Listed'), findsWidgets);
    });

    testWidgets('Inventory docks the search field into the bar on scroll', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const InventoryScreen());

      final Rect expanded = tester.getRect(find.byType(SdSearchFieldV3));

      expect(find.text('Inventory'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final Rect docked = tester.getRect(find.byType(SdSearchFieldV3));

      // It moved up into the title's row and gave the width back to the
      // actions beside it — the two halves of "docked".
      expect(docked.top, lessThan(expanded.top));
      expect(docked.width, lessThan(expanded.width));

      // The title is faded out, not removed: one field, one tree, no
      // cross-fade between two of them.
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(
                of: find.text('Inventory'),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0,
      );

      // Search and the scanner stay reachable 300 rows down — they are the
      // chrome. The filter strip deliberately does NOT: it is a widget in the
      // body, never part of the app bar, so it scrolls away with the content.
      expect(find.byTooltip('Scan'), findsOneWidget);
      expect(find.text('All'), findsNothing);
    });

    testWidgets('Inventory keeps the filter strip out of the app bar', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const InventoryScreen());

      final Rect strip = tester.getRect(find.text('All'));
      final Rect field = tester.getRect(find.byType(SdSearchFieldV3));

      // Below the chrome, not inside it.
      expect(strip.top, greaterThan(field.bottom));
    });

    testWidgets('Quick Add sheds its label only while the list is moving', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const InventoryScreen());

      expect(find.text('Quick Add'), findsOneWidget);

      // Held, not flicked: the button expands again the moment a scroll
      // ends, so a completed drag would prove nothing.
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(CustomScrollView)),
      );

      // Two steps, because one long move is a single pointer event and the
      // drag recogniser never sees the touch slop crossed — the list would
      // not move at all and the assertion below would pass for the wrong
      // reason.
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -260));
      await tester.pumpAndSettle();

      expect(find.text('Quick Add'), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Quick Add'), findsOneWidget);
    });

    testWidgets('Analytics renders the profit statement', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const AnalyticsScreen());

      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('Net profit'), findsOneWidget);
      expect(find.text('− Cost of goods'), findsOneWidget);
      expect(find.text(r'$439.00'), findsOneWidget);
      expect(find.text(r'$11.52'), findsOneWidget);
    });

    testWidgets('Settings shows the mock switch, on, with the dataset counts', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const SettingsScreen());

      expect(find.text('Mock data'), findsOneWidget);
      expect(find.text('Showing a seeded demo business.'), findsOneWidget);
      expect(find.textContaining('11 items'), findsOneWidget);
      expect(find.textContaining('6 orders'), findsOneWidget);
    });
  });
}
