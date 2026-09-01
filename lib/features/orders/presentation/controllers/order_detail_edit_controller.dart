import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/text_input_utils.dart';
import '../../../mock_data/providers.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/order.dart';

/// Which block of the order detail screen is open for editing.
///
/// **No status, no lines, no timeline.** Ship, Mark delivered and Record
/// refund each write more than a field — see `lib/features/orders/CLAUDE.md`.
enum OrderDetailSection { order, profit, shipping }

/// What the open section holds that the seller did not type.
class OrderDetailEditState {
  const OrderDetailEditState({
    this.editing,
    this.isSaving = false,
    this.orderedAt,
    this.shipByDate,
    this.carrier,
  });

  /// Null when nothing is open. **Only ever one** — see the in-place editing
  /// rule in `docs/rules/SCREENS.md`.
  final OrderDetailSection? editing;

  final bool isSaving;
  final DateTime? orderedAt;
  final DateTime? shipByDate;
  final String? carrier;

  bool isOpen(OrderDetailSection section) => editing == section;

  OrderDetailEditState copyWith({
    DateTime? orderedAt,
    DateTime? shipByDate,
    String? carrier,
    bool? isSaving,
  }) => OrderDetailEditState(
    editing: editing,
    isSaving: isSaving ?? this.isSaving,
    orderedAt: orderedAt ?? this.orderedAt,
    shipByDate: shipByDate ?? this.shipByDate,
    carrier: carrier ?? this.carrier,
  );
}

/// Opens one section of the order detail screen, and writes it.
///
/// **Every save re-reads the order and applies only its own section's
/// fields**, so a teammate shipping it while a draft was open is not undone.
class OrderDetailEditController extends Notifier<OrderDetailEditState> {
  @override
  OrderDetailEditState build() => const OrderDetailEditState();

  /// Opens [section], seeding the choices that are not typed from [order].
  void edit(OrderDetailSection section, Order order) =>
      state = OrderDetailEditState(
        editing: section,
        orderedAt: order.orderedAt,
        shipByDate: order.shipByDate,
        carrier: order.carrier,
      );

  void cancel() => state = const OrderDetailEditState();

  void selectOrderedAt(DateTime date) =>
      state = state.copyWith(orderedAt: date);

  void selectShipByDate(DateTime date) =>
      state = state.copyWith(shipByDate: date);

  void selectCarrier(String carrier) =>
      state = state.copyWith(carrier: carrier);

  Future<void> saveOrder({
    required String orderId,
    required String buyerName,
    required String salePrice,
  }) {
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? price = Money.tryParse(salePrice, currency);
    final String? buyer = TextInputUtils.orNull(buyerName);
    final DateTime? orderedAt = state.orderedAt;

    return _write(orderId, OrderDetailSection.order, (Order current) {
      return current.copyWith(
        // A sale with no price is not a sale, so an unparseable box leaves
        // the figure the order already carries rather than clearing it.
        salePrice: price,
        orderedAt: orderedAt,
        buyerName: buyer,
        clearBuyerName: buyer == null,
      );
    });
  }

  Future<void> saveProfit({required String orderId, required String fees}) {
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? amount = Money.tryParse(fees, currency);

    return _write(orderId, OrderDetailSection.profit, (Order current) {
      // Null is "the platform has not told us", which is not zero — the
      // payout reconciliation falls back to the estimate for exactly that
      // case (hard rule 5).
      return current.copyWith(fees: amount, clearFees: amount == null);
    });
  }

  Future<void> saveShipping({
    required String orderId,
    required String trackingNumber,
    required String shippingCost,
  }) {
    final String currency = ref.read(workspaceCurrencyProvider);
    final Money? cost = Money.tryParse(shippingCost, currency);
    final String? tracking = TextInputUtils.orNull(trackingNumber);
    final String? carrier = state.carrier;
    final DateTime? shipBy = state.shipByDate;

    return _write(orderId, OrderDetailSection.shipping, (Order current) {
      return current.copyWith(
        carrier: carrier,
        clearCarrier: carrier == null,
        trackingNumber: tracking,
        clearTrackingNumber: tracking == null,
        shipByDate: shipBy,
        clearShipByDate: shipBy == null,
        shippingCost: cost,
        clearShippingCost: cost == null,
      );
    });
  }

  /// Reads the order fresh, applies [apply], writes it and closes the section.
  Future<void> _write(
    String orderId,
    OrderDetailSection section,
    Order Function(Order current) apply,
  ) async {
    if (state.isSaving) return;

    state = state.copyWith(isSaving: true);
    SdLogger.action(
      LogTagConstant.order,
      'Save order section',
      <String, Object>{'orderId': orderId, 'section': section.name},
    );

    try {
      final Order? current = await ref
          .read(orderRepositoryProvider)
          .watchOrder(orderId)
          .first;

      if (current == null) {
        SdLogger.info(
          LogTagConstant.order,
          'Order section save found no record',
          <String, Object>{'orderId': orderId, 'section': section.name},
        );

        state = const OrderDetailEditState();

        return;
      }

      await ref.read(orderRepositoryProvider).save(apply(current));

      SdLogger.info(
        LogTagConstant.order,
        'Order section saved',
        <String, Object>{'orderId': orderId, 'section': section.name},
      );

      state = const OrderDetailEditState();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.order,
        'Order section failed to save',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'orderId': orderId, 'section': section.name},
      );

      state = state.copyWith(isSaving: false);

      rethrow;
    }
  }
}

final NotifierProvider<OrderDetailEditController, OrderDetailEditState>
orderDetailEditControllerProvider =
    NotifierProvider<OrderDetailEditController, OrderDetailEditState>(
      OrderDetailEditController.new,
    );
