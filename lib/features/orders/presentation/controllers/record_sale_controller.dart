import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../domain/entities/order.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/services/bundle_allocation.dart';

/// Recording a sale — the one place an order is created.
///
/// **Two doors, one controller** (`lib/features/orders/CLAUDE.md`): Inventory's
/// Mark as sold and the Orders tab's own button both land here, and so does
/// accepting an offer. A second implementation would be a second answer to
/// what a sale writes.
///
/// **It lives in `orders/` because it creates an order** and the item move is
/// the consequence. On `ItemActionsController` it was reachable only by
/// importing Inventory's presentation layer, which the dependency rule
/// forbids — and Offers was already doing it.
class RecordSaleController extends Notifier<bool> {
  /// True while the write is in flight, so a screen can disable its actions.
  @override
  bool build() => false;

  /// Record a sale (plan §28's manual order), and return the new order's id.
  ///
  /// **Creates the order as well as moving the items**, because profit is
  /// derived from orders (hard rule 3) and an item marked sold with no order
  /// would vanish from every figure the product is judged on.
  ///
  /// **[items] is a list because an order may be a bundle.** One payment for
  /// three things is one order — Poshmark bundles and Depop's "2 for £15" are
  /// everyday — and splitting it into three orders with invented prices
  /// destroys the per-item ROI Sourcing exists to measure. [salePrice] is what
  /// the buyer paid in total; `BundleAllocation` decides each line's share of
  /// it, and the lines always add back up to the total exactly.
  Future<String> record(
    List<Item> items, {
    required Money salePrice,
    Marketplace? marketplace,
    String? marketplaceId,
    String? marketplaceName,
    required DateTime soldAt,
    String? buyerName,
    Money? payout,
    String? externalOrderId,
  }) async {
    final OrderRepository orders = ref.read(orderRepositoryProvider);
    final String orderId = SdId.unique();
    final String resolvedMarketplaceId =
        marketplaceId ?? marketplace?.name ?? 'other';
    final String resolvedMarketplaceName =
        marketplaceName ?? marketplace?.displayName ?? 'Other';
    final List<Money> shares = BundleAllocation.across(salePrice, <Money?>[
      for (final Item item in items) item.expectedPrice,
    ]);

    if (items.isEmpty) {
      throw StateError('A sale must name at least one item');
    }

    SdLogger.action(LogTagConstant.order, 'Record sale', <String, Object>{
      'itemIds': <String>[for (final Item item in items) item.id],
      'marketplaceId': resolvedMarketplaceId,
      'salePriceMinor': salePrice.minor,
    });

    state = true;

    try {
      final Order order = Order(
        id: orderId,
        status: OrderStatus.toShip,
        marketplaceRecordId: resolvedMarketplaceId,
        marketplaceNameSnapshot: resolvedMarketplaceName,
        lines: <OrderLine>[
          for (int i = 0; i < items.length; i++)
            OrderLine(
              itemId: items[i].id,
              title: items[i].title,
              quantity: 1,
              unitPrice: shares[i],
              // Null when nobody entered a cost — the order's profit is then
              // `—` rather than the whole sale price (hard rule 5).
              unitCost: items[i].purchasePrice,
            ),
        ],
        salePrice: salePrice,
        orderedAt: soldAt,
        buyerName: buyerName,
        // The platform's own order number, when the seller copied it across.
        // It is what `PayoutCsvImport` matches a payout row against, so an
        // order without one can never be reconciled from a file.
        externalOrderId: externalOrderId,
        // Null when the seller does not have it yet — most sales are recorded
        // before the platform pays. The order then reads `—` for profit and
        // joins the Payouts queue rather than carrying a guess.
        payout: payout,
      );

      await orders.recordSale(order, items);

      SdLogger.info(LogTagConstant.order, 'Sale recorded', <String, Object>{
        'items': items.length,
        'orderId': orderId,
      });
      AppAnalytics.instance.itemSold(
        marketplace: resolvedMarketplaceId,
        // The share of sales with no cost is the health metric for the whole
        // "insight" half of the product — it is what makes profit unknowable.
        // A bundle counts as costed only when every line is: one unknown cost
        // makes the whole order's profit unknowable.
        hadCost: items.every((Item item) => item.purchasePrice != null),
      );

      return orderId;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.order,
        'Failed to record sale',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{
          'itemIds': <String>[for (final Item item in items) item.id],
        },
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}
