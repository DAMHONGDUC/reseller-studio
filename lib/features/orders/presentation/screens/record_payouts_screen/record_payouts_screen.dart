import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_marketplace_tag.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/money_field.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/entities/order.dart';
import '../../../providers.dart';
import '../../controllers/order_actions_controller.dart';

/// Record what several platforms paid, in one sitting.
///
/// **The screen the payout-first model exists to make cheap.** A sale with no
/// payout has no fee and therefore no profit (hard rule 3), so this queue is
/// what stands between the seller and a business whose figures read `—`.
/// Doing it one order at a time through the detail screen is the version
/// nobody finishes — bulk is a first-class requirement (hard rule 16).
///
/// **A box per order, not a wizard.** A seller works down a bank statement or
/// a marketplace's payout report, and the shape that matches is a list they
/// can jump around in — not a flow that asks them to confirm one before it
/// shows the next.
class RecordPayoutsScreen extends ConsumerStatefulWidget {
  const RecordPayoutsScreen({super.key});

  @override
  ConsumerState<RecordPayoutsScreen> createState() =>
      _RecordPayoutsScreenState();
}

class _RecordPayoutsScreenState extends ConsumerState<RecordPayoutsScreen> {
  /// One box per order, keyed by order id.
  ///
  /// Held rather than rebuilt so a figure survives the stream re-emitting
  /// under the screen — a saved order leaves the queue, and the rest must not
  /// lose what the seller has already typed into them.
  final Map<String, TextEditingController> _boxes =
      <String, TextEditingController>{};

  @override
  void dispose() {
    for (final TextEditingController box in _boxes.values) {
      box.dispose();
    }

    super.dispose();
  }

  TextEditingController _boxFor(String orderId) =>
      _boxes.putIfAbsent(orderId, TextEditingController.new);

  /// Only the boxes with a figure in them. An empty one is an order the seller
  /// has not got to yet, never a payout of nothing.
  Map<String, Money> _typed(String currency) => <String, Money>{
    for (final MapEntry<String, TextEditingController> entry in _boxes.entries)
      if (Money.tryParse(entry.value.text, currency) case final Money amount)
        entry.key: amount,
  };

  Future<void> _submit(List<Order> orders) async {
    final NavigatorState navigator = Navigator.of(context);
    final String currency = ref.read(workspaceCurrencyProvider);
    final Map<String, Money> payouts = _typed(currency);

    try {
      await ref
          .read(orderActionsControllerProvider.notifier)
          .recordManySettlements(orders, payouts);

      if (!mounted) return;

      // Back to Payouts, where the marketplace totals have just moved.
      navigator.pop();
      SdSnackBarUtilsV3.success(
        context,
        context.l10n.recordPayoutsDone(payouts.length),
      );
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Order> orders = ref.watch(ordersAwaitingPayoutListProvider);
    final bool isBusy = ref.watch(orderActionsControllerProvider);
    final String currency = ref.watch(workspaceCurrencyProvider);
    final int filled = _typed(currency).length;

    if (orders.isEmpty) {
      return SdScaffoldV3(
        appBar: SdAppBarV3(title: context.l10n.recordPayoutsTitle),
        body: SdEmptyStateV3(
          icon: AppIconConstant.checkCircle,
          title: context.l10n.recordPayoutsAllDone,
          message: context.l10n.recordPayoutsAllDoneNote,
        ),
      );
    }

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: context.l10n.recordPayoutsTitle,
        actions: <Widget>[
          // The file is the faster way through the same queue, so it lives on
          // the screen that queue is on rather than a level up.
          SdAppBarActionButtonV3(
            icon: AppIconConstant.upload,
            tooltip: context.l10n.importPayoutsAction,
            onPressed: () => context.push(AppRoutes.importPayouts),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: SdContentPaddingV3.horizontal,
              ),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                Text(
                  context.l10n.recordPayoutsIntro,
                  style: context.textTheme3.bodySmall!.muted3(context),
                ),
                SizedBox(height: SdContentPaddingV3.sectionGap),
                for (final Order order in orders) ...<Widget>[
                  _PayoutRow(
                    order: order,
                    controller: _boxFor(order.id),
                    currency: currency,
                    onChanged: () => setState(() {}),
                  ),
                  SizedBox(height: SdSpacingConstant.h16),
                ],
                SizedBox(height: SdContentPaddingV3.bottomGap),
              ],
            ),
          ),
          AppPinnedAction(
            label: context.l10n.recordPayoutsSubmit(filled),
            isBusy: isBusy,
            onPressed: isBusy || filled == 0 ? null : () => _submit(orders),
          ),
        ],
      ),
    );
  }
}

/// One sale, and the box for what it paid.
///
/// The sale price sits beside the box because that is what the figure is
/// checked against — a payout larger than the sale is a typo, and a seller can
/// only see that if both numbers are on the same line.
class _PayoutRow extends StatelessWidget {
  const _PayoutRow({
    required this.order,
    required this.controller,
    required this.currency,
    required this.onChanged,
  });

  final Order order;
  final TextEditingController controller;
  final String currency;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final Money? typed = Money.tryParse(controller.text, currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            AppMarketplaceDot(marketplaceId: order.marketplaceId),
            SizedBox(width: SdSpacingConstant.w6),
            Expanded(
              child: Text(
                order.lines.isEmpty
                    ? order.marketplaceName
                    : order.lines.first.title,
                style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            Text(
              context.money(order.salePrice),
              style: context.textTheme3.bodySmall!.tabular3.copyWith(
                color: context.sdTheme3.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h6),
        MoneyField(
          label: context.l10n.settlePayout,
          controller: controller,
          currency: currency,
          // What this figure says the platform kept, as it is typed — the
          // seller is checking a subtraction, not copying a number blind.
          helperText: typed == null
              ? context.l10n.recordPayoutsRowHint(
                  DateTimeUtils.mediumDate(
                    order.orderedAt,
                    locale: context.localeTag,
                  ),
                )
              : context.l10n.recordPayoutsRowKept(
                  context.money(order.salePrice - typed),
                ),
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
