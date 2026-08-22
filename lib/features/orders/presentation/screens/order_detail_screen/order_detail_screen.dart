import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../expenses/domain/entities/expense.dart';
import '../../../../expenses/providers.dart';
import '../../../../pricing/domain/services/profit_calculator.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/enums/order_status.dart';
import '../../../providers.dart';
import '../../controllers/order_actions_controller.dart';
import '../../order_status_label.dart';
import '../../widgets/refund_sheet.dart';
import '../../widgets/settlement_sheet.dart';
import '../../widgets/ship_order_sheet.dart';

part 'order_detail_screen_actions.dart';
part 'order_detail_screen_body.dart';
part 'order_detail_screen_lines.dart';
part 'order_detail_screen_profit.dart';
part 'order_detail_screen_timeline.dart';

/// Order detail (plan §8).
///
/// The screen a seller opens to answer two questions: **what do I have to do
/// with this, and what did I actually make on it.** The action lives at the
/// bottom where a thumb is, and the profit statement is the block above it
/// rather than a figure buried in a row.
///
/// Watches the order rather than taking it as an argument, so a teammate
/// shipping it shows here without a reload and a notification tap
/// (`selleros:///orders/ord-4`) works with only an id.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Order?> order = ref.watch(orderProvider(orderId));
    final Order? value = order.value;

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: value == null
            ? context.l10n.orderTitleFallback
            : context.l10n.orderTitle(value.marketplace.displayName),
        subtitle: value?.externalOrderId,
      ),
      body: switch (order) {
        AsyncLoading<Order?>() when !order.hasValue => const SdLoadingV3Page(),
        AsyncError<Order?>() => SdEmptyStateV3(
          icon: Symbols.error_rounded,
          title: context.l10n.orderLoadFailed,
          message: context.l10n.commonCouldNotLoad,
        ),
        AsyncData<Order?>(value: null) => SdEmptyStateV3(
          icon: Symbols.search_off_rounded,
          title: context.l10n.orderNotFound,
          message: context.l10n.commonMayHaveBeenDeleted,
        ),
        _ => _OrderBody(order: value!),
      },
    );
  }
}
