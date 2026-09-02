import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../../mock_data/providers.dart';
import '../../domain/entities/order.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/repositories/order_repository.dart';

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
  static const Uuid _uuid = Uuid();

  /// True while the write is in flight, so a screen can disable its actions.
  @override
  bool build() => false;

  /// Record a sale (plan §28's manual order), and return the new order's id.
  ///
  /// **Creates the order as well as moving the item**, because profit is
  /// derived from orders (hard rule 3) and an item marked sold with no order
  /// would vanish from every figure the product is judged on.
  Future<String> record(
    Item item, {
    required Money salePrice,
    Marketplace? marketplace,
    String? marketplaceId,
    String? marketplaceName,
    required DateTime soldAt,
    String? buyerName,
    Money? fees,
  }) async {
    final OrderRepository orders = ref.read(orderRepositoryProvider);
    final String orderId = _uuid.v4();
    final String resolvedMarketplaceId =
        marketplaceId ?? marketplace?.name ?? 'other';
    final String resolvedMarketplaceName =
        marketplaceName ?? marketplace?.displayName ?? 'Other';

    SdLogger.action(LogTagConstant.order, 'Record sale', <String, Object>{
      'itemId': item.id,
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
          OrderLine(
            itemId: item.id,
            title: item.title,
            quantity: 1,
            unitPrice: salePrice,
            // Null when nobody entered a cost — the order's profit is then
            // `—` rather than the whole sale price (hard rule 5).
            unitCost: item.purchasePrice,
          ),
        ],
        salePrice: salePrice,
        orderedAt: soldAt,
        buyerName: buyerName,
        // Null when the seller did not type one, and it stays null: the
        // profit statement then estimates it from the platform's rate and
        // says so, rather than claiming the platform took nothing
        // (`Order.effectiveFees`).
        fees: fees,
      );

      await orders.recordSale(order, item);

      SdLogger.info(LogTagConstant.order, 'Sale recorded', <String, Object>{
        'itemId': item.id,
        'orderId': orderId,
      });
      AppAnalytics.instance.itemSold(
        marketplace: resolvedMarketplaceId,
        // The share of sales with no cost is the health metric for the whole
        // "insight" half of the product — it is what makes profit unknowable.
        hadCost: item.purchasePrice != null,
      );

      return orderId;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.order,
        'Failed to record sale',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'itemId': item.id},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}
