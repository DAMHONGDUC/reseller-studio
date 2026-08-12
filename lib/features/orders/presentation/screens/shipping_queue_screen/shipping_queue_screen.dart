import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../domain/entities/order.dart';
import '../../../providers.dart';
import '../../widgets/ship_order_sheet.dart';

/// The shipping queue (plan §8) — everything still waiting on the seller.
///
/// **Sorted by deadline, not by date ordered.** The order that has waited
/// longest is not necessarily the one about to breach a shipping window, and
/// the late-shipment penalty falls on the deadline. Orders with no deadline
/// sort last: they are real work, but nothing external is counting down.
///
/// Shipping happens from the row. A queue whose only affordance is "open the
/// order, then find the button" is a queue that takes two taps per parcel,
/// and a seller with twelve to post feels every one of them.
class ShippingQueueScreen extends ConsumerWidget {
  const ShippingQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> orders = ref.watch(ordersNeedingActionProvider);
    final DateTime now = DateTime.now();

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: 'Shipping queue',
        subtitle: orders.isEmpty ? null : '${orders.length} to send',
      ),
      body: orders.isEmpty
          ? const SdEmptyStateV3(
              icon: Symbols.local_shipping_rounded,
              title: 'Nothing to ship',
              message: 'Every paid order is on its way.',
            )
          : ListView(
              padding: SdContentPaddingV3.screen(context),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                AppListCard(
                  children: orders
                      .map(
                        (Order order) => AppListRow(
                          title: order.lines.isEmpty
                              ? order.marketplace.displayName
                              : order.lines.first.title,
                          subtitle: _deadlineLine(context, order, now),
                          icon: Symbols.package_2_rounded,
                          iconTint: (order.isOverdue(now) ?? false)
                              ? context.sdTheme3.danger
                              : context.colorScheme3.primary,
                          onTap: () => context.push(AppRoutes.order(order.id)),
                          trailing: SdButtonV3(
                            variant: SdButtonVariantV3.primary,
                            label: 'Ship',
                            size: SdButtonSizeV3.small,
                            onPressed: () =>
                                ShipOrderSheet.show(context, order),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }

  /// "Due in 2d" reads as an instruction; a date reads as a fact to work out.
  static String _deadlineLine(
    BuildContext context,
    Order order,
    DateTime now,
  ) {
    final DateTime? deadline = order.shipByDate;
    final String marketplace = order.marketplace.displayName;

    if (deadline == null) return '$marketplace · no deadline';

    final int days = DateTimeUtils.daysBetween(now, deadline);

    if (days < 0) return '$marketplace · ${-days}d overdue';
    if (days == 0) return '$marketplace · due today';

    return '$marketplace · due in ${days}d';
  }
}
