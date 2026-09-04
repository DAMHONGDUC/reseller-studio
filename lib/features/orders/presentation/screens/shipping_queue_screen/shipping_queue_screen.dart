import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/option_picker_sheet.dart';
import '../../../../carriers/domain/entities/carrier.dart';
import '../../../../carriers/providers.dart';
import '../../../domain/entities/order.dart';
import '../../../providers.dart';
import '../../controllers/order_actions_controller.dart';
import '../../widgets/ship_order_sheet.dart';

part 'shipping_queue_screen_bulk_bar.dart';

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
///
/// **A whole run ships at once** (hard rule 16). Long-press starts a
/// selection — the gesture Inventory and Record sale already use — and the bar
/// asks for the carrier once instead of twelve times.
class ShippingQueueScreen extends ConsumerWidget {
  const ShippingQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> orders = ref.watch(ordersNeedingActionProvider);
    final DateTime now = ref.watch(clockProvider).now();
    final Set<String> selected = ref.watch(shippingSelectionProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: context.l10n.shippingQueueTitle,
        subtitle: orders.isEmpty
            ? null
            : context.l10n.shippingQueueCount(orders.length),
      ),
      bottomNavigationBar: selected.isEmpty ? null : const _ShipBulkBar(),
      body: orders.isEmpty
          ? SdEmptyStateV3(
              icon: AppIconConstant.localShipping,
              title: context.l10n.shippingQueueEmptyTitle,
              message: context.l10n.shippingQueueEmptyBody,
            )
          : ListView(
              padding: SdContentPaddingV3.screen(context),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                AppListCard(
                  children: orders
                      .map(
                        (Order order) => _QueueRow(
                          order: order,
                          now: now,
                          isSelected: selected.contains(order.id),
                          isSelecting: selected.isNotEmpty,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }
}

/// One parcel waiting to go.
class _QueueRow extends ConsumerWidget {
  const _QueueRow({
    required this.order,
    required this.now,
    required this.isSelected,
    required this.isSelecting,
  });

  final Order order;
  final DateTime now;
  final bool isSelected;
  final bool isSelecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOverdue = order.isOverdue(now) ?? false;

    return AppListRow(
      title: order.lines.isEmpty
          ? order.marketplaceName
          : order.lines.first.title,
      subtitle: _deadlineLine(context, order, now),
      // A ticked row reads as ticked without reading the words, and it still
      // carries its own title, so colour is never the only signal.
      icon: isSelected ? AppIconConstant.checkCircle : AppIconConstant.package,
      iconTint: isSelected
          ? context.colorScheme3.primary
          : isOverdue
          ? context.sdTheme3.danger
          : context.colorScheme3.primary,
      onLongPress: () =>
          ref.read(shippingSelectionProvider.notifier).toggle(order.id),
      onTap: isSelecting
          ? () => ref.read(shippingSelectionProvider.notifier).toggle(order.id)
          : () => context.push(AppRoutes.order(order.id)),
      // The per-parcel button steps aside while a run is being picked: two
      // ways to ship the same row, one of them a mis-tap, is not a choice.
      trailing: isSelecting
          ? null
          : SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: context.l10n.shippingQueueShip,
              size: SdButtonSizeV3.small,
              onPressed: () => ShipOrderSheet.show(context, order),
            ),
    );
  }

  /// "Due in 2d" reads as an instruction; a date reads as a fact to work out.
  static String _deadlineLine(BuildContext context, Order order, DateTime now) {
    final DateTime? deadline = order.shipByDate;
    final String marketplace = order.marketplaceName;

    if (deadline == null) return context.l10n.shippingNoDeadline(marketplace);

    final int days = DateTimeUtils.daysBetween(now, deadline);

    if (days < 0) return context.l10n.shippingOverdueBy(marketplace, -days);
    if (days == 0) return context.l10n.shippingDueToday(marketplace);

    return context.l10n.shippingDueIn(marketplace, days);
  }
}
