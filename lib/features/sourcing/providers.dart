/// Riverpod wiring for `sourcing` — where stock comes from, and what it cost.
///
/// The last step of the plan's lifecycle is *source better*, and every figure
/// that answers it is derived here from the same item and order streams the
/// rest of the app reads. Nothing is stored (hard rule 3).
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/money/money.dart';
import '../inventory/domain/entities/item.dart';
import '../inventory/domain/enums/item_status.dart';
import '../inventory/providers.dart';
import '../mock_data/providers.dart';
import '../orders/domain/entities/order.dart';
import '../orders/providers.dart';
import '../workspace/providers.dart';
import 'domain/entities/purchase.dart';
import 'domain/entities/source.dart';

final StreamProvider<List<Source>> sourcesProvider =
    StreamProvider<List<Source>>((Ref ref) {
      return WorkspaceGuard.listOrEmpty<Source>(
        ref,
        () => ref.watch(sourceRepositoryProvider).watchSources(),
      );
    });

final StreamProvider<List<Purchase>> purchasesProvider =
    StreamProvider<List<Purchase>>((Ref ref) {
      return WorkspaceGuard.listOrEmpty<Purchase>(
        ref,
        () => ref.watch(purchaseRepositoryProvider).watchPurchases(),
      );
    });

/// Source id → name, so a row renders without a lookup per item.
final Provider<Map<String, String>> sourceNamesProvider =
    Provider<Map<String, String>>((Ref ref) {
      final List<Source> sources =
          ref.watch(sourcesProvider).value ?? const <Source>[];

      return <String, String>{
        for (final Source source in sources) source.id: source.name,
      };
    });

// See `itemProvider` for why a family's type is inferred rather than written.
// ignore: type_annotate_public_apis
final purchasesForSourceProvider =
    StreamProvider.family<List<Purchase>, String>((Ref ref, String sourceId) {
      return WorkspaceGuard.listOrEmpty<Purchase>(
        ref,
        () => ref
            .watch(purchaseRepositoryProvider)
            .watchPurchasesForSource(sourceId),
      );
    });

// ignore: type_annotate_public_apis
final itemsForPurchaseProvider = StreamProvider.family<List<Item>, String>((
  Ref ref,
  String purchaseId,
) {
  return WorkspaceGuard.listOrEmpty<Item>(
    ref,
    () => ref.watch(itemRepositoryProvider).watchItemsForPurchase(purchaseId),
  );
});

/// What one source has actually returned (plan §9, Source section).
///
/// **Spend comes from the purchases, revenue from the orders whose items
/// trace back here.** Deriving revenue from item asking prices instead would
/// report what the seller hoped for rather than what they got.
class SourcePerformance {
  const SourcePerformance({
    required this.sourceId,
    required this.spend,
    required this.itemsBought,
    required this.itemsSold,
    required this.revenue,
    required this.profit,
  });

  final String sourceId;

  /// What was paid across every purchase from this source. Null when none of
  /// them recorded a total.
  final Money? spend;

  final int itemsBought;
  final int itemsSold;

  /// What the items from this source sold for. Null when none have sold.
  final Money? revenue;

  /// Revenue minus spend. Null when either is unknown — hard rule 5: an
  /// em dash rather than a number built on a guess.
  final Money? profit;

  /// Return on what was spent here, or null when nothing was.
  double? get roi {
    final Money? made = profit;
    final Money? paid = spend;

    if (made == null || paid == null || paid.isZero) return null;

    return made.ratioOf(paid);
  }
}

/// Every source, with what it returned. What the Sources screen ranks by.
final Provider<List<SourcePerformance>> sourcePerformanceProvider =
    Provider<List<SourcePerformance>>((Ref ref) {
      final List<Source> sources =
          ref.watch(sourcesProvider).value ?? const <Source>[];
      final List<Purchase> purchases =
          ref.watch(purchasesProvider).value ?? const <Purchase>[];
      final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];
      final List<Order> orders =
          ref.watch(ordersProvider).value ?? const <Order>[];

      // itemId → what it sold for, over the orders that count as revenue.
      final Map<String, Money> soldFor = <String, Money>{};

      for (final Order order in orders) {
        if (!order.status.countsAsRevenue) continue;

        for (final OrderLine line in order.lines) {
          soldFor[line.itemId] = line.lineTotal;
        }
      }

      return sources.map((Source source) {
        final List<Item> fromSource = items
            .where((Item item) => item.sourceId == source.id)
            .toList();

        final Money? spend = purchases
            .where((Purchase purchase) => purchase.sourceId == source.id)
            .map((Purchase purchase) => purchase.totalCost)
            .totalOfKnown();

        final Money? revenue = fromSource
            .map((Item item) => soldFor[item.id])
            .totalOfKnown();

        return SourcePerformance(
          sourceId: source.id,
          spend: spend,
          itemsBought: fromSource.length,
          itemsSold: fromSource
              .where((Item item) => item.status == ItemStatus.sold)
              .length,
          revenue: revenue,
          profit: (spend == null || revenue == null) ? null : revenue - spend,
        );
      }).toList();
    });
